package com.alexafer.sudokuno.kit

/*
 * Score d'une partie terminée : niveau de la grille, temps, et surtout qualité des coups (Scoring.swift).
 * Un chiffre juste ne rapporte tous ses points que s'il était déductible au moment où il a été posé.
 */

/** Un changement de chiffre pendant la partie (0 = case effacée). `hint` : joué par un indice, il ne rapporte rien. */
data class ScoredMove(val cell: Int, val digit: Int, val hint: Boolean)

data class GameScore(
    val total: Int,
    /** Chiffres justes que la logique permettait de trouver à ce moment-là. */
    val deduced: Int,
    /** Chiffres justes mais posés sans pouvoir les connaître : des coups de chance. */
    val guessed: Int,
    /** Chiffres donnés par un indice. */
    val hinted: Int,
    /** Bonus ou malus de temps, en millièmes (1000 = temps de référence, 1500 = très rapide, 500 = très lent). */
    val timePermille: Int,
)

object Scoring {
    /** Points d'une grille parfaite jouée dans le temps de référence. */
    fun basePoints(level: Level): Int = when (level) {
        Level.FACILE -> 1000
        Level.MOYEN -> 2000
        Level.DIFFICILE -> 3500
        Level.EXPERT -> 5000
        Level.DIABOLIQUE -> 8000
        Level.LEGENDE -> 12000
    }

    /** Temps de référence, en secondes : plus vite rapporte jusqu'à +50 %, plus lent retire jusqu'à 50 %. */
    fun referenceSeconds(level: Level): Int = when (level) {
        Level.FACILE -> 5 * 60
        Level.MOYEN -> 8 * 60
        Level.DIFFICILE -> 12 * 60
        Level.EXPERT -> 20 * 60
        Level.DIABOLIQUE -> 35 * 60
        Level.LEGENDE -> 60 * 60
    }

    /** Un coup de chance vaut un cinquième d'un chiffre déduit. */
    const val GUESS_DIVISOR = 5
    /** Chaque erreur retire un vingtième des points de base. */
    const val MISTAKE_DIVISOR = 20

    /**
     * Le chiffre de cette case peut-il être connu dans l'état de `solver` ?
     * Oui si, après toutes les éliminations logiques possibles (sans poser d'autre chiffre), la case n'a plus qu'un
     * candidat ou si le chiffre n'a plus qu'une place dans sa ligne, sa colonne ou son bloc.
     * Les éliminations trouvées restent acquises dans `solver`, comme les notes d'un joueur.
     */
    internal fun isDeducible(solver: LogicalSolver, cell: Int, digit: Int): Boolean {
        val bit = Sudoku.bit(digit)
        while (true) {
            if (solver.candidates[cell] == bit) return true
            for (u in Sudoku.unitsOfCell[cell]) {
                if (Sudoku.units[u].none { it != cell && solver.candidates[it] and bit != 0 }) return true
            }
            val step = solver.eliminationStep() ?: return false
            solver.apply(step)
        }
    }

    private enum class Quality { DEDUCED, GUESSED, HINTED }

    /**
     * Score de la partie. `moves` : tous les changements de chiffres, dans l'ordre.
     *
     * On suit la partie avec un solveur qui accumule ce que la logique permet de savoir (chiffres justes posés,
     * candidats éliminés). Chaque chiffre juste est jugé la première fois qu'il est posé : déductible à ce moment-là,
     * ou coup de chance. L'effacer puis le reposer ne change pas ce jugement.
     */
    fun score(givens: Grid, solution: Grid, level: Level, moves: List<ScoredMove>, seconds: Int, mistakes: Int): GameScore {
        val solver = LogicalSolver(givens, chains = level >= Level.DIABOLIQUE)
        val state = givens.cells.copyOf()
        val quality = arrayOfNulls<Quality>(81)
        for (m in moves) {
            if (givens[m.cell] != 0) continue
            state[m.cell] = m.digit
            if (m.digit != solution[m.cell] || quality[m.cell] != null) continue
            quality[m.cell] = when {
                m.hint -> Quality.HINTED
                // Légende : nos techniques classiques ne suffisent pas, on ne peut pas juger ce qui était déductible.
                level == Level.LEGENDE -> Quality.DEDUCED
                isDeducible(solver, m.cell, m.digit) -> Quality.DEDUCED
                else -> Quality.GUESSED
            }
            solver.place(m.cell, m.digit)
        }
        var deduced = 0
        var guessed = 0
        var hinted = 0
        for (c in 0 until 81) if (state[c] == solution[c]) when (quality[c]) {
            Quality.DEDUCED -> deduced++
            Quality.GUESSED -> guessed++
            Quality.HINTED -> hinted++
            null -> {}
        }
        val base = basePoints(level)
        val empty = maxOf(1, 81 - givens.clueCount)
        val time = minOf(1500, maxOf(500, 1500 - 500 * maxOf(0, seconds) / referenceSeconds(level)))
        val earned = (base.toLong() * (GUESS_DIVISOR * deduced + guessed) * time / (GUESS_DIVISOR.toLong() * empty * 1000)).toInt()
        val total = maxOf(0, earned - mistakes * base / MISTAKE_DIVISOR)
        return GameScore(total, deduced, guessed, hinted, time)
    }
}
