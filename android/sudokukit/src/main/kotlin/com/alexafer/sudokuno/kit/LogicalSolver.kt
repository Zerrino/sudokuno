package com.alexafer.sudokuno.kit

/** Les 5 niveaux. Le niveau d'une grille = la technique la plus difficile qu'elle exige. */
enum class Level(val codeLetter: Char, internal val targetClues: Int, val minimumPlausibleSeconds: Int) {
    FACILE('F', 38, 30),
    MOYEN('M', 32, 45),
    DIFFICILE('D', 28, 60),
    EXPERT('E', 0, 90),
    DIABOLIQUE('X', 0, 120);

    companion object {
        fun fromCodeLetter(c: Char): Level? = entries.firstOrNull { it.codeLetter == c }
        fun fromOrdinal(i: Int): Level? = entries.getOrNull(i)
    }
}

/** Techniques « humaines », de la plus simple à la plus difficile (même ordre qu'en Swift). */
enum class Technique(val level: Level) {
    NAKED_SINGLE(Level.FACILE), HIDDEN_SINGLE(Level.FACILE),
    POINTING(Level.MOYEN), BOX_LINE_REDUCTION(Level.MOYEN), NAKED_PAIR(Level.MOYEN), HIDDEN_PAIR(Level.MOYEN),
    NAKED_TRIPLE(Level.DIFFICILE), HIDDEN_TRIPLE(Level.DIFFICILE), X_WING(Level.DIFFICILE),
    XY_WING(Level.EXPERT), SWORDFISH(Level.EXPERT), XYZ_WING(Level.EXPERT),
}

data class Placement(val cell: Int, val digit: Int)
data class CandidateRef(val cell: Int, val digit: Int)

data class LogicStep(
    val technique: Technique,
    val placements: List<Placement> = emptyList(),
    val eliminations: List<CandidateRef> = emptyList(),
    val unit: Int? = null,
    val focus: List<Int> = emptyList(),
)

/** Solveur « humain ». Traduction fidèle de LogicalSolver.swift : mêmes techniques, même ordre de recherche. */
class LogicalSolver(grid: Grid) {
    val values: IntArray = grid.cells.copyOf()
    val candidates = IntArray(81)

    init {
        for (i in 0 until 81) {
            if (values[i] != 0) continue
            var used = 0
            for (p in Sudoku.peers[i]) if (values[p] != 0) used = used or Sudoku.bit(values[p])
            candidates[i] = used.inv() and Sudoku.ALL_DIGITS
        }
    }

    val isSolved: Boolean get() = values.none { it == 0 }
    val hasContradiction: Boolean get() = (0 until 81).any { values[it] == 0 && candidates[it] == 0 }

    fun apply(step: LogicStep) {
        for (p in step.placements) place(p.cell, p.digit)
        for (e in step.eliminations) candidates[e.cell] = candidates[e.cell] and Sudoku.bit(e.digit).inv()
    }

    private fun place(i: Int, d: Int) {
        if (values[i] != 0) return
        values[i] = d
        candidates[i] = 0
        val b = Sudoku.bit(d).inv()
        for (p in Sudoku.peers[i]) candidates[p] = candidates[p] and b
    }

    /** Résout autant que possible ; retourne (résolue, technique la plus difficile utilisée). */
    fun solve(): Pair<Boolean, Technique?> {
        var hardest: Technique? = null
        while (!isSolved) {
            val step = nextStep() ?: break
            hardest = if (hardest == null || step.technique > hardest) step.technique else hardest
            apply(step)
        }
        return isSolved to hardest
    }

    fun nextStep(): LogicStep? {
        if (hasContradiction) return null
        return nakedSingle()
            ?: hiddenSingle()
            ?: pointing()
            ?: boxLineReduction()
            ?: nakedSubset(2)
            ?: hiddenSubset(2)
            ?: nakedSubset(3)
            ?: hiddenSubset(3)
            ?: fish(2)
            ?: xyWing()
            ?: fish(3)
            ?: xyzWing()
    }

    // --- Singletons ---

    private fun nakedSingle(): LogicStep? {
        for (i in 0 until 81) {
            if (values[i] == 0 && popcount(candidates[i]) == 1) {
                val d = Integer.numberOfTrailingZeros(candidates[i]) + 1
                return LogicStep(Technique.NAKED_SINGLE, placements = listOf(Placement(i, d)), focus = listOf(i))
            }
        }
        return null
    }

    private fun hiddenSingle(): LogicStep? {
        for (u in (18 until 27) + (0 until 18)) {
            val unit = Sudoku.units[u]
            for (d in 1..9) {
                val b = Sudoku.bit(d)
                var spot = -1
                var n = 0
                for (i in unit) {
                    if (candidates[i] and b != 0) {
                        spot = i; n++
                        if (n > 1) break
                    }
                }
                if (n == 1) return LogicStep(Technique.HIDDEN_SINGLE, placements = listOf(Placement(spot, d)), unit = u, focus = listOf(spot))
            }
        }
        return null
    }

    // --- Interactions bloc / ligne ---

    private fun pointing(): LogicStep? {
        for (bx in 0 until 9) {
            val u = 18 + bx
            val box = Sudoku.units[u]
            for (d in 1..9) {
                val b = Sudoku.bit(d)
                val spots = box.filter { candidates[it] and b != 0 }
                if (spots.size < 2) continue
                val lines = listOfNotNull(
                    if (spots.map(Sudoku::row).toSet().size == 1) Sudoku.row(spots[0]) else null,
                    if (spots.map(Sudoku::col).toSet().size == 1) 9 + Sudoku.col(spots[0]) else null,
                )
                for (line in lines) {
                    val elim = Sudoku.units[line]
                        .filter { Sudoku.box(it) != bx && candidates[it] and b != 0 }
                        .map { CandidateRef(it, d) }
                    if (elim.isNotEmpty()) return LogicStep(Technique.POINTING, eliminations = elim, unit = u, focus = spots)
                }
            }
        }
        return null
    }

    private fun boxLineReduction(): LogicStep? {
        for (u in 0 until 18) {
            val line = Sudoku.units[u]
            for (d in 1..9) {
                val b = Sudoku.bit(d)
                val spots = line.filter { candidates[it] and b != 0 }
                if (spots.size < 2 || spots.map(Sudoku::box).toSet().size != 1) continue
                val bx = Sudoku.box(spots[0])
                val elim = Sudoku.units[18 + bx]
                    .filter { it !in line && candidates[it] and b != 0 }
                    .map { CandidateRef(it, d) }
                if (elim.isNotEmpty()) return LogicStep(Technique.BOX_LINE_REDUCTION, eliminations = elim, unit = u, focus = spots)
            }
        }
        return null
    }

    // --- Sous-ensembles ---

    private fun nakedSubset(n: Int): LogicStep? {
        for (u in 0 until 27) {
            val unit = Sudoku.units[u]
            val pool = unit.filter { values[it] == 0 && popcount(candidates[it]) in 2..n }
            if (pool.size < n) continue
            for (combo in combinations(pool, n)) {
                val union = combo.fold(0) { acc, i -> acc or candidates[i] }
                if (popcount(union) != n) continue
                val elim = ArrayList<CandidateRef>()
                for (i in unit) {
                    if (values[i] == 0 && i !in combo && candidates[i] and union != 0) {
                        for (d in Sudoku.digits(candidates[i] and union)) elim.add(CandidateRef(i, d))
                    }
                }
                if (elim.isNotEmpty()) {
                    return LogicStep(if (n == 2) Technique.NAKED_PAIR else Technique.NAKED_TRIPLE, eliminations = elim, unit = u, focus = combo)
                }
            }
        }
        return null
    }

    private fun hiddenSubset(n: Int): LogicStep? {
        for (u in 0 until 27) {
            val unit = Sudoku.units[u]
            val digitSpots = ArrayList<Pair<Int, List<Int>>>()
            for (d in 1..9) {
                val b = Sudoku.bit(d)
                val spots = unit.filter { candidates[it] and b != 0 }
                if (spots.size in 2..n) digitSpots.add(d to spots)
            }
            if (digitSpots.size < n) continue
            for (combo in combinations(digitSpots.indices.toList(), n)) {
                val cells = combo.flatMap { digitSpots[it].second }.toSortedSet().toList()
                if (cells.size != n) continue
                val keep = combo.fold(0) { acc, k -> acc or Sudoku.bit(digitSpots[k].first) }
                val elim = ArrayList<CandidateRef>()
                for (i in cells) {
                    if (candidates[i] and keep.inv() != 0) {
                        for (d in Sudoku.digits(candidates[i] and keep.inv())) elim.add(CandidateRef(i, d))
                    }
                }
                if (elim.isNotEmpty()) {
                    return LogicStep(if (n == 2) Technique.HIDDEN_PAIR else Technique.HIDDEN_TRIPLE, eliminations = elim, unit = u, focus = cells)
                }
            }
        }
        return null
    }

    // --- Poissons ---

    private fun fish(n: Int): LogicStep? {
        for (d in 1..9) {
            val b = Sudoku.bit(d)
            for (byRow in listOf(true, false)) {
                val bases = ArrayList<Pair<Int, List<Int>>>()
                for (k in 0 until 9) {
                    val unit = Sudoku.units[if (byRow) k else 9 + k]
                    val covers = unit.filter { candidates[it] and b != 0 }.map { if (byRow) Sudoku.col(it) else Sudoku.row(it) }
                    if (covers.size in 2..n) bases.add(k to covers)
                }
                if (bases.size < n) continue
                for (combo in combinations(bases.indices.toList(), n)) {
                    val coverSet = combo.flatMap { bases[it].second }.toSortedSet()
                    if (coverSet.size != n) continue
                    val baseLines = combo.map { bases[it].first }.toSortedSet()
                    val elim = ArrayList<CandidateRef>()
                    for (c in coverSet) {
                        for (i in Sudoku.units[if (byRow) 9 + c else c]) {
                            if (candidates[i] and b == 0) continue
                            val line = if (byRow) Sudoku.row(i) else Sudoku.col(i)
                            if (line !in baseLines) elim.add(CandidateRef(i, d))
                        }
                    }
                    if (elim.isNotEmpty()) {
                        val focus = baseLines.flatMap { k -> Sudoku.units[if (byRow) k else 9 + k].filter { candidates[it] and b != 0 } }
                        return LogicStep(if (n == 2) Technique.X_WING else Technique.SWORDFISH, eliminations = elim, focus = focus)
                    }
                }
            }
        }
        return null
    }

    // --- Ailes ---

    private fun xyWing(): LogicStep? {
        val bivalue = (0 until 81).filter { values[it] == 0 && popcount(candidates[it]) == 2 }
        for (p in bivalue) {
            val pm = candidates[p]
            val wings = bivalue.filter { it != p && Sudoku.sees(it, p) && popcount(candidates[it] and pm) == 1 }
            for (a in wings) {
                val z = candidates[a] and pm.inv()
                val shared = candidates[a] and pm
                val need = (pm and shared.inv()) or z
                for (c in wings) {
                    if (c == a || candidates[c] != need) continue
                    val zd = Integer.numberOfTrailingZeros(z) + 1
                    val elim = (0 until 81)
                        .filter { it != p && it != a && it != c && candidates[it] and z != 0 && Sudoku.sees(it, a) && Sudoku.sees(it, c) }
                        .map { CandidateRef(it, zd) }
                    if (elim.isNotEmpty()) return LogicStep(Technique.XY_WING, eliminations = elim, focus = listOf(p, a, c))
                }
            }
        }
        return null
    }

    private fun xyzWing(): LogicStep? {
        for (p in 0 until 81) {
            if (values[p] != 0 || popcount(candidates[p]) != 3) continue
            val pm = candidates[p]
            val wings = Sudoku.peers[p].filter { values[it] == 0 && popcount(candidates[it]) == 2 && candidates[it] and pm.inv() == 0 }
            for (ai in wings.indices) {
                val a = wings[ai]
                for (c in wings.subList(ai + 1, wings.size)) {
                    val z = candidates[a] and candidates[c]
                    if (popcount(z) != 1 || (candidates[a] or candidates[c]) != pm) continue
                    val zd = Integer.numberOfTrailingZeros(z) + 1
                    val elim = (0 until 81)
                        .filter {
                            it != p && it != a && it != c && candidates[it] and z != 0 &&
                                Sudoku.sees(it, p) && Sudoku.sees(it, a) && Sudoku.sees(it, c)
                        }
                        .map { CandidateRef(it, zd) }
                    if (elim.isNotEmpty()) return LogicStep(Technique.XYZ_WING, eliminations = elim, focus = listOf(p, a, c))
                }
            }
        }
        return null
    }
}

/** Combinaisons de k éléments dans l'ordre lexicographique (déterministe). */
internal fun <T> combinations(items: List<T>, k: Int): List<List<T>> {
    if (k <= 0 || items.size < k) return if (k == 0) listOf(emptyList()) else emptyList()
    val result = ArrayList<List<T>>()
    val idx = IntArray(k) { it }
    while (true) {
        result.add(idx.map { items[it] })
        var i = k - 1
        while (i >= 0 && idx[i] == items.size - k + i) i--
        if (i < 0) break
        idx[i]++
        for (j in i + 1 until k) idx[j] = idx[j - 1] + 1
    }
    return result
}

