package com.alexafer.sudokuno.model

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.alexafer.sudokuno.i18n.L
import com.alexafer.sudokuno.ui.displayName
import com.alexafer.sudokuno.kit.Grid
import com.alexafer.sudokuno.kit.Hint
import com.alexafer.sudokuno.kit.HintEngine
import com.alexafer.sudokuno.kit.Legends
import com.alexafer.sudokuno.kit.Level
import com.alexafer.sudokuno.kit.Puzzle
import com.alexafer.sudokuno.kit.PuzzleCode
import com.alexafer.sudokuno.kit.Sudoku
import kotlinx.serialization.Serializable

/** Défi reçu par un lien ou un message partagé. */
@Serializable
data class Challenge(val seconds: Int, val hints: Int)

@Serializable
sealed interface GameMode {
    /** Partie de niveau : compte pour le déblocage et les records. */
    @Serializable data object LevelGame : GameMode
    /** Grille du jour. */
    @Serializable data object Daily : GameMode
    /** Grille ouverte depuis un code partagé, éventuellement avec un défi. */
    @Serializable data class Shared(override val challenge: Challenge? = null) : GameMode

    val challenge: Challenge? get() = null

    companion object {
        fun title(mode: GameMode, code: PuzzleCode, level: Level): String = when (mode) {
            LevelGame -> (code as? PuzzleCode.Custom)?.let { Legends.find(it.grid) }?.name ?: level.displayName
            Daily -> L("Du jour · %@", level.displayName)
            is Shared -> when {
                code is PuzzleCode.Custom && Legends.find(code.grid) != null -> L("Légende · %@", Legends.find(code.grid)!!.name)
                code is PuzzleCode.Custom -> L("Grille créée · %@", level.displayName)
                mode.challenge == null -> L("Grille partagée · %@", level.displayName)
                else -> L("Défi · %@", level.displayName)
            }
        }
    }
}

/** État sauvegardé d'une partie en cours. */
@Serializable
data class SavedGame(
    val code: String,
    val mode: GameMode,
    val level: Int,
    val givens: String,
    val solution: String,
    val values: List<Int>,
    val notes: List<Int>,
    val elapsed: Int,
    val mistakes: Int,
    val hintsUsed: Int,
    val hintsEnabled: Boolean,
    val updatedAt: Long,
    /** Journal des coups (`Move.packed`). Absent des sauvegardes d'avant le replay. */
    val moves: List<Int>? = null,
    /** Partie en mode validation (voir `GameSession.strict`). Absent des anciennes sauvegardes : mode normal. */
    val strict: Boolean? = null,
) {
    val puzzleCode: PuzzleCode get() = PuzzleCode.parse(code)!!
    val levelValue: Level get() = Level.entries[level]
    val filledCount: Int get() = values.count { it != 0 }
    val title: String get() = GameMode.title(mode, puzzleCode, levelValue)
}

/** Un coup du journal de partie : le chiffre d'une case change (0 = case effacée). Voir Playback.swift. */
data class Move(val cell: Int, val digit: Int, val kind: Kind, val time: Int) {
    /** Posé ou effacé par le joueur, joué par un indice, ou retour en arrière (bouton Annuler). */
    enum class Kind { PLAYER, HINT, UNDO }

    /** Forme compacte enregistrée : temps × 100 000 + type × 10 000 + case × 10 + chiffre. */
    val packed: Int get() = time * 100_000 + kind.ordinal * 10_000 + cell * 10 + digit

    companion object {
        fun unpack(packed: Int): Move? {
            val low = packed % 10_000
            val kind = Kind.entries.getOrNull(packed / 10_000 % 10)
            if (packed < 0 || kind == null || low / 10 >= 81) return null
            return Move(low / 10, low % 10, kind, packed / 100_000)
        }
    }
}

/** De quoi revoir une partie coup par coup depuis l'historique. */
@Serializable
data class Playback(val givens: String, val solution: String, val moves: List<Int>) {
    val decoded: List<Move> get() = moves.mapNotNull { Move.unpack(it) }
    val givensGrid: Grid get() = Grid.parse(givens)!!
    val solutionGrid: Grid get() = Grid.parse(solution)!!

    /** État de la grille après chaque coup : `states[0]` = grille de départ, `states[k]` = après le coup k. */
    fun states(): List<IntArray> {
        var current = givensGrid.cells.copyOf()
        val out = arrayListOf(current)
        for (m in decoded) {
            current = current.copyOf()
            current[m.cell] = m.digit
            out.add(current)
        }
        return out
    }

    fun isMistake(m: Move, solution: Grid): Boolean = m.kind == Move.Kind.PLAYER && m.digit != 0 && m.digit != solution[m.cell]
}

/** Une partie : toute la logique de jeu, sans interface (équivalent de GameSession.swift). */
class GameSession(
    val puzzle: Puzzle,
    val mode: GameMode,
    private val settings: Settings,
    strict: Boolean,
    saved: SavedGame? = null,
) {
    val id: Long = System.nanoTime()
    /**
     * Mode validation : aucune erreur n'est signalée pendant la partie, la grille se valide d'un coup une fois remplie.
     * Toujours actif à partir de Diabolique, et à tous les niveaux avec le réglage « Mode difficile ».
     * Fixé au début : une partie reprise garde les règles avec lesquelles elle a commencé.
     */
    val strict: Boolean = if (saved != null) saved.strict ?: false else strict

    val values = mutableStateListOf<Int>().apply { addAll(saved?.values ?: puzzle.givens.cells.toList()) }
    val notes = mutableStateListOf<Int>().apply { addAll(saved?.notes ?: List(81) { 0 }) }
    var selected by mutableStateOf<Int?>(null)
    var notesMode by mutableStateOf(false)
    var mistakes by mutableIntStateOf(saved?.mistakes ?: 0); private set
    var hintsUsed by mutableIntStateOf(saved?.hintsUsed ?: 0); private set
    var elapsed by mutableIntStateOf(saved?.elapsed ?: 0); private set
    var isComplete by mutableStateOf(false); private set
    /** Grille ratée : trop d'erreurs, ou validation d'une grille fausse. La partie est terminée. */
    var isFailed by mutableStateOf(false); private set
    /** Suit le réglage tant qu'aucun indice n'a été utilisé dans cette partie ; ensuite les indices restent activés. */
    val hintsEnabled: Boolean get() = hintsUsed > 0 || settings.hintsEnabled
    /** La partie est finie, gagnée ou ratée : plus aucune saisie. */
    val isOver: Boolean get() = isComplete || isFailed
    /** Erreurs tolérées (`null` en mode validation) : une de plus et la grille est ratée. */
    val mistakeLimit: Int? get() = if (strict) null else puzzle.level.mistakeLimit
    /** Les chiffres faux peuvent-ils être montrés ? Jamais en mode validation, sauf une fois la grille ratée. */
    val revealsMistakes: Boolean get() = !strict || isFailed
    /** Mode validation : la grille est pleine, le joueur peut la faire vérifier. */
    val canValidate: Boolean get() = strict && !isOver && values.none { it == 0 }
    var isAbandoned = false

    var activeHint by mutableStateOf<Hint?>(null); private set
    /** 1 = zone et technique, 2 = case. */
    var hintStage by mutableIntStateOf(0); private set

    sealed interface Event {
        data class Placed(val cell: Int, val correct: Boolean, val completedUnits: Int, val nonce: Int) : Event
        data object Completed : Event
        data object Failed : Event
    }
    var lastEvent by mutableStateOf<Event?>(null); private set
    private var nonce = 0

    var onChange: (() -> Unit)? = null

    /**
     * Journal des coups, pour revoir la partie depuis l'historique. `null` : partie reprise d'une ancienne
     * sauvegarde sans journal (le début manque, donc pas de replay).
     */
    private val moves: MutableList<Int>? = if (saved == null) ArrayList() else saved.moves?.toMutableList()
    private var applyingHint = false

    /** La partie telle qu'elle a été jouée, si son journal est complet. */
    val playback: Playback? get() = moves?.let { Playback(puzzle.givens.string, puzzle.solution.string, it.toList()) }

    private fun log(cell: Int, digit: Int, kind: Move.Kind) {
        moves?.add(Move(cell, digit, kind, elapsed).packed)
    }

    init {
        isComplete = values.toList() == puzzle.solution.cells.toList()
    }

    fun snapshot() = SavedGame(
        code = puzzle.code.string, mode = mode, level = puzzle.level.ordinal,
        givens = puzzle.givens.string, solution = puzzle.solution.string,
        values = values.toList(), notes = notes.toList(), elapsed = elapsed, mistakes = mistakes,
        hintsUsed = hintsUsed, hintsEnabled = hintsEnabled, updatedAt = System.currentTimeMillis(),
        moves = moves?.toList(), strict = strict,
    )

    fun isGiven(i: Int) = puzzle.givens[i] != 0
    fun isWrong(i: Int) = values[i] != 0 && values[i] != puzzle.solution[i]
    fun hasConflict(i: Int): Boolean {
        val v = values[i]
        return v != 0 && Sudoku.peers[i].any { values[it] == v }
    }
    /**
     * Nombre d'exemplaires d'un chiffre placés : à 9, la touche est grisée. On ne compte que les justes,
     * sauf en mode validation où rien ne doit trahir une erreur.
     */
    fun placedCount(d: Int) = (0 until 81).count { values[it] == d && (strict || puzzle.solution[it] == d) }

    val hintsRemaining: Int get() = if (hintsEnabled) maxOf(0, MAX_HINTS - hintsUsed) else 0

    fun select(i: Int) { selected = i }

    fun moveSelection(dRow: Int, dCol: Int) {
        val current = selected ?: 40
        val r = (Sudoku.row(current) + dRow + 9) % 9
        val c = (Sudoku.col(current) + dCol + 9) % 9
        selected = r * 9 + c
    }

    fun input(d: Int) {
        val i = selected ?: return
        if (isGiven(i) || isOver) return
        if (notesMode && values[i] == 0) {
            notes[i] = notes[i] xor Sudoku.bit(d)
            changed()
        } else {
            place(i, d)
        }
    }

    private fun place(i: Int, d: Int) {
        if (values[i] == d) return
        values[i] = d
        notes[i] = 0
        log(i, d, if (applyingHint) Move.Kind.HINT else Move.Kind.PLAYER)
        val correct = d == puzzle.solution[i]
        // En mode validation, un chiffre faux se comporte exactement comme un chiffre juste.
        val looksRight = strict || correct
        if (looksRight && settings.autoRemoveNotes) {
            for (p in Sudoku.peers[i]) notes[p] = notes[p] and Sudoku.bit(d).inv()
        }
        if (!correct && !strict) mistakes++
        if (activeHint?.cell == i) clearHint()
        val completedUnits = if (!looksRight) 0 else Sudoku.unitsOfCell[i].count { u ->
            Sudoku.units[u].all { if (strict) values[it] != 0 else values[it] == puzzle.solution[it] }
        }
        lastEvent = Event.Placed(i, looksRight, completedUnits, ++nonce)
        val limit = mistakeLimit
        if (!strict && values.toList() == puzzle.solution.cells.toList()) win()
        else if (limit != null && mistakes > limit) fail()
        changed()
    }

    /**
     * Mode validation : vérifie la grille pleine. Juste, la partie est gagnée ; sinon elle est ratée,
     * et les chiffres faux sont enfin montrés et comptés.
     */
    fun validate() {
        if (!canValidate) return
        if (values.toList() == puzzle.solution.cells.toList()) win()
        else {
            mistakes = (0 until 81).count { values[it] != puzzle.solution[it] }
            fail()
        }
        changed()
    }

    private fun win() {
        isComplete = true
        selected = null
        clearHint()
        lastEvent = Event.Completed
    }

    private fun fail() {
        isFailed = true
        selected = null
        clearHint()
        lastEvent = Event.Failed
    }

    fun erase() {
        val i = selected ?: return
        if (isGiven(i) || isOver || (values[i] == 0 && notes[i] == 0)) return
        if (values[i] != 0) log(i, 0, Move.Kind.PLAYER)
        values[i] = 0
        notes[i] = 0
        changed()
    }

    fun tick() { if (!isOver) elapsed++ }

    /** 1er appui : consomme un indice et montre la zone ; ensuite la case, puis le coup. */
    fun advanceHint() {
        if (isOver) return
        val hint = activeHint
        if (hint != null) {
            hintStage++
            if (hintStage >= 3) applyHint(hint)
            return
        }
        if (hintsRemaining <= 0) return
        val h = HintEngine.hint(values.toIntArray(), puzzle.solution) ?: return
        hintsUsed++
        activeHint = h
        hintStage = 1
        changed()
    }

    private fun applyHint(hint: Hint) {
        clearHint()
        selected = hint.cell
        when (hint.kind) {
            Hint.Kind.MISTAKE -> {
                log(hint.cell, 0, Move.Kind.HINT)
                values[hint.cell] = 0
                notes[hint.cell] = 0
                changed()
            }
            else -> {
                applyingHint = true
                place(hint.cell, hint.digit)
                applyingHint = false
            }
        }
    }

    fun clearHint() {
        activeHint = null
        hintStage = 0
    }

    /** Tests d'interface : remplir la grille avec la solution sauf `keepEmpty` cases. */
    fun debugPrefill(keepEmpty: Int) {
        val empties = (0 until 81).filter { values[it] == 0 }
        for (i in empties.drop(keepEmpty)) {
            values[i] = puzzle.solution[i]
            log(i, values[i], Move.Kind.PLAYER)
        }
    }

    /** Tests d'interface : remplit toute la grille, avec un chiffre faux dans la dernière case vide. */
    fun debugFillWithError() {
        val empties = (0 until 81).filter { values[it] == 0 }
        for (i in empties) {
            values[i] = if (i == empties.last()) puzzle.solution[i] % 9 + 1 else puzzle.solution[i]
            log(i, values[i], Move.Kind.PLAYER)
        }
    }

    fun debugSetElapsed(seconds: Int) { elapsed = seconds }

    /** Captures et tests : chaque case vide reçoit en notes tous ses candidats possibles. */
    fun debugFillNotes() {
        for (i in 0 until 81) {
            if (values[i] != 0) continue
            var used = 0
            for (p in Sudoku.peers[i]) if (values[p] != 0) used = used or Sudoku.bit(values[p])
            notes[i] = used.inv() and Sudoku.ALL_DIGITS
        }
    }

    private fun changed() { onChange?.invoke() }

    companion object {
        const val MAX_HINTS = 3

        fun fromSaved(saved: SavedGame, settings: Settings): GameSession {
            val puzzle = Puzzle(saved.puzzleCode, saved.levelValue, Grid.parse(saved.givens)!!, Grid.parse(saved.solution)!!)
            return GameSession(puzzle, saved.mode, settings, strict = false, saved = saved)
        }
    }
}
