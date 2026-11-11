/// Solveur rapide : backtracking avec masques de bits et heuristique MRV
/// (on choisit toujours la case vide qui a le moins de candidats).
public enum Solver {

    /// Nombre de solutions, en s'arrêtant à `limit`. `limit: 2` suffit pour vérifier l'unicité.
    public static func countSolutions(_ grid: Grid, limit: Int = 2) -> Int {
        guard var state = State(grid) else { return 0 }
        var count = 0
        var first: [UInt8]?
        var rng: SeededRandom?
        search(&state, count: &count, limit: limit, first: &first, rng: &rng)
        return count
    }

    public static func hasUniqueSolution(_ grid: Grid) -> Bool {
        countSolutions(grid, limit: 2) == 1
    }

    /// Jusqu'à `limit` solutions. Retourne nil si la recherche dépasse `maxNodes` (grille trop ouverte ou piège).
    public static func solutions(_ grid: Grid, limit: Int = 2, maxNodes: Int = 2_000_000) -> [Grid]? {
        guard var state = State(grid) else { return [] }
        var found: [Grid] = []
        var nodes = 0
        let complete = collect(&state, into: &found, limit: limit, nodes: &nodes, maxNodes: maxNodes)
        return complete ? found : nil
    }

    /// Recherche séparée de `search` pour ne jamais toucher au chemin du générateur v1.
    private static func collect(_ s: inout State, into found: inout [Grid], limit: Int, nodes: inout Int, maxNodes: Int) -> Bool {
        nodes += 1
        if nodes > maxNodes { return false }
        var best = -1
        var bestMask: UInt16 = 0
        var bestCount = 10
        for i in 0..<81 where s.cells[i] == 0 {
            let m = s.candidates(i)
            let n = m.nonzeroBitCount
            if n < bestCount {
                best = i; bestMask = m; bestCount = n
                if n <= 1 { break }
            }
        }
        if best == -1 {
            found.append(Grid(cells: s.cells))
            return true
        }
        if bestCount == 0 { return true }
        for d in Sudoku.digits(bestMask) {
            s.set(best, d)
            let ok = collect(&s, into: &found, limit: limit, nodes: &nodes, maxNodes: maxNodes)
            s.clear(best, d)
            if !ok { return false }
            if found.count >= limit { return true }
        }
        return true
    }

    /// Une solution (la première trouvée), ou nil si la grille n'en a pas.
    public static func solve(_ grid: Grid) -> Grid? {
        guard var state = State(grid) else { return nil }
        var count = 0
        var first: [UInt8]?
        var rng: SeededRandom?
        search(&state, count: &count, limit: 1, first: &first, rng: &rng)
        return first.map(Grid.init(cells:))
    }

    /// Une grille complète aléatoire (déterministe pour un générateur donné).
    public static func randomSolution(rng: inout SeededRandom) -> Grid {
        var state = State(Grid())!
        var count = 0
        var first: [UInt8]?
        var optionalRNG: SeededRandom? = rng
        search(&state, count: &count, limit: 1, first: &first, rng: &optionalRNG)
        rng = optionalRNG!
        return Grid(cells: first!)
    }

    // MARK: - Implémentation

    struct State {
        var cells: [UInt8]
        var rows = [UInt16](repeating: 0, count: 9)
        var cols = [UInt16](repeating: 0, count: 9)
        var boxes = [UInt16](repeating: 0, count: 9)

        init?(_ grid: Grid) {
            cells = grid.cells
            for i in 0..<81 where cells[i] != 0 {
                let b = Sudoku.bit(cells[i])
                let r = Sudoku.row(i), c = Sudoku.col(i), x = Sudoku.box(i)
                if (rows[r] | cols[c] | boxes[x]) & b != 0 { return nil }
                rows[r] |= b; cols[c] |= b; boxes[x] |= b
            }
        }

        @inline(__always) func candidates(_ i: Int) -> UInt16 {
            ~(rows[Sudoku.row(i)] | cols[Sudoku.col(i)] | boxes[Sudoku.box(i)]) & Sudoku.allDigits
        }

        @inline(__always) mutating func set(_ i: Int, _ d: UInt8) {
            let b = Sudoku.bit(d)
            cells[i] = d
            rows[Sudoku.row(i)] |= b; cols[Sudoku.col(i)] |= b; boxes[Sudoku.box(i)] |= b
        }

        @inline(__always) mutating func clear(_ i: Int, _ d: UInt8) {
            let b = ~Sudoku.bit(d)
            cells[i] = 0
            rows[Sudoku.row(i)] &= b; cols[Sudoku.col(i)] &= b; boxes[Sudoku.box(i)] &= b
        }
    }

    private static func search(
        _ s: inout State, count: inout Int, limit: Int, first: inout [UInt8]?, rng: inout SeededRandom?
    ) {
        // MRV : la case vide avec le moins de candidats.
        var best = -1
        var bestMask: UInt16 = 0
        var bestCount = 10
        for i in 0..<81 where s.cells[i] == 0 {
            let m = s.candidates(i)
            let n = m.nonzeroBitCount
            if n < bestCount {
                best = i; bestMask = m; bestCount = n
                if n <= 1 { break }
            }
        }
        if best == -1 {
            count += 1
            if first == nil { first = s.cells }
            return
        }
        if bestCount == 0 { return }

        var digits = Sudoku.digits(bestMask)
        if rng != nil { rng!.shuffle(&digits) }
        for d in digits {
            s.set(best, d)
            search(&s, count: &count, limit: limit, first: &first, rng: &rng)
            s.clear(best, d)
            if count >= limit { return }
        }
    }
}
