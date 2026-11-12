package com.alexafer.sudokuno.kit

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
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

    /** Diabolique v2 (SKN1-Z-…, chaînes) : valeurs calculées par le moteur Swift le 11/11/2026. */
    @Test fun chainsMatchSwift() {
        val refs = mapOf(
            "SKN1-Z-0000-0000-0000-3F" to ".146..2....72.5...5.....8.64....9....9.1.3.7....4....11.2.....4...8.29....8..476.",
            "SKN1-Z-0000-0000-0001-A2" to "....6.384..........7...9.65.2..97...3..2.4..6...13..4.46.3...5..........918.5....",
        )
        for ((c, givens) in refs) {
            val code = PuzzleCode.parse(c)!!
            assertEquals(c, code.string)
            val p = PuzzleFactory.make(code)
            assertEquals(c, Level.DIABOLIQUE, p.level)
            assertEquals(c, givens, p.givens.string)
        }
        // Suite des coups de chaîne sur SKN1-Z-…-3F
        val solver = LogicalSolver(Grid.parse(refs.values.first())!!)
        val seq = ArrayList<String>()
        while (!solver.isSolved) {
            val st = solver.nextStep() ?: break
            if (st.technique >= Technique.TURBOT_FISH) seq.add(st.technique.name)
            solver.apply(st)
        }
        assertEquals("TURBOT_FISH,TURBOT_FISH,TURBOT_FISH,AIC,AIC,TURBOT_FISH", seq.joinToString(","))
        // Blocage sur AI Escargot : même état qu'en Swift (24 chiffres, 216 candidats).
        val esc = LogicalSolver(Legends.find("escargot")!!.givens)
        esc.solve()
        assertEquals(24, esc.values.count { it != 0 })
        assertEquals(216, esc.candidates.sumOf { Integer.bitCount(it) })
        assertEquals("SKN1-C-GMJ4-S1J4-HGH0-9092-0D0G-QGN2-2G1R-N681-PC89", PuzzleCode.Custom(Legends.find("escargot")!!.givens).string)
    }

    @Test fun customCodeMatchesSwift() {
        val g = Grid.parse(EASY_PUZZLE)!!
        assertEquals("SKN1-C-5954-V1P8-16RD-JA9A-22P1-401T-KE0C-6ENK-H2P2-72A2-040", PuzzleCode.Custom(g).string)
        assertEquals(PuzzleCode.Custom(g), PuzzleCode.parse("SKN1-C-5954-V1P8-16RD-JA9A-22P1-401T-KE0C-6ENK-H2P2-72A2-040"))
    }

    @Test fun transformMatchesSwift() {
        assertEquals("5....3..8.6921.57..........23..7965.67..5218...16.....3....1..5..........9274.36.", GridTransform(SeededRandom(5uL)).apply(Grid.parse(EASY_PUZZLE)!!).string)
    }

    /** Explications pas à pas : résumés calculés par le moteur Swift le 12/11/2026 (`ExplainerTests.signature`). */
    @Test fun explanationsMatchSwift() {
        val refs = mapOf(
            ".1.9..5..6.3.58...89.41..36.59.214..1..3.58...82.497..56..8...4...56...1.37..2.5." to "43|0x43|-|543827012",
            "3..41.5.7.....84..5..7...2....92..4.9.......1.1..86....7...5..4..36.....1.4.97..2" to "57|0x49,1x4,2x1,4x1,6x1,8x1|-|906815414",
            ".1..7......9.6...776.1..9...9.6....4.4.781.9.5....3.1...6..8.499...4.7......5..6." to "60|0x38,1x14,2x3,4x1,11x2,12x2|26:2 53:2 42:2 38:2|45934089",
            "561...7.3.9.7..65.38.....9....57...2...4.6...15..83.7..7.....49.15..2.6.9.6...5.." to "50|0x38,1x11,2x1|-|158847222",
            ".146..2....72.5...5.....8.64....9....9.1.3.7....4....11.2.....4...8.29....8..476." to "63|0x35,1x18,2x1,3x1,9x2,12x4,15x2|35:3 71:3 65:3 47:3|55455358",
        )
        for ((puzzle, expected) in refs) {
            val grid = Grid.parse(puzzle)!!
            val e = Explainer.explain(grid, Solver.solutions(grid, 2)!!.first())!!
            assertEquals(puzzle, 0, e.reveals)
            val used = e.techniques.joinToString(",") { "${it.first.ordinal}x${it.second}" }
            val chain = e.steps.firstOrNull { it.step?.chain?.isNotEmpty() == true }?.step?.chain?.joinToString(" ") { "${it.cell}:${it.digit}" } ?: "-"
            var details = 0L
            for (st in e.steps.mapNotNull { it.step }) {
                details = (details * 31 + st.digits.fold(0L) { a, d -> a * 10 + d } + st.units.fold(0L) { a, u -> a * 27 + u } + st.focus.sum()) % 1_000_000_007
            }
            assertEquals(puzzle, expected, "${e.steps.size}|$used|$chain|$details")
            // La dernière étape mène bien à la solution.
            val last = e.steps.last()
            val end = last.values.copyOf()
            for (pl in last.placements) end[pl.cell] = pl.digit
            assertEquals(puzzle, e.solution.string, Grid(end).string)
        }
    }

    /** Aides du créateur : mêmes résultats qu'en Swift (12/11/2026). */
    @Test fun creatorHelpsMatchSwift() {
        val facile = Grid.parse(".1.9..5..6.3.58...89.41..36.59.214..1..3.58...82.497..56..8...4...56...1.37..2.5.")!!
        val redundant = PuzzleAnalysis.redundantClues(facile)
        assertEquals(34, redundant.size)
        assertEquals(1287, redundant.sum())
        val open = Grid.parse("3..41.5.7.....84..5..7...2....92..4.9.......1.1..86....7...5..4..36.....1.4.97..2")!!
        for (i in (0 until 81).filter { open[it] != 0 }.take(4)) open[i] = 0
        assertEquals("3.6.....7.....84..5..7...2....92..4.9.....6.1.1..86....7.3.5..4..36.....1.4.97..2", PuzzleAnalysis.completed(open)!!.string)
        assertTrue(PuzzleAnalysis.isSymmetric(Grid.parse(".".repeat(81))!!))
    }

    /** Rejoue une preuve sans faire confiance au moteur (même vérification que `ForcingTests.check` en Swift). */
    private fun check(proof: ForcingProof, values: IntArray, candidates: IntArray): Boolean {
        val v = values.copyOf()
        val c = candidates.copyOf()
        fun place(cell: Int, d: Int) {
            v[cell] = d
            c[cell] = 0
            for (p in Sudoku.peers[cell]) c[p] = c[p] and Sudoku.bit(d).inv()
        }
        val a = proof.assumption
        if (v[a.cell] != 0 || c[a.cell] and Sudoku.bit(a.digit) == 0) return false
        place(a.cell, a.digit)
        for (link in proof.links) when (link) {
            is ForcingProof.Link.Place -> {
                val p = link.placement
                if (v[p.cell] != 0) return false
                when (val r = link.reason) {
                    ForcingProof.Reason.NakedSingle -> if (c[p.cell] != Sudoku.bit(p.digit)) return false
                    is ForcingProof.Reason.HiddenSingle ->
                        if (Sudoku.units[r.unit].filter { c[it] and Sudoku.bit(p.digit) != 0 } != listOf(p.cell)) return false
                }
                place(p.cell, p.digit)
            }
            is ForcingProof.Link.Exclusion -> {
                if (!check(link.proof, v, c)) return false
                c[link.proof.assumption.cell] = c[link.proof.assumption.cell] and Sudoku.bit(link.proof.assumption.digit).inv()
            }
        }
        return when (val k = proof.contradiction) {
            is ForcingProof.Contradiction.EmptyCell -> v[k.cell] == 0 && c[k.cell] == 0
            is ForcingProof.Contradiction.NoPlace -> Sudoku.units[k.unit].all { v[it] != k.digit && c[it] and Sudoku.bit(k.digit) == 0 }
        }
    }

    private fun hash(p: ForcingProof): Long {
        val m = 1_000_000_007L
        var h = (p.assumption.cell * 9 + p.assumption.digit).toLong()
        for (link in p.links) h = when (link) {
            is ForcingProof.Link.Place -> {
                val u = (link.reason as? ForcingProof.Reason.HiddenSingle)?.let { it.unit + 1 } ?: 0
                (h * 31 + link.placement.cell * 9 + link.placement.digit + u * 1000) % m
            }
            is ForcingProof.Link.Exclusion -> (h * 37 + hash(link.proof)) % m
        }
        return when (val k = p.contradiction) {
            is ForcingProof.Contradiction.EmptyCell -> (h * 41 + k.cell) % m
            is ForcingProof.Contradiction.NoPlace -> (h * 43 + k.unit * 10 + k.digit) % m
        }
    }

    /**
     * Les 8 Légendes sont expliquées en entier, sans case révélée, avec exactement les mêmes preuves par l'absurde
     * et les mêmes motifs d'experts (SK-loop, chaînes groupées) qu'en Swift (signatures calculées par
     * `ForcingTests.signature` le 12/11/2026). Chaque preuve est rejouée.
     */
    @Test fun forcingProofsMatchSwift() {
        val refs = mapOf(
            "escargot" to "118|38|4|72|445241590|0|3|185322008",
            "inkala2010" to "123|37|3|50|258436405|0|4|335853814",
            "inkala2012" to "139|53|3|94|348748178|0|0|0",
            "easter-monster" to "112|33|1|77|958081015|1|4|987786950",
            "golden-nugget" to "131|44|10|303|815824603|0|1|468282750",
            "platinum-blonde" to "138|32|11|179|36855132|0|1|97169411",
            "unsolvable28" to "110|37|7|123|320412344|0|6|985828826",
            "unsolvable49" to "117|27|4|129|101293006|0|4|83913707",
        )
        assertEquals(Legends.all.map { it.id }.toSet(), refs.keys)
        for ((id, expected) in refs) {
            val grid = Legends.find(id)!!.givens
            val solution = Solver.solutions(grid, 2)!!.first()
            val e = Explainer.explain(grid, solution)!!
            assertEquals(id, 0, e.reveals)
            val proofs = e.steps.mapNotNull { it.step?.proof }
            for (s in e.steps) {
                for (x in s.eliminations) assertTrue(id, solution[x.cell] != x.digit)
                s.step?.proof?.let { assertTrue("$id : preuve invalide", check(it, s.values, s.candidates)) }
            }
            val total = proofs.fold(0L) { acc, p -> (acc * 53 + hash(p)) % 1_000_000_007L }
            // Motifs d'experts : liens de la SK-loop, maillons des chaînes groupées, éliminations.
            val m = 1_000_000_007L
            var expert = 0L
            for (step in e.steps.mapNotNull { it.step }) {
                if (step.technique != Technique.SK_LOOP && step.technique != Technique.GROUPED_CHAIN) continue
                for (l in step.loop) expert = (expert * 31 + l.unit * 1000 + l.digits.fold(0L) { a, d -> a * 10 + d }) % m
                for (n in step.groupChain) expert = (expert * 37 + n.cells.fold(n.digit.toLong()) { a, c -> a * 81 + c }) % m
                for (x in step.eliminations) expert = (expert * 41 + x.cell * 9 + x.digit) % m
                for (c in step.pivots) expert = (expert * 43 + c) % m
            }
            val sk = e.steps.count { it.technique == Technique.SK_LOOP }
            val grouped = e.steps.count { it.technique == Technique.GROUPED_CHAIN }
            assertEquals(id, expected, "${e.steps.size}|${proofs.size}|${proofs.count { it.isNested }}|${proofs.maxOf { it.size }}|$total|$sk|$grouped|$expert")
            // Le classement des grilles ne change pas : une Légende reste une Légende.
            assertEquals(id, Level.LEGENDE, Grader.grade(grid))
        }
    }
}
