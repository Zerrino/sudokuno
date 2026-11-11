/// Une grille célèbre pour sa difficulté. Elle se joue telle quelle et se partage avec un code de grille
/// créée (`PuzzleCode.custom`) : le jeu la reconnaît à ses chiffres.
public struct LegendPuzzle: Hashable, Sendable, Identifiable {
    /// Identifiant stable (sauvegardes, traductions). Ne jamais changer.
    public let id: String
    /// Nom sous lequel la grille est connue (non traduit).
    public let name: String
    /// Auteur, s'il est connu avec certitude.
    public let author: String?
    public let year: Int?
    public let givens: Grid
}

/// Les grilles de la Légende. Toutes ont une solution unique et résistent à toutes nos techniques,
/// chaînes comprises (vérifié par les tests, des deux côtés). L'ordre est l'ordre d'affichage.
/// Sources : sudokuwiki.org (Inkala, AI Escargot, « Unsolvable »), forums de solveurs (les autres).
/// Liste identique dans `android/sudokukit/.../Legends.kt`.
public enum Legends {
    public static let all: [LegendPuzzle] = [
        make("escargot", "AI Escargot", "Arto Inkala", 2006,
             "100007090030020008009600500005300900010080002600004000300000010040000007007000300"),
        make("inkala2010", "Inkala 2010", "Arto Inkala", 2010,
             "005300000800000020070010500400005300010070006003200080060500009004000030000009700"),
        make("inkala2012", "Inkala 2012", "Arto Inkala", 2012,
             "800000000003600000070090200050007000000045700000100030001000068008500010090000400"),
        make("easter-monster", "Easter Monster", nil, nil,
             "100000002090400050006000700050903000000070000000850040700000600030009080002000001"),
        make("golden-nugget", "Golden Nugget", nil, nil,
             "000000039000001005003050800008090006070002000100400000009080050020000600400700000"),
        make("platinum-blonde", "Platinum Blonde", nil, nil,
             "000000012000000003002300400001800005060070800000009000008500000900040500470006000"),
        make("unsolvable28", "Unsolvable #28", "David Filmer", nil,
             "600008940900006100070040000200610000000000200089002000000060005000000030800001600"),
        make("unsolvable49", "Unsolvable #49", "David Filmer", nil,
             "002800000030060007100000040600090000050600009000057060000300100070006008400000020"),
    ]

    public static func find(_ grid: Grid) -> LegendPuzzle? { all.first { $0.givens == grid } }

    public static func find(id: String) -> LegendPuzzle? { all.first { $0.id == id } }

    private static func make(_ id: String, _ name: String, _ author: String?, _ year: Int?, _ grid: String) -> LegendPuzzle {
        LegendPuzzle(id: id, name: name, author: author, year: year, givens: Grid(string: grid)!)
    }
}
