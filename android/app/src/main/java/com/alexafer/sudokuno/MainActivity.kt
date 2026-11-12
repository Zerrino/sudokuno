package com.alexafer.sudokuno

import kotlinx.coroutines.withContext
import kotlinx.coroutines.Dispatchers
import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableStateOf
import com.alexafer.sudokuno.i18n.AppLanguage
import com.alexafer.sudokuno.i18n.L10n
import com.alexafer.sudokuno.model.AppModel
import com.alexafer.sudokuno.model.AppTheme
import com.alexafer.sudokuno.model.DebugOptions
import com.alexafer.sudokuno.model.Settings
import com.alexafer.sudokuno.services.Reminder
import com.alexafer.sudokuno.ui.Router
import com.alexafer.sudokuno.ui.ShareContent
import com.alexafer.sudokuno.ui.SudokunoApp
import com.alexafer.sudokuno.ui.SudokunoTheme

class MainActivity : ComponentActivity() {
    private lateinit var model: AppModel
    private val router = Router()
    private val pendingLink = mutableStateOf<ShareContent.Link?>(null)

    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
        L10n.load(this)
        val settings = Settings(this)
        val debug = debugOptions(intent, settings)
        L10n.apply(settings.language)
        model = AppModel(applicationContext, settings, debug)
        model.gameServices.enabled = !debug.noGameServices
        if (BuildConfig.DEBUG && intent.getBooleanExtra("debugLeaderboard", false)) model.gameServices.demo = true
        model.gameServices.initialize(this)
        model.tipJar.load()
        Reminder.ensureChannel(this)
        handleLink(intent)
        if (BuildConfig.DEBUG) intent.getStringExtra("debugOpenURL")?.let { url ->
            ShareContent.parse(android.net.Uri.parse(url))?.let { pendingLink.value = it }
        }
        // Debug : ouvre directement la résolution expliquée d'une grille (81 caractères).
        if (BuildConfig.DEBUG) intent.getStringExtra("debugExplain")?.let { com.alexafer.sudokuno.kit.Grid.parse(it) }?.let { router.explain(it) }

        setContent {
            // Changer de langue reconstruit toute l'interface
            key(settings.language) {
                L10n.apply(settings.language)
                SudokunoTheme(settings.theme) {
                    SudokunoApp(model, router)
                    LaunchedEffect(pendingLink.value) {
                        val link = pendingLink.value ?: return@LaunchedEffect
                        pendingLink.value = null
                        // Lien invalide (grille sans solution unique, grille du jour à venir) : on l'ignore.
                        if (!withContext(Dispatchers.Default) { model.canOpen(link.code) }) return@LaunchedEffect
                        router.activeGame = null
                        router.play { model.sharedGame(link.code, link.challenge) }
                    }
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleLink(intent)
    }

    override fun onResume() {
        super.onResume()
        model.refreshStreak()
    }

    override fun onPause() {
        super.onPause()
        router.activeGame?.let { model.save(it) }
        Reminder.reschedule(this, model.settings.reminderEnabled, model.settings.reminderMinutes,
            model.state.streak.current, model.state.streak.isCompleted(model.today))
    }

    private fun handleLink(intent: Intent?) {
        val uri = intent?.data ?: return
        val link = ShareContent.parse(uri) ?: return
        if (com.alexafer.sudokuno.kit.PuzzleAnalysis.isPlayable(link.code)) pendingLink.value = link
    }

    /** En debug, les tests passent des « extras » équivalents aux arguments de lancement iOS. */
    private fun debugOptions(intent: Intent, settings: Settings): DebugOptions {
        if (!BuildConfig.DEBUG) return DebugOptions()
        intent.getStringExtra("appLanguage")?.let { settings.override(language = AppLanguage.fromCode(it)) }
        intent.getStringExtra("theme")?.let { settings.override(theme = AppTheme.from(it)) }
        // Les tests repartent de réglages connus : mode difficile et grand écran seulement s'ils les demandent.
        if (intent.hasExtra("debugReset")) {
            settings.hardMode = intent.getBooleanExtra("debugHardMode", false)
            settings.bigScreen = intent.getBooleanExtra("debugBigScreen", false)
            settings.hintsEnabled = true
        }
        return DebugOptions(
            reset = intent.getBooleanExtra("debugReset", false),
            demo = intent.getBooleanExtra("debugDemo", false),
            prefillAllBut = intent.getIntExtra("debugPrefillAllBut", 0),
            startElapsed = intent.getIntExtra("debugElapsed", 0),
            noGameServices = intent.getBooleanExtra("debugNoGameServices", false),
            fillNotes = intent.getBooleanExtra("debugFillNotes", false),
            unlockAll = intent.getBooleanExtra("debugUnlockAll", false),
            fillWithError = intent.getBooleanExtra("debugFillWithError", false),
        )
    }
}
