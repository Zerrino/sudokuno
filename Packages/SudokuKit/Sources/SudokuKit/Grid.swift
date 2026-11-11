/// Une grille 9×9. Les cases sont indexées de 0 à 80 (ligne × 9 + colonne), 0 = case vide.
public struct Grid: Hashable, Sendable, Codable {
    public var cells: [UInt8]

    public init() {
        cells = Array(repeating: 0, count: 81)
    }

    public init(cells: [UInt8]) {
        precondition(cells.count == 81, "Une grille contient 81 cases")
        self.cells = cells
    }

    /// Lit une grille de 81 caractères : chiffres 1-9, `0` ou `.` pour une case vide. Les espaces sont ignorés.
    public init?(string: String) {
        var parsed: [UInt8] = []
        parsed.reserveCapacity(81)
        for ch in string {
            if ch == "." || ch == "0" {
                parsed.append(0)
            } else if let d = ch.wholeNumberValue, (1...9).contains(d) {
                parsed.append(UInt8(d))
            } else if ch.isWhitespace {
                continue
            } else {
                return nil
            }
        }
        guard parsed.count == 81 else { return nil }
        cells = parsed
    }

    /// Représentation compacte : 81 caractères, `.` pour une case vide.
    public var string: String {
        String(cells.map { $0 == 0 ? "." : Character(String($0)) })
    }

    public subscript(index: Int) -> UInt8 {
        get { cells[index] }
        set { cells[index] = newValue }
    }

    public var clueCount: Int { cells.reduce(0) { $0 + ($1 == 0 ? 0 : 1) } }
    public var isFilled: Bool { !cells.contains(0) }

    /// Vrai si aucun chiffre n'apparaît deux fois dans une ligne, une colonne ou un bloc.
    public var isConsistent: Bool {
        for unit in Sudoku.units {
            var seen: UInt16 = 0
            for i in unit where cells[i] != 0 {
                let b = Sudoku.bit(cells[i])
                if seen & b != 0 { return false }
                seen |= b
            }
        }
        return true
    }
}

/// Géométrie du Sudoku et utilitaires sur les masques de candidats (bit d-1 = chiffre d).
public enum Sudoku {
    public static let allDigits: UInt16 = 0x1FF

    @inline(__always) public static func row(_ i: Int) -> Int { i / 9 }
    @inline(__always) public static func col(_ i: Int) -> Int { i % 9 }
    @inline(__always) public static func box(_ i: Int) -> Int { (i / 27) * 3 + (i % 9) / 3 }
    @inline(__always) public static func bit(_ d: UInt8) -> UInt16 { 1 << UInt16(d - 1) }

    /// 27 unités : lignes 0-8, colonnes 9-17, blocs 18-26.
    public static let units: [[Int]] = {
        var u: [[Int]] = []
        for r in 0..<9 { u.append((0..<9).map { r * 9 + $0 }) }
        for c in 0..<9 { u.append((0..<9).map { $0 * 9 + c }) }
        for b in 0..<9 {
            let r0 = (b / 3) * 3, c0 = (b % 3) * 3
            u.append((0..<9).map { (r0 + $0 / 3) * 9 + c0 + $0 % 3 })
        }
        return u
    }()

    /// Pour chaque case : index de sa ligne, sa colonne et son bloc dans `units`.
    public static let unitsOfCell: [[Int]] = (0..<81).map { [row($0), 9 + col($0), 18 + box($0)] }

    /// Les 20 cases qui « voient » chaque case.
    public static let peers: [[Int]] = (0..<81).map { i in
        (0..<81).filter { $0 != i && (row($0) == row(i) || col($0) == col(i) || box($0) == box(i)) }
    }

    @inline(__always) public static func sees(_ a: Int, _ b: Int) -> Bool {
        a != b && (row(a) == row(b) || col(a) == col(b) || box(a) == box(b))
    }

    /// Les chiffres présents dans un masque, dans l'ordre croissant.
    public static func digits(_ mask: UInt16) -> [UInt8] {
        var out: [UInt8] = []
        var m = mask
        while m != 0 {
            let t = m.trailingZeroBitCount
            out.append(UInt8(t + 1))
            m &= m - 1
        }
        return out
    }

    public static func unitName(_ unit: Int) -> UnitKind {
        switch unit {
        case 0..<9: .row(unit)
        case 9..<18: .column(unit - 9)
        default: .box(unit - 18)
        }
    }

    public enum UnitKind: Hashable, Sendable {
        case row(Int), column(Int), box(Int)
    }
}
