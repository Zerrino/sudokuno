import SudokuKit

/// Un coup du journal de partie : le chiffre d'une case change (0 = case effacée).
struct Move: Hashable {
    enum Kind: Int {
        /// Chiffre posé ou effacé par le joueur.
        case player
        /// Coup joué par un indice.
        case hint
        /// Retour en arrière (bouton Annuler).
        case undo
    }

    var cell: Int
    var digit: UInt8
    var kind: Kind
    /// Secondes écoulées depuis le début de la partie.
    var time: Int

    /// Forme compacte enregistrée : temps × 100 000 + type × 10 000 + case × 10 + chiffre.
    var packed: Int { time * 100_000 + kind.rawValue * 10_000 + cell * 10 + Int(digit) }

    init(cell: Int, digit: UInt8, kind: Kind, time: Int) {
        self.cell = cell
        self.digit = digit
        self.kind = kind
        self.time = time
    }

    /// Le coup tel que le compte le score.
    var scored: ScoredMove { ScoredMove(cell: cell, digit: digit, hint: kind == .hint, time: time) }

    init?(packed: Int) {
        let low = packed % 10_000
        guard packed >= 0, let kind = Kind(rawValue: packed / 10_000 % 10), low / 10 < 81 else { return nil }
        self.init(cell: low / 10, digit: UInt8(low % 10), kind: kind, time: packed / 100_000)
    }
}

/// De quoi revoir une partie coup par coup depuis l'historique.
struct Playback: Codable, Hashable {
    var givens: Grid
    var solution: Grid
    /// Coups au format `Move.packed`, dans l'ordre.
    var moves: [Int]

    var decoded: [Move] { moves.compactMap(Move.init(packed:)) }

    /// État de la grille après chaque coup : `states[0]` = grille de départ, `states[k]` = après le coup k.
    var states: [[UInt8]] {
        var current = givens.cells
        var out = [current]
        for m in decoded {
            current[m.cell] = m.digit
            out.append(current)
        }
        return out
    }

    func isMistake(_ m: Move) -> Bool { m.kind == .player && m.digit != 0 && m.digit != solution[m.cell] }
}
