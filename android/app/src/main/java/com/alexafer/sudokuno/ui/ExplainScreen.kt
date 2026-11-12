package com.alexafer.sudokuno.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.alexafer.sudokuno.i18n.L
import com.alexafer.sudokuno.kit.CandidateRef
import com.alexafer.sudokuno.kit.ExplainedStep
import com.alexafer.sudokuno.kit.Explainer
import com.alexafer.sudokuno.kit.Explanation
import com.alexafer.sudokuno.kit.ForcingProof
import com.alexafer.sudokuno.kit.Grid
import com.alexafer.sudokuno.kit.Level
import com.alexafer.sudokuno.kit.Solver
import com.alexafer.sudokuno.kit.Sudoku
import com.alexafer.sudokuno.kit.Technique
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.isActive
import kotlinx.coroutines.withContext

/**
 * Rédige en clair un coup de la résolution : ce qu'on observe, pourquoi cela marche, ce qu'on en tire.
 * Même logique et mêmes textes que `StepText.swift` côté iOS.
 */
object StepText {
    /** « L3C7 » : ligne 3, colonne 7 (notation habituelle des solveurs). */
    fun cell(i: Int): String = L("L%1\$@C%2\$@", "${Sudoku.row(i) + 1}", "${Sudoku.col(i) + 1}")

    fun cells(list: List<Int>): String = list.joinToString(", ") { cell(it) }

    /** « la ligne 3 », « la colonne 7 », « le bloc 5 ». */
    fun unit(u: Int): String = when (val k = Sudoku.unitName(u)) {
        is Sudoku.UnitKind.Row -> L("la ligne %@", "${k.index + 1}")
        is Sudoku.UnitKind.Column -> L("la colonne %@", "${k.index + 1}")
        is Sudoku.UnitKind.Box -> L("le bloc %@", "${k.index + 1}")
    }

    /** « les lignes 2, 7 » (unités toutes du même type). */
    fun units(list: List<Int>): String {
        val numbers = list.joinToString(", ") { "${it % 9 + 1}" }
        return if ((list.firstOrNull() ?: 0) < 9) L("les lignes %@", numbers) else L("les colonnes %@", numbers)
    }

    /** « 5·L1C2 = 5·L1C8 – 5·L3C9 = 5·L7C9 » : = lien fort, – lien faible. */
    fun chain(nodes: List<CandidateRef>): String = nodes.withIndex().joinToString("") { (i, n) ->
        (if (i == 0) "" else if (i % 2 == 1) " = " else " – ") + "${n.digit}·${cell(n.cell)}"
    }

    /** Le raisonnement. */
    fun reason(s: ExplainedStep): String {
        val step = s.step ?: return s.placements[0].let {
            L("Aucune des techniques de Sudokuno ne permet d'avancer ici : cette grille demande des méthodes encore plus avancées. On pose le %1\$@ en %2\$@, tiré de la solution, pour continuer.", "${it.digit}", cell(it.cell))
        }
        val d = step.digits.firstOrNull()?.toString() ?: ""
        val digits = step.digits.joinToString(", ")
        return when (step.technique) {
            Technique.NAKED_SINGLE ->
                L("La case %1\$@ n'a plus qu'un candidat : le %2\$@. Tous les autres chiffres sont déjà dans sa ligne, sa colonne ou son bloc.", cell(step.focus[0]), d)
            Technique.HIDDEN_SINGLE ->
                L("Dans %1\$@, le %2\$@ ne peut aller qu'en %3\$@ : il est exclu de toutes les autres cases.", unit(step.unit ?: 0), d, cell(step.focus[0]))
            Technique.POINTING, Technique.BOX_LINE_REDUCTION ->
                L("Dans %1\$@, toutes les places possibles du %2\$@ se trouvent aussi dans %3\$@. Le %2\$@ occupera donc l'une d'elles : on le retire des autres cases dans %3\$@.", unit(step.unit ?: 0), d, unit(step.units.firstOrNull() ?: 0))
            Technique.NAKED_PAIR, Technique.NAKED_TRIPLE ->
                L("Dans %1\$@, les cases %2\$@ ne contiennent ensemble que les candidats %3\$@. Ces chiffres leur sont réservés : on les retire des autres cases dans %1\$@.", unit(step.unit ?: 0), cells(step.focus), digits)
            Technique.HIDDEN_PAIR, Technique.HIDDEN_TRIPLE ->
                L("Dans %1\$@, les chiffres %2\$@ ne peuvent aller que dans les cases %3\$@. Ces cases leur sont réservées : on y retire tous les autres candidats.", unit(step.unit ?: 0), digits, cells(step.focus))
            Technique.X_WING, Technique.SWORDFISH -> {
                val n = step.units.size / 2
                L("Dans %2\$@, le %1\$@ n'a de place que dans %3\$@. Il occupera forcément ces croisements : on le retire de toutes les autres cases dans %3\$@.", d, units(step.units.take(n)), units(step.units.takeLast(n)))
            }
            Technique.XY_WING ->
                L("Le pivot %1\$@ n'a que deux candidats. Quel que soit le bon, l'une des deux ailes (%2\$@) prendra le %3\$@. Une case qui voit les deux ailes ne peut donc pas contenir le %3\$@.", cell(step.focus[0]), cells(step.focus.drop(1)), d)
            Technique.XYZ_WING ->
                L("Le pivot %1\$@ et ses deux ailes (%2\$@) contiennent tous le %3\$@, et l'une de ces trois cases le prendra forcément. Une case qui voit les trois ne peut donc pas contenir le %3\$@.", cell(step.focus[0]), cells(step.focus.drop(1)), d)
            Technique.FORCING_CHAIN, Technique.FORCING_NET -> step.eliminations[0].let { a ->
                L("Les techniques classiques ne suffisent plus : on raisonne par l'absurde. Supposons que %1\$@ contienne le %2\$@. Voici ce que cela impose, coup après coup :", cell(a.cell), "${a.digit}")
            }
            Technique.TURBOT_FISH, Technique.X_CHAIN, Technique.XY_CHAIN, Technique.AIC ->
                L("Suis la chaîne : %@. Le signe = est un lien fort (si l'un est faux, l'autre est vrai) ; le signe – est un lien faible (si l'un est vrai, l'autre est faux). Si le premier maillon est faux, le dernier est vrai : l'un des deux bouts est donc forcément vrai, et tout candidat incompatible avec les deux est retiré.", chain(step.chain))
        }
    }

    /** Une ligne d'une preuve par l'absurde ; `indent` > 0 pour une supposition imbriquée. */
    class ProofLine(val indent: Int, val text: String, val isConclusion: Boolean)

    /** La preuve, ligne par ligne. `detailed` : dérouler aussi les suppositions imbriquées. */
    fun proofLines(proof: ForcingProof, detailed: Boolean): List<ProofLine> {
        val lines = ArrayList<ProofLine>()
        fun walk(p: ForcingProof, indent: Int) {
            for (link in p.links) when (link) {
                is ForcingProof.Link.Place -> {
                    val pl = link.placement
                    lines.add(ProofLine(indent, when (val r = link.reason) {
                        ForcingProof.Reason.NakedSingle -> L("%1\$@ = %2\$@ : c'est son seul candidat restant.", cell(pl.cell), "${pl.digit}")
                        is ForcingProof.Reason.HiddenSingle -> L("%1\$@ = %2\$@ : c'est la seule place du %2\$@ dans %3\$@.", cell(pl.cell), "${pl.digit}", unit(r.unit))
                    }, false))
                }
                is ForcingProof.Link.Exclusion -> {
                    val a = link.proof.assumption
                    if (detailed) {
                        lines.add(ProofLine(indent, L("%1\$@ ne peut pas contenir le %2\$@. En effet, si c'était le cas :", cell(a.cell), "${a.digit}"), false))
                        walk(link.proof, indent + 1)
                    } else {
                        lines.add(ProofLine(indent, L("%1\$@ ne peut pas contenir le %2\$@ : cela mènerait aussi à une contradiction (preuve imbriquée, %3\$@ coups).", cell(a.cell), "${a.digit}", "${link.proof.size}"), false))
                    }
                }
            }
            lines.add(ProofLine(indent, when (val k = p.contradiction) {
                is ForcingProof.Contradiction.EmptyCell -> L("Contradiction : %@ n'a plus aucun candidat.", cell(k.cell))
                is ForcingProof.Contradiction.NoPlace -> L("Contradiction : le %1\$@ n'a plus aucune place dans %2\$@.", "${k.digit}", unit(k.unit))
            }, true))
        }
        walk(proof, 0)
        lines.add(ProofLine(0, L("L'hypothèse est donc fausse : %1\$@ ne contient pas le %2\$@.", cell(proof.assumption.cell), "${proof.assumption.digit}"), true))
        return lines
    }

    /** Ce que le coup change dans la grille. */
    fun outcome(s: ExplainedStep): String {
        val lines = ArrayList<String>()
        if (s.step != null) for (p in s.placements) lines.add(L("On place le %1\$@ en %2\$@.", "${p.digit}", cell(p.cell)))
        val removed = s.eliminations
        if (removed.isNotEmpty()) {
            val items = removed.take(8).map { "${cell(it.cell)} ≠ ${it.digit}" } + if (removed.size > 8) listOf("…") else emptyList()
            lines.add(L("Candidats retirés : %@.", items.joinToString(", ")))
        }
        return lines.joinToString("\n")
    }
}

/** Couleurs d'une étape (motif, candidats retirés, chiffre placé), calculées une fois. */
private class Marks(s: ExplainedStep, private val p: Palette) {
    private val region = HashSet<Int>()
    private val focus = HashSet<Int>()
    private val target = HashSet<Int>()
    private val removedCells = HashSet<Int>()
    /** Clé = case * 9 + chiffre - 1. */
    private val colors = HashMap<Int, Color>()

    init {
        s.step?.let { step ->
            for (u in listOfNotNull(step.unit) + step.units) region.addAll(Sudoku.units[u].toList())
            focus.addAll(step.focus)
            for (c in step.focus) for (d in step.digits) colors[c * 9 + d - 1] = p.accent
            // Maillons de la chaîne en deux couleurs alternées : si l'un est faux, le suivant est vrai.
            step.chain.forEachIndexed { k, n -> colors[n.cell * 9 + n.digit - 1] = if (k % 2 == 0) p.freeze else p.success }
            // Preuve par l'absurde : les chiffres imposés par l'hypothèse, et l'endroit où elle casse.
            step.proof?.let { proof ->
                for (link in proof.links) when (link) {
                    is ForcingProof.Link.Place -> colors[link.placement.cell * 9 + link.placement.digit - 1] = p.freeze
                    is ForcingProof.Link.Exclusion -> colors[link.proof.assumption.cell * 9 + link.proof.assumption.digit - 1] = p.flameStart
                }
                (proof.contradiction as? ForcingProof.Contradiction.EmptyCell)?.let { removedCells.add(it.cell) }
            }
        }
        for (e in s.eliminations) { removedCells.add(e.cell); colors[e.cell * 9 + e.digit - 1] = p.error }
        for (pl in s.placements) { target.add(pl.cell); colors[pl.cell * 9 + pl.digit - 1] = p.success }
    }

    fun color(cell: Int, digit: Int): Color? = colors[cell * 9 + digit - 1]

    fun background(i: Int): Color = when (i) {
        in target -> p.hintCell
        in focus -> p.hintCell.copy(alpha = 0.45f)
        in removedCells -> p.errorFill
        in region -> p.hintRegion
        else -> Color.Transparent
    }
}

/**
 * Résolution expliquée pas à pas : à chaque étape, la grille avec ses candidats, le motif repéré,
 * la technique utilisée et pourquoi elle marche (ExplainView.swift).
 */
@Composable
fun ExplainScreen(givens: Grid, router: Router) {
    val p = LocalPalette.current
    // Étapes déjà calculées : elles arrivent une à une, la suite se calcule pendant qu'on lit le début.
    val steps = remember { androidx.compose.runtime.mutableStateListOf<ExplainedStep>() }
    // Résolution complète, une fois le calcul terminé.
    var explanation by remember { mutableStateOf<Explanation?>(null) }
    var solution by remember { mutableStateOf<Grid?>(null) }
    var failed by remember { mutableStateOf(false) }
    // Étape affichée ; steps.size = la grille résolue.
    var index by remember { mutableIntStateOf(0) }
    // Dérouler les suppositions imbriquées des preuves par l'absurde.
    var detailed by remember { mutableStateOf(false) }
    LaunchedEffect(givens) {
        // Le calcul envoie chaque étape dès qu'elle est trouvée ; il s'arrête si on quitte l'écran.
        withContext(Dispatchers.Default) {
            val sols = Solver.solutions(givens, 2)
            if (sols == null || sols.size != 1) { failed = true; return@withContext }
            solution = sols[0]
            explanation = Explainer.explain(givens, sols[0]) { steps.add(it); isActive }
        }
    }

    SubScreen(L("Explication pas à pas"), router) {
        val sol = solution
        if (sol == null || steps.isEmpty()) {
            if (failed) Text(L("Cette grille n'a pas de solution unique : impossible de l'expliquer."), color = p.secondaryText)
            else Box(Modifier.fillMaxWidth().padding(top = 80.dp), contentAlignment = Alignment.Center) { CircularProgressIndicator(color = p.accent) }
            return@SubScreen
        }
        val e = explanation
        val complete = e != null
        val step = steps.getOrNull(index)
        val marks = remember(step) { step?.let { Marks(it, p) } }

        BoardFrame(Modifier.testTag("explainBoard")) { i, size ->
            val value = step?.values?.get(i) ?: sol[i]
            val given = givens[i] != 0
            val fontSize = with(LocalDensity.current) { (size * 0.58f).toSp() }
            Box(Modifier.size(size).background(marks?.background(i) ?: Color.Transparent), contentAlignment = Alignment.Center) {
                if (value != 0) Text("$value", fontSize = fontSize, fontWeight = if (given) FontWeight.SemiBold else FontWeight.Medium,
                    color = if (given) p.given else p.entry)
                else if (step != null && marks != null) NotesGrid(step.candidates[i], size) { d -> marks.color(i, d) }
            }
        }

        // L'étape : technique, raisonnement, effet.
        Column(Modifier.fillMaxWidth().card(p).padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(if (step == null) L("Grille résolue") else L("Étape %1\$@ sur %2\$@", "${index + 1}", if (complete) "${steps.size}" else "…"),
                    Modifier.weight(1f).testTag("explainProgress"), color = p.secondaryText, fontWeight = FontWeight.SemiBold,
                    style = MaterialTheme.typography.bodyMedium)
                step?.technique?.let { LevelPill(it.level) }
            }
            if (step != null) {
                Text(step.technique?.displayName ?: L("Au-delà des techniques classiques"), fontWeight = FontWeight.Bold,
                    style = MaterialTheme.typography.titleMedium, modifier = Modifier.testTag("explainTechnique"))
                Text(StepText.reason(step), modifier = Modifier.testTag("explainReason"))
                // Preuve par l'absurde : une ligne par conséquence, les suppositions imbriquées en retrait.
                step.step?.proof?.let { proof ->
                    Column(Modifier.testTag("explainProof"), verticalArrangement = Arrangement.spacedBy(5.dp)) {
                        for (line in StepText.proofLines(proof, detailed)) Row(Modifier.padding(start = (line.indent * 16).dp),
                            horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                            Text(if (line.isConclusion) "⇒" else "•", color = if (line.isConclusion) p.error else p.secondaryText,
                                style = MaterialTheme.typography.bodyMedium)
                            Text(line.text, fontWeight = if (line.isConclusion) FontWeight.SemiBold else FontWeight.Normal,
                                style = MaterialTheme.typography.bodyMedium)
                        }
                    }
                    if (proof.isNested) TextButton(onClick = { detailed = !detailed }, modifier = Modifier.testTag("explainProofDetail")) {
                        Text(if (detailed) L("Masquer les preuves imbriquées") else L("Détailler les preuves imbriquées"))
                    }
                }
                val outcome = StepText.outcome(step)
                if (outcome.isNotEmpty()) Text(outcome, color = p.accent, fontWeight = FontWeight.SemiBold, style = MaterialTheme.typography.bodyMedium)
            } else {
                Text(L("Tu as vu toute la résolution, en %@ étapes.", "${steps.size}"), color = p.success, fontWeight = FontWeight.SemiBold,
                    modifier = Modifier.testTag("explainDone"))
            }
        }

        // Grilles très dures : la suite se calcule pendant qu'on lit.
        if (!complete) Row(Modifier.testTag("explainComputing"), verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            CircularProgressIndicator(Modifier.size(18.dp), color = p.accent, strokeWidth = 2.dp)
            Text(L("Calcul de la suite…"), color = p.secondaryText, style = MaterialTheme.typography.bodyMedium)
        }
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            FilledTonalButton(onClick = { index-- }, enabled = index > 0, modifier = Modifier.weight(1f).height(48.dp).testTag("explainPrevious")) {
                Text(L("Précédent"))
            }
            Button(onClick = { index++ }, enabled = index < (if (complete) steps.size else steps.size - 1), colors = ButtonDefaults.buttonColors(containerColor = p.accentStrong),
                modifier = Modifier.weight(1f).height(48.dp).testTag("explainNext")) { Text(L("Suivant"), fontWeight = FontWeight.SemiBold) }
        }
        // Saute les singletons pour aller au prochain coup qui fait la difficulté de la grille.
        val nextKey = steps.indices.firstOrNull { it > index && steps[it].isKey }
        if (nextKey != null) FilledTonalButton(onClick = { index = nextKey }, modifier = Modifier.fillMaxWidth().testTag("explainNextKey")) {
            Text(L("Étape clé suivante"))
        }
        if (index > 0) TextButton(onClick = { index = 0 }, modifier = Modifier.align(Alignment.CenterHorizontally)) { Text(L("Revenir au début")) }

        // Techniques utilisées : toucher une ligne mène à sa première utilisation.
        if (e != null) Column(Modifier.fillMaxWidth().card(p).padding(16.dp), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text(L("Techniques utilisées"), fontWeight = FontWeight.SemiBold, modifier = Modifier.padding(bottom = 4.dp))
            for ((technique, count) in e.techniques) TechniqueRow(technique.displayName, technique.level, count) {
                index = steps.indexOfFirst { it.technique == technique }
            }
            if (e.reveals > 0) TechniqueRow(L("Au-delà des techniques classiques"), Level.LEGENDE, e.reveals, null)
        }
    }
}

@Composable
private fun TechniqueRow(name: String, level: Level, count: Int, onClick: (() -> Unit)?) {
    val p = LocalPalette.current
    Row(Modifier.fillMaxWidth().let { if (onClick != null) it.clickable(onClick = onClick) else it }.padding(vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
        Box(Modifier.size(8.dp).background(level.tint(p.isDark), CircleShape))
        Text(name, Modifier.weight(1f))
        Text("× $count", color = p.secondaryText)
    }
}
