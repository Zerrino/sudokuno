/// Preuve par l'absurde (« chaîne forcée ») : on suppose un candidat vrai, on en tire les conséquences
/// obligatoires, et on aboutit à une contradiction. Le candidat supposé est donc faux.
///
/// Ce n'est pas un essai au hasard : chaque conséquence est forcée (singleton nu ou caché), et la preuve
/// ne garde que les conséquences qui mènent à la contradiction. Réservé à l'explication (`Explainer`) :
/// le classement des grilles (`Grader`, `LogicalSolver.nextStep`) ne s'en sert jamais.
public struct ForcingProof: Sendable {
    public enum Reason: Sendable, Equatable {
        /// La case n'a plus qu'un candidat.
        case nakedSingle
        /// Le chiffre n'a plus qu'une place dans cette unité (index dans `Sudoku.units`).
        case hiddenSingle(unit: Int)
    }

    public enum Contradiction: Sendable, Equatable {
        /// Une case vide n'a plus aucun candidat.
        case emptyCell(Int)
        /// Un chiffre n'a plus aucune place dans une unité.
        case noPlace(unit: Int, digit: UInt8)
    }

    public enum Link: Sendable {
        /// Conséquence directe : ce chiffre est forcé dans cette case.
        case placement(Placement, Reason)
        /// Conséquence indirecte : ce candidat est exclu, car le supposer mène lui aussi à une contradiction.
        case exclusion(ForcingProof)
    }

    /// Le candidat supposé vrai, et donc prouvé faux.
    public let assumption: CandidateRef
    /// Les conséquences utiles, dans l'ordre.
    public let links: [Link]
    public let contradiction: Contradiction

    /// Nombre total de conséquences, preuves imbriquées comprises.
    public var size: Int {
        links.reduce(0) { n, link in
            if case .exclusion(let p) = link { return n + 1 + p.size }
            return n + 1
        }
    }

    /// Vrai si la preuve contient des suppositions imbriquées.
    public var isNested: Bool { links.contains { if case .exclusion = $0 { true } else { false } } }

    /// La grille telle qu'elle serait pendant la preuve, après les `count` premières conséquences (0 = juste après
    /// avoir posé l'hypothèse). Sert à dérouler le raisonnement à l'écran, comme le ferait un joueur sur le papier.
    /// `hypothetical` : les cases remplies « pour voir », dans l'ordre (l'hypothèse en premier).
    public func state(after count: Int, values: [UInt8], candidates: [UInt16])
        -> (values: [UInt8], candidates: [UInt16], hypothetical: [Int]) {
        var v = values, c = candidates
        var cells: [Int] = []
        func place(_ cell: Int, _ d: UInt8) {
            v[cell] = d
            c[cell] = 0
            for p in Sudoku.peers[cell] { c[p] &= ~Sudoku.bit(d) }
            cells.append(cell)
        }
        place(assumption.cell, assumption.digit)
        for link in links.prefix(max(0, count)) {
            switch link {
            case .placement(let p, _): place(p.cell, p.digit)
            case .exclusion(let inner): c[inner.assumption.cell] &= ~Sudoku.bit(inner.assumption.digit)
            }
        }
        return (v, c, cells)
    }

    /// Cases concernées par les conséquences directes, dans l'ordre.
    public var cells: [Int] {
        var out = [assumption.cell]
        for link in links {
            let c: Int = switch link {
            case .placement(let p, _): p.cell
            case .exclusion(let proof): proof.assumption.cell
            }
            if !out.contains(c) { out.append(c) }
        }
        return out
    }
}

/// Recherche de preuves par l'absurde sur un état de grille.
struct ForcingSearch {
    /// Une conséquence dans l'arbre de preuve en construction.
    private struct Node {
        enum Kind {
            case assume(CandidateRef)
            case place(Placement, ForcingProof.Reason)
            case exclude(ForcingProof)
        }
        let kind: Kind
        /// Conséquences antérieures dont celle-ci dépend.
        let premises: [Int]
    }

    /// État d'une hypothèse : grille, candidats, et pour chaque candidat retiré la conséquence qui l'a retiré.
    private struct Branch {
        var values: [UInt8]
        var candidates: [UInt16]
        /// `cause[case * 9 + chiffre - 1]` = nœud qui a retiré ce candidat, ou -1 (retiré avant l'hypothèse, ou encore présent).
        var cause: [Int32]

        mutating func place(_ cell: Int, _ d: UInt8, node: Int) {
            for e in Sudoku.digits(candidates[cell]) where e != d { cause[cell * 9 + Int(e) - 1] = Int32(node) }
            values[cell] = d
            candidates[cell] = 0
            let b = Sudoku.bit(d)
            for p in Sudoku.peers[cell] where candidates[p] & b != 0 {
                candidates[p] &= ~b
                cause[p * 9 + Int(d) - 1] = Int32(node)
            }
        }

        mutating func exclude(_ cell: Int, _ d: UInt8, node: Int) {
            candidates[cell] &= ~Sudoku.bit(d)
            cause[cell * 9 + Int(d) - 1] = Int32(node)
        }

        /// Nœuds qui ont retiré les autres candidats de la case.
        func causes(cell: Int, except d: UInt8 = 0) -> [Int] {
            var out: [Int] = []
            for e in 1...9 where UInt8(e) != d {
                let n = Int(cause[cell * 9 + e - 1])
                if n >= 0 && !out.contains(n) { out.append(n) }
            }
            return out
        }

        /// Nœuds qui ont retiré le chiffre des autres cases de l'unité.
        func causes(unit: Int, digit d: UInt8, except cell: Int = -1) -> [Int] {
            var out: [Int] = []
            for x in Sudoku.units[unit] where x != cell {
                let n = Int(cause[x * 9 + Int(d) - 1])
                if n >= 0 && !out.contains(n) { out.append(n) }
            }
            return out
        }
    }

    private var nodes: [Node] = []
    /// Garde-fou : nombre d'hypothèses imbriquées essayées pour une même preuve.
    private var budget = 0

    /// Prouve que `candidate` est faux dans l'état donné, si une contradiction se déduit.
    /// `nested` : autoriser des suppositions imbriquées quand les singletons ne suffisent plus.
    static func refute(_ candidate: CandidateRef, values: [UInt8], candidates: [UInt16], nested: Bool) -> ForcingProof? {
        var search = ForcingSearch()
        search.budget = nested ? 4000 : 0
        let root = Branch(values: values, candidates: candidates, cause: [Int32](repeating: -1, count: 729))
        return search.refute(candidate, in: root, depth: nested ? 1 : 0)
    }

    private mutating func refute(_ candidate: CandidateRef, in outer: Branch, depth: Int) -> ForcingProof? {
        let start = nodes.count
        var branch = outer
        nodes.append(Node(kind: .assume(candidate), premises: []))
        branch.place(candidate.cell, candidate.digit, node: start)
        guard let (contradiction, premises) = propagate(&branch, depth: depth) else {
            nodes.removeSubrange(start...)
            return nil
        }
        // On ne garde que les conséquences dont la contradiction dépend.
        var needed = Set(premises.filter { $0 >= start })
        var i = nodes.count - 1
        while i > start {
            if needed.contains(i) { for p in nodes[i].premises where p >= start { needed.insert(p) } }
            i -= 1
        }
        var links: [ForcingProof.Link] = []
        for n in (start + 1)..<nodes.count where needed.contains(n) {
            switch nodes[n].kind {
            case .place(let p, let r): links.append(.placement(p, r))
            case .exclude(let proof): links.append(.exclusion(proof))
            case .assume: break
            }
        }
        // Ce que cette preuve doit à l'hypothèse englobante (pour élaguer celle-ci à son tour).
        var outer = Set(premises.filter { $0 < start })
        for n in needed { for p in nodes[n].premises where p < start { outer.insert(p) } }
        lastOuterPremises = outer.sorted()
        nodes.removeSubrange(start...)
        return ForcingProof(assumption: candidate, links: links, contradiction: contradiction)
    }

    private var lastOuterPremises: [Int] = []

    /// Tire toutes les conséquences forcées. Retourne la contradiction et les nœuds dont elle dépend, ou `nil`.
    private mutating func propagate(_ b: inout Branch, depth: Int) -> (ForcingProof.Contradiction, [Int])? {
        while true {
            // Contradictions.
            for c in 0..<81 where b.values[c] == 0 && b.candidates[c] == 0 {
                return (.emptyCell(c), b.causes(cell: c))
            }
            var single: (cell: Int, digit: UInt8, reason: ForcingProof.Reason, premises: [Int])?
            for c in 0..<81 where b.values[c] == 0 && b.candidates[c].nonzeroBitCount == 1 {
                let d = UInt8(b.candidates[c].trailingZeroBitCount + 1)
                single = (c, d, .nakedSingle, b.causes(cell: c, except: d))
                break
            }
            for u in Array(18..<27) + Array(0..<18) {
                let unit = Sudoku.units[u]
                var placed: UInt16 = 0
                for i in unit where b.values[i] != 0 { placed |= Sudoku.bit(b.values[i]) }
                for d in UInt8(1)...9 where placed & Sudoku.bit(d) == 0 {
                    var spot = -1, n = 0
                    for i in unit where b.candidates[i] & Sudoku.bit(d) != 0 { spot = i; n += 1 }
                    if n == 0 { return (.noPlace(unit: u, digit: d), b.causes(unit: u, digit: d)) }
                    if n == 1 && single == nil && b.candidates[spot].nonzeroBitCount > 1 {
                        single = (spot, d, .hiddenSingle(unit: u), b.causes(unit: u, digit: d, except: spot))
                    }
                }
            }
            if let s = single {
                nodes.append(Node(kind: .place(Placement(cell: s.cell, digit: s.digit), s.reason), premises: s.premises))
                b.place(s.cell, s.digit, node: nodes.count - 1)
                continue
            }
            // Plus de singleton : supposition imbriquée (singletons seulement à l'intérieur).
            guard depth > 0 else { return nil }
            // Les cases les plus contraintes d'abord : ce sont les hypothèses les plus parlantes.
            let cells = (0..<81).filter { b.values[$0] == 0 }.sorted {
                (b.candidates[$0].nonzeroBitCount, $0) < (b.candidates[$1].nonzeroBitCount, $1)
            }
            var found = false
            search: for c in cells {
                for d in Sudoku.digits(b.candidates[c]) {
                    guard budget > 0 else { return nil }
                    budget -= 1
                    if let proof = refute(CandidateRef(cell: c, digit: d), in: b, depth: depth - 1) {
                        nodes.append(Node(kind: .exclude(proof), premises: lastOuterPremises))
                        b.exclude(c, d, node: nodes.count - 1)
                        found = true
                        break search
                    }
                }
            }
            if !found { return nil }
        }
    }
}

extension LogicalSolver {
    /// Une preuve imbriquée aussi courte est prise sans chercher mieux.
    static let shortNestedProof = 25
    /// Sinon, on compare ce nombre de preuves imbriquées et on garde la plus courte (compromis lisibilité / temps de calcul).
    static let nestedProofsCompared = 12

    /// Meilleure preuve par l'absurde disponible : la plus courte avec des singletons seuls, sinon la première
    /// qui demande des suppositions imbriquées. `falseCandidates` limite la recherche aux candidats réellement faux
    /// (un candidat vrai ne mène jamais à une contradiction : inutile de l'essayer).
    public func forcingStep(solution: Grid) -> LogicStep? {
        var targets: [CandidateRef] = []
        for c in 0..<81 where values[c] == 0 {
            for d in Sudoku.digits(candidates[c]) where d != solution[c] { targets.append(CandidateRef(cell: c, digit: d)) }
        }
        var best: ForcingProof?
        for t in targets {
            guard let p = ForcingSearch.refute(t, values: values, candidates: candidates, nested: false) else { continue }
            if best == nil || p.size < best!.size { best = p }
        }
        if best == nil {
            // Suppositions imbriquées : bien plus coûteuses. On essaie d'abord les cases les plus contraintes,
            // et on s'arrête à la première preuve assez courte (ou après quelques preuves, en gardant la plus courte).
            let ordered = targets.sorted {
                (candidates[$0.cell].nonzeroBitCount, $0.cell, $0.digit) < (candidates[$1.cell].nonzeroBitCount, $1.cell, $1.digit)
            }
            var found = 0
            for t in ordered {
                guard let p = ForcingSearch.refute(t, values: values, candidates: candidates, nested: true) else { continue }
                if best == nil || p.size < best!.size { best = p }
                found += 1
                if p.size <= Self.shortNestedProof || found >= Self.nestedProofsCompared { break }
            }
        }
        guard let proof = best else { return nil }
        var step = LogicStep(technique: proof.isNested ? .forcingNet : .forcingChain,
                             eliminations: [proof.assumption], focus: proof.cells, digits: [proof.assumption.digit])
        if case .noPlace(let u, _) = proof.contradiction { step.unit = u }
        step.proof = proof
        return step
    }
}
