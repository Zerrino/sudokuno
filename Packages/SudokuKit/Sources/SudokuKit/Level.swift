/// Les 5 niveaux de Sudokuno. Le niveau d'une grille = la technique la plus difficile qu'elle exige.
public enum Level: Int, CaseIterable, Comparable, Codable, Sendable, Identifiable {
    case facile = 0, moyen, difficile, expert, diabolique

    public var id: Int { rawValue }

    public static func < (a: Level, b: Level) -> Bool { a.rawValue < b.rawValue }

    /// Lettre utilisée dans les codes de grille. Ne jamais changer (compatibilité des codes partagés).
    public var codeLetter: Character {
        switch self {
        case .facile: "F"
        case .moyen: "M"
        case .difficile: "D"
        case .expert: "E"
        case .diabolique: "X"
        }
    }

    public init?(codeLetter: Character) {
        guard let l = Level.allCases.first(where: { $0.codeLetter == codeLetter }) else { return nil }
        self = l
    }

    /// Nombre d'indices visé après génération (on ajoute des chiffres de la solution pour le confort,
    /// tant que le niveau ne change pas). 0 = on garde la grille minimale.
    var targetClues: Int {
        switch self {
        case .facile: 38
        case .moyen: 32
        case .difficile: 28
        case .expert, .diabolique: 0
        }
    }

    /// Temps minimal plausible (en secondes) pour envoyer un score à Game Center.
    public var minimumPlausibleSeconds: Int {
        switch self {
        case .facile: 30
        case .moyen: 45
        case .difficile: 60
        case .expert: 90
        case .diabolique: 120
        }
    }
}

/// Techniques de résolution « humaines », de la plus simple à la plus difficile.
public enum Technique: Int, CaseIterable, Comparable, Codable, Sendable {
    case nakedSingle, hiddenSingle
    case pointing, boxLineReduction, nakedPair, hiddenPair
    case nakedTriple, hiddenTriple, xWing
    case xyWing, swordfish, xyzWing

    public static func < (a: Technique, b: Technique) -> Bool { a.rawValue < b.rawValue }

    public var level: Level {
        switch self {
        case .nakedSingle, .hiddenSingle: .facile
        case .pointing, .boxLineReduction, .nakedPair, .hiddenPair: .moyen
        case .nakedTriple, .hiddenTriple, .xWing: .difficile
        case .xyWing, .swordfish, .xyzWing: .expert
        }
    }
}
