/// Motifs d'experts pour les grilles extrêmes : SK-loop et chaînes groupées.
///
/// Réservés à l'explication (`Explainer`), quand `LogicalSolver.nextStep` est à court : ils ne sont jamais appelés
/// par le classement des grilles ni par le générateur. Essayés avant les preuves par l'absurde, plus parlants qu'elles.

/// Un lien d'une SK-loop : dans cette unité, la boucle prend forcément ces chiffres.
public struct LoopLink: Sendable, Hashable {
    /// Index dans `Sudoku.units` (une ligne ou une colonne entre deux blocs, ou un bloc).
    public let unit: Int
    public let digits: [UInt8]
}

extension LogicalSolver {

    // MARK: - SK-loop

    /// SK-loop (découverte par Steve Kurzhals sur « Easter Monster »).
    ///
    /// Quatre cases « pivot » forment un rectangle sur quatre blocs. Dans chaque bloc, les deux voisines du pivot
    /// sur sa ligne et les deux sur sa colonne forment deux groupes : huit groupes en tout, reliés en boucle,
    /// tour à tour par une ligne ou une colonne (entre deux blocs) et par un bloc (entre les deux groupes d'un bloc).
    /// Si les N cases vides de la boucle ne peuvent contenir que N chiffres répartis sur ces huit liens, chaque lien
    /// consomme tous ses chiffres : on les retire du reste de sa ligne, de sa colonne ou de son bloc.
    func skLoop() -> LogicStep? {
        for r1 in 0..<9 { for r2 in (r1 + 1)..<9 where r1 / 3 != r2 / 3 {
            for c1 in 0..<9 { for c2 in (c1 + 1)..<9 where c1 / 3 != c2 / 3 {
                if let step = skLoop(rows: (r1, r2), cols: (c1, c2)) { return step }
            } }
        } }
        return nil
    }

    private func skLoop(rows: (Int, Int), cols: (Int, Int)) -> LogicStep? {
        // Les quatre pivots, dans l'ordre de la boucle : haut-gauche, haut-droite, bas-droite, bas-gauche.
        let pivots = [(rows.0, cols.0), (rows.0, cols.1), (rows.1, cols.1), (rows.1, cols.0)]
        func rowMates(_ r: Int, _ c: Int) -> [Int] { (0..<3).map { c / 3 * 3 + $0 }.filter { $0 != c }.map { r * 9 + $0 } }
        func colMates(_ r: Int, _ c: Int) -> [Int] { (0..<3).map { r / 3 * 3 + $0 }.filter { $0 != r }.map { $0 * 9 + c } }
        // Huit groupes G0…G7 et huit liens : le lien i relie G(i) et G(i+1).
        // G0 = ligne du pivot 0, G1 = ligne du pivot 1 (lien 0 : la ligne du haut), G2 = colonne du pivot 1 (lien 1 : son bloc), etc.
        let p = pivots
        let all: [[Int]] = [
            rowMates(p[0].0, p[0].1), rowMates(p[1].0, p[1].1),
            colMates(p[1].0, p[1].1), colMates(p[2].0, p[2].1),
            rowMates(p[2].0, p[2].1), rowMates(p[3].0, p[3].1),
            colMates(p[3].0, p[3].1), colMates(p[0].0, p[0].1),
        ]
        func box(_ q: (Int, Int)) -> Int { 18 + Sudoku.box(q.0 * 9 + q.1) }
        let units = [rows.0, box(p[1]), 9 + cols.1, box(p[2]), rows.1, box(p[3]), 9 + cols.0, box(p[0])]
        let groups = all.map { $0.filter { values[$0] == 0 } }
        guard groups.allSatisfy({ !$0.isEmpty }) else { return nil }
        let masks = groups.map { $0.reduce(UInt16(0)) { $0 | candidates[$1] } }
        let cellCount = groups.reduce(0) { $0 + $1.count }

        // On essaie chaque choix pour le lien 7 (entre G7 et G0) ; les autres liens s'en déduisent de proche en proche.
        let free = Sudoku.digits(masks[0] & masks[7])
        for pick in 0..<(1 << free.count) {
            var last: UInt16 = 0
            for (k, d) in free.enumerated() where pick & (1 << k) != 0 { last |= Sudoku.bit(d) }
            var links = [UInt16](repeating: 0, count: 8)
            links[7] = last
            var previous = last
            var valid = true
            for i in 0..<7 {
                links[i] = masks[i] & ~previous
                // Un lien ne porte que des chiffres présents des deux côtés.
                if links[i] & ~masks[i + 1] != 0 { valid = false; break }
                previous = links[i]
            }
            guard valid, masks[7] & ~links[6] == last, links.allSatisfy({ $0 != 0 }) else { continue }
            guard links.reduce(0, { $0 + $1.nonzeroBitCount }) == cellCount else { continue }

            var elim: [CandidateRef] = []
            for i in 0..<8 {
                let inside = groups[i] + groups[(i + 1) % 8]
                for c in Sudoku.units[units[i]] where values[c] == 0 && !inside.contains(c) {
                    for d in Sudoku.digits(candidates[c] & links[i]) {
                        let ref = CandidateRef(cell: c, digit: d)
                        if !elim.contains(ref) { elim.append(ref) }
                    }
                }
            }
            guard !elim.isEmpty else { continue }
            var step = LogicStep(technique: .skLoop, eliminations: elim, focus: groups.flatMap { $0 })
            step.loop = (0..<8).map { LoopLink(unit: units[$0], digits: Sudoku.digits(links[$0])) }
            step.pivots = pivots.map { $0.0 * 9 + $0.1 }
            return step
        }
        return nil
    }

    // MARK: - Chaînes groupées

    /// Un maillon d'une chaîne groupée : un chiffre dans une case, ou dans un groupe de 2 ou 3 cases
    /// d'un même bloc alignées sur une même ligne ou colonne (« le chiffre est quelque part dans ce groupe »).
    public struct GroupNode: Sendable, Hashable {
        public let cells: [Int]
        public let digit: UInt8
    }

    /// Chaîne d'inférences alternées dont les maillons peuvent être des groupes de cases.
    /// Même principe que `chain()` : la chaîne A = … = Z prouve « A ou Z est vrai », donc tout candidat
    /// incompatible avec les deux tombe. Ne garde que la chaîne la plus courte (12 maillons au plus).
    func groupedChain() -> LogicStep? {
        // Maillons : chaque candidat, puis chaque groupe (intersection bloc-ligne avec au moins 2 places).
        var nodes: [GroupNode] = []
        var single = [Int](repeating: -1, count: 729)
        for c in 0..<81 where values[c] == 0 {
            for d in Sudoku.digits(candidates[c]) {
                single[c * 9 + Int(d) - 1] = nodes.count
                nodes.append(GroupNode(cells: [c], digit: d))
            }
        }
        let singleCount = nodes.count
        for d in UInt8(1)...9 {
            for b in 0..<9 {
                for line in 0..<18 {
                    let cells = Sudoku.units[line].filter { Sudoku.box($0) == b && candidates[$0] & Sudoku.bit(d) != 0 }
                    if cells.count >= 2 { nodes.append(GroupNode(cells: cells, digit: d)) }
                }
            }
        }
        guard nodes.count > singleCount else { return nil }

        // Maillons présents dans chaque unité, par chiffre.
        var inUnit = [[Int]](repeating: [], count: 27 * 9)
        for (n, node) in nodes.enumerated() {
            for u in 0..<27 where node.cells.allSatisfy({ Sudoku.unitsOfCell[$0].contains(u) }) {
                inUnit[u * 9 + Int(node.digit) - 1].append(n)
            }
        }
        var strong = [[Int]](repeating: [], count: nodes.count)
        var weak = [[Int]](repeating: [], count: nodes.count)
        for u in 0..<27 {
            for d in 0..<9 {
                let list = inUnit[u * 9 + d]
                let places = Sudoku.units[u].filter { candidates[$0] & (1 << UInt16(d)) != 0 }
                for (i, a) in list.enumerated() {
                    for b in list[(i + 1)...] where !nodes[a].cells.contains(where: nodes[b].cells.contains) {
                        if !weak[a].contains(b) { weak[a].append(b); weak[b].append(a) }
                        // Lien fort : à eux deux, ils couvrent toutes les places du chiffre dans l'unité.
                        if nodes[a].cells.count + nodes[b].cells.count == places.count, !strong[a].contains(b) {
                            strong[a].append(b); strong[b].append(a)
                        }
                    }
                }
            }
        }
        for c in 0..<81 where values[c] == 0 {
            let ds = Sudoku.digits(candidates[c])
            for d in ds {
                let n = single[c * 9 + Int(d) - 1]
                for e in ds where e != d {
                    let m = single[c * 9 + Int(e) - 1]
                    weak[n].append(m)
                    if ds.count == 2 { strong[n].append(m) }
                }
            }
        }

        let maxNodes = Self.maxChainNodes
        var dist = [Int](repeating: 0, count: nodes.count * 2)
        var parent = [Int](repeating: -1, count: nodes.count * 2)
        var best: (path: [Int], elim: [CandidateRef])?
        var bestLength = maxNodes + 1
        var queue: [Int] = []
        for a in nodes.indices {
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
                    let elim = groupedEliminations(nodes[a], nodes[n])
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
        var focus: [Int] = []
        for n in best.path { for c in nodes[n].cells where !focus.contains(c) { focus.append(c) } }
        var step = LogicStep(technique: .groupedChain, eliminations: best.elim, focus: focus)
        step.groupChain = best.path.map { nodes[$0] }
        return step
    }

    /// Ce que prouve « A ou Z est vrai » quand A et Z peuvent être des groupes.
    private func groupedEliminations(_ a: GroupNode, _ z: GroupNode) -> [CandidateRef] {
        if a.digit == z.digit {
            guard !a.cells.contains(where: z.cells.contains) else { return [] }
            let bit = Sudoku.bit(a.digit)
            return (0..<81)
                .filter { c in
                    candidates[c] & bit != 0 && !a.cells.contains(c) && !z.cells.contains(c)
                        && a.cells.allSatisfy { Sudoku.sees(c, $0) } && z.cells.allSatisfy { Sudoku.sees(c, $0) }
                }
                .map { CandidateRef(cell: $0, digit: a.digit) }
        }
        // Chiffres différents : seulement entre deux cases simples.
        guard a.cells.count == 1, z.cells.count == 1 else { return [] }
        let ac = a.cells[0], zc = z.cells[0]
        var out: [CandidateRef] = []
        if ac == zc {
            for e in Sudoku.digits(candidates[ac]) where e != a.digit && e != z.digit { out.append(CandidateRef(cell: ac, digit: e)) }
        } else if Sudoku.sees(ac, zc) {
            if candidates[zc] & Sudoku.bit(a.digit) != 0 { out.append(CandidateRef(cell: zc, digit: a.digit)) }
            if candidates[ac] & Sudoku.bit(z.digit) != 0 { out.append(CandidateRef(cell: ac, digit: z.digit)) }
        }
        return out
    }

    /// Les motifs d'experts, du plus spectaculaire au plus général.
    public func expertStep() -> LogicStep? { skLoop() ?? groupedChain() }
}
