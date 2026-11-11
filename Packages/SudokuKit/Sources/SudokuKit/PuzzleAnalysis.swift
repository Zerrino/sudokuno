/// Analyse en direct d'une grille en cours de création.
public struct PuzzleAnalysis: Sendable, Equatable {
    public enum Status: Sendable, Equatable {
        /// Deux chiffres identiques dans une même ligne, colonne ou bloc.
        case conflict(cells: [Int])
        /// Aucune solution possible.
        case noSolution
        /// Plusieurs solutions : `suggestion` est un chiffre (d'une des solutions) qui en élimine au moins une.
        case multipleSolutions(suggestion: Placement)
        /// Grille valide : solution unique.
        case unique(level: Level, hardest: Technique?, solution: Grid)
        /// Recherche trop longue : grille trop ouverte pour conclure.
        case undetermined
    }

    public let clueCount: Int
    public let status: Status

    public var isPlayable: Bool {
        if case .unique = status { return true }
        return false
    }

    public static func analyze(_ grid: Grid) -> PuzzleAnalysis {
        let clues = grid.clueCount
        var conflicts = Set<Int>()
        for unit in Sudoku.units {
            for a in unit where grid[a] != 0 {
                for b in unit where b != a && grid[b] == grid[a] { conflicts.insert(a) }
            }
        }
        if !conflicts.isEmpty {
            return PuzzleAnalysis(clueCount: clues, status: .conflict(cells: conflicts.sorted()))
        }
        guard let sols = Solver.solutions(grid, limit: 2) else {
            return PuzzleAnalysis(clueCount: clues, status: .undetermined)
        }
        switch sols.count {
        case 0:
            return PuzzleAnalysis(clueCount: clues, status: .noSolution)
        case 1:
            var solver = LogicalSolver(grid)
            let result = solver.solve()
            let level: Level = result.solved ? (result.hardest?.level ?? .facile) : .diabolique
            return PuzzleAnalysis(clueCount: clues, status: .unique(level: level, hardest: result.solved ? result.hardest : nil, solution: sols[0]))
        default:
            let i = (0..<81).first { sols[0][$0] != sols[1][$0] }!
            return PuzzleAnalysis(clueCount: clues, status: .multipleSolutions(suggestion: Placement(cell: i, digit: sols[0][i])))
        }
    }

    /// Une grille créée peut-elle être jouée (solution unique) ?
    public static func isPlayable(_ code: PuzzleCode) -> Bool {
        if case .custom(let grid) = code { return analyze(grid).isPlayable }
        return true
    }
}

extension Placement {
    public init(_ cell: Int, _ digit: UInt8) { self.init(cell: cell, digit: digit) }
}
