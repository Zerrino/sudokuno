/// Une étape d'une résolution expliquée : l'état de la grille AVANT le coup, puis le coup.
public struct ExplainedStep: Sendable {
    /// Chiffres posés avant ce coup (0 = case vide).
    public let values: [UInt8]
    /// Candidats restants avant ce coup (masque par case).
    public let candidates: [UInt16]
    /// Le coup logique. `nil` : aucune de nos techniques ne s'applique, on pose un chiffre de la solution (`reveal`).
    public let step: LogicStep?
    public let reveal: Placement?

    public var technique: Technique? { step?.technique }
    public var placements: [Placement] { step?.placements ?? reveal.map { [$0] } ?? [] }
    public var eliminations: [CandidateRef] { step?.eliminations ?? [] }
    /// Un coup qui demande plus qu'un singleton : c'est là que la grille se joue.
    public var isKey: Bool { step.map { $0.technique > .hiddenSingle } ?? true }
}

/// Résolution complète, coup par coup, telle qu'un joueur la ferait : la technique la plus simple d'abord.
public struct Explanation: Sendable {
    public let steps: [ExplainedStep]
    /// La grille résolue (état après le dernier coup).
    public let solution: Grid
    /// Techniques utilisées, de la plus simple à la plus difficile, avec leur nombre de coups.
    public let techniques: [(technique: Technique, count: Int)]
    /// Nombre de cases qu'il a fallu révéler faute de technique connue (0 pour toute grille générée).
    public let reveals: Int
}

public enum Explainer {
    /// Explique la résolution de `grid`. `solution` sert seulement quand nos techniques ne suffisent plus.
    /// `nil` si la grille de départ contredit la solution.
    ///
    /// `onStep` reçoit chaque étape dès qu'elle est trouvée (les grilles Légende demandent plusieurs secondes de calcul :
    /// l'écran peut ainsi montrer le début sans attendre la fin). S'il retourne `false`, le calcul s'arrête et on retourne `nil`.
    public static func explain(_ grid: Grid, solution: Grid, onStep: ((ExplainedStep) -> Bool)? = nil) -> Explanation? {
        guard (0..<81).allSatisfy({ grid[$0] == 0 || grid[$0] == solution[$0] }) else { return nil }
        var solver = LogicalSolver(grid)
        var steps: [ExplainedStep] = []
        var counts = [Int](repeating: 0, count: Technique.allCases.count)
        var reveals = 0
        while !solver.isSolved {
            if let last = steps.last, let onStep, !onStep(last) { return nil }
            if let step = solver.nextStep() {
                steps.append(ExplainedStep(values: solver.values, candidates: solver.candidates, step: step, reveal: nil))
                counts[step.technique.rawValue] += 1
                solver.apply(step)
            } else if let step = solver.forcingStep(solution: solution) {
                // Les techniques classiques sont à court : preuve par l'absurde.
                steps.append(ExplainedStep(values: solver.values, candidates: solver.candidates, step: step, reveal: nil))
                counts[step.technique.rawValue] += 1
                solver.apply(step)
            } else {
                let cell = solver.mostConstrainedCell()
                let reveal = Placement(cell: cell, digit: solution[cell])
                steps.append(ExplainedStep(values: solver.values, candidates: solver.candidates, step: nil, reveal: reveal))
                reveals += 1
                solver.place(cell, solution[cell])
            }
        }
        if let last = steps.last, let onStep, !onStep(last) { return nil }
        let used = Technique.allCases.filter { counts[$0.rawValue] > 0 }.map { (technique: $0, count: counts[$0.rawValue]) }
        return Explanation(steps: steps, solution: solution, techniques: used, reveals: reveals)
    }
}

extension LogicalSolver {
    /// Première case vide ayant le moins de candidats : celle qu'on révèle quand la logique est à court.
    public func mostConstrainedCell() -> Int {
        (0..<81).filter { values[$0] == 0 }.min { candidates[$0].nonzeroBitCount < candidates[$1].nonzeroBitCount }!
    }
}
