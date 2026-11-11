import Foundation

/// Un jour calendaire en UTC. La grille du jour et la série en dépendent.
public struct DayStamp: Hashable, Comparable, Codable, Sendable {
    /// Nombre de jours depuis le 1er janvier 1970 (UTC).
    public let dayNumber: Int

    public init(dayNumber: Int) { self.dayNumber = dayNumber }

    public init(date: Date) {
        dayNumber = Int((date.timeIntervalSince1970 / 86_400).rounded(.down))
    }

    public static var today: DayStamp { DayStamp(date: .now) }

    public init?(year: Int, month: Int, day: Int) {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        guard let date = cal.date(from: DateComponents(year: year, month: month, day: day)),
              cal.component(.day, from: date) == day, cal.component(.month, from: date) == month
        else { return nil }
        self.init(date: date)
    }

    public static func < (a: DayStamp, b: DayStamp) -> Bool { a.dayNumber < b.dayNumber }

    public func adding(days: Int) -> DayStamp { DayStamp(dayNumber: dayNumber + days) }

    public var date: Date { Date(timeIntervalSince1970: TimeInterval(dayNumber) * 86_400) }

    public var components: (year: Int, month: Int, day: Int) {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let c = cal.dateComponents([.year, .month, .day], from: date)
        return (c.year!, c.month!, c.day!)
    }

    /// « 20261110 »
    public var key: String {
        let c = components
        return String(format: "%04d%02d%02d", c.year, c.month, c.day)
    }

    /// 0 = lundi … 6 = dimanche. Le 1er janvier 1970 était un jeudi.
    public var weekday: Int { ((dayNumber + 3) % 7 + 7) % 7 }

    /// Début du jour suivant (minuit UTC) : moment où la grille du jour change.
    public var nextStart: Date { adding(days: 1).date }
}

/// Le code d'une grille. Saisir le même code recrée exactement la même grille, partout.
public enum PuzzleCode: Hashable, Codable, Sendable {
    case level(Level, seed: UInt64)
    case daily(DayStamp)
    /// Grille créée par un joueur : elle ne vient d'aucune graine, le code contient donc la grille.
    case custom(Grid)
    /// Ancien code Diabolique (`SKN1-X-…`, générateur v1, sans chaînes). Toujours lu et rejoué à l'identique ;
    /// les nouvelles parties Diabolique utilisent `.level(.diabolique, …)` (`SKN1-Z-…`, chaînes obligatoires).
    case diaboliqueV1(seed: UInt64)

    /// Version du générateur. Ne JAMAIS modifier le comportement d'une version publiée :
    /// créer une nouvelle version et garder l'ancien code.
    public static let generatorVersion = 1
    static let prefix = "SKN1"
    static let alphabet = Array("0123456789ABCDEFGHJKMNPQRSTVWXYZ") // base 32 de Crockford

    public var string: String {
        switch self {
        case .daily(let day):
            return "\(Self.prefix)-J-\(day.key)"
        case .custom(let grid):
            let symbols = Self.encodeCustom(grid)
            let groups = stride(from: 0, to: symbols.count, by: 4).map { String(symbols[$0..<min($0 + 4, symbols.count)]) }
            return "\(Self.prefix)-C-" + groups.joined(separator: "-")
        case .level(let level, let seed):
            return Self.seedString(letter: level.codeLetter, level: level, seed: seed)
        case .diaboliqueV1(let seed):
            return Self.seedString(letter: "X", level: .diabolique, seed: seed)
        }
    }

    static func seedString(letter: Character, level: Level, seed: UInt64) -> String {
        var chars: [Character] = []
        var v = seed
        for _ in 0..<13 {
            chars.append(Self.alphabet[Int(v & 31)])
            v >>= 5
        }
        chars.reverse()
        chars.append(Self.alphabet[Self.checksum(level: level, symbols: chars)])
        let s = String(chars)
        let g = [s.prefix(4), s.dropFirst(4).prefix(4), s.dropFirst(8).prefix(4), s.dropFirst(12)]
        return "\(Self.prefix)-\(letter)-" + g.map(String.init).joined(separator: "-")
    }

    public var level: Level? {
        switch self {
        case .level(let l, _): l
        case .diaboliqueV1: .diabolique
        default: nil
        }
    }

    public var isDaily: Bool {
        if case .daily = self { return true }
        return false
    }

    /// Lit un code. Tolère minuscules, espaces, tirets manquants et confusions O/0, I/1, L/1.
    public init?(string raw: String) {
        let cleaned = raw.uppercased().filter { !$0.isWhitespace && $0 != "-" }
        guard cleaned.hasPrefix(Self.prefix) else { return nil }
        var rest = cleaned.dropFirst(Self.prefix.count)
        guard let kind = rest.first else { return nil }
        rest = rest.dropFirst()

        if kind == "C" {
            guard let grid = Self.decodeCustom(rest.map { ch in
                switch ch { case "O": "0"; case "I", "L": "1"; default: ch }
            }) else { return nil }
            self = .custom(grid)
            return
        }

        if kind == "J" {
            let digits = String(rest)
            guard digits.count == 8, digits.allSatisfy(\.isNumber),
                  let y = Int(digits.prefix(4)), let m = Int(digits.dropFirst(4).prefix(2)), let d = Int(digits.suffix(2)),
                  let day = DayStamp(year: y, month: m, day: d)
            else { return nil }
            self = .daily(day)
            return
        }

        let legacy = kind == "X"
        guard let level = legacy ? .diabolique : Level(codeLetter: kind) else { return nil }
        let symbols: [Character] = rest.map { ch in
            switch ch {
            case "O": "0"
            case "I", "L": "1"
            default: ch
            }
        }
        guard symbols.count == 14 else { return nil }
        var seed: UInt64 = 0
        for (k, ch) in symbols.prefix(13).enumerated() {
            guard let v = Self.alphabet.firstIndex(of: ch) else { return nil }
            if k == 0 && v > 15 { return nil } // 13 × 5 = 65 bits : le premier symbole ne porte que 4 bits
            seed = (seed << 5) | UInt64(v)
        }
        guard Self.alphabet[Self.checksum(level: level, symbols: Array(symbols.prefix(13)))] == symbols[13] else { return nil }
        self = legacy ? .diaboliqueV1(seed: seed) : .level(level, seed: seed)
    }

    // MARK: - Grilles créées (format C)
    //
    // Bits : 81 bits de présence (case 0 → 80), puis 4 bits par chiffre donné (chiffre - 1),
    // complétés par des zéros jusqu'à un multiple de 5, écrits en base 32 de Crockford.
    // Un dernier symbole de contrôle détecte les fautes de frappe.

    static func encodeCustom(_ grid: Grid) -> [Character] {
        var bits: [Bool] = grid.cells.map { $0 != 0 }
        for v in grid.cells where v != 0 {
            let x = Int(v - 1)
            for k in (0..<4).reversed() { bits.append((x >> k) & 1 == 1) }
        }
        while bits.count % 5 != 0 { bits.append(false) }
        var symbols: [Character] = []
        for i in stride(from: 0, to: bits.count, by: 5) {
            var v = 0
            for k in 0..<5 { v = v << 1 | (bits[i + k] ? 1 : 0) }
            symbols.append(alphabet[v])
        }
        symbols.append(alphabet[customChecksum(symbols)])
        return symbols
    }

    static func decodeCustom(_ raw: [Character]) -> Grid? {
        guard raw.count >= 18, let check = raw.last else { return nil }
        let symbols = Array(raw.dropLast())
        guard alphabet[customChecksum(symbols)] == check else { return nil }
        var bits: [Bool] = []
        for ch in symbols {
            guard let v = alphabet.firstIndex(of: ch) else { return nil }
            for k in (0..<5).reversed() { bits.append((v >> k) & 1 == 1) }
        }
        guard bits.count >= 81 else { return nil }
        let present = Array(bits[0..<81])
        let n = present.filter { $0 }.count
        let needed = 81 + 4 * n
        guard bits.count >= needed, bits.count - needed < 5, !bits[needed...].contains(true) else { return nil }
        var cells = [UInt8](repeating: 0, count: 81)
        var pos = 81
        for i in 0..<81 where present[i] {
            var x = 0
            for k in 0..<4 { x = x << 1 | (bits[pos + k] ? 1 : 0) }
            pos += 4
            guard x <= 8 else { return nil }
            cells[i] = UInt8(x + 1)
        }
        let grid = Grid(cells: cells)
        return grid.isConsistent ? grid : nil
    }

    /// Poids de 1 à 30, jamais nuls modulo 31, même pour un code long.
    static func customChecksum(_ symbols: [Character]) -> Int {
        var sum = 11
        for (k, ch) in symbols.enumerated() {
            sum += (k % 30 + 1) * (alphabet.firstIndex(of: ch) ?? 0)
        }
        return sum % 31
    }

    /// Somme pondérée modulo 31 : détecte toute faute de frappe sur un seul symbole.
    static func checksum(level: Level, symbols: [Character]) -> Int {
        var sum = (level.rawValue + 1) * 7
        for (k, ch) in symbols.enumerated() {
            sum += (k + 2) * (alphabet.firstIndex(of: ch) ?? 0)
        }
        return sum % 31
    }

    /// Cherche un code dans un texte libre (message partagé collé par l'utilisateur).
    public static func find(in text: String) -> PuzzleCode? {
        let upper = text.uppercased()
        var search = upper.startIndex
        while let r = upper.range(of: prefix, range: search..<upper.endIndex) {
            let tail = upper[r.lowerBound...].prefix { $0.isLetter || $0.isNumber || $0 == "-" }
            if let code = PuzzleCode(string: String(tail)) { return code }
            search = r.upperBound
        }
        return nil
    }
}
