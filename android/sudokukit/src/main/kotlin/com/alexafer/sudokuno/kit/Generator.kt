package com.alexafer.sudokuno.kit

object Grader {
    /** Niveau d'une grille à solution unique : la technique la plus difficile nécessaire. */
    fun grade(puzzle: Grid): Level {
        val (solved, hardest) = LogicalSolver(puzzle).solve()
        if (!solved) return Level.DIABOLIQUE
        return hardest?.level ?: Level.FACILE
    }
}

/** Traduction fidèle de Generator.swift (générateur v1 : NE PAS MODIFIER). */
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

    fun generate(level: Level, rng: SeededRandom, maxAttempts: Int = Int.MAX_VALUE): Pair<Grid, Grid>? {
        var attempt = 0
        while (attempt < maxAttempts) {
            attempt++
            val (minimal, solution) = minimalPuzzle(rng)
            val puzzle = minimal.copy()
            var grade = Grader.grade(puzzle)
            if (grade < level) continue

            val empties = (0 until 81).filter { puzzle[it] == 0 }.toIntArray()
            rng.shuffle(empties)
            var k = 0
            while (grade > level && k < empties.size) {
                val i = empties[k++]
                puzzle[i] = solution[i]
                grade = Grader.grade(puzzle)
            }
            if (grade != level) continue

            while (puzzle.clueCount < level.targetClues && k < empties.size) {
                val i = empties[k++]
                puzzle[i] = solution[i]
                if (Grader.grade(puzzle) != level) puzzle[i] = 0
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
