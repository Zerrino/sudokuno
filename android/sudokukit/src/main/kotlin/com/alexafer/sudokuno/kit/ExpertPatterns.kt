package com.alexafer.sudokuno.kit

/*
 * Motifs d'experts pour les grilles extrêmes : SK-loop et chaînes groupées (ExpertPatterns.swift).
 *
 * Réservés à l'explication (Explainer), quand LogicalSolver.nextStep est à court : ils ne sont jamais appelés
 * par le classement des grilles ni par le générateur. Essayés avant les preuves par l'absurde, plus parlants qu'elles.
 */

/** Un lien d'une SK-loop : dans cette unité (index dans `Sudoku.units`), la boucle prend forcément ces chiffres. */
data class LoopLink(val unit: Int, val digits: List<Int>)

/**
 * Un maillon d'une chaîne groupée : un chiffre dans une case, ou dans un groupe de 2 ou 3 cases
 * d'un même bloc alignées sur une même ligne ou colonne (« le chiffre est quelque part dans ce groupe »).
 */
data class GroupNode(val cells: List<Int>, val digit: Int)

/**
 * SK-loop (découverte par Steve Kurzhals sur « Easter Monster »).
 *
 * Quatre cases « pivot » forment un rectangle sur quatre blocs. Dans chaque bloc, les deux voisines du pivot
 * sur sa ligne et les deux sur sa colonne forment deux groupes : huit groupes en tout, reliés en boucle,
 * tour à tour par une ligne ou une colonne (entre deux blocs) et par un bloc (entre les deux groupes d'un bloc).
 * Si les N cases vides de la boucle ne peuvent contenir que N chiffres répartis sur ces huit liens, chaque lien
 * consomme tous ses chiffres : on les retire du reste de sa ligne, de sa colonne ou de son bloc.
 */
fun LogicalSolver.skLoop(): LogicStep? {
    for (r1 in 0 until 9) for (r2 in r1 + 1 until 9) {
        if (r1 / 3 == r2 / 3) continue
        for (c1 in 0 until 9) for (c2 in c1 + 1 until 9) {
            if (c1 / 3 == c2 / 3) continue
            skLoop(r1, r2, c1, c2)?.let { return it }
        }
    }
    return null
}

private fun LogicalSolver.skLoop(r1: Int, r2: Int, c1: Int, c2: Int): LogicStep? {
    // Les quatre pivots, dans l'ordre de la boucle : haut-gauche, haut-droite, bas-droite, bas-gauche.
    val p = listOf(r1 to c1, r1 to c2, r2 to c2, r2 to c1)
    fun rowMates(r: Int, c: Int) = (0 until 3).map { c / 3 * 3 + it }.filter { it != c }.map { r * 9 + it }
    fun colMates(r: Int, c: Int) = (0 until 3).map { r / 3 * 3 + it }.filter { it != r }.map { it * 9 + c }
    // Huit groupes G0…G7 et huit liens : le lien i relie G(i) et G(i+1).
    val all = listOf(
        rowMates(p[0].first, p[0].second), rowMates(p[1].first, p[1].second),
        colMates(p[1].first, p[1].second), colMates(p[2].first, p[2].second),
        rowMates(p[2].first, p[2].second), rowMates(p[3].first, p[3].second),
        colMates(p[3].first, p[3].second), colMates(p[0].first, p[0].second),
    )
    fun box(q: Pair<Int, Int>) = 18 + Sudoku.box(q.first * 9 + q.second)
    val units = listOf(r1, box(p[1]), 9 + c2, box(p[2]), r2, box(p[3]), 9 + c1, box(p[0]))
    val groups = all.map { g -> g.filter { values[it] == 0 } }
    if (groups.any { it.isEmpty() }) return null
    val masks = groups.map { g -> g.fold(0) { acc, i -> acc or candidates[i] } }
    val cellCount = groups.sumOf { it.size }

    // On essaie chaque choix pour le lien 7 (entre G7 et G0) ; les autres liens s'en déduisent de proche en proche.
    val free = Sudoku.digits(masks[0] and masks[7])
    for (pick in 0 until (1 shl free.size)) {
        var last = 0
        for (k in free.indices) if (pick and (1 shl k) != 0) last = last or Sudoku.bit(free[k])
        val links = IntArray(8)
        links[7] = last
        var previous = last
        var valid = true
        for (i in 0 until 7) {
            links[i] = masks[i] and previous.inv()
            // Un lien ne porte que des chiffres présents des deux côtés.
            if (links[i] and masks[i + 1].inv() != 0) { valid = false; break }
            previous = links[i]
        }
        if (!valid || (masks[7] and links[6].inv()) != last || links.any { it == 0 }) continue
        if (links.sumOf { popcount(it) } != cellCount) continue

        val elim = ArrayList<CandidateRef>()
        for (i in 0 until 8) {
            val inside = groups[i] + groups[(i + 1) % 8]
            for (c in Sudoku.units[units[i]]) {
                if (values[c] != 0 || c in inside) continue
                for (d in Sudoku.digits(candidates[c] and links[i])) {
                    val ref = CandidateRef(c, d)
                    if (ref !in elim) elim.add(ref)
                }
            }
        }
        if (elim.isEmpty()) continue
        return LogicStep(
            Technique.SK_LOOP, eliminations = elim, focus = groups.flatten(),
            loop = (0 until 8).map { LoopLink(units[it], Sudoku.digits(links[it]).toList()) },
            pivots = p.map { it.first * 9 + it.second },
        )
    }
    return null
}

/**
 * Chaîne d'inférences alternées dont les maillons peuvent être des groupes de cases.
 * Même principe que `chain()` : la chaîne A = … = Z prouve « A ou Z est vrai », donc tout candidat
 * incompatible avec les deux tombe. Ne garde que la chaîne la plus courte (12 maillons au plus).
 */
fun LogicalSolver.groupedChain(): LogicStep? {
    // Maillons : chaque candidat, puis chaque groupe (intersection bloc-ligne avec au moins 2 places).
    val nodes = ArrayList<GroupNode>()
    val single = IntArray(729) { -1 }
    for (c in 0 until 81) if (values[c] == 0) {
        for (d in Sudoku.digits(candidates[c])) {
            single[c * 9 + d - 1] = nodes.size
            nodes.add(GroupNode(listOf(c), d))
        }
    }
    val singleCount = nodes.size
    for (d in 1..9) for (b in 0 until 9) for (line in 0 until 18) {
        val cells = Sudoku.units[line].filter { Sudoku.box(it) == b && candidates[it] and Sudoku.bit(d) != 0 }
        if (cells.size >= 2) nodes.add(GroupNode(cells, d))
    }
    if (nodes.size == singleCount) return null

    // Maillons présents dans chaque unité, par chiffre.
    val inUnit = Array(27 * 9) { ArrayList<Int>() }
    for (n in nodes.indices) {
        val node = nodes[n]
        for (u in 0 until 27) if (node.cells.all { u in Sudoku.unitsOfCell[it] }) inUnit[u * 9 + node.digit - 1].add(n)
    }
    val strong = Array(nodes.size) { ArrayList<Int>() }
    val weak = Array(nodes.size) { ArrayList<Int>() }
    for (u in 0 until 27) for (d in 0 until 9) {
        val list = inUnit[u * 9 + d]
        val places = Sudoku.units[u].count { candidates[it] and (1 shl d) != 0 }
        for (i in list.indices) {
            val a = list[i]
            for (j in i + 1 until list.size) {
                val b = list[j]
                if (nodes[a].cells.any { it in nodes[b].cells }) continue
                if (b !in weak[a]) { weak[a].add(b); weak[b].add(a) }
                // Lien fort : à eux deux, ils couvrent toutes les places du chiffre dans l'unité.
                if (nodes[a].cells.size + nodes[b].cells.size == places && b !in strong[a]) { strong[a].add(b); strong[b].add(a) }
            }
        }
    }
    for (c in 0 until 81) if (values[c] == 0) {
        val ds = Sudoku.digits(candidates[c])
        for (d in ds) {
            val n = single[c * 9 + d - 1]
            for (e in ds) {
                if (e == d) continue
                val m = single[c * 9 + e - 1]
                weak[n].add(m)
                if (ds.size == 2) strong[n].add(m)
            }
        }
    }

    val dist = IntArray(nodes.size * 2)
    val parent = IntArray(nodes.size * 2) { -1 }
    var bestPath: List<Int>? = null
    var bestElim: List<CandidateRef> = emptyList()
    var bestLength = MAX_CHAIN_NODES + 1
    val queue = ArrayList<Int>()
    for (a in nodes.indices) {
        for (s in queue) dist[s] = 0
        queue.clear()
        val start = a * 2
        dist[start] = 1
        parent[start] = -1
        queue.add(start)
        var head = 0
        while (head < queue.size) {
            val s = queue[head++]
            val n = s / 2
            val length = dist[s]
            if (s % 2 == 1 && length >= 4) {
                val elim = groupedEliminations(nodes[a], nodes[n])
                if (elim.isNotEmpty()) {
                    val path = ArrayList<Int>()
                    var t = s
                    while (t >= 0) { path.add(t / 2); t = parent[t] }
                    bestPath = path.reversed()
                    bestElim = elim
                    bestLength = length
                    break
                }
            }
            if (length + 1 >= bestLength) continue
            for (m in if (s % 2 == 0) strong[n] else weak[n]) {
                val next = m * 2 + if (s % 2 == 0) 1 else 0
                if (dist[next] == 0) {
                    dist[next] = length + 1
                    parent[next] = s
                    queue.add(next)
                }
            }
        }
    }
    val path = bestPath ?: return null
    val focus = ArrayList<Int>()
    for (n in path) for (c in nodes[n].cells) if (c !in focus) focus.add(c)
    return LogicStep(Technique.GROUPED_CHAIN, eliminations = bestElim, focus = focus, groupChain = path.map { nodes[it] })
}

/** Ce que prouve « A ou Z est vrai » quand A et Z peuvent être des groupes. */
private fun LogicalSolver.groupedEliminations(a: GroupNode, z: GroupNode): List<CandidateRef> {
    if (a.digit == z.digit) {
        if (a.cells.any { it in z.cells }) return emptyList()
        val bit = Sudoku.bit(a.digit)
        return (0 until 81)
            .filter { c ->
                candidates[c] and bit != 0 && c !in a.cells && c !in z.cells &&
                    a.cells.all { Sudoku.sees(c, it) } && z.cells.all { Sudoku.sees(c, it) }
            }
            .map { CandidateRef(it, a.digit) }
    }
    // Chiffres différents : seulement entre deux cases simples.
    if (a.cells.size != 1 || z.cells.size != 1) return emptyList()
    val ac = a.cells[0]
    val zc = z.cells[0]
    val out = ArrayList<CandidateRef>()
    if (ac == zc) {
        for (e in Sudoku.digits(candidates[ac])) if (e != a.digit && e != z.digit) out.add(CandidateRef(ac, e))
    } else if (Sudoku.sees(ac, zc)) {
        if (candidates[zc] and Sudoku.bit(a.digit) != 0) out.add(CandidateRef(zc, a.digit))
        if (candidates[ac] and Sudoku.bit(z.digit) != 0) out.add(CandidateRef(ac, z.digit))
    }
    return out
}

/** Les motifs d'experts, du plus spectaculaire au plus général. */
fun LogicalSolver.expertStep(): LogicStep? = skLoop() ?: groupedChain()
