/// Score d'une partie, chiffre par chiffre (version 2).
///
/// Chaque chiffre juste est jugé au moment où il est posé. S'il pouvait être connu à cet instant, il rapporte les points
/// de la technique la plus simple qui permettait alors d'avancer dans la grille (le « goulot » : remplir d'abord les
/// cases difficiles ne rapporte pas plus), plus ou moins selon le temps mis à le trouver (depuis le chiffre juste
/// précédent). Un chiffre qu'aucune logique ne permettait encore de connaître est un coup de chance.
/// Copie exacte : `Scoring.kt` (Android). Les deux doivent donner les mêmes points.

/// Un changement de chiffre pendant la partie (0 = case effacée).
public struct ScoredMove: Sendable, Hashable {
    public let cell: Int
    public let digit: UInt8
    /// Coup joué par un indice : il ne rapporte rien.
    public let hint: Bool
    /// Secondes écoulées depuis le début de la partie.
    public let time: Int

    public init(cell: Int, digit: UInt8, hint: Bool, time: Int = 0) {
        self.cell = cell
        self.digit = digit
        self.hint = hint
        self.time = time
    }
}

/// Le jugement d'un coup, pour le score et pour le commentaire du replay.
public enum MoveJudgement: Sendable, Hashable {
    /// Chiffre juste, et la logique permettait de le trouver : `technique` est la plus difficile qu'il fallait.
    case deduced(Technique)
    /// Chiffre juste, mais rien ne permettait encore de le connaître : un coup de chance.
    case guessed
    /// Chiffre juste trouvé après un essai faux dans la même case : compté comme un coup de chance.
    case corrected
    /// Chiffre juste, donné par un indice.
    case hinted
    /// Chiffre faux.
    case mistake
    /// Case effacée.
    case erased
    /// Chiffre juste déjà jugé : effacé puis reposé.
    case repeated
}

public struct MoveVerdict: Sendable, Hashable {
    public let judgement: MoveJudgement
    /// Pour un chiffre déduit : la technique la plus simple qui permettait d'avancer dans la grille à ce moment-là
    /// (n'importe où). C'est elle qui donne les points : chercher un chiffre plus difficile que nécessaire ne rapporte pas plus.
    public var easiest: Technique? = nil
    /// Points rapportés par ce coup.
    public let points: Int
    /// Bonus de rapidité, en millièmes (1000 = temps de référence de la technique ; 500 à 1500). 0 si sans objet.
    public let speedPermille: Int
}

public struct GameScore: Sendable, Hashable, Codable {
    public let total: Int
    /// Chiffres justes que la logique permettait de trouver à ce moment-là.
    public let deduced: Int
    /// Chiffres justes posés sans pouvoir les connaître : des coups de chance.
    public let guessed: Int
    /// Chiffres donnés par un indice.
    public let hinted: Int
    /// Rapidité moyenne des chiffres déduits, en millièmes (1000 = temps de référence, 1500 = très rapide, 500 = très lent).
    public let timePermille: Int
    /// Version du calcul (absent = première version, à recalculer).
    public let version: Int?
    /// Technique la plus difficile utilisée par le joueur (`rawValue` de `Technique`).
    public let hardest: Int?

    public init(total: Int, deduced: Int, guessed: Int, hinted: Int, timePermille: Int, version: Int?, hardest: Int?) {
        self.total = total
        self.deduced = deduced
        self.guessed = guessed
        self.hinted = hinted
        self.timePermille = timePermille
        self.version = version
        self.hardest = hardest
    }

    public var hardestTechnique: Technique? { hardest.flatMap(Technique.init(rawValue:)) }
    public var isCurrent: Bool { version == Scoring.version }
}

public enum Scoring {
    public static let version = 2

    /// Points d'un chiffre trouvé avec cette technique, au temps de référence.
    public static func points(_ t: Technique) -> Int {
        switch t {
        case .nakedSingle: 10
        case .hiddenSingle: 10
        case .pointing: 30
        case .boxLineReduction: 30
        case .nakedPair: 40
        case .hiddenPair: 50
        case .nakedTriple: 60
        case .hiddenTriple: 70
        case .xWing: 80
        case .xyWing: 100
        case .swordfish: 120
        case .xyzWing: 120
        case .turbotFish: 150
        case .xChain: 170
        case .xyChain: 170
        case .aic: 200
        case .groupedChain: 230
        case .skLoop: 260
        case .forcingChain: 280
        case .forcingNet: 320
        }
    }

    /// Temps de référence pour trouver un chiffre avec cette technique, en secondes. Instantané : ×1,5 ; deux fois
    /// plus long : ×0,5.
    public static func referenceSeconds(_ t: Technique) -> Int {
        switch t.level {
        case .facile: 15
        case .moyen: 30
        case .difficile: 45
        case .expert: 60
        case .diabolique: 90
        case .legende: 150
        }
    }

    /// Un coup de chance rapporte toujours ça, quel que soit le temps.
    public static let guessPoints = 2
    /// Chaque erreur retire ça.
    public static let mistakePenalty = 25

    static func speed(seconds: Int, technique: Technique) -> Int {
        min(1500, max(500, 1500 - 500 * max(0, seconds) / referenceSeconds(technique)))
    }

    /// Score de la partie. `moves` : tous les changements de chiffres, dans l'ordre.
    public static func score(givens: Grid, solution: Grid, level: Level, moves: [ScoredMove], mistakes: Int) -> GameScore {
        var tracker = ScoreTracker(givens: givens, solution: solution, level: level)
        for m in moves { tracker.record(m) }
        return tracker.score(mistakes: mistakes)
    }

    /// Le jugement de chaque coup, dans l'ordre (pour le replay).
    public static func analyze(givens: Grid, solution: Grid, level: Level, moves: [ScoredMove]) -> [MoveVerdict] {
        var tracker = ScoreTracker(givens: givens, solution: solution, level: level)
        return moves.map { tracker.record($0) }
    }
}

/// Suit une partie coup par coup : sert au score final, au score en direct et au replay.
///
/// Un solveur accumule ce que la logique permet de savoir (chiffres justes posés, candidats éliminés).
/// Pour juger un chiffre, on cherche sur une copie, de la technique la plus simple à la plus difficile, jusqu'à ce que
/// la case n'ait plus qu'un candidat ou que le chiffre n'ait plus qu'une place dans une unité. Trouvé : la copie
/// devient le nouvel état (le joueur a fait ce raisonnement). Pas trouvé : coup de chance, la copie est oubliée.
public struct ScoreTracker: Sendable {
    public let givens: Grid
    public let solution: Grid
    public let level: Level
    private var solver: LogicalSolver
    /// Chaque case juste n'est jugée qu'une fois.
    private var judged = [Bool](repeating: false, count: 81)
    /// Un chiffre faux a été essayé dans la case.
    private var tried = [Bool](repeating: false, count: 81)
    private var points = [Int](repeating: 0, count: 81)
    private var kind = [UInt8](repeating: 0, count: 81) // 1 déduit, 2 chance, 3 indice
    private var state: [UInt8]
    private var lastTime = 0
    private var speedSum = 0
    private var speedCount = 0
    private var hardest: Technique?

    public init(givens: Grid, solution: Grid, level: Level) {
        self.givens = givens
        self.solution = solution
        self.level = level
        solver = LogicalSolver(givens)
        state = givens.cells
    }

    /// Points des chiffres justes actuellement sur la grille (sans les erreurs).
    public var earned: Int { (0..<81).reduce(0) { $0 + (state[$1] == solution[$1] ? points[$1] : 0) } }

    @discardableResult
    public mutating func record(_ m: ScoredMove) -> MoveVerdict {
        guard givens[m.cell] == 0 else { return MoveVerdict(judgement: .repeated, points: 0, speedPermille: 0) }
        state[m.cell] = m.digit
        if m.digit == 0 { return MoveVerdict(judgement: .erased, points: 0, speedPermille: 0) }
        if m.digit != solution[m.cell] {
            tried[m.cell] = true
            return MoveVerdict(judgement: .mistake, points: 0, speedPermille: 0)
        }
        if judged[m.cell] { return MoveVerdict(judgement: .repeated, points: 0, speedPermille: 0) }
        judged[m.cell] = true
        let easiest = m.hint ? nil : bottleneck()
        let elapsed = m.time - lastTime
        lastTime = max(lastTime, m.time)
        let verdict: MoveVerdict
        if m.hint {
            kind[m.cell] = 3
            verdict = MoveVerdict(judgement: .hinted, points: 0, speedPermille: 0)
        } else if !tried[m.cell], let needed = deduction(cell: m.cell, digit: m.digit) {
            let t = min(needed, easiest ?? needed)
            let speed = Scoring.speed(seconds: elapsed, technique: t)
            let p = Scoring.points(t) * speed / 1000
            points[m.cell] = p
            kind[m.cell] = 1
            speedSum += speed
            speedCount += 1
            if hardest.map({ t > $0 }) ?? true { hardest = t }
            verdict = MoveVerdict(judgement: .deduced(needed), easiest: t, points: p, speedPermille: speed)
        } else {
            points[m.cell] = Scoring.guessPoints
            kind[m.cell] = 2
            verdict = MoveVerdict(judgement: tried[m.cell] ? .corrected : .guessed, points: Scoring.guessPoints, speedPermille: 0)
        }
        solver.place(m.cell, m.digit)
        return verdict
    }

    public func score(mistakes: Int) -> GameScore {
        var deduced = 0, guessed = 0, hinted = 0
        for c in 0..<81 where givens[c] == 0 && state[c] == solution[c] {
            switch kind[c] {
            case 1: deduced += 1
            case 2: guessed += 1
            case 3: hinted += 1
            default: break
            }
        }
        let total = max(0, earned - mistakes * Scoring.mistakePenalty)
        return GameScore(total: total, deduced: deduced, guessed: guessed, hinted: hinted,
                         timePermille: speedCount > 0 ? speedSum / speedCount : 1000,
                         version: Scoring.version, hardest: hardest?.rawValue)
    }

    /// La technique la plus simple qui permet de poser un chiffre (n'importe où) dans l'état actuel : on applique les
    /// techniques de la plus simple à la plus difficile jusqu'au premier chiffre posé, et on garde la plus difficile utilisée.
    private func bottleneck() -> Technique? {
        var s = solver
        var used: Technique?
        while let step = s.nextStep() ?? (level == .legende ? s.expertStep() ?? s.forcingStep(solution: solution) : nil) {
            if used.map({ step.technique > $0 }) ?? true { used = step.technique }
            if !step.placements.isEmpty { return used }
            s.apply(step)
        }
        return nil
    }

    /// La technique la plus difficile qu'il fallait pour connaître ce chiffre maintenant, ou `nil` (coup de chance).
    private mutating func deduction(cell: Int, digit: UInt8) -> Technique? {
        var s = solver
        var used: Technique?
        let bit = Sudoku.bit(digit)
        while true {
            if s.values[cell] == digit { break }
            if s.candidates[cell] == bit {
                used = used ?? .nakedSingle
                break
            }
            if Sudoku.unitsOfCell[cell].contains(where: { u in
                !Sudoku.units[u].contains { $0 != cell && s.candidates[$0] & bit != 0 }
            }) {
                used = used ?? .hiddenSingle
                break
            }
            guard let step = s.eliminationStep()
                ?? (level == .legende ? s.expertStep() ?? s.forcingStep(solution: solution) : nil)
            else { return nil }
            if used.map({ step.technique > $0 }) ?? true { used = step.technique }
            s.apply(step)
            if s.hasContradiction { return nil }
        }
        solver = s
        return used
    }
}

extension LogicalSolver {
    /// Le prochain coup qui élimine des candidats sans poser de chiffre (mêmes techniques et même ordre que `nextStep`,
    /// singletons exclus, chaînes comprises). Sert à juger si un chiffre était déductible (`Scoring`).
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
        return chain()
    }
}
