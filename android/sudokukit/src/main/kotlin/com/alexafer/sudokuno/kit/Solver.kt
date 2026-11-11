package com.alexafer.sudokuno.kit

/** Solveur rapide : backtracking + heuristique MRV. Traduction fidèle de Solver.swift. */
object Solver {

    fun countSolutions(grid: Grid, limit: Int = 2): Int {
        val state = State.of(grid) ?: return 0
        val ctx = Ctx(limit, null)
        search(state, ctx)
        return ctx.count
    }

    fun hasUniqueSolution(grid: Grid): Boolean = countSolutions(grid, 2) == 1

    fun solve(grid: Grid): Grid? {
        val state = State.of(grid) ?: return null
        val ctx = Ctx(1, null)
        search(state, ctx)
        return ctx.first?.let { Grid(it) }
    }

    /** Une grille complète aléatoire (déterministe pour un générateur donné). */
    fun randomSolution(rng: SeededRandom): Grid {
        val state = State.of(Grid())!!
        val ctx = Ctx(1, rng)
        search(state, ctx)
        return Grid(ctx.first!!)
    }

    /** Jusqu'à `limit` solutions ; null si la recherche dépasse `maxNodes`. */
    fun solutions(grid: Grid, limit: Int = 2, maxNodes: Int = 2_000_000): List<Grid>? {
        val state = State.of(grid) ?: return emptyList()
        val found = ArrayList<Grid>()
        val nodes = IntArray(1)
        val complete = collect(state, found, limit, nodes, maxNodes)
        return if (complete) found else null
    }

    // --- Implémentation ---

    internal class State(val cells: IntArray) {
        val rows = IntArray(9)
        val cols = IntArray(9)
        val boxes = IntArray(9)

        fun candidates(i: Int): Int =
            (rows[Sudoku.row(i)] or cols[Sudoku.col(i)] or boxes[Sudoku.box(i)]).inv() and Sudoku.ALL_DIGITS

        fun set(i: Int, d: Int) {
            val b = Sudoku.bit(d)
            cells[i] = d
            rows[Sudoku.row(i)] = rows[Sudoku.row(i)] or b
            cols[Sudoku.col(i)] = cols[Sudoku.col(i)] or b
            boxes[Sudoku.box(i)] = boxes[Sudoku.box(i)] or b
        }

        fun clear(i: Int, d: Int) {
            val b = Sudoku.bit(d).inv()
            cells[i] = 0
            rows[Sudoku.row(i)] = rows[Sudoku.row(i)] and b
            cols[Sudoku.col(i)] = cols[Sudoku.col(i)] and b
            boxes[Sudoku.box(i)] = boxes[Sudoku.box(i)] and b
        }

        companion object {
            fun of(grid: Grid): State? {
                val s = State(grid.cells.copyOf())
                for (i in 0 until 81) {
                    val v = s.cells[i]
                    if (v == 0) continue
                    val b = Sudoku.bit(v)
                    val r = Sudoku.row(i); val c = Sudoku.col(i); val x = Sudoku.box(i)
                    if ((s.rows[r] or s.cols[c] or s.boxes[x]) and b != 0) return null
                    s.rows[r] = s.rows[r] or b; s.cols[c] = s.cols[c] or b; s.boxes[x] = s.boxes[x] or b
                }
                return s
            }
        }
    }

    private class Ctx(val limit: Int, val rng: SeededRandom?) {
        var count = 0
        var first: IntArray? = null
    }

    private fun mrv(s: State): Pair<Int, Int> {
        var best = -1
        var bestMask = 0
        var bestCount = 10
        for (i in 0 until 81) {
            if (s.cells[i] != 0) continue
            val m = s.candidates(i)
            val n = popcount(m)
            if (n < bestCount) {
                best = i; bestMask = m; bestCount = n
                if (n <= 1) break
            }
        }
        return best to bestMask
    }

    private fun search(s: State, ctx: Ctx) {
        val (best, mask) = mrv(s)
        if (best == -1) {
            ctx.count += 1
            if (ctx.first == null) ctx.first = s.cells.copyOf()
            return
        }
        if (mask == 0) return
        val digits = Sudoku.digits(mask)
        ctx.rng?.shuffle(digits)
        for (d in digits) {
            s.set(best, d)
            search(s, ctx)
            s.clear(best, d)
            if (ctx.count >= ctx.limit) return
        }
    }

    private fun collect(s: State, found: MutableList<Grid>, limit: Int, nodes: IntArray, maxNodes: Int): Boolean {
        nodes[0] += 1
        if (nodes[0] > maxNodes) return false
        val (best, mask) = mrv(s)
        if (best == -1) {
            found.add(Grid(s.cells))
            return true
        }
        if (mask == 0) return true
        for (d in Sudoku.digits(mask)) {
            s.set(best, d)
            val ok = collect(s, found, limit, nodes, maxNodes)
            s.clear(best, d)
            if (!ok) return false
            if (found.size >= limit) return true
        }
        return true
    }
}
