package com.alexafer.sudokuno.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.rounded.ArrowBack
import androidx.compose.material.icons.automirrored.rounded.KeyboardArrowRight
import androidx.compose.material.icons.rounded.AcUnit
import androidx.compose.material.icons.rounded.BarChart
import androidx.compose.material.icons.rounded.CalendarMonth
import androidx.compose.material.icons.rounded.CheckCircle
import androidx.compose.material.icons.rounded.EditNote
import androidx.compose.material.icons.rounded.EmojiEvents
import androidx.compose.material.icons.rounded.History
import androidx.compose.material.icons.rounded.LocalFireDepartment
import androidx.compose.material.icons.rounded.Lock
import androidx.compose.material.icons.rounded.PlayArrow
import androidx.compose.material.icons.rounded.Settings
import androidx.compose.material.icons.rounded.Tag
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LargeTopAppBar
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.alexafer.sudokuno.i18n.L
import com.alexafer.sudokuno.i18n.L10n
import com.alexafer.sudokuno.kit.DailySchedule
import com.alexafer.sudokuno.kit.Level
import com.alexafer.sudokuno.model.AppModel
import com.alexafer.sudokuno.model.SavedGame
import kotlinx.coroutines.delay
import java.time.format.DateTimeFormatter
import java.time.format.FormatStyle

// --- Composants communs ---

fun Modifier.card(p: Palette): Modifier = this
    .shadow(8.dp, RoundedCornerShape(22.dp), ambientColor = Color.Black.copy(alpha = 0.06f), spotColor = Color.Black.copy(alpha = 0.06f))
    .background(p.card, RoundedCornerShape(22.dp))
    .clip(RoundedCornerShape(22.dp))

@Composable
fun FlameBadge(count: Int, dimmed: Boolean, size: Int = 56) {
    val p = LocalPalette.current
    Box(
        Modifier.size(size.dp).clip(CircleShape)
            .background(if (dimmed) Color.Gray.copy(alpha = 0.18f) else p.flameEnd.copy(alpha = 0.18f)),
        contentAlignment = Alignment.Center,
    ) {
        Icon(Icons.Rounded.LocalFireDepartment, null, Modifier.size((size * 0.55).dp),
            tint = if (dimmed) Color.Gray else p.flameStart)
    }
}

@Composable
fun LevelPill(level: Level) {
    val p = LocalPalette.current
    val tint = level.tint(p.isDark)
    Text(level.displayName, Modifier.background(tint.copy(alpha = 0.16f), RoundedCornerShape(50)).padding(horizontal = 10.dp, vertical = 3.dp),
        color = tint, style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.Bold)
}

/** Écran secondaire avec flèche retour (équivalent d'un écran poussé dans une NavigationStack). */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SubScreen(title: String, router: Router, actions: @Composable () -> Unit = {}, content: @Composable ColumnScope.() -> Unit) {
    val p = LocalPalette.current
    Scaffold(
        containerColor = p.background,
        topBar = {
            TopAppBar(
                title = { Text(title, fontWeight = FontWeight.SemiBold) },
                navigationIcon = { IconButton(onClick = { router.pop() }, Modifier.testTag("back")) { Icon(Icons.AutoMirrored.Rounded.ArrowBack, L("Accueil")) } },
                actions = { actions() },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = p.background),
            )
        },
    ) { pad ->
        Column(
            Modifier.padding(pad).fillMaxSize().verticalScroll(rememberScrollState()).padding(horizontal = 16.dp).padding(bottom = 24.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp),
            content = content,
        )
    }
}

// --- Accueil ---

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(model: AppModel, router: Router) {
    val p = LocalPalette.current
    val state = model.state
    Scaffold(
        containerColor = p.background,
        topBar = {
            LargeTopAppBar(
                title = { Text("Sudokuno", fontWeight = FontWeight.Bold) },
                actions = {
                    IconButton(onClick = { router.push(Route.LEADERBOARD) }) { Icon(Icons.Rounded.EmojiEvents, L("Classements"), tint = p.accent) }
                    IconButton(onClick = { router.push(Route.SETTINGS) }, Modifier.testTag("settingsButton")) { Icon(Icons.Rounded.Settings, L("Réglages"), tint = p.accent) }
                },
                colors = TopAppBarDefaults.largeTopAppBarColors(containerColor = p.background, scrolledContainerColor = p.background),
            )
        },
    ) { pad ->
        Column(
            Modifier.padding(pad).fillMaxSize().verticalScroll(rememberScrollState()),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Column(Modifier.widthIn(max = 640.dp).fillMaxWidth().padding(horizontal = 16.dp).padding(bottom = 24.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)) {
                StreakCard(model) { router.push(Route.STREAK) }
                DailyCard(model, router)
                model.lastInProgress?.let { ContinueCard(model, router, it, model.inProgress.size - 1) }
                Text(L("Niveaux"), style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold, modifier = Modifier.padding(start = 4.dp, top = 4.dp))
                for (level in Level.entries) LevelRow(model, level) { router.play { model.newLevelGame(level) } }
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    Shortcut(L("Créer une grille"), Icons.Rounded.EditNote, Modifier.weight(1f)) { router.push(Route.CREATOR) }
                    Shortcut(L("Entrer un code"), Icons.Rounded.Tag, Modifier.weight(1f)) { router.push(Route.ENTER_CODE) }
                }
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    Shortcut(L("Historique"), Icons.Rounded.History, Modifier.weight(1f)) { router.push(Route.HISTORY) }
                    Shortcut(L("Statistiques"), Icons.Rounded.BarChart, Modifier.weight(1f)) { router.push(Route.STATS) }
                }
            }
        }
    }
    @Suppress("UNUSED_EXPRESSION") state
}

@Composable
private fun StreakCard(model: AppModel, onClick: () -> Unit) {
    val p = LocalPalette.current
    val streak = model.state.streak
    val atRisk = streak.isAtRisk(model.today)
    Row(Modifier.fillMaxWidth().card(p).clickable(onClick = onClick).padding(16.dp).testTag("streakCard"),
        verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(16.dp)) {
        FlameBadge(streak.current, streak.current == 0 || atRisk)
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text(if (streak.current == 0) L("Lance ta série") else L("%lld jours de série", streak.current),
                style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
            Text(when {
                streak.current == 0 -> L("Réussis le Sudoku du jour pour allumer la flamme.")
                atRisk -> L("Fais le Sudoku du jour pour la prolonger !")
                else -> L("Bravo, la flamme est entretenue aujourd'hui.")
            }, color = p.secondaryText, style = MaterialTheme.typography.bodyMedium)
            if (streak.freezes > 0) Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                Icon(Icons.Rounded.AcUnit, null, Modifier.size(14.dp), tint = p.freeze)
                Text(L("%lld gels de série", streak.freezes), color = p.freeze, style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.SemiBold)
            }
        }
        Icon(Icons.AutoMirrored.Rounded.KeyboardArrowRight, null, tint = Color.Gray)
    }
}

@Composable
private fun DailyCard(model: AppModel, router: Router) {
    val p = LocalPalette.current
    val today = model.today
    val level = DailySchedule.level(today)
    val result = model.dailyResult(today)
    val saved = model.savedDaily(today)
    var now by remember { mutableLongStateOf(System.currentTimeMillis()) }
    LaunchedEffect(Unit) { while (true) { delay(30_000); now = System.currentTimeMillis() } }
    val remaining = ((today.nextStartMillis - now) / 1000).coerceAtLeast(0).toInt()

    Column(Modifier.fillMaxWidth().card(p).padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Rounded.CalendarMonth, null, Modifier.size(20.dp))
            Spacer(Modifier.width(8.dp))
            Text(L("Sudoku du jour"), style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold, modifier = Modifier.weight(1f))
            LevelPill(level)
        }
        Text(today.date.format(DateTimeFormatter.ofLocalizedDate(FormatStyle.FULL).withLocale(L10n.locale)).capitalizedFirst(),
            color = p.secondaryText, style = MaterialTheme.typography.bodyMedium)
        if (result?.onTime == true) Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            Icon(Icons.Rounded.CheckCircle, null, tint = p.success, modifier = Modifier.size(18.dp))
            Text(L("Réussi en %@", clock(result.seconds)), color = p.success, fontWeight = FontWeight.SemiBold)
            Text(if (result.hints == 0) L("Sans indice") else "💡 ${result.hints}", color = p.secondaryText)
        }
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(L("Prochaine grille dans %1\$lld h %2\$02lld", remaining / 3600, (remaining % 3600) / 60),
                color = p.secondaryText, style = MaterialTheme.typography.labelMedium, modifier = Modifier.weight(1f))
            if (result?.onTime != true) Button(
                onClick = { router.play { model.dailyGame(today) } },
                colors = ButtonDefaults.buttonColors(containerColor = p.accentStrong),
                modifier = Modifier.testTag("dailyPlay"),
            ) { Text(if (saved == null) L("Jouer") else L("Continuer"), fontWeight = FontWeight.SemiBold) }
        }
    }
}

@Composable
private fun ContinueCard(model: AppModel, router: Router, saved: SavedGame, others: Int) {
    val p = LocalPalette.current
    val tint = saved.levelValue.tint(p.isDark)
    Row(Modifier.fillMaxWidth().card(p).clickable { router.activeGame = model.resume(saved) }.padding(16.dp),
        verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(14.dp)) {
        Box(Modifier.size(44.dp).clip(CircleShape).background(tint.copy(alpha = 0.18f)), contentAlignment = Alignment.Center) {
            Icon(Icons.Rounded.PlayArrow, null, tint = tint)
        }
        Column(Modifier.weight(1f)) {
            Text(L("Reprendre · %@", saved.title), fontWeight = FontWeight.SemiBold)
            Text(L("%lld/81 cases · %@", saved.filledCount, clock(saved.elapsed)), color = p.secondaryText, style = MaterialTheme.typography.bodyMedium)
            if (others > 0) Text(L("+ %lld autres parties en cours", others), color = p.accent, style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.SemiBold)
        }
        Icon(Icons.AutoMirrored.Rounded.KeyboardArrowRight, null, tint = Color.Gray)
    }
}

@Composable
private fun LevelRow(model: AppModel, level: Level, onClick: () -> Unit) {
    val p = LocalPalette.current
    val progress = model.state.progress
    val unlocked = progress.isUnlocked(level)
    val tint = if (unlocked) level.tint(p.isDark) else Color.Gray
    val stats = model.state.stats[level.ordinal]
    Row(Modifier.fillMaxWidth().card(p).clickable(enabled = unlocked, onClick = onClick).padding(16.dp).testTag("level-${level.codeLetter}"),
        verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(14.dp)) {
        Box(Modifier.size(44.dp).clip(RoundedCornerShape(12.dp)).background(tint.copy(alpha = 0.16f)), contentAlignment = Alignment.Center) {
            Icon(if (unlocked) level.icon else Icons.Rounded.Lock, null, tint = tint)
        }
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
            Text(level.displayName, fontWeight = FontWeight.SemiBold)
            val lock = progress.unlockProgress(level)
            val previous = Level.fromOrdinal(level.ordinal - 1)
            if (lock != null && previous != null) {
                Text(L("%1\$lld/%2\$lld victoires en %3\$@ pour débloquer", lock.first, lock.second, previous.displayName),
                    color = p.secondaryText, style = MaterialTheme.typography.labelMedium)
                LinearProgressIndicator(progress = { lock.first.toFloat() / lock.second }, color = previous.tint(p.isDark),
                    modifier = Modifier.fillMaxWidth())
            } else {
                Text(level.summary, color = p.secondaryText, style = MaterialTheme.typography.labelMedium)
            }
        }
        val best = stats?.bestSeconds
        if (unlocked && best != null) Column(horizontalAlignment = Alignment.End) {
            Text(clock(best), fontWeight = FontWeight.SemiBold)
            Text(L("record"), color = p.secondaryText, fontSize = 11.sp)
        }
    }
}

@Composable
private fun Shortcut(title: String, icon: ImageVector, modifier: Modifier, onClick: () -> Unit) {
    val p = LocalPalette.current
    Column(modifier.card(p).clickable(onClick = onClick).padding(16.dp).testTag("shortcut-$title"),
        horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Icon(icon, null, tint = p.accent)
        Text(title, fontWeight = FontWeight.SemiBold, style = MaterialTheme.typography.bodyMedium)
    }
}

fun Modifier.dimmed(on: Boolean) = if (on) alpha(0.35f) else this
