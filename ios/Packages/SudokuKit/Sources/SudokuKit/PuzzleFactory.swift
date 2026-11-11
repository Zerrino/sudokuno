import Foundation

/// Une grille prête à jouer.
public struct Puzzle: Hashable, Sendable {
    public let code: PuzzleCode
    public let level: Level
    public let givens: Grid
    public let solution: Grid

    public init(code: PuzzleCode, level: Level, givens: Grid, solution: Grid) {
        self.code = code
        self.level = level
        self.givens = givens
        self.solution = solution
    }
}

/// Difficulté de la grille du jour selon le jour de la semaine (UTC).
public enum DailySchedule {
    /// lundi → dimanche
    public static let levels: [Level] = [.facile, .moyen, .moyen, .difficile, .difficile, .expert, .expert]

    public static func level(for day: DayStamp) -> Level { levels[day.weekday] }

    public static func seed(for day: DayStamp) -> UInt64 {
        var sm = SplitMix64(seed: 0x5355_444F_4B55_4E4F ^ UInt64(day.dayNumber))
        return sm.next()
    }
}

public enum PuzzleFactory {

    /// Recrée la grille correspondant à un code. Déterministe. Quelques ms en Release, plus en Debug :
    /// appeler hors du thread principal.
    public static func make(_ code: PuzzleCode) -> Puzzle {
        switch code {
        case .daily(let day):
            let level = DailySchedule.level(for: day)
            let p = makeLevel(level, seed: DailySchedule.seed(for: day))
            return Puzzle(code: code, level: level, givens: p.puzzle, solution: p.solution)
        case .level(let level, let seed):
            let p = makeLevel(level, seed: seed)
            return Puzzle(code: code, level: level, givens: p.puzzle, solution: p.solution)
        case .diaboliqueV1(let seed):
            var rng = SeededRandom(seed: seed)
            let p = Generator.generate(level: .diabolique, rng: &rng, version: 1)!
            return Puzzle(code: code, level: .diabolique, givens: p.puzzle, solution: p.solution)
        case .custom(let grid):
            // Vérifier avant avec `PuzzleAnalysis.isPlayable` : une grille créée doit avoir une solution unique.
            return Puzzle(code: code, level: Grader.grade(grid), givens: grid, solution: Solver.solve(grid)!)
        }
    }

    /// Une graine aléatoire pour une nouvelle partie (le choix de la graine peut être non déterministe ;
    /// c'est la génération à partir de la graine qui doit l'être).
    public static func randomSeed() -> UInt64 {
        UInt64.random(in: 0...UInt64.max)
    }

    static func makeLevel(_ level: Level, seed: UInt64) -> (puzzle: Grid, solution: Grid) {
        var rng = SeededRandom(seed: seed)
        return Generator.generate(level: level, rng: &rng)!
    }
}
