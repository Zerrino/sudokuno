public enum Grader {
    /// Niveau d'une grille à solution unique : la technique la plus difficile nécessaire.
    /// Si nos techniques ne suffisent pas, la grille est Diabolique.
    public static func grade(_ puzzle: Grid) -> Level {
        var solver = LogicalSolver(puzzle)
        let result = solver.solve()
        guard result.solved else { return .diabolique }
        return result.hardest?.level ?? .facile
    }
}

public enum Generator {

    /// Une grille à solution unique, presque minimale, avec une symétrie centrale.
    public static func minimalPuzzle(rng: inout SeededRandom) -> (puzzle: Grid, solution: Grid) {
        let solution = Solver.randomSolution(rng: &rng)
        var puzzle = solution
        var order = Array(0...40) // paires (i, 80 - i) ; 40 = case centrale
        rng.shuffle(&order)
        for i in order {
            let j = 80 - i
            let a = puzzle[i], b = puzzle[j]
            puzzle[i] = 0
            puzzle[j] = 0
            if !Solver.hasUniqueSolution(puzzle) {
                puzzle[i] = a
                puzzle[j] = b
            }
        }
        return (puzzle, solution)
    }

    /// Génère une grille du niveau demandé. Déterministe : même générateur → même grille.
    ///
    /// On part d'une grille minimale. Si elle est trop difficile, on lui rend des chiffres de la solution
    /// jusqu'à atteindre le niveau. Puis on ajoute des chiffres « de confort » tant que le niveau ne change pas.
    public static func generate(level: Level, rng: inout SeededRandom, maxAttempts: Int = .max) -> (puzzle: Grid, solution: Grid)? {
        var attempt = 0
        while attempt < maxAttempts {
            attempt += 1
            let (minimal, solution) = minimalPuzzle(rng: &rng)
            var puzzle = minimal
            var grade = Grader.grade(puzzle)
            if grade < level { continue }

            var empties = (0..<81).filter { puzzle[$0] == 0 }
            rng.shuffle(&empties)
            var k = 0
            while grade > level && k < empties.count {
                let i = empties[k]
                k += 1
                puzzle[i] = solution[i]
                grade = Grader.grade(puzzle)
            }
            guard grade == level else { continue }

            while puzzle.clueCount < level.targetClues && k < empties.count {
                let i = empties[k]
                k += 1
                puzzle[i] = solution[i]
                if Grader.grade(puzzle) != level { puzzle[i] = 0 }
            }
            return (puzzle, solution)
        }
        return nil
    }
}

/// Transformation qui conserve la validité, l'unicité et la difficulté d'une grille :
/// renumérotation des chiffres, permutation des bandes / piles et des lignes / colonnes à l'intérieur,
/// transposition éventuelle.
public struct GridTransform: Sendable {
    let digitMap: [UInt8] // index 0 inutilisé, digitMap[d] = nouveau chiffre
    let rowOrder: [Int]
    let colOrder: [Int]
    let transpose: Bool

    public init(rng: inout SeededRandom) {
        var digits: [UInt8] = Array(1...9)
        rng.shuffle(&digits)
        digitMap = [0] + digits

        func lineOrder() -> [Int] {
            var groups = [0, 1, 2]
            rng.shuffle(&groups)
            var order: [Int] = []
            for g in groups {
                var inner = [0, 1, 2]
                rng.shuffle(&inner)
                order += inner.map { g * 3 + $0 }
            }
            return order
        }
        rowOrder = lineOrder()
        colOrder = lineOrder()
        transpose = rng.nextBool()
    }

    public func apply(_ grid: Grid) -> Grid {
        var out = Grid()
        for r in 0..<9 {
            for c in 0..<9 {
                let v = grid[rowOrder[r] * 9 + colOrder[c]]
                let mapped = v == 0 ? 0 : digitMap[Int(v)]
                if transpose { out[c * 9 + r] = mapped } else { out[r * 9 + c] = mapped }
            }
        }
        return out
    }
}
