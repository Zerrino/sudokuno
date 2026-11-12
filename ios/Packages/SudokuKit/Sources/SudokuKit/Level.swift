/// Les niveaux de Sudokuno. Le niveau d'une grille = la technique la plus difficile qu'elle exige.
/// Légende : grilles célèbres (`Legends`) que même nos chaînes ne résolvent pas. Jamais générée.
public enum Level: Int, CaseIterable, Comparable, Codable, Sendable, Identifiable {
    case facile = 0, moyen, difficile, expert, diabolique, legende

    /// Niveaux produits par le générateur (et donc par un code `SKN1-<lettre>-…`).
    public static let generated: [Level] = [.facile, .moyen, .difficile, .expert, .diabolique]

    public var id: Int { rawValue }

    public static func < (a: Level, b: Level) -> Bool { a.rawValue < b.rawValue }

    /// Lettre utilisée dans les codes de grille. Ne jamais changer (compatibilité des codes partagés).
    public var codeLetter: Character {
        switch self {
        case .facile: "F"
        case .moyen: "M"
        case .difficile: "D"
        case .expert: "E"
        case .diabolique: "Z" // "X" = ancien Diabolique (générateur v1), voir `PuzzleCode.diaboliqueV1`
        case .legende: "L"
        }
    }

    /// Lettre des identifiants Game Center / Google Play Jeux (classements, succès) et des tests d'interface.
    /// Figée : Diabolique reste « X » même si ses codes de grille utilisent « Z ».
    public var servicesLetter: Character { self == .diabolique ? "X" : codeLetter }

    /// Seulement les niveaux générés : une grille Légende se partage avec son code de grille créée.
    public init?(codeLetter: Character) {
        guard let l = Level.generated.first(where: { $0.codeLetter == codeLetter }) else { return nil }
        self = l
    }

    /// Nombre d'indices visé après génération (on ajoute des chiffres de la solution pour le confort,
    /// tant que le niveau ne change pas). 0 = on garde la grille minimale.
    var targetClues: Int {
        switch self {
        case .facile: 38
        case .moyen: 32
        case .difficile: 28
        case .expert, .diabolique, .legende: 0
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
        case .legende: 180
        }
    }
}

/// Techniques de résolution « humaines », de la plus simple à la plus difficile.
public enum Technique: Int, CaseIterable, Comparable, Codable, Sendable {
    case nakedSingle, hiddenSingle
    case pointing, boxLineReduction, nakedPair, hiddenPair
    case nakedTriple, hiddenTriple, xWing
    case xyWing, swordfish, xyzWing
    /// Chaînes (voir `LogicalSolver.chain()`). Ajoutées après les autres : les niveaux Facile → Expert
    /// et donc leurs codes ne changent pas.
    case turbotFish, xChain, xyChain, aic
    /// Preuves par l'absurde (voir `ForcingProof`) : seulement pour expliquer les grilles Légende,
    /// jamais produites par `LogicalSolver.nextStep` ni comptées dans le classement des grilles.
    case forcingChain, forcingNet

    public static func < (a: Technique, b: Technique) -> Bool { a.rawValue < b.rawValue }

    /// Une vraie chaîne (au-delà du simple Turbot) : exigée pour une grille Diabolique générée.
    public var isLongChain: Bool { self >= .xChain }

    public var level: Level {
        switch self {
        case .nakedSingle, .hiddenSingle: .facile
        case .pointing, .boxLineReduction, .nakedPair, .hiddenPair: .moyen
        case .nakedTriple, .hiddenTriple, .xWing: .difficile
        case .xyWing, .swordfish, .xyzWing: .expert
        case .turbotFish, .xChain, .xyChain, .aic: .diabolique
        case .forcingChain, .forcingNet: .legende
        }
    }
}
