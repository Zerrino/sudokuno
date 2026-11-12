package com.alexafer.sudokuno.kit

/**
 * Preuve par l'absurde (« chaîne forcée ») : on suppose un candidat vrai, on en tire les conséquences
 * obligatoires, et on aboutit à une contradiction. Le candidat supposé est donc faux.
 *
 * Ce n'est pas un essai au hasard : chaque conséquence est forcée (singleton nu ou caché), et la preuve
 * ne garde que les conséquences qui mènent à la contradiction. Réservé à l'explication (`Explainer`) :
 * le classement des grilles ne s'en sert jamais. Traduction fidèle de ForcingChains.swift.
 */
class ForcingProof(
    /** Le candidat supposé vrai, et donc prouvé faux. */
    val assumption: CandidateRef,
    /** Les conséquences utiles, dans l'ordre. */
    val links: List<Link>,
    val contradiction: Contradiction,
) {
    sealed interface Reason {
        /** La case n'a plus qu'un candidat. */
        data object NakedSingle : Reason
        /** Le chiffre n'a plus qu'une place dans cette unité (index dans `Sudoku.units`). */
        data class HiddenSingle(val unit: Int) : Reason
    }

    sealed interface Contradiction {
        /** Une case vide n'a plus aucun candidat. */
        data class EmptyCell(val cell: Int) : Contradiction
        /** Un chiffre n'a plus aucune place dans une unité. */
        data class NoPlace(val unit: Int, val digit: Int) : Contradiction
    }

    sealed interface Link {
        /** Conséquence directe : ce chiffre est forcé dans cette case. */
        class Place(val placement: Placement, val reason: Reason) : Link
        /** Conséquence indirecte : ce candidat est exclu, car le supposer mène lui aussi à une contradiction. */
        class Exclusion(val proof: ForcingProof) : Link
    }

    /** Nombre total de conséquences, preuves imbriquées comprises. */
    val size: Int get() = links.sumOf { if (it is Link.Exclusion) 1 + it.proof.size else 1 }

    /** Vrai si la preuve contient des suppositions imbriquées. */
    val isNested: Boolean get() = links.any { it is Link.Exclusion }

    /** La grille pendant la preuve : chiffres, candidats, et cases remplies « pour voir » (l'hypothèse en premier). */
    class State(val values: IntArray, val candidates: IntArray, val hypothetical: List<Int>)

    /**
     * La grille telle qu'elle serait après les `count` premières conséquences (0 = juste après avoir posé l'hypothèse).
     * Sert à dérouler le raisonnement à l'écran, comme le ferait un joueur sur le papier.
     */
    fun state(count: Int, values: IntArray, candidates: IntArray): State {
        val v = values.copyOf()
        val c = candidates.copyOf()
        val cells = ArrayList<Int>()
        fun place(cell: Int, d: Int) {
            v[cell] = d
            c[cell] = 0
            for (p in Sudoku.peers[cell]) c[p] = c[p] and Sudoku.bit(d).inv()
            cells.add(cell)
        }
        place(assumption.cell, assumption.digit)
        for (link in links.take(maxOf(0, count))) when (link) {
            is Link.Place -> place(link.placement.cell, link.placement.digit)
            is Link.Exclusion -> c[link.proof.assumption.cell] = c[link.proof.assumption.cell] and Sudoku.bit(link.proof.assumption.digit).inv()
        }
        return State(v, c, cells)
    }

    /** Cases concernées par les conséquences directes, dans l'ordre. */
    val cells: List<Int> get() {
        val out = arrayListOf(assumption.cell)
        for (link in links) {
            val c = when (link) {
                is Link.Place -> link.placement.cell
                is Link.Exclusion -> link.proof.assumption.cell
            }
            if (c !in out) out.add(c)
        }
        return out
    }
}

/** Recherche de preuves par l'absurde sur un état de grille. */
internal class ForcingSearch private constructor(private var budget: Int) {
    private sealed interface Kind {
        class Assume(val candidate: CandidateRef) : Kind
        class Place(val placement: Placement, val reason: ForcingProof.Reason) : Kind
        class Exclude(val proof: ForcingProof) : Kind
    }

    /** Une conséquence dans l'arbre de preuve en construction, et celles dont elle dépend. */
    private class Node(val kind: Kind, val premises: List<Int>)

    /** État d'une hypothèse : grille, candidats, et pour chaque candidat retiré la conséquence qui l'a retiré. */
    private class Branch(val values: IntArray, val candidates: IntArray, val cause: IntArray) {
        fun copy() = Branch(values.copyOf(), candidates.copyOf(), cause.copyOf())

        fun place(cell: Int, d: Int, node: Int) {
            for (e in Sudoku.digits(candidates[cell])) if (e != d) cause[cell * 9 + e - 1] = node
            values[cell] = d
            candidates[cell] = 0
            val b = Sudoku.bit(d)
            for (p in Sudoku.peers[cell]) if (candidates[p] and b != 0) {
                candidates[p] = candidates[p] and b.inv()
                cause[p * 9 + d - 1] = node
            }
        }

        fun exclude(cell: Int, d: Int, node: Int) {
            candidates[cell] = candidates[cell] and Sudoku.bit(d).inv()
            cause[cell * 9 + d - 1] = node
        }

        /** Nœuds qui ont retiré les autres candidats de la case. */
        fun cellCauses(cell: Int, except: Int = 0): List<Int> {
            val out = ArrayList<Int>()
            for (e in 1..9) {
                if (e == except) continue
                val n = cause[cell * 9 + e - 1]
                if (n >= 0 && n !in out) out.add(n)
            }
            return out
        }

        /** Nœuds qui ont retiré le chiffre des autres cases de l'unité. */
        fun unitCauses(unit: Int, d: Int, except: Int = -1): List<Int> {
            val out = ArrayList<Int>()
            for (x in Sudoku.units[unit]) {
                if (x == except) continue
                val n = cause[x * 9 + d - 1]
                if (n >= 0 && n !in out) out.add(n)
            }
            return out
        }
    }

    private val nodes = ArrayList<Node>()
    private var lastOuterPremises: List<Int> = emptyList()

    private fun refute(candidate: CandidateRef, outer: Branch, depth: Int): ForcingProof? {
        val start = nodes.size
        val branch = outer.copy()
        nodes.add(Node(Kind.Assume(candidate), emptyList()))
        branch.place(candidate.cell, candidate.digit, start)
        val result = propagate(branch, depth)
        if (result == null) {
            while (nodes.size > start) nodes.removeAt(nodes.lastIndex)
            return null
        }
        val (contradiction, premises) = result
        // On ne garde que les conséquences dont la contradiction dépend.
        val needed = HashSet<Int>()
        for (p in premises) if (p >= start) needed.add(p)
        var i = nodes.size - 1
        while (i > start) {
            if (i in needed) for (p in nodes[i].premises) if (p >= start) needed.add(p)
            i--
        }
        val links = ArrayList<ForcingProof.Link>()
        for (n in start + 1 until nodes.size) {
            if (n !in needed) continue
            when (val k = nodes[n].kind) {
                is Kind.Place -> links.add(ForcingProof.Link.Place(k.placement, k.reason))
                is Kind.Exclude -> links.add(ForcingProof.Link.Exclusion(k.proof))
                is Kind.Assume -> {}
            }
        }
        // Ce que cette preuve doit à l'hypothèse englobante (pour élaguer celle-ci à son tour).
        val outerSet = sortedSetOf<Int>()
        for (p in premises) if (p < start) outerSet.add(p)
        for (n in needed) for (p in nodes[n].premises) if (p < start) outerSet.add(p)
        lastOuterPremises = outerSet.toList()
        while (nodes.size > start) nodes.removeAt(nodes.lastIndex)
        return ForcingProof(candidate, links, contradiction)
    }

    private class Single(val cell: Int, val digit: Int, val reason: ForcingProof.Reason, val premises: List<Int>)

    /** Tire toutes les conséquences forcées. Retourne la contradiction et les nœuds dont elle dépend, ou `null`. */
    private fun propagate(b: Branch, depth: Int): Pair<ForcingProof.Contradiction, List<Int>>? {
        while (true) {
            for (c in 0 until 81) if (b.values[c] == 0 && b.candidates[c] == 0) {
                return ForcingProof.Contradiction.EmptyCell(c) to b.cellCauses(c)
            }
            var single: Single? = null
            for (c in 0 until 81) if (b.values[c] == 0 && popcount(b.candidates[c]) == 1) {
                val d = Integer.numberOfTrailingZeros(b.candidates[c]) + 1
                single = Single(c, d, ForcingProof.Reason.NakedSingle, b.cellCauses(c, d))
                break
            }
            for (u in UNIT_ORDER) {
                val unit = Sudoku.units[u]
                var placed = 0
                for (i in unit) if (b.values[i] != 0) placed = placed or Sudoku.bit(b.values[i])
                for (d in 1..9) {
                    val bit = Sudoku.bit(d)
                    if (placed and bit != 0) continue
                    var spot = -1
                    var n = 0
                    for (i in unit) if (b.candidates[i] and bit != 0) { spot = i; n++ }
                    if (n == 0) return ForcingProof.Contradiction.NoPlace(u, d) to b.unitCauses(u, d)
                    if (n == 1 && single == null && popcount(b.candidates[spot]) > 1) {
                        single = Single(spot, d, ForcingProof.Reason.HiddenSingle(u), b.unitCauses(u, d, spot))
                    }
                }
            }
            if (single != null) {
                nodes.add(Node(Kind.Place(Placement(single.cell, single.digit), single.reason), single.premises))
                b.place(single.cell, single.digit, nodes.size - 1)
                continue
            }
            // Plus de singleton : supposition imbriquée (singletons seulement à l'intérieur).
            if (depth <= 0) return null
            // Les cases les plus contraintes d'abord : ce sont les hypothèses les plus parlantes.
            val cells = (0 until 81).filter { b.values[it] == 0 }.sortedWith(compareBy({ popcount(b.candidates[it]) }, { it }))
            var found = false
            search@ for (c in cells) {
                for (d in Sudoku.digits(b.candidates[c])) {
                    if (budget <= 0) return null
                    budget--
                    val proof = refute(CandidateRef(c, d), b, depth - 1) ?: continue
                    nodes.add(Node(Kind.Exclude(proof), lastOuterPremises))
                    b.exclude(c, d, nodes.size - 1)
                    found = true
                    break@search
                }
            }
            if (!found) return null
        }
    }

    companion object {
        private val UNIT_ORDER = (18 until 27) + (0 until 18)

        /**
         * Prouve que `candidate` est faux dans l'état donné, si une contradiction se déduit.
         * `nested` : autoriser des suppositions imbriquées quand les singletons ne suffisent plus.
         */
        fun refute(candidate: CandidateRef, values: IntArray, candidates: IntArray, nested: Boolean): ForcingProof? {
            val search = ForcingSearch(if (nested) 4000 else 0)
            val root = Branch(values.copyOf(), candidates.copyOf(), IntArray(729) { -1 })
            return search.refute(candidate, root, if (nested) 1 else 0)
        }
    }
}

/** Une preuve imbriquée aussi courte est prise sans chercher mieux. */
private const val SHORT_NESTED_PROOF = 25
/** Sinon, on compare ce nombre de preuves imbriquées et on garde la plus courte (compromis lisibilité / temps de calcul). */
private const val NESTED_PROOFS_COMPARED = 12

/**
 * Meilleure preuve par l'absurde disponible : la plus courte avec des singletons seuls, sinon la première
 * qui demande des suppositions imbriquées. Seuls les candidats réellement faux sont essayés
 * (un candidat vrai ne mène jamais à une contradiction).
 */
fun LogicalSolver.forcingStep(solution: Grid): LogicStep? {
    val targets = ArrayList<CandidateRef>()
    for (c in 0 until 81) if (values[c] == 0) {
        for (d in Sudoku.digits(candidates[c])) if (d != solution[c]) targets.add(CandidateRef(c, d))
    }
    var best: ForcingProof? = null
    for (t in targets) {
        val p = ForcingSearch.refute(t, values, candidates, nested = false) ?: continue
        if (best == null || p.size < best.size) best = p
    }
    if (best == null) {
        val ordered = targets.sortedWith(compareBy({ popcount(candidates[it.cell]) }, { it.cell }, { it.digit }))
        var found = 0
        for (t in ordered) {
            val p = ForcingSearch.refute(t, values, candidates, nested = true) ?: continue
            if (best == null || p.size < best.size) best = p
            found++
            if (p.size <= SHORT_NESTED_PROOF || found >= NESTED_PROOFS_COMPARED) break
        }
    }
    val proof = best ?: return null
    return LogicStep(
        if (proof.isNested) Technique.FORCING_NET else Technique.FORCING_CHAIN,
        eliminations = listOf(proof.assumption), focus = proof.cells, digits = listOf(proof.assumption.digit),
        unit = (proof.contradiction as? ForcingProof.Contradiction.NoPlace)?.unit, proof = proof,
    )
}
