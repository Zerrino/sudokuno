package com.alexafer.sudokuno.kit

import java.time.LocalDate
import java.time.format.DateTimeFormatter

/** Un jour calendaire UTC (jours depuis le 1er janvier 1970). */
@kotlinx.serialization.Serializable
@JvmInline
value class DayStamp(val dayNumber: Int) : Comparable<DayStamp> {
    override fun compareTo(other: DayStamp) = dayNumber.compareTo(other.dayNumber)
    fun adding(days: Int) = DayStamp(dayNumber + days)

    val date: LocalDate get() = LocalDate.ofEpochDay(dayNumber.toLong())
    /** « 20261110 » */
    val key: String get() = date.format(DateTimeFormatter.BASIC_ISO_DATE)
    /** 0 = lundi … 6 = dimanche. */
    val weekday: Int get() = ((dayNumber + 3) % 7 + 7) % 7
    /** Début du jour suivant (minuit UTC), en millisecondes. */
    val nextStartMillis: Long get() = (dayNumber + 1).toLong() * 86_400_000L

    companion object {
        fun fromMillis(epochMillis: Long) = DayStamp(Math.floorDiv(epochMillis, 86_400_000L).toInt())
        fun today() = fromMillis(System.currentTimeMillis())
        fun of(year: Int, month: Int, day: Int): DayStamp? =
            runCatching { DayStamp(LocalDate.of(year, month, day).toEpochDay().toInt()) }.getOrNull()
    }
}

/** Le code d'une grille : le même code recrée la même grille, sur iOS comme sur Android. */
sealed interface PuzzleCode {
    data class LevelSeed(override val level: Level, val seed: ULong) : PuzzleCode
    data class Daily(val day: DayStamp) : PuzzleCode
    /** Grille créée par un joueur : le code contient la grille. */
    data class Custom(val grid: Grid) : PuzzleCode
    /** Ancien code Diabolique (`SKN1-X-…`, générateur v1, sans chaînes), toujours rejoué à l'identique. */
    data class DiaboliqueV1(val seed: ULong) : PuzzleCode {
        override val level: Level get() = Level.DIABOLIQUE
    }

    val string: String
        get() = when (this) {
            is Daily -> "$PREFIX-J-${day.key}"
            is LevelSeed -> seedString(level.codeLetter, level, seed)
            is DiaboliqueV1 -> seedString('X', Level.DIABOLIQUE, seed)
            is Custom -> {
                val symbols = encodeCustom(grid)
                "$PREFIX-C-" + symbols.chunked(4).joinToString("-") { String(it.toCharArray()) }
            }
        }

    val level: Level? get() = null
    val isDaily: Boolean get() = this is Daily

    companion object {
        const val GENERATOR_VERSION = 1
        const val PREFIX = "SKN1"
        val ALPHABET = "0123456789ABCDEFGHJKMNPQRSTVWXYZ".toList() // base 32 de Crockford

        private fun seedString(letter: Char, level: Level, seed: ULong): String {
            val chars = CharArray(13)
            var v = seed
            for (k in 0 until 13) {
                chars[k] = ALPHABET[(v and 31uL).toInt()]
                v = v shr 5
            }
            chars.reverse()
            val symbols = chars.toList() + ALPHABET[checksum(level, chars.toList())]
            val s = String(symbols.toCharArray())
            return "$PREFIX-$letter-" + listOf(s.substring(0, 4), s.substring(4, 8), s.substring(8, 12), s.substring(12)).joinToString("-")
        }

        private fun fixAmbiguous(c: Char) = when (c) { 'O' -> '0'; 'I', 'L' -> '1'; else -> c }

        fun parse(raw: String): PuzzleCode? {
            val cleaned = raw.uppercase().filter { !it.isWhitespace() && it != '-' }
            if (!cleaned.startsWith(PREFIX)) return null
            var rest = cleaned.substring(PREFIX.length)
            val kind = rest.firstOrNull() ?: return null
            rest = rest.substring(1)

            if (kind == 'C') {
                return decodeCustom(rest.map(::fixAmbiguous))?.let { Custom(it) }
            }
            if (kind == 'J') {
                if (rest.length != 8 || !rest.all(Char::isDigit)) return null
                val day = DayStamp.of(rest.substring(0, 4).toInt(), rest.substring(4, 6).toInt(), rest.substring(6, 8).toInt()) ?: return null
                return Daily(day)
            }
            val legacy = kind == 'X'
            val level = if (legacy) Level.DIABOLIQUE else Level.fromCodeLetter(kind) ?: return null
            val symbols = rest.map(::fixAmbiguous)
            if (symbols.size != 14) return null
            var seed = 0uL
            for ((k, ch) in symbols.take(13).withIndex()) {
                val v = ALPHABET.indexOf(ch)
                if (v < 0) return null
                if (k == 0 && v > 15) return null
                seed = (seed shl 5) or v.toULong()
            }
            if (ALPHABET[checksum(level, symbols.take(13))] != symbols[13]) return null
            return if (legacy) DiaboliqueV1(seed) else LevelSeed(level, seed)
        }

        internal fun checksum(level: Level, symbols: List<Char>): Int {
            var sum = (level.ordinal + 1) * 7
            for ((k, ch) in symbols.withIndex()) sum += (k + 2) * maxOf(ALPHABET.indexOf(ch), 0)
            return sum % 31
        }

        // Format C : 81 bits de présence, puis 4 bits par chiffre (chiffre - 1), complétés jusqu'à un multiple de 5.
        internal fun encodeCustom(grid: Grid): List<Char> {
            val bits = ArrayList<Boolean>()
            for (v in grid.cells) bits.add(v != 0)
            for (v in grid.cells) if (v != 0) {
                val x = v - 1
                for (k in 3 downTo 0) bits.add((x shr k) and 1 == 1)
            }
            while (bits.size % 5 != 0) bits.add(false)
            val symbols = ArrayList<Char>()
            for (i in bits.indices step 5) {
                var v = 0
                for (k in 0 until 5) v = (v shl 1) or (if (bits[i + k]) 1 else 0)
                symbols.add(ALPHABET[v])
            }
            symbols.add(ALPHABET[customChecksum(symbols)])
            return symbols
        }

        internal fun decodeCustom(raw: List<Char>): Grid? {
            if (raw.size < 18) return null
            val check = raw.last()
            val symbols = raw.dropLast(1)
            if (ALPHABET[customChecksum(symbols)] != check) return null
            val bits = ArrayList<Boolean>()
            for (ch in symbols) {
                val v = ALPHABET.indexOf(ch)
                if (v < 0) return null
                for (k in 4 downTo 0) bits.add((v shr k) and 1 == 1)
            }
            if (bits.size < 81) return null
            val present = bits.subList(0, 81)
            val n = present.count { it }
            val needed = 81 + 4 * n
            if (bits.size < needed || bits.size - needed >= 5 || bits.subList(needed, bits.size).any { it }) return null
            val cells = IntArray(81)
            var pos = 81
            for (i in 0 until 81) if (present[i]) {
                var x = 0
                for (k in 0 until 4) x = (x shl 1) or (if (bits[pos + k]) 1 else 0)
                pos += 4
                if (x > 8) return null
                cells[i] = x + 1
            }
            val grid = Grid(cells)
            return if (grid.isConsistent) grid else null
        }

        internal fun customChecksum(symbols: List<Char>): Int {
            var sum = 11
            for ((k, ch) in symbols.withIndex()) sum += (k % 30 + 1) * maxOf(ALPHABET.indexOf(ch), 0)
            return sum % 31
        }

        /** Cherche un code dans un texte libre (message partagé collé). */
        fun find(text: String): PuzzleCode? {
            val upper = text.uppercase()
            var from = 0
            while (true) {
                val idx = upper.indexOf(PREFIX, from)
                if (idx < 0) return null
                val tail = upper.substring(idx).takeWhile { it.isLetterOrDigit() || it == '-' }
                parse(tail)?.let { return it }
                from = idx + PREFIX.length
            }
        }
    }
}

data class Puzzle(val code: PuzzleCode, val level: Level, val givens: Grid, val solution: Grid)

object DailySchedule {
    /** lundi → dimanche */
    val levels = listOf(Level.FACILE, Level.MOYEN, Level.MOYEN, Level.DIFFICILE, Level.DIFFICILE, Level.EXPERT, Level.EXPERT)
    fun level(day: DayStamp) = levels[day.weekday]
    fun seed(day: DayStamp): ULong = SplitMix64(0x5355444F4B554E4FuL xor day.dayNumber.toLong().toULong()).next()
}

object PuzzleFactory {
    /** Recrée la grille d'un code. Déterministe ; à appeler hors du thread principal. */
    fun make(code: PuzzleCode): Puzzle = when (code) {
        is PuzzleCode.Daily -> {
            val level = DailySchedule.level(code.day)
            val (p, s) = makeLevel(level, DailySchedule.seed(code.day))
            Puzzle(code, level, p, s)
        }
        is PuzzleCode.LevelSeed -> {
            val (p, s) = makeLevel(code.level, code.seed)
            Puzzle(code, code.level, p, s)
        }
        is PuzzleCode.DiaboliqueV1 -> {
            val (p, s) = Generator.generate(Level.DIABOLIQUE, SeededRandom(code.seed), version = 1)!!
            Puzzle(code, Level.DIABOLIQUE, p, s)
        }
        is PuzzleCode.Custom -> Puzzle(code, Grader.grade(code.grid), code.grid, Solver.solve(code.grid)!!)
    }

    fun randomSeed(): ULong = java.security.SecureRandom().nextLong().toULong()

    private fun makeLevel(level: Level, seed: ULong): Pair<Grid, Grid> = Generator.generate(level, SeededRandom(seed))!!
}
