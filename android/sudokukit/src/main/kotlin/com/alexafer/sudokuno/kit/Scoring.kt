package com.alexafer.sudokuno.kit

/*
 * Score d'une partie, chiffre par chiffre (version 2). Traduction exacte de Scoring.swift : mêmes points.
 *
 * Chaque chiffre juste est jugé au moment où il est posé. S'il pouvait être connu à cet instant, il rapporte les points
 * de la technique la plus simple qui permettait alors d'avancer dans la grille (le « goulot »), plus ou moins selon le
 * temps mis à le trouver (depuis le chiffre juste précédent). Un chiffre qu'aucune logique ne permettait encore de connaître est un coup de chance.
 */

/** Un changement de chiffre pendant la partie (0 = case effacée). `hint` : joué par un indice. `time` : secondes écoulées. */
data class ScoredMove(val cell: Int, val digit: Int, val hint: Boolean, val time: Int = 0)

/** Le jugement d'un coup, pour le score et pour le commentaire du replay. */
sealed class MoveJudgement {
    /** Chiffre juste, et la logique permettait de le trouver : `technique` est la plus difficile qu'il fallait. */
    data class Deduced(val technique: Technique) : MoveJudgement()
    /** Chiffre juste, mais rien ne permettait encore de le connaître : un coup de chance. */
    data object Guessed : MoveJudgement()
    /** Chiffre juste trouvé après un essai faux dans la même case : compté comme un coup de chance. */
    data object Corrected : MoveJudgement()
    /** Chiffre juste, donné par un indice. */
    data object Hinted : MoveJudgement()
    /** Chiffre faux. */
    data object Mistake : MoveJudgement()
    /** Case effacée. */
    data object Erased : MoveJudgement()
    /** Chiffre juste déjà jugé : effacé puis reposé. */
    data object Repeated : MoveJudgement()
}

/**
 * `easiest` : pour un chiffre déduit, la technique la plus simple qui permettait d'avancer dans la grille à ce moment-là
 * (c'est elle qui donne les points). `speedPermille` : bonus de rapidité (1000 = temps de référence ; 500 à 1500), 0 si sans objet.
 */
data class MoveVerdict(val judgement: MoveJudgement, val points: Int, val speedPermille: Int, val easiest: Technique? = null)

data class GameScore(
    val total: Int,
    /** Chiffres justes que la logique permettait de trouver à ce moment-là. */
    val deduced: Int,
    /** Chiffres justes posés sans pouvoir les connaître : des coups de chance. */
    val guessed: Int,
    /** Chiffres donnés par un indice. */
    val hinted: Int,
    /** Rapidité moyenne des chiffres déduits, en millièmes (1000 = temps de référence). */
    val timePermille: Int,
    /** Version du calcul (null = première version, à recalculer). */
    val version: Int?,
    /** Technique la plus difficile utilisée par le joueur (`ordinal` de `Technique`). */
    val hardest: Int?,
) {
    val hardestTechnique: Technique? get() = hardest?.let { Technique.entries.getOrNull(it) }
    val isCurrent: Boolean get() = version == Scoring.VERSION
}

object Scoring {
    const val VERSION = 2

    /** Points d'un chiffre trouvé avec cette technique, au temps de référence. */
    fun points(t: Technique): Int = when (t) {
        Technique.NAKED_SINGLE -> 10
        Technique.HIDDEN_SINGLE -> 10
        Technique.POINTING -> 30
        Technique.BOX_LINE_REDUCTION -> 30
        Technique.NAKED_PAIR -> 40
        Technique.HIDDEN_PAIR -> 50
        Technique.NAKED_TRIPLE -> 60
        Technique.HIDDEN_TRIPLE -> 70
        Technique.X_WING -> 80
        Technique.XY_WING -> 100
        Technique.SWORDFISH -> 120
        Technique.XYZ_WING -> 120
        Technique.TURBOT_FISH -> 150
        Technique.X_CHAIN -> 170
        Technique.XY_CHAIN -> 170
        Technique.AIC -> 200
        Technique.GROUPED_CHAIN -> 230
        Technique.SK_LOOP -> 260
        Technique.FORCING_CHAIN -> 280
        Technique.FORCING_NET -> 320
    }

    /** Temps de référence pour trouver un chiffre avec cette technique, en secondes. */
    fun referenceSeconds(t: Technique): Int = when (t.level) {
        Level.FACILE -> 15
        Level.MOYEN -> 30
        Level.DIFFICILE -> 45
        Level.EXPERT -> 60
        Level.DIABOLIQUE -> 90
        Level.LEGENDE -> 150
    }

    /** Un coup de chance rapporte toujours ça, quel que soit le temps. */
    const val GUESS_POINTS = 2
    /** Chaque erreur retire ça. */
    const val MISTAKE_PENALTY = 25

    internal fun speed(seconds: Int, technique: Technique): Int =
        minOf(1500, maxOf(500, 1500 - 500 * maxOf(0, seconds) / referenceSeconds(technique)))

    /** Score de la partie. `moves` : tous les changements de chiffres, dans l'ordre. */
    fun score(givens: Grid, solution: Grid, level: Level, moves: List<ScoredMove>, mistakes: Int): GameScore {
        val tracker = ScoreTracker(givens, solution, level)
        for (m in moves) tracker.record(m)
        return tracker.score(mistakes)
    }

    /** Le jugement de chaque coup, dans l'ordre (pour le replay). */
    fun analyze(givens: Grid, solution: Grid, level: Level, moves: List<ScoredMove>): List<MoveVerdict> {
        val tracker = ScoreTracker(givens, solution, level)
        return moves.map { tracker.record(it) }
    }
}

/**
 * Suit une partie coup par coup : sert au score final, au score en direct et au replay (voir `ScoreTracker` en Swift).
 * Pour juger un chiffre, on cherche sur une copie du solveur ; trouvé, la copie devient le nouvel état ;
 * pas trouvé, coup de chance et la copie est oubliée.
 */
class ScoreTracker(val givens: Grid, val solution: Grid, val level: Level) {
    private var solver = LogicalSolver(givens)
    private val judged = BooleanArray(81)
    private val tried = BooleanArray(81)
    private val points = IntArray(81)
    private val kind = IntArray(81) // 1 déduit, 2 chance, 3 indice
    private val state = givens.cells.copyOf()
    private var lastTime = 0
    private var speedSum = 0
    private var speedCount = 0
    private var hardest: Technique? = null

    /** Points des chiffres justes actuellement sur la grille (sans les erreurs). */
    val earned: Int get() = (0 until 81).sumOf { if (state[it] == solution[it]) points[it] else 0 }

    fun record(m: ScoredMove): MoveVerdict {
        if (givens[m.cell] != 0) return MoveVerdict(MoveJudgement.Repeated, 0, 0)
        state[m.cell] = m.digit
        if (m.digit == 0) return MoveVerdict(MoveJudgement.Erased, 0, 0)
        if (m.digit != solution[m.cell]) {
            tried[m.cell] = true
            return MoveVerdict(MoveJudgement.Mistake, 0, 0)
        }
        if (judged[m.cell]) return MoveVerdict(MoveJudgement.Repeated, 0, 0)
        judged[m.cell] = true
        val easiest = if (m.hint) null else bottleneck()
        val elapsed = m.time - lastTime
        lastTime = maxOf(lastTime, m.time)
        val needed = if (m.hint || tried[m.cell]) null else deduction(m.cell, m.digit)
        val t = needed?.let { if (easiest != null && easiest < it) easiest else it }
        val verdict = when {
            m.hint -> {
                kind[m.cell] = 3
                MoveVerdict(MoveJudgement.Hinted, 0, 0)
            }
            needed != null && t != null -> {
                val speed = Scoring.speed(elapsed, t)
                val p = Scoring.points(t) * speed / 1000
                points[m.cell] = p
                kind[m.cell] = 1
                speedSum += speed
                speedCount++
                if (hardest == null || t > hardest!!) hardest = t
                MoveVerdict(MoveJudgement.Deduced(needed), p, speed, t)
            }
            else -> {
                points[m.cell] = Scoring.GUESS_POINTS
                kind[m.cell] = 2
                MoveVerdict(if (tried[m.cell]) MoveJudgement.Corrected else MoveJudgement.Guessed, Scoring.GUESS_POINTS, 0)
            }
        }
        solver.place(m.cell, m.digit)
        return verdict
    }

    fun score(mistakes: Int): GameScore {
        var deduced = 0
        var guessed = 0
        var hinted = 0
        for (c in 0 until 81) {
            if (givens[c] != 0 || state[c] != solution[c]) continue
            when (kind[c]) {
                1 -> deduced++
                2 -> guessed++
                3 -> hinted++
            }
        }
        val total = maxOf(0, earned - mistakes * Scoring.MISTAKE_PENALTY)
        return GameScore(total, deduced, guessed, hinted, if (speedCount > 0) speedSum / speedCount else 1000,
            Scoring.VERSION, hardest?.ordinal)
    }

    /**
     * La technique la plus simple qui permet de poser un chiffre (n'importe où) dans l'état actuel : on applique les
     * techniques de la plus simple à la plus difficile jusqu'au premier chiffre posé, et on garde la plus difficile utilisée.
     */
    private fun bottleneck(): Technique? {
        val s = solver.copy()
        var used: Technique? = null
        while (true) {
            val step = s.nextStep() ?: (if (level == Level.LEGENDE) s.expertStep() ?: s.forcingStep(solution) else null) ?: return null
            if (used == null || step.technique > used) used = step.technique
            if (step.placements.isNotEmpty()) return used
            s.apply(step)
        }
    }

    /** La technique la plus difficile qu'il fallait pour connaître ce chiffre maintenant, ou null (coup de chance). */
    private fun deduction(cell: Int, digit: Int): Technique? {
        val s = solver.copy()
        var used: Technique? = null
        val bit = Sudoku.bit(digit)
        while (true) {
            if (s.values[cell] == digit) break
            if (s.candidates[cell] == bit) {
                used = used ?: Technique.NAKED_SINGLE
                break
            }
            if (Sudoku.unitsOfCell[cell].any { u -> Sudoku.units[u].none { it != cell && s.candidates[it] and bit != 0 } }) {
                used = used ?: Technique.HIDDEN_SINGLE
                break
            }
            val step = s.eliminationStep()
                ?: (if (level == Level.LEGENDE) s.expertStep() ?: s.forcingStep(solution) else null)
                ?: return null
            if (used == null || step.technique > used) used = step.technique
            s.apply(step)
            if (s.hasContradiction) return null
        }
        solver = s
        return used
    }
}
