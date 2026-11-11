package com.alexafer.sudokuno.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.ui.Alignment
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Star
import androidx.compose.material.icons.rounded.StarBorder
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.alexafer.sudokuno.i18n.L
import com.alexafer.sudokuno.kit.LegendPuzzle
import com.alexafer.sudokuno.kit.Legends
import com.alexafer.sudokuno.kit.Level
import com.alexafer.sudokuno.model.AppModel

/** Niveau Légende : les grilles célèbres pour leur difficulté, à jouer telles quelles (LegendsView.swift). */
@Composable
fun LegendsScreen(model: AppModel, router: Router) {
    val p = LocalPalette.current
    SubScreen(L("Légende"), router) {
        Text(
            L("Ces grilles sont célèbres dans le monde entier pour leur difficulté. Aucune technique de Sudokuno n'en vient à bout : il faudra de très longues chaînes de raisonnement, ou des essais."),
            color = p.secondaryText, style = MaterialTheme.typography.bodyMedium, modifier = Modifier.padding(horizontal = 4.dp),
        )
        for (legend in Legends.all) {
            LegendRow(legend, model.legendBest(legend), model.legendInProgress(legend)) {
                router.play { model.newLegendGame(legend) }
            }
        }
    }
}

@Composable
private fun LegendRow(legend: LegendPuzzle, best: Int?, inProgress: Boolean, onClick: () -> Unit) {
    val p = LocalPalette.current
    val tint = Level.LEGENDE.tint(p.isDark)
    Row(Modifier.fillMaxWidth().card(p).clickable(onClick = onClick).padding(16.dp).testTag("legend-${legend.id}"),
        horizontalArrangement = Arrangement.spacedBy(14.dp)) {
        Box(Modifier.size(44.dp).clip(RoundedCornerShape(12.dp)).background(tint.copy(alpha = 0.16f)), contentAlignment = Alignment.Center) {
            Icon(if (best != null) Icons.Rounded.Star else Icons.Rounded.StarBorder, null, tint = tint)
        }
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text(legend.name, fontWeight = FontWeight.SemiBold)
            Text(LegendText.credit(legend), color = p.secondaryText, style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.SemiBold)
            Text(LegendText.story(legend), color = p.secondaryText, style = MaterialTheme.typography.labelMedium)
            val status = when {
                inProgress -> L("En cours")
                best != null -> L("Résolue · record %@", clock(best))
                else -> L("Pas encore résolue")
            }
            Text(status, color = tint, fontWeight = FontWeight.Bold, style = MaterialTheme.typography.labelMedium,
                modifier = Modifier.padding(top = 2.dp).clip(RoundedCornerShape(50)).background(tint.copy(alpha = 0.16f))
                    .padding(horizontal = 10.dp, vertical = 4.dp))
        }
    }
}

/** Textes des grilles de la Légende (traduits), identiques à LegendText en Swift. */
object LegendText {
    fun credit(legend: LegendPuzzle): String = when {
        legend.author != null && legend.year != null -> "${legend.author} · ${legend.year}"
        legend.author != null -> legend.author!!
        else -> L("Forums de passionnés")
    }

    fun story(legend: LegendPuzzle): String = when (legend.id) {
        "escargot" -> L("Publiée en 2006 par le mathématicien finlandais Arto Inkala, qui la présentait comme la grille la plus difficile du monde.")
        "inkala2010" -> L("Arto Inkala dit avoir mis trois mois à créer cette grille, encore plus dure qu'AI Escargot.")
        "inkala2012" -> L("La « grille la plus difficile du monde » qui a fait le tour de la presse en juin 2012.")
        "easter-monster" -> L("Célèbre chez les spécialistes pour son motif presque symétrique en croix : l'une des grilles les plus dures connues.")
        "golden-nugget" -> L("Longtemps en tête des classements de difficulté établis par les passionnés.")
        "platinum-blonde" -> L("Jugée la plus difficile par les chercheurs Ercsey-Ravasz et Toroczkai, qui mesurent la difficulté comme du chaos.")
        "unsolvable28", "unsolvable49" -> L("Une des grilles « insolubles » de SudokuWiki : aucune technique logique classique n'en vient à bout.")
        else -> ""
    }
}
