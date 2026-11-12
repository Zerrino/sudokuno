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
    @Test(arguments: Level.generated)
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

    /// Diabolique (v2) : il faut une vraie chaîne, pas seulement un Turbot ou une technique Expert.
    @Test func diaboliqueNeedsALongChain() {
        for seed in UInt64(20)..<26 {
            var rng = SeededRandom(seed: seed)
            let (puzzle, _) = Generator.generate(level: .diabolique, rng: &rng)!
            let (level, hardest) = Grader.analyze(puzzle)
            #expect(level == .diabolique)
            #expect(hardest?.isLongChain == true)
            #expect(Grader.details(puzzle).chainSteps >= Grader.diaboliqueMinChainSteps)
            // Sans les chaînes, la grille résiste : elle était bien au-delà d'Expert.
            #expect(Grader.analyze(puzzle, chains: false).level == .diabolique)
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
    @Test func legacyDiaboliqueCodeStillReads() throws {
        let old = PuzzleCode.diaboliqueV1(seed: 3)
        #expect(old.string.hasPrefix("SKN1-X-"))
        #expect(PuzzleCode(string: old.string) == old)
        #expect(old.level == .diabolique)
        let new = PuzzleCode.level(.diabolique, seed: 3)
        #expect(new.string.hasPrefix("SKN1-Z-"))
        #expect(PuzzleFactory.make(old).givens != PuzzleFactory.make(new).givens)
        // Une Légende ne se partage que par son code de grille créée.
        #expect(PuzzleCode(string: PuzzleCode.level(.legende, seed: 1).string) == nil)
    }

    @Test func levelCodeRoundTrip() {
        for level in Level.generated {
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
            (.diaboliqueV1(seed: 3), GOLDEN_DIABOLIQUE), // ancien SKN1-X-…
            (.level(.diabolique, seed: 3), GOLDEN_DIABOLIQUE_V2), // SKN1-Z-…
            (.daily(day), GOLDEN_DAILY),
        ]
        for (code, expected) in golden {
            #expect(PuzzleFactory.make(code).givens.string == expected, "\(code.string)")
        }
    }
}

@Suite("Chaînes et Légende")
struct ChainTests {
    /// Chaque coup du solveur (chaînes comprises) garde le chiffre de la solution dans les candidats.
    @Test func chainStepsAreSound() {
        var used = Set<Technique>()
        for seed in UInt64(0)..<8 {
            var rng = SeededRandom(seed: 900 + seed)
            let (puzzle, solution) = Generator.generate(level: .diabolique, rng: &rng)!
            var solver = LogicalSolver(puzzle)
            while !solver.isSolved, let step = solver.nextStep() {
                used.insert(step.technique)
                for e in step.eliminations { #expect(solution[e.cell] != e.digit, "\(step.technique)") }
                for p in step.placements { #expect(solution[p.cell] == p.digit) }
                solver.apply(step)
            }
            #expect(solver.isSolved)
        }
        #expect(used.contains { $0.isLongChain })
    }

    @Test func legendsAreUniqueAndBeyondOurTechniques() {
        #expect(Set(Legends.all.map(\.id)).count == Legends.all.count)
        for legend in Legends.all {
            #expect(Solver.hasUniqueSolution(legend.givens), "\(legend.name)")
            #expect(Grader.grade(legend.givens) == .legende, "\(legend.name)")
            #expect(Legends.find(legend.givens) == legend)
            let code = PuzzleCode.custom(legend.givens)
            #expect(PuzzleFactory.make(code).level == .legende)
        }
    }

    @Test func legendHintsStayCorrect() throws {
        let legend = try #require(Legends.find(id: "escargot"))
        let solution = try #require(Solver.solve(legend.givens))
        var values = legend.givens.cells
        while let h = HintEngine.hint(values: values, solution: solution) {
            #expect(solution[h.cell] == h.digit && values[h.cell] == 0)
            values[h.cell] = h.digit
        }
        #expect(Grid(cells: values) == solution)
    }

    /// Repère de vitesse (Debug, donc bien plus lent que l'app en Release).
    @Test func diaboliqueGenerationSpeed() {
        let clock = ContinuousClock()
        let t = clock.measure {
            for seed in UInt64(0)..<10 { _ = PuzzleFactory.make(.level(.diabolique, seed: 5000 + seed)) }
        }
        print("10 grilles Diabolique v2 :", t)
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

@Suite("Explication pas à pas")
struct ExplainerTests {
    /// Résumé d'une explication, comparé tel quel côté Kotlin (`CrossPlatformTest.explanationsMatchSwift`).
    static func signature(_ e: Explanation) -> String {
        let used = e.techniques.map { "\($0.technique.rawValue)x\($0.count)" }.joined(separator: ",")
        let chain = e.steps.first { !($0.step?.chain.isEmpty ?? true) }?.step?.chain.map { "\($0.cell):\($0.digit)" }.joined(separator: " ") ?? "-"
        let details = e.steps.compactMap(\.step).reduce(0) { acc, s in
            (acc &* 31 &+ s.digits.reduce(0) { $0 * 10 + Int($1) } &+ s.units.reduce(0) { $0 * 27 + $1 } &+ s.focus.reduce(0, +)) % 1_000_000_007
        }
        return "\(e.steps.count)|\(used)|\(chain)|\(details)"
    }

    @Test(arguments: [GOLDEN_FACILE, GOLDEN_DIFFICILE, GOLDEN_DIABOLIQUE, GOLDEN_DIABOLIQUE_V2, GOLDEN_DAILY])
    func replaysToTheSolution(_ puzzle: String) throws {
        let grid = try #require(Grid(string: puzzle))
        let solution = try #require(Solver.solutions(grid, limit: 2)?.first)
        let e = try #require(Explainer.explain(grid, solution: solution))
        #expect(e.reveals == 0)
        var values = grid.cells
        for s in e.steps {
            #expect(s.values == values)
            for p in s.placements {
                #expect(solution[p.cell] == p.digit)
                #expect(s.candidates[p.cell] & Sudoku.bit(p.digit) != 0)
                values[p.cell] = p.digit
            }
            // Un candidat retiré existe encore avant le coup et n'est jamais le bon chiffre.
            for x in s.eliminations {
                #expect(s.candidates[x.cell] & Sudoku.bit(x.digit) != 0)
                #expect(solution[x.cell] != x.digit)
            }
            let step = try #require(s.step)
            #expect(!step.focus.isEmpty)
            if step.technique >= .turbotFish { #expect(step.chain.count >= 4) } else { #expect(!step.digits.isEmpty) }
        }
        #expect(values == solution.cells)
        #expect(e.techniques.map(\.count).reduce(0, +) == e.steps.count)
        print("EXPLAIN", puzzle.prefix(12), Self.signature(e))
    }

    @Test func rejectsAGridThatContradictsTheSolution() throws {
        var grid = try #require(Grid(string: GOLDEN_FACILE))
        let solution = try #require(Solver.solutions(grid, limit: 2)?.first)
        let i = try #require((0..<81).first { grid[$0] == 0 })
        grid[i] = solution[i] % 9 + 1
        #expect(Explainer.explain(grid, solution: solution) == nil)
    }
}

@Suite("Aides du créateur")
struct CreatorHelpTests {
    @Test func redundantCluesCanEachBeRemoved() throws {
        let facile = try #require(Grid(string: GOLDEN_FACILE))
        let redundant = PuzzleAnalysis.redundantClues(facile)
        #expect(!redundant.isEmpty) // les chiffres « de confort » du niveau Facile
        for i in redundant {
            var lighter = facile
            lighter[i] = 0
            #expect(PuzzleAnalysis.analyze(lighter).isPlayable)
        }
        let kept = (0..<81).first { facile[$0] != 0 && !redundant.contains($0) }
        if let kept {
            var broken = facile
            broken[kept] = 0
            #expect(!PuzzleAnalysis.analyze(broken).isPlayable)
        }
        print("REDUNDANT", redundant.count, redundant.reduce(0, +))
    }

    @Test func completesAnOpenGrid() throws {
        var grid = try #require(Grid(string: GOLDEN_DIFFICILE))
        let solution = try #require(Solver.solutions(grid, limit: 2)?.first)
        for i in (0..<81).filter({ grid[$0] != 0 }).prefix(4) { grid[i] = 0 }
        #expect(!PuzzleAnalysis.analyze(grid).isPlayable)
        let done = try #require(PuzzleAnalysis.completed(grid))
        #expect(PuzzleAnalysis.analyze(done).isPlayable)
        #expect((0..<81).allSatisfy { grid[$0] == 0 || grid[$0] == done[$0] })
        #expect(done.clueCount > grid.clueCount)
        _ = solution
        var conflict = grid
        let filled = (0..<81).filter { grid[$0] != 0 }
        conflict[filled[0] / 9 * 9 + (filled[0] % 9 == 0 ? 1 : 0)] = grid[filled[0]]
        #expect(PuzzleAnalysis.completed(conflict) == nil)
        print("COMPLETED", done.string)
    }

    @Test func symmetry() throws {
        #expect(PuzzleAnalysis.isSymmetric(Grid()))
        var g = Grid()
        g[0] = 5
        #expect(!PuzzleAnalysis.isSymmetric(g))
        g[80] = 3
        #expect(PuzzleAnalysis.isSymmetric(g))
    }
}

@Suite("Preuves par l'absurde")
struct ForcingTests {
    /// Rejoue une preuve sans faire confiance au moteur : chaque conséquence doit être réellement forcée
    /// par les seules conséquences gardées, et la contradiction doit être réelle.
    static func check(_ proof: ForcingProof, values: [UInt8], candidates: [UInt16]) -> Bool {
        var v = values, c = candidates
        func place(_ cell: Int, _ d: UInt8) {
            v[cell] = d
            c[cell] = 0
            for p in Sudoku.peers[cell] { c[p] &= ~Sudoku.bit(d) }
        }
        guard v[proof.assumption.cell] == 0, c[proof.assumption.cell] & Sudoku.bit(proof.assumption.digit) != 0 else { return false }
        place(proof.assumption.cell, proof.assumption.digit)
        for link in proof.links {
            switch link {
            case .placement(let p, let reason):
                guard v[p.cell] == 0 else { return false }
                switch reason {
                case .nakedSingle:
                    guard c[p.cell] == Sudoku.bit(p.digit) else { return false }
                case .hiddenSingle(let u):
                    let spots = Sudoku.units[u].filter { c[$0] & Sudoku.bit(p.digit) != 0 }
                    guard spots == [p.cell] else { return false }
                }
                place(p.cell, p.digit)
            case .exclusion(let inner):
                guard check(inner, values: v, candidates: c) else { return false }
                c[inner.assumption.cell] &= ~Sudoku.bit(inner.assumption.digit)
            }
        }
        switch proof.contradiction {
        case .emptyCell(let cell): return v[cell] == 0 && c[cell] == 0
        case .noPlace(let u, let d):
            return Sudoku.units[u].allSatisfy { v[$0] != d && c[$0] & Sudoku.bit(d) == 0 }
        }
    }

    /// Résumé comparé tel quel côté Kotlin (`CrossPlatformTest.forcingProofsMatchSwift`).
    static func signature(_ e: Explanation) -> String {
        let proofs = e.steps.compactMap { $0.step?.proof }
        func hash(_ p: ForcingProof) -> Int {
            var h = p.assumption.cell * 9 + Int(p.assumption.digit)
            for link in p.links {
                switch link {
                case .placement(let pl, let r):
                    let u: Int = if case .hiddenSingle(let unit) = r { unit + 1 } else { 0 }
                    h = (h &* 31 &+ pl.cell * 9 + Int(pl.digit) + u * 1000) % 1_000_000_007
                case .exclusion(let inner): h = (h &* 37 &+ hash(inner)) % 1_000_000_007
                }
            }
            switch p.contradiction {
            case .emptyCell(let c): return (h &* 41 &+ c) % 1_000_000_007
            case .noPlace(let u, let d): return (h &* 43 &+ u * 10 + Int(d)) % 1_000_000_007
            }
        }
        let total = proofs.reduce(0) { ($0 &* 53 &+ hash($1)) % 1_000_000_007 }
        // Motifs d'experts : liens de la SK-loop, maillons des chaînes groupées, éliminations.
        var expert = 0
        for step in e.steps.compactMap(\.step) where step.technique == .skLoop || step.technique == .groupedChain {
            for l in step.loop { expert = (expert &* 31 &+ l.unit * 1000 + l.digits.reduce(0) { $0 * 10 + Int($1) }) % 1_000_000_007 }
            for n in step.groupChain { expert = (expert &* 37 &+ n.cells.reduce(Int(n.digit)) { $0 * 81 + $1 }) % 1_000_000_007 }
            for x in step.eliminations { expert = (expert &* 41 &+ x.cell * 9 + Int(x.digit)) % 1_000_000_007 }
            for c in step.pivots { expert = (expert &* 43 &+ c) % 1_000_000_007 }
        }
        let sk = e.steps.filter { $0.technique == .skLoop }.count
        let grouped = e.steps.filter { $0.technique == .groupedChain }.count
        return "\(e.steps.count)|\(proofs.count)|\(proofs.filter(\.isNested).count)|\(proofs.map(\.size).max() ?? 0)|\(total)|\(sk)|\(grouped)|\(expert)"
    }

    /// Deux Légendes suffisent en mode debug (le calcul y est lent) ; les huit sont vérifiées côté Kotlin.
    @Test(arguments: ["escargot", "inkala2010"])
    func legendsAreFullyExplained(_ id: String) throws {
        let legend = try #require(Legends.all.first { $0.id == id })
        let solution = try #require(Solver.solutions(legend.givens, limit: 2)?.first)
        let e = try #require(Explainer.explain(legend.givens, solution: solution))
        #expect(e.reveals == 0, "plus aucune case révélée : tout est prouvé")
        var values = legend.givens.cells
        var proofs = 0
        for s in e.steps {
            let step = try #require(s.step)
            for x in s.eliminations { #expect(solution[x.cell] != x.digit) }
            for p in s.placements {
                #expect(solution[p.cell] == p.digit)
                values[p.cell] = p.digit
            }
            if let proof = step.proof {
                proofs += 1
                #expect(step.technique == (proof.isNested ? .forcingNet : .forcingChain))
                #expect(step.eliminations == [proof.assumption])
                #expect(Self.check(proof, values: s.values, candidates: s.candidates), "preuve invalide à l'étape \(step)")
            }
        }
        #expect(values == solution.cells)
        #expect(proofs > 0)
        print("FORCING", id, Self.signature(e))
    }

    /// La SK-loop d'Easter Monster : le motif de référence, avec ses 13 éliminations connues.
    @Test func easterMonsterStartsWithItsSKLoop() throws {
        let legend = try #require(Legends.all.first { $0.id == "easter-monster" })
        let solver = LogicalSolver(legend.givens)
        let step = try #require(solver.skLoop())
        #expect(step.eliminations.count == 13)
        #expect(step.loop.count == 8 && step.pivots.count == 4)
        #expect(step.loop.reduce(0) { $0 + $1.digits.count } == step.focus.count, "autant de chiffres que de cases dans la boucle")
        let solution = try #require(Solver.solutions(legend.givens, limit: 2)?.first)
        for x in step.eliminations { #expect(solution[x.cell] != x.digit) }
        // Une grille ordinaire n'en contient pas.
        #expect(LogicalSolver(try #require(Grid(string: GOLDEN_DIABOLIQUE_V2))).skLoop() == nil)
    }

    /// Chaînes groupées : chaque lien fort ou faible est réel, et la conclusion ne retire jamais un bon chiffre.
    @Test func groupedChainsAreSound() throws {
        let legend = try #require(Legends.all.first { $0.id == "inkala2010" })
        let solution = try #require(Solver.solutions(legend.givens, limit: 2)?.first)
        let e = try #require(Explainer.explain(legend.givens, solution: solution))
        let grouped = e.steps.filter { $0.technique == .groupedChain }
        #expect(!grouped.isEmpty)
        for s in grouped {
            let chain = try #require(s.step?.groupChain)
            #expect(chain.count >= 4 && chain.count % 2 == 0)
            #expect(chain.contains { $0.cells.count > 1 }, "sans groupe, ce serait une chaîne ordinaire")
            for (i, pair) in zip(chain, chain.dropFirst()).enumerated() {
                let (a, b) = pair
                if a.digit == b.digit {
                    let unit = try #require((0..<27).first { u in (a.cells + b.cells).allSatisfy { Sudoku.unitsOfCell[$0].contains(u) } })
                    if i % 2 == 0 { // lien fort : à eux deux, toutes les places du chiffre dans l'unité
                        let places = Sudoku.units[unit].filter { s.candidates[$0] & Sudoku.bit(a.digit) != 0 }
                        #expect((0..<27).contains { u in
                            (a.cells + b.cells).allSatisfy { Sudoku.unitsOfCell[$0].contains(u) }
                                && Set(Sudoku.units[u].filter { s.candidates[$0] & Sudoku.bit(a.digit) != 0 }) == Set(a.cells + b.cells)
                        }, "lien fort invalide \(places)")
                    }
                } else {
                    #expect(a.cells == b.cells && a.cells.count == 1)
                    if i % 2 == 0 { #expect(s.candidates[a.cells[0]].nonzeroBitCount == 2) }
                }
            }
            for x in s.eliminations { #expect(solution[x.cell] != x.digit) }
        }
    }

    /// Les preuves par l'absurde ne servent qu'à l'explication : le classement des grilles ne change pas.
    @Test func gradingIgnoresForcingChains() {
        for legend in Legends.all { #expect(Grader.grade(legend.givens) == .legende) }
        #expect(Technique.forcingChain.level == .legende && Technique.forcingNet.level == .legende)
    }
}

@Suite("Score")
struct ScoringTests {
    /// Coups dans l'ordre du solveur logique : tous déductibles.
    static func logicalMoves(_ grid: Grid) -> [ScoredMove] {
        var solver = LogicalSolver(grid)
        var moves: [ScoredMove] = []
        while !solver.isSolved, let step = solver.nextStep() {
            for p in step.placements { moves.append(ScoredMove(cell: p.cell, digit: p.digit, hint: false)) }
            solver.apply(step)
        }
        return moves
    }

    @Test(arguments: [(GOLDEN_FACILE, Level.facile), (GOLDEN_DIFFICILE, .difficile), (GOLDEN_DIABOLIQUE_V2, .diabolique)])
    func logicalPlayScoresFullPoints(_ puzzle: String, _ level: Level) throws {
        let grid = try #require(Grid(string: puzzle))
        let solution = try #require(Solver.solutions(grid, limit: 2)?.first)
        let moves = Self.logicalMoves(grid)
        let empty = 81 - grid.clueCount
        let perfect = Scoring.score(givens: grid, solution: solution, level: level, moves: moves,
                                    seconds: Scoring.referenceSeconds(level), mistakes: 0)
        #expect(perfect.deduced == empty && perfect.guessed == 0 && perfect.hinted == 0)
        #expect(perfect.total == Scoring.basePoints(level))
        // Remplir la grille dans l'ordre des cases, sans réfléchir : beaucoup de coups de chance, bien moins de points.
        let blind = (0..<81).filter { grid[$0] == 0 }.map { ScoredMove(cell: $0, digit: solution[$0], hint: false) }
        let lucky = Scoring.score(givens: grid, solution: solution, level: level, moves: blind,
                                  seconds: Scoring.referenceSeconds(level), mistakes: 0)
        #expect(lucky.deduced + lucky.guessed == empty)
        // (Une grille Facile est presque toute en singletons : y remplir à l'aveugle reste « logique ».)
        if level > .facile { #expect(lucky.guessed > 0 && lucky.total < perfect.total) }
        // Plus vite : jusqu'à +50 % ; très lent : -50 % ; une erreur retire 5 % de la base.
        let fast = Scoring.score(givens: grid, solution: solution, level: level, moves: moves, seconds: 0, mistakes: 0)
        let slow = Scoring.score(givens: grid, solution: solution, level: level, moves: moves, seconds: 100_000, mistakes: 0)
        #expect(fast.total == Scoring.basePoints(level) * 3 / 2 && slow.total == Scoring.basePoints(level) / 2)
        let oneMistake = Scoring.score(givens: grid, solution: solution, level: level, moves: moves,
                                       seconds: Scoring.referenceSeconds(level), mistakes: 1)
        #expect(oneMistake.total == perfect.total - Scoring.basePoints(level) / 20)
        print("SCORE", level, "\(perfect.total)|\(lucky.total)|\(lucky.deduced)|\(lucky.guessed)")
    }

    @Test func hintsAndCorrectionsAreCounted() throws {
        let grid = try #require(Grid(string: GOLDEN_FACILE))
        let solution = try #require(Solver.solutions(grid, limit: 2)?.first)
        var moves = Self.logicalMoves(grid)
        // Le premier coup devient un indice ; le deuxième est d'abord faux, effacé, puis juste.
        moves[0] = ScoredMove(cell: moves[0].cell, digit: moves[0].digit, hint: true)
        let second = moves[1]
        moves.insert(ScoredMove(cell: second.cell, digit: second.digit % 9 + 1, hint: false), at: 1)
        moves.insert(ScoredMove(cell: second.cell, digit: 0, hint: false), at: 2)
        let s = Scoring.score(givens: grid, solution: solution, level: .facile, moves: moves, seconds: 300, mistakes: 1)
        let empty = 81 - grid.clueCount
        #expect(s.hinted == 1 && s.deduced == empty - 1 && s.guessed == 0)
        #expect(s.total == 1000 * (empty - 1) / empty - 50)
    }
}
