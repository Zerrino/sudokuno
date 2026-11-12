package com.alexafer.sudokuno.ui

import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material3.SegmentedButton
import com.alexafer.sudokuno.kit.DailySchedule
import com.alexafer.sudokuno.kit.Grader
import androidx.compose.material.icons.rounded.EditNote
import androidx.compose.material.icons.rounded.Inbox
import androidx.compose.material.icons.rounded.Delete
import androidx.compose.material.icons.rounded.Share
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.setValue
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.unit.dp
import com.alexafer.sudokuno.i18n.L
import com.alexafer.sudokuno.kit.Level
import com.alexafer.sudokuno.kit.PuzzleCode
import com.alexafer.sudokuno.model.AppModel
import com.alexafer.sudokuno.model.GameMode
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/** « Mes grilles » : grilles créées avec l'éditeur et grilles reçues par lien ou par code (MyGridsView.swift). */
@OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class)
@Composable
fun MyGridsScreen(model: AppModel, router: Router) {
    val p = LocalPalette.current
    val context = LocalContext.current
    var received by remember { mutableStateOf(false) }
    val records = if (received) model.state.receivedGrids else model.state.createdGrids
    // Niveau des grilles créées, calculé en arrière-plan.
    val levels = remember { androidx.compose.runtime.mutableStateMapOf<String, Level>() }
    LaunchedEffect(received, records.size) {
        for (r in records.toList()) {
            val c = r.puzzleCode as? PuzzleCode.Custom ?: continue
            if (r.code !in levels) levels[r.code] = kotlinx.coroutines.withContext(kotlinx.coroutines.Dispatchers.Default) { Grader.grade(c.grid) }
        }
    }
    fun levelOf(code: PuzzleCode, key: String): Level? = when (code) {
        is PuzzleCode.Custom -> levels[key]
        is PuzzleCode.Daily -> DailySchedule.level(code.day)
        else -> code.level
    }
    SubScreen(L("Mes grilles"), router) {
        androidx.compose.material3.SingleChoiceSegmentedButtonRow(Modifier.fillMaxWidth().testTag("myGridsTabs")) {
            listOf(false to L("Créées"), true to L("Reçues")).forEachIndexed { i, (value, label) ->
                SegmentedButton(
                    selected = received == value, onClick = { received = value },
                    shape = androidx.compose.material3.SegmentedButtonDefaults.itemShape(i, 2),
                ) { Text(label) }
            }
        }
        SectionCard {
            if (records.isEmpty()) Text(
                if (received) L("Les grilles reçues par lien ou par code apparaîtront ici.") else L("Aucune grille créée. Crée la tienne avec l'éditeur !"),
                color = p.secondaryText, modifier = Modifier.padding(vertical = 10.dp))
            records.toList().forEachIndexed { k, record ->
                val code = record.puzzleCode ?: return@forEachIndexed
                if (k > 0) HorizontalDivider()
                val level = levelOf(code, record.code)
                val status = when {
                    model.isInProgress(record.code) -> L("En cours")
                    model.bestTime(record.code) != null -> L("Résolue · %@", clock(model.bestTime(record.code)!!))
                    else -> L("Pas encore jouée")
                }
                HistoryRow(GameMode.title(GameMode.Shared(null), code, level ?: Level.FACILE), level ?: Level.FACILE, status, record.date,
                    if (received) Icons.Rounded.Inbox else Icons.Rounded.EditNote, if (level == null) Color.Gray else null,
                    onClick = { router.play { model.openGrid(code) } },
                    trailing = {
                        IconButton(onClick = { ShareContent.share(context, ShareContent.inviteMessage(code, (level ?: Level.FACILE).displayName)) }) {
                            Icon(Icons.Rounded.Share, L("Partager cette grille"), tint = p.secondaryText) }
                        IconButton(onClick = { model.forget(record, received) }) { Icon(Icons.Rounded.Delete, L("Supprimer"), tint = p.secondaryText) }
                    })
            }
        }
    }
}
