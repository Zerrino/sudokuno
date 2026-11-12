package com.alexafer.sudokuno.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.rounded.KeyboardArrowLeft
import androidx.compose.material.icons.automirrored.rounded.KeyboardArrowRight
import androidx.compose.material.icons.rounded.Pause
import androidx.compose.material.icons.rounded.PlayArrow
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Slider
import androidx.compose.material3.Text
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
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.alexafer.sudokuno.i18n.L
import com.alexafer.sudokuno.model.Move
import com.alexafer.sudokuno.model.Playback
import kotlinx.coroutines.delay

/**
 * Revoir une partie de l'historique : chaque chiffre posé, effacé ou annulé, dans l'ordre et avec son instant
 * (PlaybackView.swift).
 */
@Composable
fun PlaybackScreen(playback: Playback, router: Router) {
    val p = LocalPalette.current
    val moves = remember(playback) { playback.decoded }
    val states = remember(playback) { playback.states() }
    val givens = remember(playback) { playback.givensGrid }
    val solution = remember(playback) { playback.solutionGrid }
    // Nombre de coups déjà joués à l'écran (0 = grille de départ).
    var index by remember { mutableIntStateOf(0) }
    var playing by remember { mutableStateOf(false) }
    val current = if (index > 0) moves[index - 1] else null
    val mistakes = remember(playback) { moves.count { playback.isMistake(it, solution) } }

    // Lecture automatique : un coup toutes les 0,6 s (l'effet ne tourne que pendant la lecture).
    LaunchedEffect(playing) {
        while (playing) {
            delay(600)
            if (index < moves.size) index++
            if (index >= moves.size) playing = false
        }
    }

    fun describe(m: Move): String {
        val cell = StepText.cell(m.cell)
        return when (m.kind) {
            Move.Kind.PLAYER -> when {
                m.digit == 0 -> L("Tu effaces la case %@.", cell)
                playback.isMistake(m, solution) -> L("Tu places le %1\$@ en %2\$@ : ce n'est pas le bon chiffre.", "${m.digit}", cell)
                else -> L("Tu places le %1\$@ en %2\$@.", "${m.digit}", cell)
            }
            Move.Kind.HINT -> if (m.digit == 0) L("Indice : la case %@ est effacée.", cell) else L("Indice : le %1\$@ en %2\$@.", "${m.digit}", cell)
            Move.Kind.UNDO -> if (m.digit == 0) L("Annulation : la case %@ redevient vide.", cell)
                else L("Annulation : la case %1\$@ revient au %2\$@.", cell, "${m.digit}")
        }
    }

    SubScreen(L("Revoir la partie"), router) {
        val values = states[index]
        BoardFrame(Modifier.testTag("playbackBoard")) { i, size ->
            val wrong = values[i] != 0 && values[i] != solution[i]
            CellView(values[i], 0, givens[i] != 0, wrong, { pal ->
                if (current?.cell == i) (if (wrong) pal.errorFill else pal.selection) else Color.Transparent
            }, size, Modifier)
        }

        Column(Modifier.fillMaxWidth().card(p).padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(L("Coup %1\$@ sur %2\$@", "$index", "${moves.size}"), Modifier.weight(1f).testTag("playbackProgress"),
                    color = p.secondaryText, fontWeight = FontWeight.SemiBold, style = MaterialTheme.typography.bodyMedium)
                current?.let { Text("⏱ ${clock(it.time)}", color = p.secondaryText, fontWeight = FontWeight.SemiBold, style = MaterialTheme.typography.bodyMedium) }
            }
            Text(current?.let { describe(it) } ?: L("Début de la partie"), fontWeight = FontWeight.SemiBold,
                color = if (current != null && playback.isMistake(current, solution)) p.error else p.given,
                modifier = Modifier.testTag("playbackMove"))
            Text(L("%lld erreurs", mistakes), color = if (mistakes == 0) p.success else p.error,
                style = MaterialTheme.typography.bodyMedium, modifier = Modifier.testTag("playbackMistakes"))
            if (moves.size > 1) Slider(value = index.toFloat(), onValueChange = { index = Math.round(it); playing = false },
                valueRange = 0f..moves.size.toFloat())
        }

        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            FilledTonalButton(onClick = { playing = false; index-- }, enabled = index > 0,
                modifier = Modifier.weight(1f).height(48.dp).testTag("playbackPrevious")) {
                Icon(Icons.AutoMirrored.Rounded.KeyboardArrowLeft, L("Précédent"))
            }
            Button(onClick = { if (index >= moves.size) index = 0; playing = !playing }, enabled = moves.isNotEmpty(),
                colors = ButtonDefaults.buttonColors(containerColor = p.accentStrong),
                modifier = Modifier.weight(2f).height(48.dp).testTag("playbackPlay")) {
                Icon(if (playing) Icons.Rounded.Pause else Icons.Rounded.PlayArrow, null)
                Text(if (playing) L("Pause") else L("Lecture"), fontWeight = FontWeight.SemiBold, modifier = Modifier.padding(start = 6.dp))
            }
            FilledTonalButton(onClick = { playing = false; index++ }, enabled = index < moves.size,
                modifier = Modifier.weight(1f).height(48.dp).testTag("playbackNext")) {
                Icon(Icons.AutoMirrored.Rounded.KeyboardArrowRight, L("Suivant"))
            }
        }
        val nextMistake = moves.indices.firstOrNull { it >= index && playback.isMistake(moves[it], solution) }
        if (nextMistake != null) FilledTonalButton(onClick = { playing = false; index = nextMistake + 1 },
            modifier = Modifier.fillMaxWidth().testTag("playbackNextMistake")) { Text(L("Erreur suivante")) }
    }
}
