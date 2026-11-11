import Foundation
import Testing
@testable import SudokuKit

// Grille classique (Project Euler n° 96, grille 01).
let easyPuzzle = "003020600900305001001806400008102900700000008006708200002609500800203009005010300"
let easySolution = "483921657967345821251876493548132976729564138136798245372689514814253769695417382"

@Suite("Aléatoire déterministe")
struct RandomTests {
    @Test func splitMixReferenceValue() {
        var sm = SplitMix64(seed: 0)
        #expect(sm.next() == 0xE220_A839_7B1D_CDAF)
    }

    @Test func sameSeedSameSequence() {
        var a = SeededRandom(seed: 42), b = SeededRandom(seed: 42)
        for _ in 0..<100 { #expect(a.next() == b.next()) }
    }

    @Test func boundedStaysInRange() {
        var r = SeededRandom(seed: 7)
        for n in 1..<50 { for _ in 0..<20 { #expect((0..<n).contains(r.next(below: n))) } }
    }

    @Test func shuffleIsAPermutation() {
        var r = SeededRandom(seed: 1)
        var a = Array(0..<50)
        r.shuffle(&a)
        #expect(a.sorted() == Array(0..<50))
        #expect(a != Array(0..<50))
    }
}

@Suite("Grille et solveur")
struct SolverTests {
    @Test func parsesAndPrints() throws {
        let g = try #require(Grid(string: easyPuzzle))
        #expect(g.clueCount == 32)
        #expect(Grid(string: g.string) == g)
        #expect(Grid(string: "123") == nil)
    }

    @Test func peersAndUnits() {
        #expect(Sudoku.peers.allSatisfy { $0.count == 20 })
        #expect(Sudoku.units.count == 27)
        #expect(Sudoku.box(80) == 8 && Sudoku.box(30) == 4)
    }

    @Test func solvesClassicPuzzle() throws {
        let g = try #require(Grid(string: easyPuzzle))
        #expect(Solver.solve(g)?.string == Grid(string: easySolution)?.string)
        #expect(Solver.hasUniqueSolution(g))
    }

    @Test func detectsMultipleAndNoSolutions() throws {
        #expect(Solver.countSolutions(Grid(), limit: 2) == 2)
        var bad = try #require(Grid(string: easyPuzzle))
        bad[0] = 6 // conflit avec le 6 de la ligne 1
        #expect(Solver.countSolutions(bad) == 0)
    }

    @Test func randomSolutionIsValidAndDeterministic() {
        var r1 = SeededRandom(seed: 99), r2 = SeededRandom(seed: 99)
        let a = Solver.randomSolution(rng: &r1), b = Solver.randomSolution(rng: &r2)
        #expect(a == b)
        #expect(a.isFilled && a.isConsistent)
    }
}

@Suite("Solveur logique et niveaux")
struct LogicTests {
    @Test func classicPuzzleIsFacile() throws {
        let g = try #require(Grid(string: easyPuzzle))
        #expect(Grader.grade(g) == .facile)
    }

    /// Propriété essentielle : sur de nombreuses grilles, aucune technique ne place un mauvais chiffre
    /// ni n'élimine le bon candidat.
    @Test(arguments: 0..<40)
    func logicalStepsNeverContradictSolution(seed: Int) {
        var rng = SeededRandom(seed: UInt64(seed))
        let (puzzle, solution) = Generator.minimalPuzzle(rng: &rng)
        var solver = LogicalSolver(puzzle)
        while let step = solver.nextStep() {
            for p in step.placements { #expect(solution[p.cell] == p.digit, "\(step.technique) place faux") }
            for e in step.eliminations { #expect(solution[e.cell] != e.digit, "\(step.technique) élimine la solution") }
            #expect(!step.placements.isEmpty || !step.eliminations.isEmpty)
            solver.apply(step)
        }
        if solver.isSolved { #expect(Grid(cells: solver.values) == solution) }
    }

    @Test func combinationsAreComplete() {
        #expect(combinations([1, 2, 3, 4], 2).count == 6)
        #expect(combinations([1, 2, 3], 3) == [[1, 2, 3]])
        #expect(combinations([1], 2).isEmpty)
    }
}

@Suite("Générateur")
struct GeneratorTests {
    @Test(arguments: Level.allCases)
    func generatesUniquePuzzleOfRequestedLevel(level: Level) {
        for seed in UInt64(0)..<3 {
            var rng = SeededRandom(seed: seed &* 1_000_003)
            let (puzzle, solution) = Generator.generate(level: level, rng: &rng)!
            #expect(Solver.hasUniqueSolution(puzzle))
            #expect(Solver.solve(puzzle) == solution)
            #expect(Grader.grade(puzzle) == level)
            for i in 0..<81 where puzzle[i] != 0 { #expect(puzzle[i] == solution[i]) }
        }
    }

    @Test func easyPuzzlesHaveComfortClues() {
        var rng = SeededRandom(seed: 5)
        let (puzzle, _) = Generator.generate(level: .facile, rng: &rng)!
        #expect(puzzle.clueCount >= 36)
    }

    @Test func transformKeepsValidityAndUniqueness() throws {
        let g = try #require(Grid(string: easyPuzzle))
        let s = try #require(Grid(string: easySolution))
        var rng = SeededRandom(seed: 3)
        let t = GridTransform(rng: &rng)
        #expect(t.apply(s).isConsistent && t.apply(s).isFilled)
        #expect(Solver.solve(t.apply(g)) == t.apply(s))
        #expect(Grader.grade(t.apply(g)) == Grader.grade(g))
    }
}

@Suite("Codes de grille")
struct CodeTests {
    @Test func levelCodeRoundTrip() {
        for level in Level.allCases {
            for seed: UInt64 in [0, 1, 42, .max, 0xDEAD_BEEF_CAFE_F00D] {
                let code = PuzzleCode.level(level, seed: seed)
                #expect(code.string.count == 24)
                #expect(PuzzleCode(string: code.string) == code)
            }
        }
    }

    @Test func toleratesSloppyInput() {
        let code = PuzzleCode.level(.difficile, seed: 0x0123_4567_89AB_CDEF)
        let sloppy = code.string.lowercased().replacingOccurrences(of: "-", with: " ")
        #expect(PuzzleCode(string: sloppy) == code)
    }

    @Test func detectsTypos() {
        let s = Array(PuzzleCode.level(.moyen, seed: 123_456_789).string)
        var rejected = 0, total = 0
        for k in 7..<s.count where s[k] != "-" {
            var t = s
            t[k] = t[k] == "7" ? "8" : "7"
            total += 1
            if PuzzleCode(string: String(t)) == nil { rejected += 1 }
        }
        #expect(rejected == total)
    }

    @Test func dailyCode() throws {
        let day = try #require(DayStamp(year: 2026, month: 11, day: 10))
        #expect(PuzzleCode.daily(day).string == "SKN1-J-20261110")
        #expect(PuzzleCode(string: "skn1-j-20261110") == .daily(day))
        #expect(PuzzleCode(string: "SKN1-J-20261131") == nil)
        #expect(day.weekday == 1) // mardi
    }

    @Test func findsCodeInSharedMessage() {
        let code = PuzzleCode.level(.expert, seed: 987_654_321)
        let msg = "Sudokuno · Expert 🔥3\n⏱ 6:42 · 💡 1 indice\nCode : \(code.string)\nsudokuno://p/\(code.string)?t=402&h=1"
        #expect(PuzzleCode.find(in: msg) == code)
        #expect(PuzzleCode.find(in: "rien ici") == nil)
    }

    /// Tests de référence : si l'un d'eux casse, le générateur v1 a changé et les codes partagés
    /// ne donneraient plus les mêmes grilles. Ne pas « corriger » ces valeurs : créer un générateur v2.
    @Test func goldenPuzzles() throws {
        let day = try #require(DayStamp(year: 2026, month: 11, day: 10))
        let golden: [(PuzzleCode, String)] = [
            (.level(.facile, seed: 1), GOLDEN_FACILE),
            (.level(.difficile, seed: 2), GOLDEN_DIFFICILE),
            (.level(.diabolique, seed: 3), GOLDEN_DIABOLIQUE),
            (.daily(day), GOLDEN_DAILY),
        ]
        for (code, expected) in golden {
            #expect(PuzzleFactory.make(code).givens.string == expected, "\(code.string)")
        }
    }
}

@Suite("Indices")
struct HintTests {
    @Test func flagsMistakeFirst() throws {
        var values = try #require(Grid(string: easyPuzzle)).cells
        let solution = try #require(Grid(string: easySolution))
        values[0] = 1 // la solution est 4
        let hint = try #require(HintEngine.hint(values: values, solution: solution))
        #expect(hint.kind == .mistake && hint.cell == 0)
    }

    @Test func placementHintIsCorrect() throws {
        let puzzle = try #require(Grid(string: easyPuzzle))
        let solution = try #require(Grid(string: easySolution))
        let hint = try #require(HintEngine.hint(values: puzzle.cells, solution: solution))
        #expect(hint.kind == .placement)
        #expect(solution[hint.cell] == hint.digit)
        #expect(hint.region.contains(hint.cell))
    }

    @Test func hintOnHardPuzzleStillCorrect() {
        var rng = SeededRandom(seed: 11)
        let (p, s) = Generator.generate(level: .diabolique, rng: &rng)!
        var values = p.cells
        // On joue tous les indices jusqu'au bout : chacun doit être juste.
        while let h = HintEngine.hint(values: values, solution: s) {
            #expect(h.kind != .mistake)
            #expect(s[h.cell] == h.digit && values[h.cell] == 0)
            values[h.cell] = h.digit
        }
        #expect(Grid(cells: values) == s)
    }
}

@Suite("Série et progression")
struct ProgressTests {
    let d0 = DayStamp(dayNumber: 20_000)

    @Test func consecutiveDaysIncrease() {
        var s = StreakState()
        s.recordCompletion(day: d0)
        s.recordCompletion(day: d0.adding(days: 1))
        #expect(s.recordCompletion(day: d0.adding(days: 2)) == 3) // jalon
        #expect(s.current == 3 && s.longest == 3)
    }

    @Test func sameDayTwiceCountsOnce() {
        var s = StreakState()
        s.recordCompletion(day: d0)
        s.recordCompletion(day: d0)
        #expect(s.current == 1)
    }

    @Test func missedDayResetsWithoutFreeze() {
        var s = StreakState()
        s.recordCompletion(day: d0)
        s.recordCompletion(day: d0.adding(days: 1))
        #expect(s.refresh(today: d0.adding(days: 3)) == .reset)
        #expect(s.current == 0 && s.longest == 2)
        s.recordCompletion(day: d0.adding(days: 3))
        #expect(s.current == 1)
    }

    @Test func freezesEarnedAndConsumed() {
        var s = StreakState()
        for k in 0..<7 { s.recordCompletion(day: d0.adding(days: k)) }
        #expect(s.freezes == 1)
        // jour 7 manqué, on revient le jour 8
        #expect(s.refresh(today: d0.adding(days: 8)) == .freezesUsed(1))
        #expect(s.freezes == 0 && s.current == 7)
        #expect(s.refresh(today: d0.adding(days: 8)) == nil) // idempotent
        s.recordCompletion(day: d0.adding(days: 8))
        #expect(s.current == 8)
        #expect(s.frozenDays.contains(d0.adding(days: 7)))
    }

    @Test func freezesAreCapped() {
        var s = StreakState()
        for k in 0..<35 { s.recordCompletion(day: d0.adding(days: k)) }
        #expect(s.freezes == StreakState.maxFreezes)
    }

    @Test func atRisk() {
        var s = StreakState()
        s.recordCompletion(day: d0)
        #expect(!s.isAtRisk(today: d0))
        #expect(s.isAtRisk(today: d0.adding(days: 1)))
    }

    @Test func levelsUnlockProgressively() {
        var p = LevelProgress()
        #expect(p.isUnlocked(.facile) && !p.isUnlocked(.moyen))
        for _ in 0..<4 { #expect(p.recordWin(.facile) == nil) }
        #expect(p.unlockProgress(.moyen)! == (4, 5))
        #expect(p.recordWin(.facile) == .moyen)
        #expect(p.isUnlocked(.moyen) && !p.isUnlocked(.difficile))
        // Une victoire Expert « hors parcours » ne débloque pas Diabolique tant qu'Expert est verrouillé.
        for _ in 0..<10 { p.recordWin(.expert) }
        #expect(!p.isUnlocked(.diabolique))
    }
}

@Suite("Créateur de grilles")
struct CreatorTests {
    @Test func customCodeRoundTrip() throws {
        let g = try #require(Grid(string: easyPuzzle))
        let code = PuzzleCode.custom(g)
        #expect(code.string.hasPrefix("SKN1-C-"))
        #expect(PuzzleCode(string: code.string) == code)
        #expect(PuzzleCode(string: code.string.lowercased()) == code)
        #expect(PuzzleCode.find(in: "Essaie : \(code.string) !") == code)
    }

    @Test func customCodeDetectsTypos() throws {
        let s = Array(PuzzleCode.custom(try #require(Grid(string: easyPuzzle))).string)
        for k in 7..<s.count where s[k] != "-" {
            var t = s
            t[k] = t[k] == "7" ? "8" : "7"
            #expect(PuzzleCode(string: String(t)) == nil, "faute non détectée en position \(k)")
        }
    }

    @Test func customPuzzleIsPlayedAsIs() throws {
        let g = try #require(Grid(string: easyPuzzle))
        let p = PuzzleFactory.make(.custom(g))
        #expect(p.givens == g && p.level == .facile)
        #expect(p.solution.string == Grid(string: easySolution)!.string)
    }

    @Test func analysisStatuses() throws {
        var g = try #require(Grid(string: easyPuzzle))
        guard case .unique(let level, _, _) = PuzzleAnalysis.analyze(g).status else { Issue.record("unique attendu"); return }
        #expect(level == .facile)

        var conflict = g
        conflict[1] = 3 // le 3 de la case 2 est dans la même ligne
        guard case .conflict(let cells) = PuzzleAnalysis.analyze(conflict).status else { Issue.record("conflit attendu"); return }
        #expect(cells.contains(1) && cells.contains(2))

        // Grille presque vide : plusieurs solutions, la suggestion aide à converger.
        var sparse = Grid()
        sparse[0] = 1
        guard case .multipleSolutions(let s) = PuzzleAnalysis.analyze(sparse).status else { Issue.record("multiple attendu"); return }
        #expect(sparse[s.cell] == 0)

        // Suivre les suggestions finit par donner une grille unique.
        var steps = 0
        while case .multipleSolutions(let s) = PuzzleAnalysis.analyze(sparse).status, steps < 81 {
            sparse[s.cell] = s.digit
            steps += 1
        }
        #expect(PuzzleAnalysis.analyze(sparse).isPlayable)

        g[0] = 0; g[2] = 0
        #expect(PuzzleAnalysis.analyze(g).clueCount == 31) // la case 0 était déjà vide
    }

    @Test func impossibleGridHasNoSolution() throws {
        // Ligne 1 : 1 à 8, et un 9 dans la colonne 9 plus bas → la case (0,8) n'a plus de candidat.
        var g = Grid()
        for c in 0..<8 { g[c] = UInt8(c + 1) }
        g[9 * 4 + 8] = 9
        #expect(PuzzleAnalysis.analyze(g).status == .noSolution)
    }
}
