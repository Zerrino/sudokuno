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
    fun best(level: Level) = "best_${level.codeLetter}"
}

object AchievementId {
    const val PERFECT = "perfect"
    const val FIRST_DIABOLIQUE = "diabolique_first"
    const val FIRST_CHALLENGE_WON = "challenge_won"
    fun unlocked(level: Level) = "unlock_${level.codeLetter}"
    fun streak(days: Int) = "streak_$days"
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
            if (isAuthenticated) loadPlayer(activity)
        }
    }

    fun signIn() {
        val a = activity.get() ?: return
        if (!enabled || !isConfigured) return
        PlayGames.getGamesSignInClient(a).signIn().addOnCompleteListener { task ->
            isAuthenticated = task.isSuccessful && task.result.isAuthenticated
            if (isAuthenticated) loadPlayer(a)
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
        if (!isAuthenticated || seconds < level.minimumPlausibleSeconds) return
        val client = leaderboards() ?: return
        val tag = ScoreTag(hints, hintsEnabled, mistakes, day?.key).raw
        for (b in boards) res("leaderboard", b)?.let { client.submitScore(it, seconds * 1000L, tag) } // format « temps » en ms
    }

    fun submitStreak(days: Int) {
        if (!isAuthenticated || days <= 0) return
        res("leaderboard", LeaderboardId.STREAK)?.let { leaderboards()?.submitScore(it, days.toLong()) }
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
            client.loadTopScores(id, span, LeaderboardVariant.COLLECTION_PUBLIC, 50)
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

    fun showAllLeaderboards() {
        val a = activity.get() ?: return
        leaderboards()?.allLeaderboardsIntent?.addOnSuccessListener { a.startActivityForResult(it, 9001) }
    }

    fun showAchievements() {
        val a = activity.get() ?: return
        PlayGames.getAchievementsClient(a).achievementsIntent.addOnSuccessListener { a.startActivityForResult(it, 9002) }
    }
}
