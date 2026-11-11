package com.alexafer.sudokuno.kit

import org.junit.Assert.assertEquals
import org.junit.Test

/**
 * Valeurs calculées par le moteur Swift (iOS) le 11/11/2026. Android doit retrouver EXACTEMENT les mêmes :
 * un code partagé depuis un iPhone donne la même grille sur Android, et inversement.
 * Ne jamais « corriger » ces valeurs : si un test casse, c'est le moteur Kotlin qui diverge.
 */
class CrossPlatformTest {
    private data class Ref(val code: String, val level: Int, val givens: String, val solution: String)

    private val references = listOf(
        Ref("SKN1-F-0000-0000-0000-1N", 0, ".1.9..5..6.3.58...89.41..36.59.214..1..3.58...82.497..56..8...4...56...1.37..2.5.", "214936587673258149895417236759821463146375892382649715561783924928564371437192658"),
        Ref("SKN1-M-DXBD-YXZ5-FXW0-D8", 1, "..5......27965.....1437....9....628.14....79..862....1....6531....83.975......6..", "835924167279651834614378529957146283142583796386297451798465312461832975523719648"),
        Ref("SKN1-D-0000-0000-0000-2J", 2, "3..41.5.7.....84..5..7...2....92..4.9.......1.1..86....7...5..4..36.....1.4.97..2", "328419567697258413541763928735921846986574231412386795279135684853642179164897352"),
        Ref("SKN1-E-0000-0000-0002-DK", 3, "7.......3..9.3..52.1.8..4..2....3...39.5.1.27...9....1..8..4.3.94..6.2..5.......4", "752149863489637152613852479261473985394581627875926341128794536947365218536218794"),
        Ref("SKN1-X-0000-0000-0000-3F", 4, ".1..7......9.6...776.1..9...9.6....4.4.781.9.5....3.1...6..8.499...4.7......5..6.", "315879426829564137764132958193625874642781395587493612276318549951246783438957261"),
        Ref("SKN1-J-20261110", 1, "561...7.3.9.7..65.38.....9....57...2...4.6...15..83.7..7.....49.15..2.6.9.6...5..", "561924783294738651387651294643579812728416935159283476872365149415892367936147528"),
        Ref("SKN1-J-20270101", 2, ".2.1.5.....17.8.42......1.659.6....8...3.9...3......642.7.......3.8.62.....9.2.7.", "423165897651798342879423156592614738746389521318257964267531489934876215185942673"),
    )

    @Test fun randomNumbersMatchSwift() {
        val r = SeededRandom(12345uL)
        assertEquals("13720838825685603483,2398916695208396998,17770384849984869256,891717726879801395,10241316046318454344", (0 until 5).joinToString(",") { r.next().toString() })
        val r2 = SeededRandom(999uL)
        assertEquals("0,3,6,3,0,6,2,5,8,13", (0 until 10).joinToString(",") { r2.nextBelow(7 + it).toString() })
    }

    @Test fun puzzlesMatchSwift() {
        for (ref in references) {
            val code = PuzzleCode.parse(ref.code)!!
            assertEquals(ref.code, code.string)
            val p = PuzzleFactory.make(code)
            assertEquals(ref.code, ref.level, p.level.ordinal)
            assertEquals(ref.code, ref.givens, p.givens.string)
            assertEquals(ref.code, ref.solution, p.solution.string)
        }
    }

    @Test fun customCodeMatchesSwift() {
        val g = Grid.parse(EASY_PUZZLE)!!
        assertEquals("SKN1-C-5954-V1P8-16RD-JA9A-22P1-401T-KE0C-6ENK-H2P2-72A2-040", PuzzleCode.Custom(g).string)
        assertEquals(PuzzleCode.Custom(g), PuzzleCode.parse("SKN1-C-5954-V1P8-16RD-JA9A-22P1-401T-KE0C-6ENK-H2P2-72A2-040"))
    }

    @Test fun transformMatchesSwift() {
        assertEquals("5....3..8.6921.57..........23..7965.67..5218...16.....3....1..5..........9274.36.", GridTransform(SeededRandom(5uL)).apply(Grid.parse(EASY_PUZZLE)!!).string)
    }
}
