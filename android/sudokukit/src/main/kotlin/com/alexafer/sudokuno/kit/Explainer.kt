package com.alexafer.sudokuno.kit

/** Une étape d'une résolution expliquée : l'état de la grille AVANT le coup, puis le coup (Explainer.swift). */
class ExplainedStep(
    /** Chiffres posés avant ce coup (0 = case vide). */
    val values: IntArray,
    /** Candidats restants avant ce coup (masque par case). */
    val candidates: IntArray,
    /** Le coup logique. `null` : aucune de nos techniques ne s'applique, on pose un chiffre de la solution (`reveal`). */
    val step: LogicStep?,
    val reveal: Placement?,
) {
    val technique: Technique? get() = step?.technique
    val placements: List<Placement> get() = step?.placements ?: listOfNotNull(reveal)
    val eliminations: List<CandidateRef> get() = step?.eliminations ?: emptyList()
    /** Un coup qui demande plus qu'un singleton : c'est là que la grille se joue. */
    val isKey: Boolean get() = step?.let { it.technique > Technique.HIDDEN_SINGLE } ?: true
}

/** Résolution complète, coup par coup, telle qu'un joueur la ferait : la technique la plus simple d'abord. */
class Explanation(
    val steps: List<ExplainedStep>,
    /** La grille résolue (état après le dernier coup). */
    val solution: Grid,
    /** Techniques utilisées, de la plus simple à la plus difficile, avec leur nombre de coups. */
    val techniques: List<Pair<Technique, Int>>,
    /** Nombre de cases qu'il a fallu révéler faute de technique connue (0 pour toute grille générée). */
    val reveals: Int,
)

object Explainer {
    /**
     * Explique la résolution de `grid`. `solution` sert seulement quand nos techniques ne suffisent plus.
     * `null` si la grille de départ contredit la solution.
     *
     * `onStep` reçoit chaque étape dès qu'elle est trouvée (les grilles Légende demandent plusieurs secondes de calcul :
     * l'écran peut ainsi montrer le début sans attendre la fin). S'il retourne `false`, le calcul s'arrête et on retourne `null`.
     */
    fun explain(grid: Grid, solution: Grid, onStep: ((ExplainedStep) -> Boolean)? = null): Explanation? {
        if ((0 until 81).any { grid[it] != 0 && grid[it] != solution[it] }) return null
        val solver = LogicalSolver(grid)
        val steps = ArrayList<ExplainedStep>()
        val counts = IntArray(Technique.entries.size)
        var reveals = 0
        while (!solver.isSolved) {
            if (steps.isNotEmpty() && onStep != null && !onStep(steps.last())) return null
            val step = solver.nextStep()
            if (step != null) {
                steps.add(ExplainedStep(solver.values.copyOf(), solver.candidates.copyOf(), step, null))
                counts[step.technique.ordinal]++
                solver.apply(step)
            } else {
                // Les techniques classiques sont à court : preuve par l'absurde.
                val forcing = solver.forcingStep(solution)
                if (forcing != null) {
                    steps.add(ExplainedStep(solver.values.copyOf(), solver.candidates.copyOf(), forcing, null))
                    counts[forcing.technique.ordinal]++
                    solver.apply(forcing)
                    continue
                }
                val cell = solver.mostConstrainedCell()
                steps.add(ExplainedStep(solver.values.copyOf(), solver.candidates.copyOf(), null, Placement(cell, solution[cell])))
                reveals++
                solver.place(cell, solution[cell])
            }
        }
        if (steps.isNotEmpty() && onStep != null && !onStep(steps.last())) return null
        val used = Technique.entries.filter { counts[it.ordinal] > 0 }.map { it to counts[it.ordinal] }
        return Explanation(steps, solution, used, reveals)
    }
}
