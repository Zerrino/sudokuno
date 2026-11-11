// Générateurs pseudo-aléatoires DÉTERMINISTES.
//
// Règle d'or : toute la génération de grilles passe par ces types. On n'utilise jamais
// SystemRandomNumberGenerator, Hasher, `shuffle()` / `randomElement()` de la bibliothèque standard
// ni l'ordre d'itération d'un Set ou d'un Dictionary : ils changent d'un lancement ou d'une version
// à l'autre, et un même code de grille donnerait des grilles différentes.

/// SplitMix64 (Steele, Lea & Flood, 2014). Sert à initialiser xoshiro et à dériver des graines.
public struct SplitMix64: Sendable {
    public var state: UInt64

    public init(seed: UInt64) { state = seed }

    public mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

/// xoshiro256** (Blackman & Vigna, 2018), initialisé par SplitMix64.
public struct SeededRandom: Sendable {
    private var s0, s1, s2, s3: UInt64

    public init(seed: UInt64) {
        var sm = SplitMix64(seed: seed)
        s0 = sm.next(); s1 = sm.next(); s2 = sm.next(); s3 = sm.next()
    }

    @inline(__always) private static func rotl(_ x: UInt64, _ k: UInt64) -> UInt64 {
        (x << k) | (x >> (64 - k))
    }

    public mutating func next() -> UInt64 {
        let result = Self.rotl(s1 &* 5, 7) &* 9
        let t = s1 << 17
        s2 ^= s0
        s3 ^= s1
        s1 ^= s2
        s0 ^= s3
        s2 ^= t
        s3 = Self.rotl(s3, 45)
        return result
    }

    /// Entier uniforme dans 0..<bound (méthode de Lemire, sans biais).
    public mutating func next(below bound: Int) -> Int {
        precondition(bound > 0)
        let b = UInt64(bound)
        var m = next().multipliedFullWidth(by: b)
        if m.low < b {
            let threshold = (0 &- b) % b
            while m.low < threshold {
                m = next().multipliedFullWidth(by: b)
            }
        }
        return Int(m.high)
    }

    public mutating func nextBool() -> Bool { next() & 1 == 1 }

    /// Mélange de Fisher–Yates.
    public mutating func shuffle<T>(_ array: inout [T]) {
        guard array.count > 1 else { return }
        var i = array.count - 1
        while i > 0 {
            let j = next(below: i + 1)
            array.swapAt(i, j)
            i -= 1
        }
    }
}
