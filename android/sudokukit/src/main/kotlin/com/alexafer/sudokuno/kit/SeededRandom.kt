package com.alexafer.sudokuno.kit

// Générateurs pseudo-aléatoires DÉTERMINISTES, identiques bit à bit à SeededRandom.swift.
// Règle d'or : ne jamais utiliser kotlin.random, java.util.Random, shuffled() ni l'ordre d'un HashSet
// dans la génération, sinon un même code donnerait des grilles différentes selon la plateforme.

/** SplitMix64 (Steele, Lea & Flood, 2014). */
class SplitMix64(var state: ULong) {
    fun next(): ULong {
        state += 0x9E3779B97F4A7C15uL
        var z = state
        z = (z xor (z shr 30)) * 0xBF58476D1CE4E5B9uL
        z = (z xor (z shr 27)) * 0x94D049BB133111EBuL
        return z xor (z shr 31)
    }
}

/** xoshiro256** (Blackman & Vigna, 2018), initialisé par SplitMix64. */
class SeededRandom(seed: ULong) {
    private var s0: ULong
    private var s1: ULong
    private var s2: ULong
    private var s3: ULong

    init {
        val sm = SplitMix64(seed)
        s0 = sm.next(); s1 = sm.next(); s2 = sm.next(); s3 = sm.next()
    }

    private fun rotl(x: ULong, k: Int): ULong = (x shl k) or (x shr (64 - k))

    fun next(): ULong {
        val result = rotl(s1 * 5uL, 7) * 9uL
        val t = s1 shl 17
        s2 = s2 xor s0
        s3 = s3 xor s1
        s1 = s1 xor s2
        s0 = s0 xor s3
        s2 = s2 xor t
        s3 = rotl(s3, 45)
        return result
    }

    /** Entier uniforme dans 0 until bound (méthode de Lemire), comme `next(below:)` en Swift. */
    fun nextBelow(bound: Int): Int {
        require(bound > 0)
        val b = bound.toULong()
        var x = next()
        var low = x * b
        var high = mulHigh(x, b)
        if (low < b) {
            val threshold = (0uL - b) % b
            while (low < threshold) {
                x = next()
                low = x * b
                high = mulHigh(x, b)
            }
        }
        return high.toInt()
    }

    fun nextBool(): Boolean = next() and 1uL == 1uL

    /** Mélange de Fisher–Yates (même ordre de tirages qu'en Swift). */
    fun shuffle(array: IntArray) {
        var i = array.size - 1
        while (i > 0) {
            val j = nextBelow(i + 1)
            val tmp = array[i]; array[i] = array[j]; array[j] = tmp
            i--
        }
    }

    companion object {
        /** 64 bits de poids fort du produit non signé a × b (équivalent de multipliedFullWidth). */
        fun mulHigh(a: ULong, b: ULong): ULong {
            val mask = 0xFFFFFFFFuL
            val aLo = a and mask
            val aHi = a shr 32
            val bLo = b and mask
            val bHi = b shr 32
            val p0 = aLo * bLo
            val p1 = aLo * bHi
            val p2 = aHi * bLo
            val p3 = aHi * bHi
            val carry = ((p0 shr 32) + (p1 and mask) + (p2 and mask)) shr 32
            return p3 + (p1 shr 32) + (p2 shr 32) + carry
        }
    }
}
