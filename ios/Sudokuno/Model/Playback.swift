import SudokuKit

/// Un évènement du journal de partie : le chiffre d'une case change (0 = case effacée), ou une note est ajoutée / retirée.
struct Move: Hashable {
    enum Kind: Int {
        /// Chiffre posé ou effacé par le joueur.
        case player
        /// Coup joué par un indice.
        case hint
        /// Retour en arrière (bouton Annuler).
        case undo
        /// Note `digit` ajoutée dans la case (depuis la version 1.0.16 ; absent des parties plus anciennes).
        case noteOn
        /// Note `digit` retirée de la case (à la main, ou effacée quand un chiffre est posé).
        case noteOff
    }

    /// Un vrai coup (chiffre), pas une note : seuls ceux-là comptent pour le score et le replay.
    var isDigit: Bool { kind != .noteOn && kind != .noteOff }

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
    /// Coups au format `Move.packed`, dans l'ordre (notes comprises).
    var moves: [Int]

    /// Les coups de chiffres, dans l'ordre (sans les notes).
    var decoded: [Move] { moves.compactMap(Move.init(packed:)).filter(\.isDigit) }

    /// Notes du joueur à chaque étape du replay : `notesStates[k]` = après le coup k (et les notes prises avant le coup
    /// suivant). `nil` si la partie n'a aucune note enregistrée.
    var notesStates: [[UInt16]]? {
        let all = moves.compactMap(Move.init(packed:))
        guard all.contains(where: { !$0.isDigit }) else { return nil }
        var current = [UInt16](repeating: 0, count: 81)
        var out: [[UInt16]] = []
        for m in all {
            switch m.kind {
            case .noteOn: current[m.cell] |= Sudoku.bit(m.digit)
            case .noteOff: current[m.cell] &= ~Sudoku.bit(m.digit)
            default: out.append(current)
            }
        }
        out.append(current)
        return out
    }

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
