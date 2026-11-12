package com.alexafer.sudokuno.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.AutoFixHigh
import androidx.compose.material.icons.rounded.CheckCircle
import androidx.compose.material.icons.rounded.ContentCopy
import androidx.compose.material.icons.rounded.Error
import androidx.compose.material.icons.rounded.HourglassEmpty
import androidx.compose.material.icons.rounded.PlayArrow
import androidx.compose.material.icons.rounded.Share
import androidx.compose.material.icons.rounded.Backspace
import androidx.compose.material.icons.rounded.CallSplit
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.setValue
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import kotlinx.coroutines.launch
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.alexafer.sudokuno.i18n.L
import com.alexafer.sudokuno.kit.Grid
import com.alexafer.sudokuno.kit.PuzzleAnalysis
import com.alexafer.sudokuno.kit.PuzzleCode
import com.alexafer.sudokuno.kit.Sudoku
import com.alexafer.sudokuno.model.AppModel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.withContext

// --- Créateur ---

@Composable
fun CreatorScreen(model: AppModel, router: Router) {
    val p = LocalPalette.current
    val context = LocalContext.current
    val clipboard = LocalClipboardManager.current
    val prefs = remember { context.getSharedPreferences("creator", android.content.Context.MODE_PRIVATE) }
    val cells = remember { androidx.compose.runtime.mutableStateListOf<Int>().apply {
        addAll((Grid.parse(prefs.getString("draft", "") ?: "") ?: Grid()).cells.toList())
    } }
    var selected by remember { mutableIntStateOf(0) }
    var analysis by remember { mutableStateOf<PuzzleAnalysis?>(null) }
    var confirmClear by remember { mutableStateOf(false) }
    var savedNotice by remember { mutableStateOf(false) }
    // Chiffres qu'on peut retirer sans perdre l'unicité (calculé en arrière-plan quand la grille est valide).
    var redundant by remember { mutableStateOf<List<Int>>(emptyList()) }
    var showRedundant by remember { mutableStateOf(false) }
    var completing by remember { mutableStateOf(false) }
    val scope = androidx.compose.runtime.rememberCoroutineScope()

    // Analyse relancée à chaque modification de la grille (la plus récente gagne).
    LaunchedEffect(Unit) {
        androidx.compose.runtime.snapshotFlow { cells.toList() }.collectLatest { list ->
            val grid = Grid(list.toIntArray())
            prefs.edit().putString("draft", grid.string).apply()
            val result = withContext(Dispatchers.Default) { PuzzleAnalysis.analyze(grid) }
            analysis = result
            redundant = emptyList()
            if (!result.isPlayable) { showRedundant = false; return@collectLatest }
            redundant = withContext(Dispatchers.Default) { PuzzleAnalysis.redundantClues(grid) }
            if (redundant.isEmpty()) showRedundant = false
        }
    }
    val conflicts = (analysis?.status as? PuzzleAnalysis.Status.Conflict)?.cells?.toSet() ?: emptySet()

    SubScreen(L("Créer une grille"), router, actions = {
        TextButton(onClick = { confirmClear = true }) { Text(L("Tout effacer")) }
    }) {
        BoardFrame { i, cell ->
            val sel = selected
            CellView(cells[i], 0, true, i in conflicts, { pal ->
                when {
                    sel == i -> pal.selection
                    i in conflicts -> pal.errorFill
                    cells[sel] != 0 && cells[i] == cells[sel] -> pal.sameDigit
                    Sudoku.row(i) == Sudoku.row(sel) || Sudoku.col(i) == Sudoku.col(sel) || Sudoku.box(i) == Sudoku.box(sel) -> pal.related
                    else -> Color.Transparent
                }
            }, cell, Modifier.alpha(if (showRedundant && i in redundant) 0.35f else 1f).clickable { selected = i }.testTag("create-$i"))
        }
        Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
            for (d in 1..9) Box(Modifier.weight(1f).height(50.dp).clip(RoundedCornerShape(12.dp)).background(p.card)
                .clickable { cells[selected] = if (cells[selected] == d) 0 else d }.testTag("createKey-$d"), contentAlignment = Alignment.Center) {
                Text("$d", fontSize = 24.sp, fontWeight = FontWeight.SemiBold, color = p.entry)
            }
        }
        FilledTonalButton(onClick = { cells[selected] = 0 }, modifier = Modifier.fillMaxWidth()) {
            Icon(Icons.Rounded.Backspace, null); Spacer(Modifier.width(6.dp)); Text(L("Effacer"))
        }
        // Analyse
        Column(Modifier.fillMaxWidth().card(p).padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Row { Text(L("Analyse"), Modifier.weight(1f), fontWeight = FontWeight.SemiBold)
                Text(L("%lld chiffres", cells.count { it != 0 }), color = p.secondaryText) }
            when (val st = analysis?.status) {
                null -> Text("…")
                is PuzzleAnalysis.Status.Conflict -> StatusLine(L("Conflit : un chiffre apparaît deux fois dans une ligne, une colonne ou un bloc."), Icons.Rounded.Error, p.error)
                PuzzleAnalysis.Status.NoSolution -> StatusLine(L("Aucune solution : cette grille est impossible. Retire ou change un chiffre."), Icons.Rounded.Error, p.error)
                PuzzleAnalysis.Status.Undetermined -> StatusLine(L("Pas encore assez de chiffres pour conclure. Continue à remplir."), Icons.Rounded.HourglassEmpty, p.secondaryText)
                is PuzzleAnalysis.Status.MultipleSolutions -> {
                    StatusLine(L("Plusieurs solutions possibles : ajoute des chiffres pour qu'il n'y en ait qu'une."), Icons.Rounded.CallSplit, p.flameEnd)
                    FilledTonalButton(onClick = { cells[st.suggestion.cell] = st.suggestion.digit; selected = st.suggestion.cell },
                        modifier = Modifier.testTag("addSuggestion")) {
                        Icon(Icons.Rounded.AutoFixHigh, null); Spacer(Modifier.width(6.dp)); Text(L("Ajouter un chiffre suggéré"))
                    }
                    FilledTonalButton(enabled = !completing, modifier = Modifier.testTag("autoComplete"), onClick = {
                        completing = true
                        val before = cells.toList()
                        scope.launch {
                            val done = withContext(Dispatchers.Default) { PuzzleAnalysis.completed(Grid(before.toIntArray())) }
                            completing = false
                            if (done != null && cells.toList() == before) for (i in 0 until 81) cells[i] = done[i]
                        }
                    }) { Text(L("Compléter automatiquement")) }
                }
                is PuzzleAnalysis.Status.Unique -> {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Box(Modifier.weight(1f).testTag("validPuzzle")) { StatusLine(L("Grille valide : solution unique"), Icons.Rounded.CheckCircle, p.success) }
                        LevelPill(st.level)
                    }
                    Text(st.hardest?.let { L("Technique la plus difficile : %@", it.displayName) } ?: L("Demande des techniques au-delà des classiques."),
                        color = p.secondaryText, style = MaterialTheme.typography.bodyMedium)
                    // Conseils de créateur : chiffres en trop et symétrie du motif.
                    if (redundant.isEmpty()) {
                        Text(L("Grille minimale : aucun chiffre en trop."), color = p.secondaryText, style = MaterialTheme.typography.bodyMedium)
                    } else Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(L("%@ chiffres peuvent être retirés sans changer la solution.", "${redundant.size}"), Modifier.weight(1f),
                            color = p.secondaryText, style = MaterialTheme.typography.bodyMedium)
                        TextButton(onClick = { showRedundant = !showRedundant }, modifier = Modifier.testTag("showRedundant")) {
                            Text(if (showRedundant) L("Masquer") else L("Voir"))
                        }
                    }
                    if (PuzzleAnalysis.isSymmetric(Grid(cells.toIntArray()))) Text(L("Motif symétrique, comme les grilles des créateurs."),
                        color = p.secondaryText, style = MaterialTheme.typography.bodyMedium)
                    FilledTonalButton(onClick = { router.explain(Grid(cells.toIntArray())) }, modifier = Modifier.testTag("explainCustom")) {
                        Text(L("Voir la résolution expliquée"))
                    }
                }
            }
            // Avec 7 chiffres différents ou moins, deux chiffres absents peuvent toujours s'échanger.
            if (cells.count { it != 0 } >= 17 && cells.filter { it != 0 }.distinct().size < 8)
                Text(L("Utilise au moins 8 chiffres différents : avec moins, il y a forcément plusieurs solutions."),
                    color = p.secondaryText, style = MaterialTheme.typography.labelMedium)
            if (cells.count { it != 0 } < 17) Text(L("Il faut au moins 17 chiffres pour qu'une grille ait une solution unique."),
                color = p.secondaryText, style = MaterialTheme.typography.labelMedium)
        }
        val unique = analysis?.status as? PuzzleAnalysis.Status.Unique
        if (unique != null) {
            val code = PuzzleCode.Custom(Grid(cells.toIntArray()))
            Column(Modifier.fillMaxWidth().card(p).padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Text(L("Code de ta grille"), fontWeight = FontWeight.SemiBold)
                Text(code.string, fontFamily = FontFamily.Monospace, style = MaterialTheme.typography.bodySmall, modifier = Modifier.testTag("customCode"))
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    Button(onClick = { model.recordCreated(code); ShareContent.share(context, ShareContent.inviteMessage(code, unique.level.displayName)) },
                        colors = ButtonDefaults.buttonColors(containerColor = p.accentStrong), modifier = Modifier.weight(1f)) {
                        Icon(Icons.Rounded.Share, null); Spacer(Modifier.width(6.dp)); Text(L("Partager"))
                    }
                    FilledTonalButton(onClick = { model.recordCreated(code); clipboard.setText(AnnotatedString(code.string)) }, modifier = Modifier.weight(1f)) {
                        Icon(Icons.Rounded.ContentCopy, null); Spacer(Modifier.width(6.dp)); Text(L("Copier"))
                    }
                }
                FilledTonalButton(onClick = { model.recordCreated(code); router.play { model.sharedGame(code, null) } }, modifier = Modifier.fillMaxWidth().testTag("playCustom")) {
                    Icon(Icons.Rounded.PlayArrow, null); Spacer(Modifier.width(6.dp)); Text(L("Jouer cette grille"))
                }
                Button(onClick = {
                    // Terminé : la grille rejoint « Mes grilles » et l'éditeur repart d'une grille vide.
                    model.recordCreated(code)
                    for (i in 0 until 81) cells[i] = 0
                    selected = 0
                    savedNotice = true
                }, colors = ButtonDefaults.buttonColors(containerColor = p.accentStrong), modifier = Modifier.fillMaxWidth().testTag("creatorDone")) {
                    Icon(Icons.Rounded.CheckCircle, null); Spacer(Modifier.width(6.dp)); Text(L("Terminé"))
                }
                Text(L("Le code contient toute ta grille : tes amis retrouvent exactement la même, même hors ligne."),
                    color = p.secondaryText, style = MaterialTheme.typography.labelMedium)
            }
        }
    }
    if (savedNotice) AlertDialog(
        onDismissRequest = { savedNotice = false },
        title = { Text(L("Grille enregistrée")) },
        text = { Text(L("Tu la retrouves dans Mes grilles. Tu peux en créer une nouvelle.")) },
        confirmButton = { TextButton(onClick = { savedNotice = false }, modifier = Modifier.testTag("savedOk")) { Text(L("OK")) } },
    )
    if (confirmClear) AlertDialog(
        onDismissRequest = { confirmClear = false },
        title = { Text(L("Effacer toute la grille ?")) },
        confirmButton = { TextButton(onClick = { confirmClear = false; for (i in 0 until 81) cells[i] = 0; selected = 0 }) { Text(L("Tout effacer"), color = p.error) } },
        dismissButton = { TextButton(onClick = { confirmClear = false }) { Text(L("Annuler")) } },
    )
}
