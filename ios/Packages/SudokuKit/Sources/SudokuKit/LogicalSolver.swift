public struct Placement: Hashable, Sendable {
    public let cell: Int
    public let digit: UInt8
}

public struct CandidateRef: Hashable, Sendable {
    public let cell: Int
    public let digit: UInt8
}

/// Un coup logique : une technique qui place des chiffres ou élimine des candidats.
public struct LogicStep: Sendable {
    public let technique: Technique
    public var placements: [Placement] = []
    public var eliminations: [CandidateRef] = []
    /// Unité (index dans `Sudoku.units`) au cœur du raisonnement, si elle existe.
    public var unit: Int?
    /// Cases qui forment le motif (paire, X-Wing, pivot…).
    public var focus: [Int] = []
    // Détails réservés à l'explication (`Explainer`) : ils ne changent ni les coups trouvés ni leur ordre.
    /// Chiffres du motif (le chiffre confiné, ceux de la paire, celui du poisson, le chiffre commun d'une aile…).
    public var digits: [UInt8] = []
    /// Autres unités du raisonnement : la ligne visée par un bloc (ou l'inverse), lignes de base puis de couverture d'un poisson.
    public var units: [Int] = []
    /// Maillons d'une chaîne, dans l'ordre ; les liens alternent fort, faible, fort…
    public var chain: [CandidateRef] = []
}

/// Solveur « humain » : applique les techniques de la plus simple à la plus difficile.
/// Sert à évaluer la difficulté et à produire les indices.
public struct LogicalSolver: Sendable {
    public private(set) var values: [UInt8]
    public private(set) var candidates: [UInt16]
    /// Chercher aussi des chaînes (Turbot, X-Chain, XY-Chain, AIC) quand le reste échoue.
    public let chains: Bool

    public init(_ grid: Grid, chains: Bool = true) {
        self.chains = chains
        values = grid.cells
        candidates = [UInt16](repeating: 0, count: 81)
        for i in 0..<81 where values[i] == 0 {
            var used: UInt16 = 0
            for p in Sudoku.peers[i] where values[p] != 0 { used |= Sudoku.bit(values[p]) }
            candidates[i] = ~used & Sudoku.allDigits
        }
    }

    public var isSolved: Bool { !values.contains(0) }

    /// Une case vide sans candidat : la grille est contradictoire.
    public var hasContradiction: Bool {
        (0..<81).contains { values[$0] == 0 && candidates[$0] == 0 }
    }

    public mutating func apply(_ step: LogicStep) {
        for p in step.placements { place(p.cell, p.digit) }
        for e in step.eliminations { candidates[e.cell] &= ~Sudoku.bit(e.digit) }
    }

    mutating func place(_ i: Int, _ d: UInt8) {
        guard values[i] == 0 else { return }
        values[i] = d
        candidates[i] = 0
        let b = ~Sudoku.bit(d)
        for p in Sudoku.peers[i] { candidates[p] &= b }
    }

    /// Résout autant que possible. Retourne la technique la plus difficile utilisée.
    @discardableResult
    public mutating func solve() -> (solved: Bool, hardest: Technique?) {
        var hardest: Technique?
        while !isSolved, let step = nextStep() {
            hardest = max(hardest ?? step.technique, step.technique)
            apply(step)
        }
        return (isSolved, hardest)
    }

    /// Le prochain coup logique, en essayant les techniques dans l'ordre de difficulté.
    public func nextStep() -> LogicStep? {
        if hasContradiction { return nil }
        let finders: [(LogicalSolver) -> LogicStep?] = [
            { $0.nakedSingle() },
            { $0.hiddenSingle() },
            { $0.pointing() },
            { $0.boxLineReduction() },
            { $0.nakedSubset(size: 2) },
            { $0.hiddenSubset(size: 2) },
            { $0.nakedSubset(size: 3) },
            { $0.hiddenSubset(size: 3) },
            { $0.fish(size: 2) },
            { $0.xyWing() },
            { $0.fish(size: 3) },
            { $0.xyzWing() },
        ]
        for find in finders {
            if let step = find(self) { return step }
        }
        return chains ? chain() : nil
    }

    // MARK: - Singletons

    func nakedSingle() -> LogicStep? {
        for i in 0..<81 where values[i] == 0 && candidates[i].nonzeroBitCount == 1 {
            let d = UInt8(candidates[i].trailingZeroBitCount + 1)
            return LogicStep(technique: .nakedSingle, placements: [Placement(cell: i, digit: d)], focus: [i], digits: [d])
        }
        return nil
    }

    func hiddenSingle() -> LogicStep? {
        // Blocs d'abord : c'est ce qu'un humain repère le plus facilement.
        for u in Array(18..<27) + Array(0..<18) {
            let unit = Sudoku.units[u]
            for d in UInt8(1)...9 {
                let b = Sudoku.bit(d)
                var spot = -1
                var n = 0
                for i in unit where candidates[i] & b != 0 {
                    spot = i; n += 1
                    if n > 1 { break }
                }
                if n == 1 {
                    return LogicStep(technique: .hiddenSingle, placements: [Placement(cell: spot, digit: d)],
                                     unit: u, focus: [spot], digits: [d])
                }
            }
        }
        return nil
    }

    // MARK: - Interactions bloc / ligne

    /// Dans un bloc, un chiffre confiné à une ligne (ou colonne) est éliminé du reste de cette ligne.
    func pointing() -> LogicStep? {
        for bx in 0..<9 {
            let u = 18 + bx
            let box = Sudoku.units[u]
            for d in UInt8(1)...9 {
                let b = Sudoku.bit(d)
                let spots = box.filter { candidates[$0] & b != 0 }
                guard spots.count >= 2 else { continue }
                for line in [Set(spots.map(Sudoku.row)).count == 1 ? Sudoku.row(spots[0]) : nil,
                             Set(spots.map(Sudoku.col)).count == 1 ? 9 + Sudoku.col(spots[0]) : nil]
                    .compactMap({ $0 }) {
                    let elim = Sudoku.units[line]
                        .filter { Sudoku.box($0) != bx && candidates[$0] & b != 0 }
                        .map { CandidateRef(cell: $0, digit: d) }
                    if !elim.isEmpty {
                        return LogicStep(technique: .pointing, eliminations: elim, unit: u, focus: spots, digits: [d], units: [line])
                    }
                }
            }
        }
        return nil
    }

    /// Dans une ligne (ou colonne), un chiffre confiné à un bloc est éliminé du reste du bloc.
    func boxLineReduction() -> LogicStep? {
        for u in 0..<18 {
            let line = Sudoku.units[u]
            for d in UInt8(1)...9 {
                let b = Sudoku.bit(d)
                let spots = line.filter { candidates[$0] & b != 0 }
                guard spots.count >= 2, Set(spots.map(Sudoku.box)).count == 1 else { continue }
                let bx = Sudoku.box(spots[0])
                let elim = Sudoku.units[18 + bx]
                    .filter { !line.contains($0) && candidates[$0] & b != 0 }
                    .map { CandidateRef(cell: $0, digit: d) }
                if !elim.isEmpty {
                    return LogicStep(technique: .boxLineReduction, eliminations: elim, unit: u, focus: spots, digits: [d], units: [18 + bx])
                }
            }
        }
        return nil
    }

    // MARK: - Sous-ensembles (paires, triplets)

    func nakedSubset(size n: Int) -> LogicStep? {
        for u in 0..<27 {
            let unit = Sudoku.units[u]
            let pool = unit.filter { values[$0] == 0 && (2...n).contains(candidates[$0].nonzeroBitCount) }
            guard pool.count >= n else { continue }
            for combo in combinations(pool, n) {
                let union = combo.reduce(UInt16(0)) { $0 | candidates[$1] }
                guard union.nonzeroBitCount == n else { continue }
                var elim: [CandidateRef] = []
                for i in unit where values[i] == 0 && !combo.contains(i) && candidates[i] & union != 0 {
                    for d in Sudoku.digits(candidates[i] & union) { elim.append(CandidateRef(cell: i, digit: d)) }
                }
                if !elim.isEmpty {
                    return LogicStep(technique: n == 2 ? .nakedPair : .nakedTriple, eliminations: elim, unit: u, focus: combo,
                                     digits: Sudoku.digits(union))
                }
            }
        }
        return nil
    }

    func hiddenSubset(size n: Int) -> LogicStep? {
        for u in 0..<27 {
            let unit = Sudoku.units[u]
            // Chiffres encore à placer dans l'unité, avec leurs positions possibles.
            var digitSpots: [(digit: UInt8, spots: [Int])] = []
            for d in UInt8(1)...9 {
                let b = Sudoku.bit(d)
                let spots = unit.filter { candidates[$0] & b != 0 }
                if (2...n).contains(spots.count) { digitSpots.append((d, spots)) }
            }
            guard digitSpots.count >= n else { continue }
            for combo in combinations(Array(digitSpots.indices), n) {
                let cells = Set(combo.flatMap { digitSpots[$0].spots })
                guard cells.count == n else { continue }
                let keep = combo.reduce(UInt16(0)) { $0 | Sudoku.bit(digitSpots[$1].digit) }
                var elim: [CandidateRef] = []
                for i in cells.sorted() where candidates[i] & ~keep != 0 {
                    for d in Sudoku.digits(candidates[i] & ~keep) { elim.append(CandidateRef(cell: i, digit: d)) }
                }
                if !elim.isEmpty {
                    return LogicStep(technique: n == 2 ? .hiddenPair : .hiddenTriple, eliminations: elim,
                                     unit: u, focus: cells.sorted(), digits: Sudoku.digits(keep))
                }
            }
        }
        return nil
    }

    // MARK: - Poissons (X-Wing, Swordfish)

    func fish(size n: Int) -> LogicStep? {
        for d in UInt8(1)...9 {
            let b = Sudoku.bit(d)
            for byRow in [true, false] {
                // base[k] = positions (colonnes si byRow) du chiffre dans la ligne k
                var bases: [(line: Int, covers: [Int])] = []
                for k in 0..<9 {
                    let unit = Sudoku.units[byRow ? k : 9 + k]
                    let covers = unit.filter { candidates[$0] & b != 0 }.map { byRow ? Sudoku.col($0) : Sudoku.row($0) }
                    if (2...n).contains(covers.count) { bases.append((k, covers)) }
                }
                guard bases.count >= n else { continue }
                for combo in combinations(Array(bases.indices), n) {
                    let coverSet = Set(combo.flatMap { bases[$0].covers })
                    guard coverSet.count == n else { continue }
                    let baseLines = Set(combo.map { bases[$0].line })
                    var elim: [CandidateRef] = []
                    for c in coverSet.sorted() {
                        for i in Sudoku.units[byRow ? 9 + c : c] where candidates[i] & b != 0 {
                            let line = byRow ? Sudoku.row(i) : Sudoku.col(i)
                            if !baseLines.contains(line) { elim.append(CandidateRef(cell: i, digit: d)) }
                        }
                    }
                    if !elim.isEmpty {
                        let focus = baseLines.sorted().flatMap { k in
                            Sudoku.units[byRow ? k : 9 + k].filter { candidates[$0] & b != 0 }
                        }
                        return LogicStep(technique: n == 2 ? .xWing : .swordfish, eliminations: elim, focus: focus, digits: [d],
                                         units: baseLines.sorted().map { byRow ? $0 : 9 + $0 } + coverSet.sorted().map { byRow ? 9 + $0 : $0 })
                    }
                }
            }
        }
        return nil
    }

    // MARK: - Ailes (XY-Wing, XYZ-Wing)

    func xyWing() -> LogicStep? {
        let bivalue = (0..<81).filter { values[$0] == 0 && candidates[$0].nonzeroBitCount == 2 }
        for p in bivalue {
            let pm = candidates[p]
            let wings = bivalue.filter { $0 != p && Sudoku.sees($0, p) && (candidates[$0] & pm).nonzeroBitCount == 1 }
            for a in wings {
                let z = candidates[a] & ~pm
                let shared = candidates[a] & pm
                let need = (pm & ~shared) | z
                for c in wings where c != a && candidates[c] == need {
                    let zd = UInt8(z.trailingZeroBitCount + 1)
                    let elim = (0..<81)
                        .filter { $0 != p && $0 != a && $0 != c && candidates[$0] & z != 0 && Sudoku.sees($0, a) && Sudoku.sees($0, c) }
                        .map { CandidateRef(cell: $0, digit: zd) }
                    if !elim.isEmpty {
                        return LogicStep(technique: .xyWing, eliminations: elim, focus: [p, a, c], digits: [zd])
                    }
                }
            }
        }
        return nil
    }

    func xyzWing() -> LogicStep? {
        for p in 0..<81 where values[p] == 0 && candidates[p].nonzeroBitCount == 3 {
            let pm = candidates[p]
            let wings = Sudoku.peers[p].filter {
                values[$0] == 0 && candidates[$0].nonzeroBitCount == 2 && candidates[$0] & ~pm == 0
            }
            for (ai, a) in wings.enumerated() {
                for c in wings[(ai + 1)...] {
                    let z = candidates[a] & candidates[c]
                    guard z.nonzeroBitCount == 1, candidates[a] | candidates[c] == pm else { continue }
                    let zd = UInt8(z.trailingZeroBitCount + 1)
                    let elim = (0..<81)
                        .filter {
                            $0 != p && $0 != a && $0 != c && candidates[$0] & z != 0
                                && Sudoku.sees($0, p) && Sudoku.sees($0, a) && Sudoku.sees($0, c)
                        }
                        .map { CandidateRef(cell: $0, digit: zd) }
                    if !elim.isEmpty {
                        return LogicStep(technique: .xyzWing, eliminations: elim, focus: [p, a, c], digits: [zd])
                    }
                }
            }
        }
        return nil
    }
}

// MARK: - Chaînes

extension LogicalSolver {
    /// Longueur maximale d'une chaîne, en candidats.
    static let maxChainNodes = 12

    /// Chaîne d'inférences alternées (AIC) la plus courte qui élimine un candidat.
    ///
    /// Un nœud est un candidat (case, chiffre), numéroté `case * 9 + chiffre - 1`.
    /// - lien fort A = B : si A est faux, B est vrai (case à deux candidats, ou chiffre à deux places dans une unité) ;
    /// - lien faible A - B : si A est vrai, B est faux (même case, ou même chiffre dans deux cases qui se voient).
    /// Une chaîne A = … = Z qui commence et finit par un lien fort prouve « A ou Z est vrai ».
    /// Le chemin est une suite d'implications valides, il n'a donc pas besoin d'être sans répétition.
    func chain() -> LogicStep? {
        var strong = [[Int]](repeating: [], count: 729)
        var weak = [[Int]](repeating: [], count: 729)
        var nodes: [Int] = []
        for c in 0..<81 where values[c] == 0 {
            let m = candidates[c]
            for d in 0..<9 where m & (1 << UInt16(d)) != 0 {
                let n = c * 9 + d
                nodes.append(n)
                let b: UInt16 = 1 << UInt16(d)
                if m.nonzeroBitCount == 2 { strong[n].append(c * 9 + (m & ~b).trailingZeroBitCount) }
                for u in Sudoku.unitsOfCell[c] {
                    var other = -1
                    var count = 0
                    for i in Sudoku.units[u] where candidates[i] & b != 0 {
                        count += 1
                        if i != c { other = i }
                    }
                    if count == 2 { strong[n].append(other * 9 + d) }
                }
                for e in 0..<9 where e != d && m & (1 << UInt16(e)) != 0 { weak[n].append(c * 9 + e) }
                for p in Sudoku.peers[c] where candidates[p] & b != 0 { weak[n].append(p * 9 + d) }
            }
        }

        // État = nœud * 2 + 0 (faux : lien fort ensuite) ou + 1 (vrai : lien faible ensuite).
        var dist = [Int](repeating: 0, count: 1458)
        var parent = [Int](repeating: -1, count: 1458)
        var best: (path: [Int], elim: [CandidateRef])?
        var bestLength = Self.maxChainNodes + 1
        var queue: [Int] = []
        queue.reserveCapacity(1458)
        for a in nodes {
            for s in queue { dist[s] = 0 }
            queue.removeAll(keepingCapacity: true)
            let start = a * 2
            dist[start] = 1
            parent[start] = -1
            queue.append(start)
            var head = 0
            search: while head < queue.count {
                let s = queue[head]
                head += 1
                let n = s / 2
                let length = dist[s]
                if s % 2 == 1 && length >= 4 {
                    let elim = chainEliminations(a, n)
                    if !elim.isEmpty {
                        var path: [Int] = []
                        var t = s
                        while t >= 0 { path.append(t / 2); t = parent[t] }
                        best = (path.reversed(), elim)
                        bestLength = length
                        break search
                    }
                }
                guard length + 1 < bestLength else { continue }
                for m in (s % 2 == 0 ? strong[n] : weak[n]) {
                    let next = m * 2 + (s % 2 == 0 ? 1 : 0)
                    if dist[next] == 0 {
                        dist[next] = length + 1
                        parent[next] = s
                        queue.append(next)
                    }
                }
            }
        }
        guard let best else { return nil }

        let path = best.path
        let technique: Technique
        if path.allSatisfy({ $0 % 9 == path[0] % 9 }) {
            technique = path.count == 4 ? .turbotFish : .xChain
        } else if stride(from: 0, to: path.count - 1, by: 2).allSatisfy({ path[$0] / 9 == path[$0 + 1] / 9 })
                    && stride(from: 1, to: path.count - 1, by: 2).allSatisfy({ path[$0] % 9 == path[$0 + 1] % 9 }) {
            technique = .xyChain
        } else {
            technique = .aic
        }
        var focus: [Int] = []
        for n in path where !focus.contains(n / 9) { focus.append(n / 9) }
        return LogicStep(technique: technique, eliminations: best.elim, focus: focus,
                         chain: path.map { CandidateRef(cell: $0 / 9, digit: UInt8($0 % 9 + 1)) })
    }

    /// Ce que prouve « A ou Z est vrai ».
    func chainEliminations(_ a: Int, _ z: Int) -> [CandidateRef] {
        let ac = a / 9, ad = a % 9, zc = z / 9, zd = z % 9
        var out: [CandidateRef] = []
        if ac == zc {
            guard ad != zd else { return [] }
            for e in 0..<9 where e != ad && e != zd && candidates[ac] & (1 << UInt16(e)) != 0 {
                out.append(CandidateRef(cell: ac, digit: UInt8(e + 1)))
            }
        } else if ad == zd {
            let b: UInt16 = 1 << UInt16(ad)
            for i in 0..<81 where i != ac && i != zc && candidates[i] & b != 0 && Sudoku.sees(i, ac) && Sudoku.sees(i, zc) {
                out.append(CandidateRef(cell: i, digit: UInt8(ad + 1)))
            }
        } else if Sudoku.sees(ac, zc) {
            if candidates[zc] & (1 << UInt16(ad)) != 0 { out.append(CandidateRef(cell: zc, digit: UInt8(ad + 1))) }
            if candidates[ac] & (1 << UInt16(zd)) != 0 { out.append(CandidateRef(cell: ac, digit: UInt8(zd + 1))) }
        }
        return out
    }
}

/// Combinaisons de k éléments, dans l'ordre (déterministe).
func combinations<T>(_ items: [T], _ k: Int) -> [[T]] {
    guard k > 0, items.count >= k else { return k == 0 ? [[]] : [] }
    var result: [[T]] = []
    var idx = Array(0..<k)
    while true {
        result.append(idx.map { items[$0] })
        var i = k - 1
        while i >= 0 && idx[i] == items.count - k + i { i -= 1 }
        if i < 0 { break }
        idx[i] += 1
        for j in (i + 1)..<k { idx[j] = idx[j - 1] + 1 }
    }
    return result
}
