package com.alexafer.sudokuno.services

import android.app.Activity
import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.alexafer.sudokuno.kit.DayStamp
import com.alexafer.sudokuno.kit.Level
import com.google.android.gms.games.LeaderboardsClient
import com.google.android.gms.games.PlayGames
import com.google.android.gms.games.PlayGamesSdk
import com.google.android.gms.games.leaderboard.LeaderboardVariant
import kotlinx.coroutines.suspendCancellableCoroutine
import java.lang.ref.WeakReference
import kotlin.coroutines.resume

/** Identifiants logiques ; les vrais identifiants Play Jeux sont dans res/values/games-ids.xml. */
object LeaderboardId {
    const val DAILY = "daily"
    const val DAILY_NO_HINT = "daily_nohint"
    const val STREAK = "streak"
    fun best(level: Level) = "best_${level.servicesLetter}"
}

object AchievementId {
    const val PERFECT = "perfect"
    const val FIRST_DIABOLIQUE = "diabolique_first"
    const val FIRST_CHALLENGE_WON = "challenge_won"
    const val FIRST_LEGEND = "legend_first"
    fun unlocked(level: Level) = "unlock_${level.servicesLetter}"
    fun streak(days: Int) = "streak_$days"
    val STREAKS = listOf(7, 30, 100, 365, 1000)
    /** Progressif : 100 grilles résolues au total. */
    const val SOLVED_100 = "solved_100"
    /** Grilles créées avec l'éditeur ; 1 = succès normal, les autres sont progressifs. */
    fun created(n: Int) = "created_$n"
    val CREATED = listOf(1, 5, 10, 25, 50, 100)
}

/**
 * Le « tag » d'un score Play Jeux (texte court) transporte indices, aides, erreurs et jour de la grille :
 * « h1e1m0d20261111 ». Il permet d'afficher les indices dans le classement de l'app et de filtrer
 * le classement quotidien sur la grille du jour (Play Jeux remet à zéro à minuit heure du Pacifique, pas UTC).
 */
data class ScoreTag(val hints: Int, val hintsEnabled: Boolean, val mistakes: Int, val day: String?) {
    val raw: String get() = "h${hints}e${if (hintsEnabled) 1 else 0}m${mistakes}d${day ?: ""}"

    companion object {
        private val re = Regex("h(\\d+)e([01])m(\\d+)d(\\d*)")
        fun parse(s: String?): ScoreTag? = s?.let { re.matchEntire(it) }?.let {
            ScoreTag(it.groupValues[1].toInt(), it.groupValues[2] == "1", it.groupValues[3].toInt(), it.groupValues[4].ifEmpty { null })
        }
    }
}

data class LeaderboardRow(val rank: Long, val name: String, val value: Long, val tag: ScoreTag?, val isMe: Boolean)

/** Google Play Jeux (équivalent de Game Center). Facultatif : l'app marche sans. */
class GameServices(private val context: Context) {
    var isAuthenticated by mutableStateOf(false); private set
    var playerName by mutableStateOf<String?>(null); private set
    /** Échec de la dernière connexion demandée par le joueur (affiché sous le bouton). */
    var signInFailed by mutableStateOf(false); private set
    /** Appelé après chaque connexion réussie (rattrape les succès progressifs). */
    var onSignedIn: (() -> Unit)? = null
    var enabled = true
    private var activity = WeakReference<Activity>(null)
    private var playerId: String? = null

    private fun res(prefix: String, id: String): String? {
        val resId = context.resources.getIdentifier("${prefix}_$id", "string", context.packageName)
        return if (resId == 0) null else context.getString(resId).ifBlank { null }
    }

    /** Configuré dans la console Google Play ? (identifiant de projet renseigné) */
    val isConfigured: Boolean get() = (res("game_services", "project_id") ?: "0") != "0"

    fun initialize(activity: Activity) {
        this.activity = WeakReference(activity)
        if (!enabled || !isConfigured) return
        PlayGamesSdk.initialize(context)
        PlayGames.getGamesSignInClient(activity).isAuthenticated.addOnCompleteListener { task ->
            isAuthenticated = task.isSuccessful && task.result.isAuthenticated
            if (isAuthenticated) { loadPlayer(activity); onSignedIn?.invoke() }
        }
    }

    fun signIn() {
        val a = activity.get() ?: return
        if (!enabled || !isConfigured) return
        signInFailed = false
        PlayGames.getGamesSignInClient(a).signIn().addOnCompleteListener { task ->
            isAuthenticated = task.isSuccessful && task.result.isAuthenticated
            signInFailed = !isAuthenticated
            if (isAuthenticated) { loadPlayer(a); onSignedIn?.invoke() }
            // Cause la plus fréquente : identifiants OAuth Android (SHA-1) absents de la console Play Jeux,
            // ou compte non ajouté aux testeurs tant que la configuration n'est pas publiée.
            else android.util.Log.w("Sudokuno", "Connexion Play Jeux refusée", task.exception)
        }
    }

    private fun loadPlayer(a: Activity) {
        PlayGames.getPlayersClient(a).currentPlayer.addOnSuccessListener {
            playerName = it.displayName
            playerId = it.playerId
        }
    }

    private fun leaderboards(): LeaderboardsClient? = activity.get()?.let { PlayGames.getLeaderboardsClient(it) }

    fun submit(seconds: Int, level: Level, hints: Int, hintsEnabled: Boolean, mistakes: Int, boards: List<String>, day: DayStamp?) {
        if (!isAuthenticated) { android.util.Log.i("Sudokuno", "Score non envoyé : pas connecté à Play Jeux"); return }
        if (seconds < level.minimumPlausibleSeconds) { android.util.Log.i("Sudokuno", "Score non envoyé : temps trop court ($seconds s)"); return }
        val client = leaderboards() ?: return
        val tag = ScoreTag(hints, hintsEnabled, mistakes, day?.key).raw
        for (b in boards) res("leaderboard", b)?.let { id ->
            // format « temps » en ms ; envoi immédiat pour pouvoir relire le classement juste après
            client.submitScoreImmediate(id, seconds * 1000L, tag)
                .addOnFailureListener { android.util.Log.w("Sudokuno", "Score refusé par Play Jeux ($b)", it) }
        }
    }

    fun submitStreak(days: Int) {
        if (!isAuthenticated || days <= 0) return
        res("leaderboard", LeaderboardId.STREAK)?.let { leaderboards()?.submitScore(it, days.toLong()) }
    }

    /** Succès progressif : fixe le nombre d'étapes (sans effet s'il est déjà plus haut). */
    fun setSteps(id: String, steps: Int) {
        if (!isAuthenticated || steps <= 0) return
        val a = activity.get() ?: return
        res("achievement", id)?.let { PlayGames.getAchievementsClient(a).setSteps(it, steps) }
    }

    fun unlock(ids: List<String>) {
        if (!isAuthenticated) return
        val a = activity.get() ?: return
        val client = PlayGames.getAchievementsClient(a)
        for (id in ids) res("achievement", id)?.let { client.unlock(it) }
    }

    /** Top 50 d'un classement. Pour le classement du jour, on ne garde que les scores de la grille du jour. */
    suspend fun loadTop(board: String, today: DayStamp): List<LeaderboardRow> {
        val client = leaderboards() ?: return emptyList()
        val id = res("leaderboard", board) ?: return emptyList()
        val daily = board == LeaderboardId.DAILY || board == LeaderboardId.DAILY_NO_HINT
        val span = if (daily) LeaderboardVariant.TIME_SPAN_DAILY else LeaderboardVariant.TIME_SPAN_ALL_TIME
        return suspendCancellableCoroutine { cont ->
            client.loadTopScores(id, span, LeaderboardVariant.COLLECTION_PUBLIC, 50, true) // true : pas de cache
                .addOnSuccessListener { data ->
                    val scores = data.get()?.scores
                    val rows = scores?.map {
                        LeaderboardRow(it.rank, it.scoreHolderDisplayName, it.rawScore, ScoreTag.parse(it.scoreTag),
                            it.scoreHolder?.playerId == playerId)
                    }.orEmpty().filter { !daily || it.tag?.day == today.key }
                    scores?.release()
                    cont.resume(rows)
                }
                .addOnFailureListener { cont.resume(emptyList()) }
        }
    }

    /** Score du joueur sur un classement, même s'il n'apparaît pas dans la liste publique (profil privé). */
    suspend fun loadMine(board: String, today: DayStamp): LeaderboardRow? {
        val client = leaderboards() ?: return null
        val id = res("leaderboard", board) ?: return null
        val daily = board == LeaderboardId.DAILY || board == LeaderboardId.DAILY_NO_HINT
        val span = if (daily) LeaderboardVariant.TIME_SPAN_DAILY else LeaderboardVariant.TIME_SPAN_ALL_TIME
        return suspendCancellableCoroutine { cont ->
            client.loadCurrentPlayerLeaderboardScore(id, span, LeaderboardVariant.COLLECTION_PUBLIC)
                .addOnSuccessListener { data ->
                    val s = data.get()
                    val row = s?.let { LeaderboardRow(it.rank, it.scoreHolderDisplayName, it.rawScore, ScoreTag.parse(it.scoreTag), true) }
                    cont.resume(row?.takeIf { !daily || it.tag?.day == today.key })
                }
                .addOnFailureListener { cont.resume(null) }
        }
    }

    fun showAllLeaderboards() {
        val a = activity.get() ?: return
        leaderboards()?.allLeaderboardsIntent?.addOnSuccessListener { a.startActivityForResult(it, 9001) }
    }

    fun showAchievements() {
        val a = activity.get() ?: return
        PlayGames.getAchievementsClient(a).achievementsIntent.addOnSuccessListener { a.startActivityForResult(it, 9002) }
    }
}
