package com.alexafer.sudokuno.kit

/**
 * Une grille 9×9. Les cases sont indexées de 0 à 80 (ligne × 9 + colonne), 0 = case vide.
 * Traduction fidèle de `Grid.swift` (iOS).
 */
class Grid(cells: IntArray = IntArray(81)) {
    val cells: IntArray = cells.copyOf()

    init {
        require(this.cells.size == 81) { "Une grille contient 81 cases" }
    }

    operator fun get(i: Int): Int = cells[i]
    operator fun set(i: Int, v: Int) { cells[i] = v }

    fun copy(): Grid = Grid(cells)

    val clueCount: Int get() = cells.count { it != 0 }
    val isFilled: Boolean get() = cells.none { it == 0 }

    /** 81 caractères, `.` pour une case vide. */
    val string: String get() = buildString(81) { for (v in cells) append(if (v == 0) '.' else ('0' + v)) }

    /** Aucun chiffre en double dans une ligne, une colonne ou un bloc. */
    val isConsistent: Boolean
        get() {
            for (unit in Sudoku.units) {
                var seen = 0
                for (i in unit) {
                    val v = cells[i]
                    if (v == 0) continue
                    val b = Sudoku.bit(v)
                    if (seen and b != 0) return false
                    seen = seen or b
                }
            }
            return true
        }

    override fun equals(other: Any?): Boolean = other is Grid && cells.contentEquals(other.cells)
    override fun hashCode(): Int = cells.contentHashCode()
    override fun toString(): String = string

    companion object {
        /** Chiffres 1-9, `0` ou `.` pour une case vide ; les espaces sont ignorés. */
        fun parse(s: String): Grid? {
            val out = IntArray(81)
            var n = 0
            for (ch in s) {
                val v = when {
                    ch == '.' || ch == '0' -> 0
                    ch in '1'..'9' -> ch - '0'
                    ch.isWhitespace() -> continue
                    else -> return null
                }
                if (n >= 81) return null
                out[n++] = v
            }
            return if (n == 81) Grid(out) else null
        }
    }
}

/** Géométrie du Sudoku et masques de candidats (bit d-1 = chiffre d). */
object Sudoku {
    const val ALL_DIGITS = 0x1FF

    fun row(i: Int) = i / 9
    fun col(i: Int) = i % 9
    fun box(i: Int) = (i / 27) * 3 + (i % 9) / 3
    fun bit(d: Int) = 1 shl (d - 1)

    /** 27 unités : lignes 0-8, colonnes 9-17, blocs 18-26. */
    val units: List<IntArray> = buildList {
        for (r in 0 until 9) add(IntArray(9) { r * 9 + it })
        for (c in 0 until 9) add(IntArray(9) { it * 9 + c })
        for (b in 0 until 9) {
            val r0 = (b / 3) * 3
            val c0 = (b % 3) * 3
            add(IntArray(9) { (r0 + it / 3) * 9 + c0 + it % 3 })
        }
    }

    val unitsOfCell: List<IntArray> = List(81) { intArrayOf(row(it), 9 + col(it), 18 + box(it)) }

    /** Les 20 cases qui « voient » chaque case, dans l'ordre croissant. */
    val peers: List<IntArray> = List(81) { i ->
        (0 until 81).filter { it != i && (row(it) == row(i) || col(it) == col(i) || box(it) == box(i)) }.toIntArray()
    }

    fun sees(a: Int, b: Int) = a != b && (row(a) == row(b) || col(a) == col(b) || box(a) == box(b))

    /** Les chiffres d'un masque, dans l'ordre croissant. */
    fun digits(mask: Int): IntArray {
        val out = IntArray(Integer.bitCount(mask))
        var m = mask
        var k = 0
        while (m != 0) {
            out[k++] = Integer.numberOfTrailingZeros(m) + 1
            m = m and (m - 1)
        }
        return out
    }

    sealed interface UnitKind {
        data class Row(val index: Int) : UnitKind
        data class Column(val index: Int) : UnitKind
        data class Box(val index: Int) : UnitKind
    }

    fun unitName(unit: Int): UnitKind = when (unit) {
        in 0 until 9 -> UnitKind.Row(unit)
        in 9 until 18 -> UnitKind.Column(unit - 9)
        else -> UnitKind.Box(unit - 18)
    }
}

internal fun popcount(x: Int) = Integer.bitCount(x)
