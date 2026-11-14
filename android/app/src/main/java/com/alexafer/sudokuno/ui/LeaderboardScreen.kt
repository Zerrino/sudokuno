package com.alexafer.sudokuno.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.EmojiEvents
import androidx.compose.material.icons.rounded.LocalFireDepartment
import androidx.compose.material.icons.rounded.Lock
import androidx.compose.material3.Button
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.rememberScrollState
import androidx.compose.ui.layout.layout
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.setValue
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.alexafer.sudokuno.i18n.L
import com.alexafer.sudokuno.kit.Level
import com.alexafer.sudokuno.model.AppModel
import com.alexafer.sudokuno.services.LeaderboardId
import com.alexafer.sudokuno.services.LeaderboardRow

// --- Classements ---

@Composable
fun LeaderboardScreen(model: AppModel, router: Router) {
    val p = LocalPalette.current
    val gs = model.gameServices
    // (identifiant, libellé court de l'onglet, titre complet)
    val boards = listOf(
        Triple(LeaderboardId.DAILY, L("Du jour"), L("Du jour")),
        Triple(LeaderboardId.BEST, L("Meilleure partie"), L("Meilleure partie")),
        Triple(LeaderboardId.TOTAL, L("Total des scores"), L("Total des scores")),
    ) + Level.entries.map { Triple(LeaderboardId.level(it), it.displayName, L("Record %@", it.displayName)) } +
        Triple(LeaderboardId.STREAK, L("Plus longue série"), L("Plus longue série"))
    var board by remember { mutableStateOf(boards[0]) }
    var rows by remember { mutableStateOf<List<LeaderboardRow>?>(null) }
    var mine by remember { mutableStateOf<LeaderboardRow?>(null) }
    LaunchedEffect(board, gs.isAuthenticated) {
        rows = null; mine = null
        val top = gs.loadTop(board.first, model.today)
        mine = gs.loadMine(board.first, model.today)
        rows = top
    }
    val daily = board.first == LeaderboardId.DAILY
    val streak = board.first == LeaderboardId.STREAK
    val total = board.first == LeaderboardId.TOTAL

    SubScreen(L("Classements"), router) {
        // Onglets défilants, qui débordent jusqu'aux bords de l'écran.
        Row(
            Modifier.layout { m, c ->
                val extra = 16.dp.roundToPx()
                val pl = m.measure(c.copy(maxWidth = c.maxWidth + 2 * extra))
                layout(c.maxWidth, pl.height) { pl.place(-extra, 0) }
            }.horizontalScroll(rememberScrollState()).padding(horizontal = 16.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            boards.forEach { b ->
                val selected = b == board
                Text(
                    b.second, maxLines = 1,
                    color = if (selected) Color.White else p.given,
                    fontWeight = if (selected) FontWeight.SemiBold else FontWeight.Medium,
                    style = MaterialTheme.typography.labelLarge,
                    modifier = Modifier.clip(CircleShape).background(if (selected) p.accentStrong else p.card)
                        .clickable { board = b }.padding(horizontal = 16.dp, vertical = 10.dp).testTag("board-${b.first}"),
                )
            }
        }

        Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Column(Modifier.fillMaxWidth().card(p).padding(8.dp)) {
                Row(Modifier.fillMaxWidth().padding(start = 8.dp, end = 8.dp, top = 6.dp, bottom = 8.dp), verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Icon(if (streak) Icons.Rounded.LocalFireDepartment else Icons.Rounded.EmojiEvents, null,
                        tint = if (streak) p.flameStart else p.flameEnd, modifier = Modifier.size(22.dp))
                    Text(board.third, fontWeight = FontWeight.Bold, style = MaterialTheme.typography.titleMedium)
                }
                val list = rows
                when {
                    !gs.isAuthenticated -> BoardMessage(Icons.Rounded.Lock, L("Connecte-toi à Google Play Jeux pour voir les classements.")) {
                        if (gs.isConfigured) Button(onClick = { gs.signIn() }) { Text(L("Google Play Jeux")) }
                        if (gs.signInFailed) Text(L("Connexion à Google Play Jeux impossible pour le moment. Réessaie plus tard."),
                            color = p.error, style = MaterialTheme.typography.labelMedium, textAlign = TextAlign.Center)
                    }
                    list == null -> Box(Modifier.fillMaxWidth().padding(vertical = 36.dp), contentAlignment = Alignment.Center) {
                        CircularProgressIndicator(Modifier.size(28.dp), color = p.accent, strokeWidth = 3.dp)
                    }
                    list.isEmpty() && mine == null -> BoardMessage(Icons.Rounded.EmojiEvents, L("Aucun score pour l'instant. Sois le premier !"))
                    else -> {
                        list.forEach { BoardRow(it, streak, total) }
                        mine?.takeIf { m -> list.none { it.isMe } }?.let { m ->
                            if (list.isNotEmpty()) Text("⋯", Modifier.fillMaxWidth(), color = p.secondaryText, textAlign = TextAlign.Center)
                            BoardRow(m, streak, total)
                            // Absent de la liste publique alors que son rang devrait y figurer : profil Play Jeux non public.
                            if (list.size < 50 || m.rank in 1..list.size.toLong()) Text(
                                L("Les autres joueurs ne te voient pas : dans Google Play Jeux, ouvre ton profil › Paramètres et rends ton activité de jeu visible par tout le monde."),
                                color = p.flameStart, style = MaterialTheme.typography.labelMedium,
                                modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp).testTag("privateProfile"))
                        }
                    }
                }
            }
            if (!streak) Text(L("Classement au score : chaque chiffre rapporte selon la technique qu'il demandait et le temps mis à le trouver."),
                color = p.secondaryText, style = MaterialTheme.typography.labelMedium, modifier = Modifier.padding(horizontal = 8.dp))
            if (!streak && !total) Text(L("Seules les grilles parfaites sont classées : sans indice, sans erreur et du premier coup."), color = p.secondaryText,
                style = MaterialTheme.typography.labelMedium, modifier = Modifier.padding(horizontal = 8.dp).testTag("rankedRule"))
            if (total) Text(L("Le meilleur score de chaque grille réussie, additionné."), color = p.secondaryText,
                style = MaterialTheme.typography.labelMedium, modifier = Modifier.padding(horizontal = 8.dp))
            if (daily) Text(L("Remis à zéro chaque jour à minuit UTC, avec la grille du jour."), color = p.secondaryText,
                style = MaterialTheme.typography.labelMedium, modifier = Modifier.padding(horizontal = 8.dp))
        }

        if (gs.isAuthenticated) SectionCard {
            ChevronRow(L("Ouvrir Google Play Jeux")) { gs.showAllLeaderboards() }
            HorizontalDivider(color = p.gridLine.copy(alpha = 0.5f))
            ChevronRow(L("Voir mes succès")) { gs.showAchievements() }
        }
    }
}

/** Ligne d'un classement : médaille ou rang, joueur (et indices utilisés), score. */
@Composable
private fun BoardRow(r: LeaderboardRow, streak: Boolean, total: Boolean) {
    val p = LocalPalette.current
    val medal = when (r.rank) { 1L -> Color(0xFFE2A300); 2L -> Color(0xFF8E97A8); 3L -> Color(0xFFBF7A45); else -> null }
    Row(
        Modifier.fillMaxWidth().clip(RoundedCornerShape(14.dp)).background(if (r.isMe) p.accent.copy(alpha = 0.12f) else Color.Transparent)
            .padding(horizontal = 8.dp, vertical = 9.dp),
        verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Box(Modifier.size(32.dp).background(medal ?: Color.Transparent, CircleShape), contentAlignment = Alignment.Center) {
            Text(if (r.rank > 0) "${r.rank}" else "–", fontWeight = FontWeight.Bold, maxLines = 1,
                color = if (medal != null) Color.White else p.secondaryText,
                style = if (r.rank > 99) MaterialTheme.typography.labelMedium else MaterialTheme.typography.bodyMedium)
        }
        Column(Modifier.weight(1f)) {
            Text(r.name, fontWeight = if (r.isMe) FontWeight.Bold else FontWeight.Medium, maxLines = 1, overflow = TextOverflow.Ellipsis,
                color = if (r.isMe) p.accent else p.given)
            if (!streak && !total) r.tag?.let {
                Text(ShareContent.hintsText(it.hints, it.hintsEnabled), color = p.secondaryText, style = MaterialTheme.typography.labelMedium, maxLines = 1)
            }
        }
        val number = MaterialTheme.typography.titleMedium.copy(fontFeatureSettings = "tnum", fontWeight = FontWeight.Bold)
        if (streak) {
            Icon(Icons.Rounded.LocalFireDepartment, null, tint = p.flameStart, modifier = Modifier.size(20.dp))
            Text("${r.value}", style = number)
        } else Text(L("%@ pts", ScoreText.points(r.value.toInt())), style = number)
    }
}

@Composable
private fun BoardMessage(icon: androidx.compose.ui.graphics.vector.ImageVector, text: String, extra: @Composable ColumnScope.() -> Unit = {}) {
    val p = LocalPalette.current
    Column(Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 28.dp), horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Icon(icon, null, tint = p.secondaryText.copy(alpha = 0.6f), modifier = Modifier.size(40.dp))
        Text(text, color = p.secondaryText, textAlign = TextAlign.Center)
        extra()
    }
}
