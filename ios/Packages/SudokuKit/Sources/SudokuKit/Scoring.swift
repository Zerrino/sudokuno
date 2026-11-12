/// Score d'une partie terminée : niveau de la grille, temps, et surtout qualité des coups.
/// Un chiffre juste ne rapporte tous ses points que s'il était déductible au moment où il a été posé.

/// Un changement de chiffre pendant la partie (0 = case effacée).
public struct ScoredMove: Sendable, Hashable {
    public let cell: Int
    public let digit: UInt8
    /// Coup joué par un indice : il ne rapporte rien.
    public let hint: Bool

    public init(cell: Int, digit: UInt8, hint: Bool) {
        self.cell = cell
        self.digit = digit
        self.hint = hint
    }
}

public struct GameScore: Sendable, Hashable, Codable {
    public let total: Int
    /// Chiffres justes que la logique permettait de trouver à ce moment-là.
    public let deduced: Int
    /// Chiffres justes mais posés sans pouvoir les connaître : des coups de chance.
    public let guessed: Int
    /// Chiffres donnés par un indice.
    public let hinted: Int
    /// Bonus ou malus de temps, en millièmes (1000 = temps de référence, 1500 = très rapide, 500 = très lent).
    public let timePermille: Int
}

public enum Scoring {
    /// Points d'une grille parfaite jouée dans le temps de référence.
    public static func basePoints(_ level: Level) -> Int {
        switch level {
        case .facile: 1000
        case .moyen: 2000
        case .difficile: 3500
        case .expert: 5000
        case .diabolique: 8000
        case .legende: 12000
        }
    }

    /// Temps de référence, en secondes : plus vite rapporte jusqu'à +50 %, plus lent retire jusqu'à 50 %.
    public static func referenceSeconds(_ level: Level) -> Int {
        switch level {
        case .facile: 5 * 60
        case .moyen: 8 * 60
        case .difficile: 12 * 60
        case .expert: 20 * 60
        case .diabolique: 35 * 60
        case .legende: 60 * 60
        }
    }

    /// Un coup de chance vaut un cinquième d'un chiffre déduit.
    public static let guessDivisor = 5
    /// Chaque erreur retire un vingtième des points de base.
    public static let mistakeDivisor = 20

    /// Le chiffre de cette case peut-il être connu dans l'état de `solver` ?
    /// Oui si, après toutes les éliminations logiques possibles (sans poser d'autre chiffre), la case n'a plus qu'un
    /// candidat ou si le chiffre n'a plus qu'une place dans sa ligne, sa colonne ou son bloc.
    /// Les éliminations trouvées restent acquises dans `solver`, comme les notes d'un joueur.
    static func isDeducible(_ solver: inout LogicalSolver, cell: Int, digit: UInt8) -> Bool {
        let bit = Sudoku.bit(digit)
        while true {
            if solver.candidates[cell] == bit { return true }
            for u in Sudoku.unitsOfCell[cell] where !Sudoku.units[u].contains(where: { $0 != cell && solver.candidates[$0] & bit != 0 }) {
                return true
            }
            guard let step = solver.eliminationStep() else { return false }
            solver.apply(step)
        }
    }

    /// Score de la partie. `moves` : tous les changements de chiffres, dans l'ordre.
    ///
    /// On suit la partie avec un solveur qui accumule ce que la logique permet de savoir (chiffres justes posés,
    /// candidats éliminés). Chaque chiffre juste est jugé la première fois qu'il est posé : déductible à ce moment-là,
    /// ou coup de chance. L'effacer puis le reposer ne change pas ce jugement.
    public static func score(givens: Grid, solution: Grid, level: Level, moves: [ScoredMove], seconds: Int, mistakes: Int) -> GameScore {
        enum Quality { case deduced, guessed, hinted }
        var solver = LogicalSolver(givens, chains: level >= .diabolique)
        var state = givens.cells
        var quality = [Quality?](repeating: nil, count: 81)
        for m in moves where givens[m.cell] == 0 {
            state[m.cell] = m.digit
            guard m.digit == solution[m.cell], quality[m.cell] == nil else { continue }
            if m.hint {
                quality[m.cell] = .hinted
            } else if level == .legende {
                // Légende : nos techniques classiques ne suffisent pas, on ne peut pas juger ce qui était déductible.
                quality[m.cell] = .deduced
            } else {
                quality[m.cell] = isDeducible(&solver, cell: m.cell, digit: m.digit) ? .deduced : .guessed
            }
            solver.place(m.cell, m.digit)
        }
        var deduced = 0, guessed = 0, hinted = 0
        for c in 0..<81 where state[c] == solution[c] {
            switch quality[c] {
            case .deduced: deduced += 1
            case .guessed: guessed += 1
            case .hinted: hinted += 1
            case nil: break
            }
        }
        let base = basePoints(level)
        let empty = max(1, 81 - givens.clueCount)
        let time = min(1500, max(500, 1500 - 500 * max(0, seconds) / referenceSeconds(level)))
        let earned = base * (guessDivisor * deduced + guessed) * time / (guessDivisor * empty * 1000)
        let total = max(0, earned - mistakes * base / mistakeDivisor)
        return GameScore(total: total, deduced: deduced, guessed: guessed, hinted: hinted, timePermille: time)
    }
}

extension LogicalSolver {
    /// Le prochain coup qui élimine des candidats sans poser de chiffre (mêmes techniques et même ordre que `nextStep`,
    /// singletons exclus). Sert à juger si un chiffre était déductible (`Scoring`).
    func eliminationStep() -> LogicStep? {
        if hasContradiction { return nil }
        let finders: [(LogicalSolver) -> LogicStep?] = [
            { $0.pointing() }, { $0.boxLineReduction() },
            { $0.nakedSubset(size: 2) }, { $0.hiddenSubset(size: 2) },
            { $0.nakedSubset(size: 3) }, { $0.hiddenSubset(size: 3) },
            { $0.fish(size: 2) }, { $0.xyWing() }, { $0.fish(size: 3) }, { $0.xyzWing() },
        ]
        for find in finders {
            if let step = find(self) { return step }
        }
        return chains ? chain() : nil
    }
}
