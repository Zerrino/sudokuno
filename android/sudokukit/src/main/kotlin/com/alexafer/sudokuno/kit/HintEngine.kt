package com.alexafer.sudokuno.kit

/** Un indice en 3 étapes : 1. zone et technique ; 2. case et motif ; 3. coup appliqué. */
data class Hint(
    val kind: Kind,
    val cell: Int,
    val digit: Int,
    val technique: Technique?,
    val supportingTechnique: Technique?,
    val region: List<Int>,
    val focus: List<Int>,
) {
    enum class Kind { MISTAKE, PLACEMENT, REVELATION }
}

object HintEngine {
    /** Indice calculé sur l'état ACTUEL de la grille du joueur (sans ses notes). */
    fun hint(values: IntArray, solution: Grid): Hint? {
        val wrong = (0 until 81).firstOrNull { values[it] != 0 && values[it] != solution[it] }
        if (wrong != null) {
            return Hint(Hint.Kind.MISTAKE, wrong, solution[wrong], null, null,
                Sudoku.units[18 + Sudoku.box(wrong)].toList(), listOf(wrong))
        }
        if (values.none { it == 0 }) return null

        val solver = LogicalSolver(Grid(values))
        var supporting: Technique? = null
        while (true) {
            val step = solver.nextStep() ?: break
            val p = step.placements.firstOrNull()
            if (p != null) {
                val region = step.unit?.let { Sudoku.units[it].toList() } ?: Sudoku.units[18 + Sudoku.box(p.cell)].toList()
                return Hint(Hint.Kind.PLACEMENT, p.cell, p.digit, step.technique, supporting, region, step.focus)
            }
            supporting = if (supporting == null || step.technique > supporting) step.technique else supporting
            solver.apply(step)
        }
        val cell = (0 until 81).filter { values[it] == 0 }.minBy { popcount(solver.candidates[it]) }
        return Hint(Hint.Kind.REVELATION, cell, solution[cell], null, null,
            Sudoku.units[18 + Sudoku.box(cell)].toList(), listOf(cell))
    }
}

/** Analyse en direct d'une grille en cours de création (PuzzleAnalysis.swift). */
data class PuzzleAnalysis(val clueCount: Int, val status: Status) {
    sealed interface Status {
        data class Conflict(val cells: List<Int>) : Status
        data object NoSolution : Status
        data class MultipleSolutions(val suggestion: Placement) : Status
        data class Unique(val level: Level, val hardest: Technique?, val solution: Grid) : Status
        data object Undetermined : Status
    }

    val isPlayable: Boolean get() = status is Status.Unique

    companion object {
        fun analyze(grid: Grid): PuzzleAnalysis {
            val clues = grid.clueCount
            val conflicts = sortedSetOf<Int>()
            for (unit in Sudoku.units) for (a in unit) {
                if (grid[a] == 0) continue
                for (b in unit) if (b != a && grid[b] == grid[a]) conflicts.add(a)
            }
            if (conflicts.isNotEmpty()) return PuzzleAnalysis(clues, Status.Conflict(conflicts.toList()))
            val sols = Solver.solutions(grid, 2) ?: return PuzzleAnalysis(clues, Status.Undetermined)
            return when (sols.size) {
                0 -> PuzzleAnalysis(clues, Status.NoSolution)
                1 -> {
                    val (solved, hardest) = LogicalSolver(grid).solve()
                    val level = if (solved) hardest?.level ?: Level.FACILE else Level.LEGENDE
                    PuzzleAnalysis(clues, Status.Unique(level, if (solved) hardest else null, sols[0]))
                }
                else -> {
                    val i = (0 until 81).first { sols[0][it] != sols[1][it] }
                    PuzzleAnalysis(clues, Status.MultipleSolutions(Placement(i, sols[0][i])))
                }
            }
        }

        fun isPlayable(code: PuzzleCode): Boolean = if (code is PuzzleCode.Custom) analyze(code.grid).isPlayable else true
    }
}
