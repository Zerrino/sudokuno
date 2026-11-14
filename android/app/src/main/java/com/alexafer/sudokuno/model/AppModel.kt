package com.alexafer.sudokuno.model

import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.setValue
import com.alexafer.sudokuno.kit.DayStamp
import com.alexafer.sudokuno.kit.DailySchedule
import com.alexafer.sudokuno.kit.LegendPuzzle
import com.alexafer.sudokuno.kit.Level
import com.alexafer.sudokuno.kit.LevelProgress
import com.alexafer.sudokuno.kit.Puzzle
import com.alexafer.sudokuno.kit.PuzzleCode
import com.alexafer.sudokuno.kit.PuzzleFactory
import com.alexafer.sudokuno.kit.StreakState
import com.alexafer.sudokuno.services.AchievementId
import com.alexafer.sudokuno.services.GameServices
import com.alexafer.sudokuno.services.LeaderboardId
import com.alexafer.sudokuno.services.TipJar
import com.alexafer.sudokuno.kit.Scoring
import com.alexafer.sudokuno.kit.Technique
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import java.io.File
import java.util.UUID

@Serializable
data class LevelStats(
    val started: Int = 0,
    val won: Int = 0,
    val totalSeconds: Int = 0,
    val bestSeconds: Int? = null,
    val perfect: Int = 0,
    /** Meilleur temps d'une grille parfaite (voir `AppModel.isRanked`) : le seul envoyé aux classements. */
    val bestRankedSeconds: Int? = null,
) {
    val averageSeconds: Int? get() = if (won > 0) totalSeconds / won else null
    val winRate: Double? get() = if (started > 0) won.toDouble() / started else null
}

/** Une grille de « Mes grilles » (créée avec l'éditeur ou reçue par lien / code). */
@Serializable
data class GridRecord(val code: String, val date: Long) {
    val puzzleCode: PuzzleCode? get() = PuzzleCode.parse(code)
}

@Serializable
data class DailyResult(
    val seconds: Int, val hints: Int, val mistakes: Int, val onTime: Boolean,
    /** Grille parfaite, donc envoyée au classement du jour. */
    val ranked: Boolean = false,
    /** Score de la partie classée (classement du jour au score), une fois calculé. */
    val score: Int? = null,
)

/** Score enregistré d'une partie (copie de `GameScore` du moteur, pour la sauvegarde). */
@Serializable
data class ScoreRecord(
    val total: Int, val deduced: Int, val guessed: Int, val hinted: Int, val timePermille: Int,
    /** Version du calcul (null = première version, à recalculer). */
    val version: Int? = null,
    /** Technique la plus difficile utilisée (`ordinal` de `Technique`). */
    val hardest: Int? = null,
) {
    val isCurrent: Boolean get() = version == Scoring.VERSION
    val hardestTechnique: Technique? get() = hardest?.let { Technique.entries.getOrNull(it) }
}

/** Une grille terminée (ou abandonnée, avec son état pour la reprendre). */
@Serializable
data class HistoryEntry(
    val id: String = UUID.randomUUID().toString(),
    val code: String,
    val mode: GameMode,
    val level: Int,
    val seconds: Int,
    val hints: Int,
    val mistakes: Int,
    val hintsEnabled: Boolean,
    val completedAt: Long,
    val abandoned: SavedGame? = null,
    /** Journal de la partie terminée, pour la revoir coup par coup. Absent des parties d'avant le replay. */
    val playback: Playback? = null,
    /** Grille ratée (trop d'erreurs, ou validation d'une grille fausse). */
    val failed: Boolean = false,
    /** Score de la partie réussie, calculé juste après la victoire. */
    val score: ScoreRecord? = null,
    /** Classements où envoyer le score dès qu'il est calculé (grille parfaite du premier coup). */
    val boards: List<String>? = null,
    /** Partie d'entraînement (grille déjà jouée, ou ratée puis continuée) : elle ne compte nulle part. */
    val practice: Boolean = false,
) {
    val isAbandoned: Boolean get() = abandoned != null
    /** Grille réellement réussie : ni abandonnée, ni ratée. */
    val isWin: Boolean get() = !isAbandoned && !failed && !practice
    /** La partie à revoir : celle d'une grille terminée, ou le début d'une partie abandonnée. */
    val review: Playback? get() = abandoned?.let { s -> s.moves?.let { Playback(s.givens, s.solution, it) } } ?: if (abandoned == null) playback else null
    val puzzleCode: PuzzleCode get() = PuzzleCode.parse(code)!!
    val levelValue: Level get() = Level.entries[level]
}

/** Tout ce qui est sauvegardé sur l'appareil (fichier JSON local, rien n'est envoyé). */
@Serializable
data class PersistedState(
    val streak: StreakState = StreakState(),
    val progress: LevelProgress = LevelProgress(),
    val stats: MutableMap<Int, LevelStats> = mutableMapOf(),
    val saved: MutableMap<String, SavedGame> = mutableMapOf(),
    val dailyResults: MutableMap<Int, DailyResult> = mutableMapOf(),
    val achievements: MutableSet<String> = mutableSetOf(),
    var challengesWon: Int = 0,
    val history: MutableList<HistoryEntry> = mutableListOf(),
    /** Codes des grilles créées avec l'éditeur (jouées, partagées ou copiées). */
    val created: MutableSet<String> = mutableSetOf(),
    /** « Mes grilles », la plus récente d'abord. */
    val createdGrids: MutableList<GridRecord> = mutableListOf(),
    val receivedGrids: MutableList<GridRecord> = mutableListOf(),
    /** Meilleur score envoyé à chaque classement (hors classement du jour), pour le renvoyer à la connexion. */
    val bestScores: MutableMap<String, Int> = mutableMapOf(),
    /** Meilleur score de chaque grille réussie : leur somme est le total (`LeaderboardId.TOTAL`). */
    val scoredCodes: MutableMap<String, Int> = mutableMapOf(),
) {
    val scoreTotal: Int get() = scoredCodes.values.sum()
}

data class CompletionSummary(
    val seconds: Int,
    val mistakes: Int,
    val hints: Int,
    val hintsEnabled: Boolean,
    val level: Level,
    val code: PuzzleCode,
    val mode: GameMode,
    val isNewRecord: Boolean = false,
    val previousBest: Int? = null,
    val streak: Int? = null,
    val milestone: Int? = null,
    val unlocked: Level? = null,
    val countsForDaily: Boolean = false,
    /** Entraînement : la partie ne compte pas. */
    val practice: Boolean = false,
    /** Ligne de l'historique de cette partie : son score y est inscrit dès qu'il est calculé. */
    val entryId: String? = null,
) {
    val isPerfect: Boolean get() = hints == 0 && mistakes == 0
}

/** Cœur de l'app Android, équivalent de AppModel.swift. */
class AppModel(context: Context, val settings: Settings, val debug: DebugOptions = DebugOptions()) {
    private val file = File(context.filesDir, "sudokuno-state.json")
    private val json = Json { ignoreUnknownKeys = true; encodeDefaults = true; allowStructuredMapKeys = true }

    /** Incrémenté à chaque modification : Compose relit l'état. */
    var revision by mutableIntStateOf(0)
        private set
    private var _state = PersistedState()
    val state: PersistedState get() { revision; return _state }

    val gameServices = GameServices(context)
        .also { it.onSignedIn = { syncGameServices() } }
    val tipJar = TipJar(context)

    private val prepared = mutableMapOf<Level, Puzzle>()
    /** Calculs de score : ils continuent même si l'écran de fin est fermé. */
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    init {
        load()
        if (debug.reset) _state = PersistedState()
        if (debug.demo) _state = demoState()
        if (debug.unlockAll) for (level in Level.generated) repeat(10) { _state.progress.recordWin(level) }
        refreshStreak()
        rescoreHistory()
    }

    private fun bump() { revision++ }

    private fun load() {
        runCatching { _state = json.decodeFromString(PersistedState.serializer(), file.readText()) }
    }

    fun persist() {
        runCatching { file.writeText(json.encodeToString(PersistedState.serializer(), _state)) }
        bump()
    }

    fun resetStatistics() {
        _state = PersistedState()
        persist()
    }

    val today: DayStamp get() = DayStamp.today()

    fun refreshStreak() {
        if (_state.streak.refresh(today) != null) persist()
    }

    // --- Génération ---

    suspend fun generate(code: PuzzleCode): Puzzle = withContext(Dispatchers.Default) { PuzzleFactory.make(code) }

    suspend fun prepareUnlockedLevels() {
        for (level in Level.generated) {
            if (_state.progress.isUnlocked(level) && prepared[level] == null) {
                prepared[level] = generate(PuzzleCode.LevelSeed(level, PuzzleFactory.randomSeed()))
            }
        }
    }

    // --- Démarrer / reprendre ---

    suspend fun newLevelGame(level: Level): GameSession {
        val puzzle = prepared.remove(level) ?: generate(PuzzleCode.LevelSeed(level, PuzzleFactory.randomSeed()))
        val s = _state.stats[level.ordinal] ?: LevelStats()
        _state.stats[level.ordinal] = s.copy(started = s.started + 1)
        val session = makeSession(puzzle, GameMode.LevelGame, null)
        save(session)
        return session
    }

    /** Lance (ou reprend) une grille de la Légende. Elle compte comme une partie du niveau Légende. */
    suspend fun newLegendGame(legend: LegendPuzzle): GameSession {
        val code = PuzzleCode.Custom(legend.givens)
        _state.saved[code.string]?.let { return resume(it) }
        val puzzle = generate(code)
        val s = _state.stats[Level.LEGENDE.ordinal] ?: LevelStats()
        _state.stats[Level.LEGENDE.ordinal] = s.copy(started = s.started + 1)
        val session = makeSession(puzzle, GameMode.LevelGame, null)
        save(session)
        return session
    }

    /** Meilleur temps sur une grille de la Légende (null = jamais résolue). */
    fun legendBest(legend: LegendPuzzle): Int? {
        val code = PuzzleCode.Custom(legend.givens).string
        return state.history.filter { it.code == code && it.isWin }.minOfOrNull { it.seconds }
    }

    fun legendInProgress(legend: LegendPuzzle): Boolean = state.saved.containsKey(PuzzleCode.Custom(legend.givens).string)

    /** Une grille créée avec l'éditeur est jouée, partagée ou copiée : elle compte pour les succès « créateur ». */
    fun recordCreated(code: PuzzleCode) {
        remember(code, _state.createdGrids)
        val isNew = _state.created.add(code.string)
        persist()
        if (isNew) syncProgressAchievements()
    }

    /** Ajoute (ou remonte) une grille en tête d'une liste de « Mes grilles ». */
    private fun remember(code: PuzzleCode, list: MutableList<GridRecord>) {
        list.removeAll { it.code == code.string }
        list.add(0, GridRecord(code.string, System.currentTimeMillis()))
        while (list.size > 200) list.removeAt(list.lastIndex)
    }

    fun forget(record: GridRecord, received: Boolean) {
        (if (received) _state.receivedGrids else _state.createdGrids).remove(record)
        persist()
    }

    /** Meilleur temps sur une grille (null = jamais résolue). */
    fun bestTime(code: String): Int? = state.history.filter { it.code == code && it.isWin }.minOfOrNull { it.seconds }

    fun isInProgress(code: String): Boolean = state.saved.containsKey(code)

    /** Ouvre une grille de « Mes grilles » : reprend la partie en cours, sinon la lance. */
    suspend fun openGrid(code: PuzzleCode): GameSession {
        _state.saved[code.string]?.let { return resume(it) }
        return sharedGame(code, null, record = false)
    }

    /**
     * À chaque connexion : renvoie ce qui a pu être obtenu hors connexion (succès, records, série, grille du jour).
     * Sans risque : Play Jeux ignore un succès déjà débloqué et garde le meilleur score.
     */
    fun syncGameServices() {
        gameServices.unlock(_state.achievements.toList())
        // Seulement les scores des grilles parfaites (les classements au score sont partis de zéro).
        for ((board, score) in _state.bestScores) gameServices.submitScore(score, true, listOf(board), null)
        _state.dailyResults[today.dayNumber]?.takeIf { it.onTime && it.ranked }?.score?.let {
            gameServices.submitScore(it, true, listOf(LeaderboardId.DAILY), today)
        }
        gameServices.submitScore(_state.scoreTotal, true, listOf(LeaderboardId.TOTAL), null)
        gameServices.submitStreak(_state.streak.longest)
        syncProgressAchievements()
    }

    /** Succès progressifs (grilles résolues, grilles créées), recalculés depuis l'état local. */
    fun syncProgressAchievements() {
        gameServices.setSteps(AchievementId.SOLVED_100, minOf(_state.history.count { it.isWin }, 100))
        val made = _state.created.size
        if (made >= 1) gameServices.unlock(listOf(AchievementId.created(1)))
        for (n in AchievementId.CREATED.drop(1)) gameServices.setSteps(AchievementId.created(n), minOf(made, n))
    }

    /** Parties en cours, la plus récente d'abord. */
    val inProgress: List<SavedGame> get() = state.saved.values.sortedByDescending { it.updatedAt }

    val lastInProgress: SavedGame?
        get() = inProgress.firstOrNull { it.code != PuzzleCode.Daily(today).string }

    fun resume(saved: SavedGame): GameSession = makeSession(
        Puzzle(saved.puzzleCode, saved.levelValue, com.alexafer.sudokuno.kit.Grid.parse(saved.givens)!!,
            com.alexafer.sudokuno.kit.Grid.parse(saved.solution)!!),
        saved.mode, saved,
    )

    suspend fun dailyGame(day: DayStamp): GameSession {
        val code = PuzzleCode.Daily(day)
        _state.saved[code.string]?.let { return resume(it) }
        return makeSession(generate(code), GameMode.Daily, null)
    }

    /** Un code reçu peut-il être ouvert ? (solution unique, et pas une grille du jour à venir) */
    fun canOpen(code: PuzzleCode): Boolean =
        !(code is PuzzleCode.Daily && code.day > today) && com.alexafer.sudokuno.kit.PuzzleAnalysis.isPlayable(code)

    suspend fun sharedGame(code: PuzzleCode, challenge: Challenge?, record: Boolean = true): GameSession {
        // Grille reçue (lien, code) : elle rejoint « Mes grilles », sauf si c'est une de mes créations.
        if (record && code.string !in _state.created) {
            remember(code, _state.receivedGrids)
            persist()
        }
        if (code is PuzzleCode.Daily && code.day <= today) return dailyGame(code.day)
        val saved = _state.saved[code.string]
        if (saved != null && saved.mode.challenge == challenge) return resume(saved)
        val puzzle = generate(code)
        // Une grille partagée compte dans les statistiques de son niveau, comme une partie normale.
        val s = _state.stats[puzzle.level.ordinal] ?: LevelStats()
        _state.stats[puzzle.level.ordinal] = s.copy(started = s.started + 1)
        return makeSession(puzzle, GameMode.Shared(challenge), null)
    }

    /** Recommencer une grille ratée : même grille, nouvelle partie. La grille du jour reste la grille du jour. */
    suspend fun retry(session: GameSession): GameSession {
        val code = session.puzzle.code
        if (code is PuzzleCode.Daily && session.mode == GameMode.Daily) return dailyGame(code.day)
        return sharedGame(code, null, record = false)
    }

    /**
     * Grille ratée : elle quitte les parties en cours et rejoint l'historique, marquée comme telle.
     * Elle ne compte ni comme victoire, ni pour la série, ni pour les classements.
     */
    /** Continuer une grille ratée : elle reste ratée dans l'historique, la suite ne compte pas. */
    fun continueAfterFailure(session: GameSession) {
        session.continueAfterFailure()
        save(session)
    }

    fun fail(session: GameSession) {
        val code = session.puzzle.code.string
        _state.saved.remove(code)
        _state.history.add(0, HistoryEntry(code = code, mode = session.mode, level = session.puzzle.level.ordinal,
            seconds = session.elapsed, hints = session.hintsUsed, mistakes = session.mistakes,
            hintsEnabled = session.hintsEnabled, completedAt = System.currentTimeMillis(), playback = session.playback, failed = true,
            practice = session.practice))
        while (_state.history.size > 300) _state.history.removeAt(_state.history.lastIndex)
        persist()
    }

    /**
     * Fin d'un entraînement : seulement l'historique (avec son score, pour information). Ni statistiques, ni déblocage,
     * ni série, ni succès, ni total, ni classements.
     */
    private fun completePractice(session: GameSession): CompletionSummary {
        val code = session.puzzle.code
        val entry = HistoryEntry(code = code.string, mode = session.mode, level = session.puzzle.level.ordinal, seconds = session.elapsed,
            hints = session.hintsUsed, mistakes = session.mistakes, hintsEnabled = session.hintsEnabled,
            completedAt = System.currentTimeMillis(), playback = session.playback, practice = true)
        _state.history.add(0, entry)
        while (_state.history.size > 300) _state.history.removeAt(_state.history.lastIndex)
        scoreWin(entry)
        persist()
        return CompletionSummary(session.elapsed, session.mistakes, session.hintsUsed, session.hintsEnabled, session.puzzle.level, code,
            session.mode, practice = true, entryId = entry.id)
    }

    /** Score d'une partie, calculé hors du fil principal (juger chaque coup demande de rejouer sa logique). */
    private suspend fun computeScore(entry: HistoryEntry): ScoreRecord? {
        val playback = entry.playback ?: return null
        return withContext(Dispatchers.Default) {
            val s = Scoring.score(playback.givensGrid, playback.solutionGrid, entry.levelValue, playback.decoded.map { it.scored }, entry.mistakes)
            ScoreRecord(s.total, s.deduced, s.guessed, s.hinted, s.timePermille, s.version, s.hardest)
        }
    }

    /**
     * Score d'une partie qui vient d'être gagnée : inscrit dans l'historique (l'écran de fin l'affiche dès qu'il arrive),
     * ajouté au total et envoyé aux classements.
     */
    private fun scoreWin(entry: HistoryEntry) = scope.launch {
        val score = computeScore(entry) ?: return@launch
        val i = _state.history.indexOfFirst { it.id == entry.id }
        if (i < 0) return@launch
        _state.history[i] = _state.history[i].copy(score = score)
        if (entry.practice) { persist(); return@launch }
        if (score.total > (_state.scoredCodes[entry.code] ?: 0)) _state.scoredCodes[entry.code] = score.total
        val boards = entry.boards.orEmpty()
        var day: DayStamp? = null
        for (board in boards) {
            if (board == LeaderboardId.DAILY) {
                val code = entry.puzzleCode
                if (code is PuzzleCode.Daily) {
                    day = code.day
                    _state.dailyResults[code.day.dayNumber]?.let { _state.dailyResults[code.day.dayNumber] = it.copy(score = score.total) }
                }
            } else {
                _state.bestScores[board] = maxOf(score.total, _state.bestScores[board] ?: 0)
            }
        }
        gameServices.submitScore(score.total, entry.hintsEnabled, boards, day)
        gameServices.submitScore(_state.scoreTotal, true, listOf(LeaderboardId.TOTAL), null)
        persist()
    }

    /** Recalcule les scores de l'historique faits avec une ancienne version du calcul (affichage seulement). */
    private fun rescoreHistory() {
        val stale = _state.history.filter { !it.isAbandoned && !it.failed && it.playback != null && it.score?.isCurrent != true }
        if (stale.isEmpty()) return
        scope.launch {
            for (entry in stale) {
                val score = computeScore(entry) ?: continue
                val i = _state.history.indexOfFirst { it.id == entry.id }
                if (i >= 0) _state.history[i] = _state.history[i].copy(score = score)
            }
            persist()
        }
    }

    suspend fun replay(entry: HistoryEntry): GameSession {
        val code = entry.puzzleCode
        if (code is PuzzleCode.Daily) return dailyGame(code.day)
        return makeSession(generate(code), GameMode.Shared(null), null)
    }

    fun savedDaily(day: DayStamp): SavedGame? = state.saved[PuzzleCode.Daily(day).string]
    fun dailyResult(day: DayStamp): DailyResult? = state.dailyResults[day.dayNumber]

    fun deleteSaved(saved: SavedGame) {
        _state.saved.remove(saved.code)
        persist()
    }

    /** Abandon : la partie rejoint l'historique avec son état, pour une reprise. */
    fun abandon(session: GameSession) {
        val snapshot = session.snapshot()
        session.isAbandoned = true
        _state.saved.remove(snapshot.code)
        _state.history.add(0, HistoryEntry(code = snapshot.code, mode = session.mode, level = session.puzzle.level.ordinal,
            seconds = session.elapsed, hints = session.hintsUsed, mistakes = session.mistakes,
            hintsEnabled = session.hintsEnabled, completedAt = System.currentTimeMillis(), abandoned = snapshot))
        persist()
    }

    fun resumeAbandoned(entry: HistoryEntry): GameSession? {
        val saved = entry.abandoned ?: return null
        _state.history.removeAll { it.id == entry.id }
        val session = resume(saved)
        save(session)
        return session
    }

    private fun makeSession(puzzle: Puzzle, mode: GameMode, saved: SavedGame?): GameSession {
        // Mode validation : toujours à partir de Diabolique, ou partout avec le réglage « Mode difficile ».
        // Une grille déjà jouée (réussie, ratée ou abandonnée) ne compte plus : entraînement.
        val practice = _state.history.any { it.code == puzzle.code.string }
        val session = GameSession(puzzle, mode, settings, strict = puzzle.level.mistakeLimit == null || settings.hardMode, saved = saved,
            practice = practice)
        if (saved == null && debug.prefillAllBut > 0) session.debugPrefill(debug.prefillAllBut)
        if (saved == null && debug.fillWithError) session.debugFillWithError()
        if (saved == null && debug.startElapsed > 0) session.debugSetElapsed(debug.startElapsed)
        if (saved == null && debug.fillNotes) session.debugFillNotes()
        session.onChange = { if (!session.isOver && !session.isAbandoned) save(session) }
        return session
    }

    fun save(session: GameSession) {
        if (session.isOver || session.isAbandoned) return
        _state.saved[session.puzzle.code.string] = session.snapshot()
        persist()
    }

    // --- Fin de partie ---

    fun complete(session: GameSession): CompletionSummary {
        val code = session.puzzle.code
        val level = session.puzzle.level
        _state.saved.remove(code.string)
        if (session.practice) return completePractice(session)
        var summary = CompletionSummary(session.elapsed, session.mistakes, session.hintsUsed, session.hintsEnabled, level, code, session.mode)
        val newAchievements = mutableListOf<String>()
        // Classements : seules les grilles parfaites comptent. Sans indice, sans erreur, et du premier coup
        // (la grille n'a jamais été terminée ni abandonnée puis recommencée).
        // Un temps impossible (grille remplie en quelques secondes) n'est jamais classé.
        val ranked = summary.isPerfect && _state.history.none { it.code == code.string } && session.elapsed >= level.minimumPlausibleSeconds
        /** Classements où ira le score, une fois calculé (`scoreWin`). */
        val boards = mutableListOf<String>()

        when (val mode = session.mode) {
            GameMode.LevelGame -> {
                val s = _state.stats[level.ordinal] ?: LevelStats()
                val best = s.bestSeconds
                val isRecord = best == null || session.elapsed < best
                _state.stats[level.ordinal] = s.copy(
                    won = s.won + 1, totalSeconds = s.totalSeconds + session.elapsed,
                    perfect = s.perfect + if (summary.isPerfect) 1 else 0,
                    bestSeconds = if (isRecord) session.elapsed else best,
                    bestRankedSeconds = if (ranked) minOf(session.elapsed, s.bestRankedSeconds ?: Int.MAX_VALUE) else s.bestRankedSeconds,
                )
                summary = summary.copy(previousBest = best, isNewRecord = isRecord && best != null)
                _state.progress.recordWin(level)?.let {
                    summary = summary.copy(unlocked = it)
                    newAchievements.add(AchievementId.unlocked(it))
                }
                // Au score, la Légende a aussi son classement : le score tient compte de la difficulté de chaque chiffre.
                if (ranked) boards += listOf(LeaderboardId.level(level), LeaderboardId.BEST)
            }
            GameMode.Daily -> if (code is PuzzleCode.Daily) {
                val onTime = code.day == today
                // Un résultat classé reste : rejouer la grille du jour ne le remplace pas.
                val previous = _state.dailyResults[code.day.dayNumber]
                if (previous == null || (onTime && !previous.ranked)) {
                    _state.dailyResults[code.day.dayNumber] = DailyResult(session.elapsed, session.hintsUsed, session.mistakes, onTime, ranked && onTime)
                }
                if (onTime) {
                    val milestone = _state.streak.recordCompletion(code.day)
                    summary = summary.copy(countsForDaily = true, milestone = milestone, streak = _state.streak.current)
                    if (ranked) boards += listOf(LeaderboardId.DAILY, LeaderboardId.BEST)
                    gameServices.submitStreak(_state.streak.longest)
                    for (m in AchievementId.STREAKS) if (_state.streak.current >= m) newAchievements.add(AchievementId.streak(m))
                }
            }
            is GameMode.Shared -> {
                // Une grille partagée réussie compte dans les statistiques de son niveau (pas dans les records ni le déblocage).
                val s = _state.stats[level.ordinal] ?: LevelStats()
                _state.stats[level.ordinal] = s.copy(won = s.won + 1, totalSeconds = s.totalSeconds + session.elapsed,
                    perfect = s.perfect + if (summary.isPerfect) 1 else 0)
                val c = mode.challenge
                if (c != null && session.elapsed < c.seconds) {
                    _state.challengesWon++
                    newAchievements.add(AchievementId.FIRST_CHALLENGE_WON)
                }
            }
        }

        val entry = HistoryEntry(code = code.string, mode = session.mode, level = level.ordinal, seconds = session.elapsed,
            hints = session.hintsUsed, mistakes = session.mistakes, hintsEnabled = session.hintsEnabled,
            completedAt = System.currentTimeMillis(), playback = session.playback, boards = boards.ifEmpty { null })
        summary = summary.copy(entryId = entry.id)
        _state.history.add(0, entry)
        scoreWin(entry)
        while (_state.history.size > 300) _state.history.removeAt(_state.history.lastIndex)

        if (summary.isPerfect) newAchievements.add(AchievementId.PERFECT)
        if (level == Level.DIABOLIQUE) newAchievements.add(AchievementId.FIRST_DIABOLIQUE)
        if (level == Level.LEGENDE) newAchievements.add(AchievementId.FIRST_LEGEND)
        val fresh = newAchievements.filter { it !in _state.achievements }
        _state.achievements.addAll(fresh)
        gameServices.unlock(fresh)
        syncProgressAchievements()

        persist()
        return summary
    }

    /** État de démonstration pour les captures : 12 jours de série, niveaux débloqués, records. */
    private fun demoState(): PersistedState {
        val s = PersistedState()
        val t = DayStamp.today()
        for (k in 12 downTo 1) {
            val day = t.adding(-k)
            s.streak.recordCompletion(day)
            s.dailyResults[day.dayNumber] = DailyResult(240 + k * 17, if (k % 3 == 0) 1 else 0, 0, true)
        }
        repeat(7) { s.progress.recordWin(Level.FACILE) }
        repeat(10) { s.progress.recordWin(Level.MOYEN) }
        repeat(4) { s.progress.recordWin(Level.DIFFICILE) }
        s.stats[Level.FACILE.ordinal] = LevelStats(8, 7, 7 * 251, 168, 5)
        s.stats[Level.MOYEN.ordinal] = LevelStats(11, 10, 10 * 402, 297, 6)
        s.stats[Level.DIFFICILE.ordinal] = LevelStats(5, 4, 4 * 655, 541, 1)
        return s
    }
}

/** Options de test (intent extras en debug), équivalentes aux arguments de lancement iOS. */
data class DebugOptions(
    val reset: Boolean = false,
    val demo: Boolean = false,
    val prefillAllBut: Int = 0,
    val startElapsed: Int = 0,
    val noGameServices: Boolean = false,
    val fillNotes: Boolean = false,
    val unlockAll: Boolean = false,
    val fillWithError: Boolean = false,
)
