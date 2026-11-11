package com.alexafer.sudokuno.kit

data class GradeDetails(val level: Level, val hardest: Technique?, val chainSteps: Int)

object Grader {
    /** Une grille Diabolique (v2) doit demander au moins ce nombre de coups de chaîne, dont une vraie chaîne. */
    const val DIABOLIQUE_MIN_CHAIN_STEPS = 3

    /** Niveau d'une grille à solution unique ; si même les chaînes ne suffisent pas : Légende. */
    fun grade(puzzle: Grid): Level = details(puzzle).level

    fun details(puzzle: Grid, chains: Boolean = true): GradeDetails {
        val solver = LogicalSolver(puzzle, chains)
        var hardest: Technique? = null
        var chainSteps = 0
        while (!solver.isSolved) {
            val step = solver.nextStep() ?: break
            if (hardest == null || step.technique > hardest) hardest = step.technique
            if (step.technique >= Technique.TURBOT_FISH) chainSteps++
            solver.apply(step)
        }
        if (!solver.isSolved) return GradeDetails(if (chains) Level.LEGENDE else Level.DIABOLIQUE, hardest, chainSteps)
        return GradeDetails(hardest?.level ?: Level.FACILE, hardest, chainSteps)
    }
}

/** Traduction fidèle de Generator.swift. Le comportement d'une version publiée ne change jamais. */
object Generator {

    fun minimalPuzzle(rng: SeededRandom): Pair<Grid, Grid> {
        val solution = Solver.randomSolution(rng)
        val puzzle = solution.copy()
        val order = IntArray(41) { it } // paires (i, 80 - i) ; 40 = case centrale
        rng.shuffle(order)
        for (i in order) {
            val j = 80 - i
            val a = puzzle[i]; val b = puzzle[j]
            puzzle[i] = 0; puzzle[j] = 0
            if (!Solver.hasUniqueSolution(puzzle)) {
                puzzle[i] = a; puzzle[j] = b
            }
        }
        return puzzle to solution
    }

    /**
     * `version` 1 : Diabolique d'origine (sans chaînes), pour les anciens codes `SKN1-X-…`.
     * Version 2 : une Diabolique exige une vraie chaîne et au moins DIABOLIQUE_MIN_CHAIN_STEPS coups de chaîne.
     * Jusqu'à Expert, le classement se fait sans les chaînes (identique au générateur v1).
     */
    fun generate(level: Level, rng: SeededRandom, version: Int = 2, maxAttempts: Int = Int.MAX_VALUE): Pair<Grid, Grid>? {
        require(level != Level.LEGENDE) { "Les grilles Légende ne sont pas générées" }
        val chains = level == Level.DIABOLIQUE && version >= 2
        var attempt = 0
        while (attempt < maxAttempts) {
            attempt++
            val (minimal, solution) = minimalPuzzle(rng)
            val puzzle = minimal.copy()
            var details = Grader.details(puzzle, chains)
            var grade = details.level
            if (grade < level) continue

            val empties = (0 until 81).filter { puzzle[it] == 0 }.toIntArray()
            rng.shuffle(empties)
            var k = 0
            while (grade > level && k < empties.size) {
                val i = empties[k++]
                puzzle[i] = solution[i]
                details = Grader.details(puzzle, chains)
                grade = details.level
            }
            if (grade != level) continue
            if (chains && (details.hardest?.isLongChain != true || details.chainSteps < Grader.DIABOLIQUE_MIN_CHAIN_STEPS)) continue

            while (puzzle.clueCount < level.targetClues && k < empties.size) {
                val i = empties[k++]
                puzzle[i] = solution[i]
                if (Grader.details(puzzle, chains).level != level) puzzle[i] = 0
            }
            return puzzle to solution
        }
        return null
    }
}

/** Transformation qui conserve validité, unicité et difficulté (GridTransform.swift). */
class GridTransform(rng: SeededRandom) {
    private val digitMap: IntArray
    private val rowOrder: IntArray
    private val colOrder: IntArray
    private val transpose: Boolean

    init {
        val digits = IntArray(9) { it + 1 }
        rng.shuffle(digits)
        digitMap = intArrayOf(0) + digits
        fun lineOrder(): IntArray {
            val groups = intArrayOf(0, 1, 2)
            rng.shuffle(groups)
            val order = ArrayList<Int>()
            for (g in groups) {
                val inner = intArrayOf(0, 1, 2)
                rng.shuffle(inner)
                for (x in inner) order.add(g * 3 + x)
            }
            return order.toIntArray()
        }
        rowOrder = lineOrder()
        colOrder = lineOrder()
        transpose = rng.nextBool()
    }

    fun apply(grid: Grid): Grid {
        val out = Grid()
        for (r in 0 until 9) for (c in 0 until 9) {
            val v = grid[rowOrder[r] * 9 + colOrder[c]]
            val mapped = if (v == 0) 0 else digitMap[v]
            if (transpose) out[c * 9 + r] = mapped else out[r * 9 + c] = mapped
        }
        return out
    }
}
