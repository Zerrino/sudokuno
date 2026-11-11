public enum Grader {
    /// Niveau d'une grille à solution unique : la technique la plus difficile nécessaire.
    /// Si même les chaînes ne suffisent pas, la grille est une Légende.
    public static func grade(_ puzzle: Grid) -> Level { analyze(puzzle).level }

    public static func analyze(_ puzzle: Grid, chains: Bool = true) -> (level: Level, hardest: Technique?) {
        let r = details(puzzle, chains: chains)
        return (r.level, r.hardest)
    }

    /// Comme `analyze`, avec le nombre de coups qui demandent une chaîne (Turbot compris).
    public static func details(_ puzzle: Grid, chains: Bool = true) -> (level: Level, hardest: Technique?, chainSteps: Int) {
        var solver = LogicalSolver(puzzle, chains: chains)
        var hardest: Technique?
        var chainSteps = 0
        while !solver.isSolved, let step = solver.nextStep() {
            hardest = max(hardest ?? step.technique, step.technique)
            if step.technique >= .turbotFish { chainSteps += 1 }
            solver.apply(step)
        }
        guard solver.isSolved else { return (chains ? .legende : .diabolique, hardest, chainSteps) }
        return (hardest?.level ?? .facile, hardest, chainSteps)
    }

    /// Une grille Diabolique (v2) doit demander au moins ce nombre de coups de chaîne, dont une vraie chaîne.
    public static let diaboliqueMinChainSteps = 3
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
    /// Diabolique : la grille doit exiger une vraie chaîne (X-Chain, XY-Chain ou AIC), pas seulement un Turbot,
    /// et au moins `Grader.diaboliqueMinChainSteps` coups de chaîne.
    /// Les grilles Légende sont choisies dans `Legends`, jamais générées.
    ///
    /// Jusqu'à Expert, le classement se fait sans les chaînes : « au-delà d'Expert » suffit, c'est plus rapide
    /// et c'est exactement le comportement du générateur v1 (mêmes grilles pour les mêmes codes).
    /// `version` 1 : Diabolique d'origine (« au-delà d'Expert », sans chaînes), pour les anciens codes `SKN1-X-…`.
    /// Les autres niveaux sont identiques dans les deux versions.
    public static func generate(level: Level, rng: inout SeededRandom, version: Int = 2, maxAttempts: Int = .max) -> (puzzle: Grid, solution: Grid)? {
        precondition(level != .legende, "Les grilles Légende ne sont pas générées")
        let chains = level == .diabolique && version >= 2
        var attempt = 0
        while attempt < maxAttempts {
            attempt += 1
            let (minimal, solution) = minimalPuzzle(rng: &rng)
            var puzzle = minimal
            var (grade, hardest, chainSteps) = Grader.details(puzzle, chains: chains)
            if grade < level { continue }

            var empties = (0..<81).filter { puzzle[$0] == 0 }
            rng.shuffle(&empties)
            var k = 0
            while grade > level && k < empties.count {
                let i = empties[k]
                k += 1
                puzzle[i] = solution[i]
                (grade, hardest, chainSteps) = Grader.details(puzzle, chains: chains)
            }
            guard grade == level else { continue }
            if chains && (!(hardest?.isLongChain ?? false) || chainSteps < Grader.diaboliqueMinChainSteps) { continue }

            while puzzle.clueCount < level.targetClues && k < empties.count {
                let i = empties[k]
                k += 1
                puzzle[i] = solution[i]
                if Grader.analyze(puzzle, chains: chains).level != level { puzzle[i] = 0 }
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
