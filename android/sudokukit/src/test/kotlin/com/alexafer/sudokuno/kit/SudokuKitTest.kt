package com.alexafer.sudokuno.kit

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

const val EASY_PUZZLE = "003020600900305001001806400008102900700000008006708200002609500800203009005010300"
const val EASY_SOLUTION = "483921657967345821251876493548132976729564138136798245372689514814253769695417382"

/** Traduction des tests Swift (SudokuKitTests.swift). */
class SudokuKitTest {

    @Test fun splitMixReference() {
        assertEquals(0xE220A8397B1DCDAFuL, SplitMix64(0uL).next())
    }

    @Test fun mulHighIsCorrect() {
        assertEquals(0uL, SeededRandom.mulHigh(1uL, 1uL))
        assertEquals(ULong.MAX_VALUE - 1uL, SeededRandom.mulHigh(ULong.MAX_VALUE, ULong.MAX_VALUE))
        assertEquals(1uL, SeededRandom.mulHigh(1uL shl 32, 1uL shl 32))
    }

    @Test fun shuffleIsAPermutation() {
        val a = IntArray(50) { it }
        SeededRandom(1uL).shuffle(a)
        assertEquals((0 until 50).toList(), a.sorted())
        assertNotEquals((0 until 50).toList(), a.toList())
    }

    @Test fun solverSolvesClassicPuzzle() {
        val g = Grid.parse(EASY_PUZZLE)!!
        assertEquals(EASY_SOLUTION, Solver.solve(g)!!.string)
        assertTrue(Solver.hasUniqueSolution(g))
        assertEquals(2, Solver.countSolutions(Grid(), 2))
        val bad = g.copy(); bad[0] = 6
        assertEquals(0, Solver.countSolutions(bad))
    }

    @Test fun classicPuzzleIsFacile() {
        assertEquals(Level.FACILE, Grader.grade(Grid.parse(EASY_PUZZLE)!!))
    }

    @Test fun logicalStepsNeverContradictSolution() {
        for (seed in 0 until 40) {
            val (puzzle, solution) = Generator.minimalPuzzle(SeededRandom(seed.toULong()))
            val solver = LogicalSolver(puzzle)
            while (true) {
                val step = solver.nextStep() ?: break
                for (p in step.placements) assertEquals("${step.technique}", solution[p.cell], p.digit)
                for (e in step.eliminations) assertNotEquals("${step.technique}", solution[e.cell], e.digit)
                solver.apply(step)
            }
            if (solver.isSolved) assertEquals(solution, Grid(solver.values))
        }
    }

    @Test fun generatorProducesRequestedLevel() {
        for (level in Level.entries) for (seed in 0uL until 2uL) {
            val (puzzle, solution) = Generator.generate(level, SeededRandom(seed * 1_000_003uL))!!
            assertTrue(Solver.hasUniqueSolution(puzzle))
            assertEquals(solution, Solver.solve(puzzle))
            assertEquals(level, Grader.grade(puzzle))
        }
    }

    @Test fun levelCodesRoundTrip() {
        for (level in Level.entries) for (seed in listOf(0uL, 1uL, 42uL, ULong.MAX_VALUE, 0xDEADBEEFCAFEF00DuL)) {
            val code = PuzzleCode.LevelSeed(level, seed)
            assertEquals(24, code.string.length)
            assertEquals(code, PuzzleCode.parse(code.string))
        }
        val code = PuzzleCode.LevelSeed(Level.DIFFICILE, 0x0123456789ABCDEFuL)
        assertEquals(code, PuzzleCode.parse(code.string.lowercase().replace("-", " ")))
    }

    @Test fun codesDetectTypos() {
        val s = PuzzleCode.LevelSeed(Level.MOYEN, 123_456_789uL).string.toCharArray()
        for (k in 7 until s.size) {
            if (s[k] == '-') continue
            val t = s.copyOf(); t[k] = if (t[k] == '7') '8' else '7'
            assertNull(PuzzleCode.parse(String(t)))
        }
    }

    @Test fun dailyCode() {
        val day = DayStamp.of(2026, 11, 10)!!
        assertEquals("SKN1-J-20261110", PuzzleCode.Daily(day).string)
        assertEquals(PuzzleCode.Daily(day), PuzzleCode.parse("skn1-j-20261110"))
        assertNull(PuzzleCode.parse("SKN1-J-20261131"))
        assertEquals(1, day.weekday)
    }

    @Test fun findsCodeInMessage() {
        val code = PuzzleCode.LevelSeed(Level.EXPERT, 987_654_321uL)
        assertEquals(code, PuzzleCode.find("Sudokuno\nCode : ${code.string}\nsudokuno://p/${code.string}?t=402&h=1"))
        assertNull(PuzzleCode.find("rien ici"))
    }

    @Test fun hintsAreCorrect() {
        val puzzle = Grid.parse(EASY_PUZZLE)!!
        val solution = Grid.parse(EASY_SOLUTION)!!
        val wrong = puzzle.cells.copyOf(); wrong[0] = 1
        assertEquals(Hint.Kind.MISTAKE, HintEngine.hint(wrong, solution)!!.kind)
        val (p, s) = Generator.generate(Level.DIABOLIQUE, SeededRandom(11uL))!!
        val values = p.cells.copyOf()
        while (true) {
            val h = HintEngine.hint(values, s) ?: break
            assertEquals(s[h.cell], h.digit)
            values[h.cell] = h.digit
        }
        assertEquals(s, Grid(values))
    }

    @Test fun analysisStatuses() {
        val g = Grid.parse(EASY_PUZZLE)!!
        assertTrue(PuzzleAnalysis.analyze(g).status is PuzzleAnalysis.Status.Unique)
        val conflict = g.copy(); conflict[1] = 3
        assertTrue(PuzzleAnalysis.analyze(conflict).status is PuzzleAnalysis.Status.Conflict)
        val sparse = Grid(); sparse[0] = 1
        var steps = 0
        while (steps < 81) {
            val st = PuzzleAnalysis.analyze(sparse).status as? PuzzleAnalysis.Status.MultipleSolutions ?: break
            sparse[st.suggestion.cell] = st.suggestion.digit
            steps++
        }
        assertTrue(PuzzleAnalysis.analyze(sparse).isPlayable)
        val impossible = Grid(); for (c in 0 until 8) impossible[c] = c + 1; impossible[44] = 9
        assertEquals(PuzzleAnalysis.Status.NoSolution, PuzzleAnalysis.analyze(impossible).status)
    }

    @Test fun streakAndFreezes() {
        val d0 = DayStamp(20_000)
        val s = StreakState()
        for (k in 0 until 7) s.recordCompletion(d0.adding(k))
        assertEquals(7, s.current); assertEquals(1, s.freezes)
        assertEquals(StreakState.Event.FreezesUsed(1), s.refresh(d0.adding(8)))
        assertNull(s.refresh(d0.adding(8)))
        s.recordCompletion(d0.adding(8))
        assertEquals(8, s.current)
        val r = StreakState(); r.recordCompletion(d0); r.recordCompletion(d0.adding(1))
        assertEquals(StreakState.Event.Reset, r.refresh(d0.adding(3)))
        assertEquals(0, r.current); assertEquals(2, r.longest)
    }

    @Test fun levelsUnlockProgressively() {
        val p = LevelProgress()
        assertTrue(p.isUnlocked(Level.FACILE)); assertFalse(p.isUnlocked(Level.MOYEN))
        repeat(4) { assertNull(p.recordWin(Level.FACILE)) }
        assertEquals(4 to 5, p.unlockProgress(Level.MOYEN))
        assertEquals(Level.MOYEN, p.recordWin(Level.FACILE))
        repeat(10) { p.recordWin(Level.EXPERT) }
        assertFalse(p.isUnlocked(Level.DIABOLIQUE))
        assertNotNull(p.unlockProgress(Level.DIFFICILE))
    }
}
