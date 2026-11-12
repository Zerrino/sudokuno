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
import androidx.compose.ui.platform.LocalContext
import com.alexafer.sudokuno.model.AppModel
import com.alexafer.sudokuno.model.GameMode
import com.alexafer.sudokuno.model.HistoryEntry
import com.alexafer.sudokuno.model.Move
import com.alexafer.sudokuno.model.Playback
import kotlinx.coroutines.delay

/**
 * Revoir une partie de l'historique : chaque chiffre posé, effacé ou annulé, dans l'ordre et avec son instant
 * (PlaybackView.swift).
 */
@Composable
fun PlaybackScreen(model: AppModel, entry: HistoryEntry, router: Router) {
    val p = LocalPalette.current
    val context = LocalContext.current
    val playback = remember(entry) { entry.review ?: Playback(".".repeat(81), ".".repeat(81), emptyList()) }
    val moves = remember(playback) { playback.decoded }
    val states = remember(playback) { playback.states() }
    val givens = remember(playback) { playback.givensGrid }
    val solution = remember(playback) { playback.solutionGrid }
    // Nombre de coups déjà joués à l'écran (0 = grille de départ). On ouvre sur la grille telle qu'elle a été laissée.
    var index by remember { mutableIntStateOf(playback.moves.size) }
    var playing by remember { mutableStateOf(false) }
    val current = if (index > 0) moves[index - 1] else null
    // Erreurs de la partie (celles comptées en jeu ; en mode validation, les chiffres faux à la fin).
    val mistakes = remember(playback) { maxOf(entry.mistakes, moves.count { playback.isMistake(it, solution) }) }

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
        // Depuis la fin de la partie, on repart de la première erreur.
        val nextMistake = moves.indices.firstOrNull { it >= index && playback.isMistake(moves[it], solution) }
            ?: moves.indices.firstOrNull { playback.isMistake(moves[it], solution) }
        if (nextMistake != null) FilledTonalButton(onClick = { playing = false; index = nextMistake + 1 },
            modifier = Modifier.fillMaxWidth().testTag("playbackNextMistake")) { Text(L("Erreur suivante")) }

        // Résultat de la partie, puis ce qu'on peut faire de cette grille.
        Column(Modifier.fillMaxWidth().card(p).padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            val parts = arrayListOf(GameMode.title(entry.mode, entry.puzzleCode, entry.levelValue), "⏱ ${clock(entry.seconds)}",
                L("%lld erreurs", mistakes), ShareContent.hintsText(entry.hints, entry.hintsEnabled))
            if (entry.failed) parts.add(1, L("Ratée"))
            if (entry.isAbandoned) parts.add(1, L("Abandonnée"))
            entry.score?.let { parts.add(L("%@ pts", ScoreText.points(it.total))) }
            Text(parts.joinToString(" · "), color = if (entry.failed) p.error else p.secondaryText, fontWeight = FontWeight.SemiBold,
                style = MaterialTheme.typography.bodyMedium, modifier = Modifier.testTag("playbackSummary"))
            if (!entry.isAbandoned) FilledTonalButton(onClick = { router.play { model.replay(entry) } }, modifier = Modifier.fillMaxWidth()) {
                Text(L("Rejouer cette grille"))
            }
            FilledTonalButton(onClick = {
                // Le bac à sable s'ouvre sur les chiffres de départ de cette grille, pour l'analyser.
                context.getSharedPreferences("creator", android.content.Context.MODE_PRIVATE).edit().putString("draft", playback.givens).apply()
                router.push(Route.CREATOR)
            }, modifier = Modifier.fillMaxWidth().testTag("playbackSandbox")) { Text(L("Ouvrir dans le bac à sable")) }
        }
    }
}