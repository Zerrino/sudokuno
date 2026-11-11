package com.alexafer.sudokuno.ui

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.activity.compose.BackHandler
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.ExperimentalComposeUiApi
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.testTagsAsResourceId
import androidx.compose.ui.unit.dp
import com.alexafer.sudokuno.i18n.L
import com.alexafer.sudokuno.kit.PuzzleCode
import com.alexafer.sudokuno.model.AppModel
import com.alexafer.sudokuno.model.Challenge
import com.alexafer.sudokuno.model.CompletionSummary
import com.alexafer.sudokuno.model.GameSession
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch

enum class Route { HOME, STREAK, STATS, SETTINGS, LEADERBOARD, ENTER_CODE, CREATOR, HISTORY, LEGENDS, MY_GRIDS }

/** Navigation et lancement des parties (équivalent du Router iOS). */
class Router {
    val stack = mutableStateListOf(Route.HOME)
    var activeGame by mutableStateOf<GameSession?>(null)
    var loadingMessage by mutableStateOf<String?>(null)
    internal var scope: CoroutineScope? = null

    val current: Route get() = stack.last()
    fun push(r: Route) { stack.add(r) }
    fun pop() { if (stack.size > 1) stack.removeAt(stack.lastIndex) }

    fun play(message: String? = null, make: suspend () -> GameSession) {
        if (loadingMessage != null) return
        loadingMessage = message ?: L("Préparation de la grille…")
        scope?.launch {
            val s = make()
            loadingMessage = null
            activeGame = s
        }
    }
}

@OptIn(ExperimentalComposeUiApi::class)
@Composable
fun SudokunoApp(model: AppModel, router: Router) {
    val scope = rememberCoroutineScope()
    router.scope = scope
    val p = LocalPalette.current
    LaunchedEffect(Unit) { model.prepareUnlockedLevels() }

    Box(Modifier.fillMaxSize().background(p.background).semantics { testTagsAsResourceId = true }) {
        val game = router.activeGame
        if (game != null) {
            BackHandler { model.save(game); router.activeGame = null }
            GameScreen(model, router, game)
        } else {
            BackHandler(enabled = router.stack.size > 1) { router.pop() }
            when (router.current) {
                Route.HOME -> HomeScreen(model, router)
                Route.STREAK -> StreakScreen(model, router)
                Route.STATS -> StatsScreen(model, router)
                Route.SETTINGS -> SettingsScreen(model, router)
                Route.LEADERBOARD -> LeaderboardScreen(model, router)
                Route.ENTER_CODE -> EnterCodeScreen(model, router)
                Route.CREATOR -> CreatorScreen(model, router)
                Route.HISTORY -> HistoryScreen(model, router)
                Route.LEGENDS -> LegendsScreen(model, router)
                Route.MY_GRIDS -> MyGridsScreen(model, router)
            }
        }
        router.loadingMessage?.let { msg ->
            Box(Modifier.fillMaxSize().background(Color.Black.copy(alpha = 0.25f)), contentAlignment = Alignment.Center) {
                Column(
                    Modifier.background(p.card, RoundedCornerShape(24.dp)).padding(28.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(14.dp),
                ) {
                    CircularProgressIndicator()
                    Text(msg)
                }
            }
        }
    }
}

/** Messages et liens de partage (équivalent de ShareContent.swift). */
object ShareContent {
    data class Link(val code: PuzzleCode, val challenge: Challenge?)

    fun url(code: PuzzleCode, challenge: Challenge?): String {
        val base = "sudokuno://p/${code.string}"
        return if (challenge == null) base else "$base?t=${challenge.seconds}&h=${challenge.hints}"
    }

    fun parse(uri: Uri): Link? {
        if (uri.scheme != "sudokuno" || uri.host != "p") return null
        val code = PuzzleCode.parse(uri.lastPathSegment ?: return null) ?: return null
        val t = uri.getQueryParameter("t")?.toIntOrNull()
        val h = uri.getQueryParameter("h")?.toIntOrNull()
        return Link(code, t?.let { Challenge(it, h ?: 0) })
    }

    fun parse(text: String): Link? {
        val code = PuzzleCode.find(text) ?: return null
        val m = Regex("t=(\\d+)&h=(\\d+)").find(text)
        return Link(code, m?.let { Challenge(it.groupValues[1].toInt(), it.groupValues[2].toInt()) })
    }

    fun hintsText(hints: Int, enabled: Boolean): String = when {
        !enabled -> L("🚫 sans aide")
        hints == 0 -> L("💡 sans indice")
        else -> L("💡 %lld indices", hints)
    }

    fun resultMessage(s: CompletionSummary, streak: Int): String {
        val label = if (s.code.isDaily) L("Sudoku du jour · %@", s.level.displayName) else s.level.displayName
        val flame = if (s.countsForDaily && streak > 0) " 🔥$streak" else ""
        return "Sudokuno · $label$flame\n⏱ ${clock(s.seconds)} · ${hintsText(s.hints, s.hintsEnabled)}\n" +
            L("À toi de battre mon temps ! Code : %@", s.code.string) + "\n" + url(s.code, Challenge(s.seconds, s.hints))
    }

    fun inviteMessage(code: PuzzleCode, levelName: String): String =
        L("Essaie cette grille Sudokuno (%@) !", levelName) + "\n" + L("Code : %@", code.string) + "\n" + url(code, null)

    fun share(context: Context, text: String) {
        val send = Intent(Intent.ACTION_SEND).setType("text/plain").putExtra(Intent.EXTRA_TEXT, text)
        context.startActivity(Intent.createChooser(send, null))
    }
}
