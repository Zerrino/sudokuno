package com.alexafer.sudokuno.ui

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.rounded.KeyboardArrowLeft
import androidx.compose.material.icons.automirrored.rounded.KeyboardArrowRight
import androidx.compose.material.icons.rounded.AcUnit
import androidx.compose.material3.SegmentedButton
import com.alexafer.sudokuno.kit.DailySchedule
import com.alexafer.sudokuno.kit.Grader
import androidx.compose.material.icons.rounded.EditNote
import androidx.compose.material.icons.rounded.Inbox
import androidx.compose.material.icons.rounded.AutoFixHigh
import androidx.compose.material.icons.rounded.CalendarMonth
import androidx.compose.material.icons.rounded.CheckCircle
import androidx.compose.material.icons.rounded.ContentCopy
import androidx.compose.material.icons.rounded.ContentPaste
import androidx.compose.material.icons.rounded.Delete
import androidx.compose.material.icons.rounded.EmojiEvents
import androidx.compose.material.icons.rounded.Error
import androidx.compose.material.icons.rounded.Favorite
import androidx.compose.material.icons.rounded.Flag
import androidx.compose.material.icons.rounded.HourglassEmpty
import androidx.compose.material.icons.rounded.LocalFireDepartment
import androidx.compose.material.icons.rounded.Lock
import androidx.compose.material.icons.rounded.PlayArrow
import androidx.compose.material.icons.rounded.Share
import androidx.compose.material.icons.rounded.Backspace
import androidx.compose.material.icons.rounded.CallSplit
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Switch
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
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.alexafer.sudokuno.i18n.AppLanguage
import com.alexafer.sudokuno.i18n.L
import com.alexafer.sudokuno.i18n.L10n
import com.alexafer.sudokuno.kit.DayStamp
import com.alexafer.sudokuno.kit.Grid
import com.alexafer.sudokuno.kit.Legends
import com.alexafer.sudokuno.kit.Level
import com.alexafer.sudokuno.kit.PuzzleAnalysis
import com.alexafer.sudokuno.kit.PuzzleCode
import com.alexafer.sudokuno.kit.StreakState
import com.alexafer.sudokuno.kit.Sudoku
import com.alexafer.sudokuno.model.AppModel
import com.alexafer.sudokuno.model.AppTheme
import com.alexafer.sudokuno.model.GameMode
import com.alexafer.sudokuno.model.HistoryEntry
import com.alexafer.sudokuno.model.LevelStats
import com.alexafer.sudokuno.services.LeaderboardId
import com.alexafer.sudokuno.services.LeaderboardRow
import com.alexafer.sudokuno.services.Reminder
import com.alexafer.sudokuno.services.TipJar
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.withContext
import java.time.YearMonth
import java.time.format.DateTimeFormatter
import java.time.format.FormatStyle
import java.time.format.TextStyle

const val SITE_URL = "https://zerrino.github.io/sudokuno/"
const val PRIVACY_URL = "https://zerrino.github.io/sudokuno/privacy.html"
const val LEGAL_URL = "https://zerrino.github.io/sudokuno/legal.html"

@Composable
private fun SectionCard(title: String? = null, footer: String? = null, content: @Composable ColumnScope.() -> Unit) {
    val p = LocalPalette.current
    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
        title?.let { Text(it, color = p.secondaryText, style = MaterialTheme.typography.labelLarge, modifier = Modifier.padding(start = 8.dp)) }
        Column(Modifier.fillMaxWidth().card(p).padding(horizontal = 16.dp, vertical = 6.dp), content = content)
        footer?.let { Text(it, color = p.secondaryText, style = MaterialTheme.typography.labelMedium, modifier = Modifier.padding(horizontal = 8.dp)) }
    }
}

@Composable
private fun LabeledRow(label: String, value: String) {
    Row(Modifier.fillMaxWidth().padding(vertical = 10.dp), verticalAlignment = Alignment.CenterVertically) {
        Text(label, Modifier.weight(1f))
        Text(value, color = LocalPalette.current.secondaryText, fontWeight = FontWeight.Medium)
    }
}

@Composable
private fun ToggleRow(label: String, checked: Boolean, onChange: (Boolean) -> Unit) {
    Row(Modifier.fillMaxWidth().padding(vertical = 4.dp), verticalAlignment = Alignment.CenterVertically) {
        Text(label, Modifier.weight(1f))
        Switch(checked = checked, onCheckedChange = onChange)
    }
}

@Composable
private fun LinkRow(label: String, tag: String? = null, onClick: () -> Unit) {
    Text(label, color = LocalPalette.current.accent, modifier = Modifier.fillMaxWidth().clickable(onClick = onClick).padding(vertical = 12.dp)
        .let { if (tag != null) it.testTag(tag) else it })
}

// --- Série ---

@Composable
fun StreakScreen(model: AppModel, router: Router) {
    val p = LocalPalette.current
    val streak = model.state.streak
    SubScreen(L("Série"), router) {
        Column(Modifier.fillMaxWidth(), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(6.dp)) {
            FlameBadge(streak.current, streak.current == 0, 110)
            Text("${streak.current}", fontSize = 56.sp, fontWeight = FontWeight.ExtraBold)
            Text(L("Série en cours"), color = p.secondaryText, fontWeight = FontWeight.SemiBold)
        }
        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            Tile("${streak.longest}", L("Record"), Icons.Rounded.EmojiEvents, p.flameEnd, Modifier.weight(1f))
            Tile("${streak.freezes}/${StreakState.MAX_FREEZES}", L("Gels"), Icons.Rounded.AcUnit, p.freeze, Modifier.weight(1f))
            Tile("${streak.completedDays.size}", L("Grilles du jour"), Icons.Rounded.CalendarMonth, p.accent, Modifier.weight(1f))
        }
        Text(L("Tu gagnes un gel tous les %1\$lld jours de série (%2\$lld au maximum). Un gel protège ta série si tu oublies un jour.",
            StreakState.DAYS_PER_FREEZE, StreakState.MAX_FREEZES), color = p.secondaryText, style = MaterialTheme.typography.bodySmall)
        Text(L("Jalons"), fontWeight = FontWeight.SemiBold)
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            for (m in StreakState.MILESTONES.take(5)) {
                val reached = streak.longest >= m
                Column(Modifier.weight(1f).background(p.card, RoundedCornerShape(14.dp)).padding(vertical = 10.dp),
                    horizontalAlignment = Alignment.CenterHorizontally) {
                    Icon(Icons.Rounded.LocalFireDepartment, null, tint = if (reached) p.flameStart else Color.Gray)
                    Text(L("%lld j", m), fontWeight = FontWeight.Bold, style = MaterialTheme.typography.labelMedium)
                }
            }
        }
        Calendar(model, router)
    }
}

@Composable
private fun Tile(value: String, label: String, icon: androidx.compose.ui.graphics.vector.ImageVector, color: Color, modifier: Modifier) {
    val p = LocalPalette.current
    Column(modifier.card(p).padding(vertical = 14.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(4.dp)) {
        Icon(icon, null, tint = color)
        Text(value, fontWeight = FontWeight.Bold, fontSize = 20.sp)
        Text(label, color = p.secondaryText, style = MaterialTheme.typography.labelSmall)
    }
}

private val FIRST_DAY = DayStamp.of(2026, 11, 1)!!

@Composable
private fun Calendar(model: AppModel, router: Router) {
    val p = LocalPalette.current
    val today = model.today
    var offset by remember { mutableIntStateOf(0) }
    val ym = YearMonth.from(today.date).plusMonths(offset.toLong())
    val first = DayStamp(ym.atDay(1).toEpochDay().toInt())
    val streak = model.state.streak
    Column(Modifier.fillMaxWidth().card(p).padding(14.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            IconButton(onClick = { offset-- }, enabled = first > FIRST_DAY) { Icon(Icons.AutoMirrored.Rounded.KeyboardArrowLeft, null) }
            Text(ym.month.getDisplayName(TextStyle.FULL_STANDALONE, L10n.locale).capitalizedFirst() + " " + ym.year,
                Modifier.weight(1f), fontWeight = FontWeight.SemiBold, textAlign = androidx.compose.ui.text.style.TextAlign.Center)
            IconButton(onClick = { offset++ }, enabled = offset < 0) { Icon(Icons.AutoMirrored.Rounded.KeyboardArrowRight, null) }
        }
        val days = (1..7).map { java.time.DayOfWeek.of(it).getDisplayName(TextStyle.NARROW_STANDALONE, L10n.locale) }
        val cells: List<Int?> = List(first.weekday) { null } + (1..ym.lengthOfMonth()).toList()
        Row { days.forEach { Text(it, Modifier.weight(1f), color = p.secondaryText, fontWeight = FontWeight.Bold,
            textAlign = androidx.compose.ui.text.style.TextAlign.Center, style = MaterialTheme.typography.labelMedium) } }
        cells.chunked(7).forEach { week ->
            Row {
                for (k in 0 until 7) {
                    val d = week.getOrNull(k)
                    Box(Modifier.weight(1f).aspectRatio(1f).padding(3.dp), contentAlignment = Alignment.Center) {
                        if (d != null) {
                            val day = DayStamp(ym.atDay(d).toEpochDay().toInt())
                            val done = streak.isCompleted(day)
                            val frozen = day in streak.frozenDays
                            val playable = day >= FIRST_DAY && day <= today
                            val label = when { done -> L("%lld, réussi", d); frozen -> L("%lld, gelé", d); else -> L("%lld, non joué", d) }
                            Box(Modifier.fillMaxWidth().aspectRatio(1f).clip(CircleShape)
                                .then(if (done) Modifier.background(p.flame) else if (frozen) Modifier.background(p.freeze.copy(alpha = 0.25f)) else Modifier)
                                .then(if (day == today && !done) Modifier.border(2.dp, p.accent, CircleShape) else Modifier)
                                .clickable(enabled = playable) { router.play { model.dailyGame(day) } }
                                .semantics { contentDescription = label },
                                contentAlignment = Alignment.Center) {
                                if (frozen && !done) Icon(Icons.Rounded.AcUnit, null, Modifier.size(14.dp), tint = p.freeze)
                                else Text("$d", color = if (done) Color.White else if (playable) MaterialTheme.colorScheme.onSurface else Color.Gray,
                                    fontWeight = if (done) FontWeight.Bold else FontWeight.Normal, style = MaterialTheme.typography.bodyMedium)
                            }
                        }
                    }
                }
            }
        }
        Text(L("Touche un jour passé pour rejouer sa grille (sans effet sur la série)."), color = p.secondaryText, style = MaterialTheme.typography.labelSmall)
    }
}

// --- Statistiques ---

@Composable
fun StatsScreen(model: AppModel, router: Router) {
    val state = model.state
    SubScreen(L("Statistiques"), router) {
        val results = state.dailyResults.values.filter { it.onTime }
        SectionCard(L("Sudoku du jour")) {
            LabeledRow(L("Grilles réussies"), "${results.size}")
            LabeledRow(L("Série actuelle"), "${state.streak.current}")
            LabeledRow(L("Plus longue série"), "${state.streak.longest}")
            results.minOfOrNull { it.seconds }?.let { LabeledRow(L("Meilleur temps"), clock(it)) }
            LabeledRow(L("Défis gagnés"), "${state.challengesWon}")
        }
        for (level in Level.entries) {
            val s = state.stats[level.ordinal] ?: LevelStats()
            SectionCard(level.displayName) {
                LabeledRow(L("Parties commencées"), "${s.started}")
                LabeledRow(L("Victoires"), "${s.won}")
                s.winRate?.let { LabeledRow(L("Taux de réussite"), "${(it * 100).toInt()} %") }
                LabeledRow(L("Meilleur temps"), s.bestSeconds?.let(::clock) ?: "–")
                LabeledRow(L("Temps moyen"), s.averageSeconds?.let(::clock) ?: "–")
                LabeledRow(L("Parfaites (0 indice, 0 erreur)"), "${s.perfect}")
            }
        }
    }
}

// --- Réglages ---

@Composable
fun SettingsScreen(model: AppModel, router: Router) {
    val p = LocalPalette.current
    val s = model.settings
    val context = LocalContext.current
    var confirmReset by remember { mutableStateOf(false) }
    var languageMenu by remember { mutableStateOf(false) }
    fun open(url: String) = context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
    fun reschedule() = Reminder.reschedule(context, s.reminderEnabled, s.reminderMinutes,
        model.state.streak.current, model.state.streak.isCompleted(model.today))
    val notifPermission = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
        if (!granted) s.reminderEnabled = false
        reschedule()
    }

    SubScreen(L("Réglages"), router) {
        SectionCard(L("Apparence")) {
            Text(L("Thème"), Modifier.padding(top = 8.dp))
            SingleChoiceSegmentedButtonRow(Modifier.fillMaxWidth().padding(vertical = 8.dp)) {
                AppTheme.entries.forEachIndexed { i, t ->
                    SegmentedButton(selected = s.theme == t, onClick = { s.updateTheme(t) },
                        shape = SegmentedButtonDefaults.itemShape(i, AppTheme.entries.size)) {
                        Text(when (t) { AppTheme.SYSTEM -> L("Système"); AppTheme.LIGHT -> L("Clair"); AppTheme.DARK -> L("Sombre") })
                    }
                }
            }
        }
        SectionCard(L("Langue"), L("Change la langue de Sudokuno sans modifier celle de ton téléphone.")) {
            Box {
                Row(Modifier.fillMaxWidth().clickable { languageMenu = true }.padding(vertical = 12.dp).testTag("languagePicker")) {
                    Text(L("Langue"), Modifier.weight(1f))
                    Text(s.language.nativeName, color = p.accent)
                }
                DropdownMenu(expanded = languageMenu, onDismissRequest = { languageMenu = false }) {
                    AppLanguage.entries.forEach { lang ->
                        DropdownMenuItem(text = { Text(lang.nativeName) }, onClick = { languageMenu = false; s.updateLanguage(lang) })
                    }
                }
            }
        }
        SectionCard(L("Indices"), L("Le nombre d'indices utilisés apparaît à la fin de la partie, dans les messages partagés et dans les classements Google Play Jeux. Le réglage s'applique aux nouvelles parties.")) {
            ToggleRow(L("Indices (3 par grille)"), s.hintsEnabled) { s.hintsEnabled = it }
        }
        SectionCard(L("Aides")) {
            ToggleRow(L("Afficher les erreurs"), s.showMistakes) { s.showMistakes = it }
            ToggleRow(L("Surligner les conflits"), s.highlightConflicts) { s.highlightConflicts = it }
            ToggleRow(L("Surligner les chiffres identiques"), s.highlightSameDigits) { s.highlightSameDigits = it }
            ToggleRow(L("Surligner ligne, colonne et bloc"), s.highlightRelated) { s.highlightRelated = it }
            ToggleRow(L("Effacer les notes automatiquement"), s.autoRemoveNotes) { s.autoRemoveNotes = it }
        }
        SectionCard(L("Jeu")) {
            ToggleRow(L("Afficher le chrono"), s.showTimer) { s.showTimer = it }
            ToggleRow(L("Vibrations"), s.haptics) { s.haptics = it }
        }
        SectionCard(L("Notifications"), L("Une notification locale si le Sudoku du jour n'est pas encore fait. Rien n'est envoyé sur Internet.")) {
            ToggleRow(L("Rappel de série"), s.reminderEnabled) { on ->
                s.reminderEnabled = on
                if (on && Build.VERSION.SDK_INT >= 33) notifPermission.launch(Manifest.permission.POST_NOTIFICATIONS) else reschedule()
            }
            if (s.reminderEnabled) Row(Modifier.fillMaxWidth().padding(vertical = 8.dp), verticalAlignment = Alignment.CenterVertically) {
                Text(L("Heure"), Modifier.weight(1f))
                IconButton(onClick = { s.updateReminderMinutes((s.reminderMinutes - 30 + 1440) % 1440); reschedule() }) { Text("–") }
                Text("%02d:%02d".format(s.reminderMinutes / 60, s.reminderMinutes % 60), fontWeight = FontWeight.SemiBold)
                IconButton(onClick = { s.updateReminderMinutes((s.reminderMinutes + 30) % 1440); reschedule() }) { Text("+") }
            }
        }
        val gs = model.gameServices
        SectionCard(L("Google Play Jeux")) {
            if (gs.isAuthenticated) {
                LabeledRow(L("Connecté"), gs.playerName ?: "")
                LinkRow(L("Classements")) { gs.showAllLeaderboards() }
                LinkRow(L("Succès")) { gs.showAchievements() }
            } else if (gs.isConfigured) {
                LinkRow(L("Google Play Jeux")) { gs.signIn() }
                if (gs.signInFailed) Text(L("Connexion à Google Play Jeux impossible pour le moment. Réessaie plus tard."),
                    color = p.error, style = MaterialTheme.typography.labelMedium, modifier = Modifier.padding(bottom = 10.dp))
            } else {
                Text(L("Classement indisponible pour le moment."), color = p.secondaryText, modifier = Modifier.padding(vertical = 10.dp))
            }
        }
        TipJarSection(model.tipJar)
        SectionCard(L("À propos")) {
            LabeledRow(L("Version"), com.alexafer.sudokuno.BuildConfig.VERSION_NAME)
            LinkRow(L("Aide et contact")) { open(SITE_URL) }
            LinkRow(L("Politique de confidentialité")) { open(PRIVACY_URL) }
            LinkRow(L("Mentions légales"), "legalLink") { open(LEGAL_URL) }
            Text(L("Sudokuno est gratuit, sans publicité et sans suivi. Les seuls achats sont des dons facultatifs. Tes données restent sur ton appareil."),
                color = p.secondaryText, style = MaterialTheme.typography.bodySmall, modifier = Modifier.padding(vertical = 8.dp))
            Text(L("Réinitialiser les statistiques"), color = p.error, modifier = Modifier.fillMaxWidth().clickable { confirmReset = true }.padding(vertical = 12.dp))
        }
    }
    if (confirmReset) AlertDialog(
        onDismissRequest = { confirmReset = false },
        title = { Text(L("Tout réinitialiser ?")) },
        text = { Text(L("Série, statistiques, niveaux débloqués et parties en cours seront effacés.")) },
        confirmButton = { TextButton(onClick = { confirmReset = false; model.resetStatistics() }) { Text(L("Réinitialiser"), color = p.error) } },
        dismissButton = { TextButton(onClick = { confirmReset = false }) { Text(L("Annuler")) } },
    )
}

@Composable
private fun TipJarSection(jar: TipJar) {
    val p = LocalPalette.current
    val activity = LocalContext.current as? Activity
    SectionCard(L("Soutenir Sudokuno"), L("Sudokuno est gratuit et sans publicité. Un don facultatif aide à financer son développement, il ne débloque rien. Merci !")) {
        if (!jar.loaded) {
            Text("…", Modifier.padding(vertical = 10.dp))
        } else if (jar.products.isEmpty()) {
            Text(L("Dons indisponibles pour le moment."), color = p.secondaryText, modifier = Modifier.padding(vertical = 10.dp).testTag("tipsUnavailable"))
        } else {
            for (product in jar.products) {
                val tip = TipJar.Tip.of(product.productId)
                Row(Modifier.fillMaxWidth().padding(vertical = 6.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    Text(tip?.emoji ?: "💜", fontSize = 22.sp)
                    Text(tip?.displayName ?: product.name, Modifier.weight(1f))
                    Button(onClick = { activity?.let { jar.buy(it, product) } }, enabled = jar.status != TipJar.Status.PURCHASING,
                        colors = ButtonDefaults.buttonColors(containerColor = p.accentStrong)) { Text(TipJar.formattedPrice(product)) }
                }
            }
            Text(L("Montant libre"), fontWeight = FontWeight.SemiBold, modifier = Modifier.padding(top = 8.dp))
            Text(L("Choisis combien de cafés offrir, jusqu'à %lld en une fois.", 10), color = p.secondaryText, style = MaterialTheme.typography.labelMedium)
            jar.products.firstOrNull { it.productId == TipJar.Tip.SMALL.id }?.let { coffee ->
                FilledTonalButton(onClick = { activity?.let { jar.buy(it, coffee) } }, modifier = Modifier.fillMaxWidth().padding(vertical = 6.dp)) {
                    Text(L("Offrir") + " ☕️ × …")
                }
            }
        }
        if (jar.tipCount > 0) Text(L("Tu as fait %lld dons. Merci ! 💜", jar.tipCount), color = p.accent, modifier = Modifier.padding(vertical = 8.dp))
    }
    val st = jar.status
    if (st == TipJar.Status.THANKED || st == TipJar.Status.PENDING || st == TipJar.Status.FAILED) AlertDialog(
        onDismissRequest = { jar.status = TipJar.Status.IDLE },
        title = { Text(when (st) { TipJar.Status.THANKED -> L("Merci ! 💜"); TipJar.Status.PENDING -> L("Paiement en attente"); else -> L("Don non effectué") }) },
        text = { Text(when (st) {
            TipJar.Status.THANKED -> L("Ton soutien compte beaucoup pour Sudokuno.")
            TipJar.Status.PENDING -> L("Le paiement doit encore être validé. Merci de ta patience !")
            else -> L("L'achat n'a pas pu aboutir. Aucun montant n'a été débité.")
        }) },
        confirmButton = { TextButton(onClick = { jar.status = TipJar.Status.IDLE }) { Text(L("OK")) } },
    )
}

// --- Saisie d'un code ---

@Composable
fun EnterCodeScreen(model: AppModel, router: Router) {
    val p = LocalPalette.current
    val clipboard = LocalClipboardManager.current
    var text by remember { mutableStateOf("") }
    val link = remember(text) { ShareContent.parse(text) }
    SubScreen(L("Entrer un code"), router) {
        OutlinedTextField(value = text, onValueChange = { text = it }, label = { Text(L("Code de la grille")) },
            placeholder = { Text("SKN1-D-XXXX-XXXX-XXXX-XX") }, modifier = Modifier.fillMaxWidth().testTag("codeField"),
            textStyle = MaterialTheme.typography.bodyLarge.copy(fontFamily = FontFamily.Monospace))
        FilledTonalButton(onClick = { clipboard.getText()?.text?.let { text = it } }) {
            Icon(Icons.Rounded.ContentPaste, null); Spacer(Modifier.width(6.dp)); Text(L("Coller"))
        }
        Text(L("Colle le message reçu ou tape le code. On retrouve exactement la même grille, et le défi s'il y en a un."),
            color = p.secondaryText, style = MaterialTheme.typography.bodySmall)
        if (link != null) {
            val playable = remember(link) { PuzzleAnalysis.isPlayable(link.code) }
            SectionCard(L("Grille trouvée")) {
                LabeledRow(L("Code"), link.code.string)
                when (val c = link.code) {
                    is PuzzleCode.Custom -> {
                        val a = remember(c) { PuzzleAnalysis.analyze(c.grid) }
                        val st = a.status
                        val legend = Legends.find(c.grid)
                        if (legend != null) LabeledRow(L("Légende"), legend.name)
                        else if (st is PuzzleAnalysis.Status.Unique) LabeledRow(L("Grille créée par un joueur"), st.level.displayName)
                        else Text(L("Cette grille n'a pas de solution unique."), color = p.error, modifier = Modifier.padding(vertical = 10.dp))
                    }
                    is PuzzleCode.LevelSeed -> LabeledRow(L("Niveau"), c.level.displayName)
                    is PuzzleCode.DiaboliqueV1 -> LabeledRow(L("Niveau"), c.level.displayName)
                    is PuzzleCode.Daily -> LabeledRow(L("Sudoku du jour"), c.day.date.format(DateTimeFormatter.ofLocalizedDate(FormatStyle.LONG).withLocale(L10n.locale)))
                }
                link.challenge?.let { LabeledRow(L("Défi"), "${clock(it.seconds)} · ${ShareContent.hintsText(it.hints, true)}") }
                val future = (link.code as? PuzzleCode.Daily)?.let { it.day > model.today } ?: false
                Button(onClick = { router.play { model.sharedGame(link.code, link.challenge) } }, enabled = playable && !future,
                    colors = ButtonDefaults.buttonColors(containerColor = p.accentStrong), modifier = Modifier.padding(vertical = 8.dp).testTag("playCode")) {
                    Icon(Icons.Rounded.PlayArrow, null); Text(if (link.challenge == null) L("Jouer") else L("Relever le défi"))
                }
            }
        } else if (text.isNotBlank()) {
            Text(L("Code invalide. Vérifie qu'il commence par SKN1."), color = p.error)
        }
    }
}

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

    // Analyse relancée à chaque modification de la grille (la plus récente gagne).
    LaunchedEffect(Unit) {
        androidx.compose.runtime.snapshotFlow { cells.toList() }.collectLatest { list ->
            val grid = Grid(list.toIntArray())
            prefs.edit().putString("draft", grid.string).apply()
            analysis = withContext(Dispatchers.Default) { PuzzleAnalysis.analyze(grid) }
        }
    }
    val conflicts = (analysis?.status as? PuzzleAnalysis.Status.Conflict)?.cells?.toSet() ?: emptySet()

    SubScreen(L("Créer une grille"), router, actions = {
        TextButton(onClick = { confirmClear = true }) { Text(L("Tout effacer")) }
    }) {
        Box(Modifier.fillMaxWidth().aspectRatio(1f)) {
            androidx.compose.foundation.layout.BoxWithConstraints(Modifier.fillMaxWidth().aspectRatio(1f).clip(RoundedCornerShape(14.dp))
                .background(p.board).border(2.5.dp, p.gridBold, RoundedCornerShape(14.dp))) {
                val cell = maxWidth / 9
                Column {
                    for (r in 0 until 9) Row {
                        for (c in 0 until 9) {
                            val i = r * 9 + c
                            val sel = selected
                            CellView(cells[i], 0, true, i in conflicts, { pal ->
                                when {
                                    sel == i -> pal.selection
                                    i in conflicts -> pal.errorFill
                                    cells[sel] != 0 && cells[i] == cells[sel] -> pal.sameDigit
                                    Sudoku.row(i) == Sudoku.row(sel) || Sudoku.col(i) == Sudoku.col(sel) || Sudoku.box(i) == Sudoku.box(sel) -> pal.related
                                    else -> Color.Transparent
                                }
                            }, cell, Modifier.clickable { selected = i }.testTag("create-$i"))
                        }
                    }
                }
                GridLines(p)
            }
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
                }
                is PuzzleAnalysis.Status.Unique -> {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Box(Modifier.weight(1f).testTag("validPuzzle")) { StatusLine(L("Grille valide : solution unique"), Icons.Rounded.CheckCircle, p.success) }
                        LevelPill(st.level)
                    }
                    Text(st.hardest?.let { L("Technique la plus difficile : %@", it.displayName) } ?: L("Demande des techniques au-delà des classiques."),
                        color = p.secondaryText, style = MaterialTheme.typography.bodyMedium)
                }
            }
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
                Text(L("Le code contient toute ta grille : tes amis retrouvent exactement la même, même hors ligne."),
                    color = p.secondaryText, style = MaterialTheme.typography.labelMedium)
            }
        }
    }
    if (confirmClear) AlertDialog(
        onDismissRequest = { confirmClear = false },
        title = { Text(L("Effacer toute la grille ?")) },
        confirmButton = { TextButton(onClick = { confirmClear = false; for (i in 0 until 81) cells[i] = 0; selected = 0 }) { Text(L("Tout effacer"), color = p.error) } },
        dismissButton = { TextButton(onClick = { confirmClear = false }) { Text(L("Annuler")) } },
    )
}

@Composable
private fun StatusLine(text: String, icon: androidx.compose.ui.graphics.vector.ImageVector, color: Color) {
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
        Icon(icon, null, tint = color, modifier = Modifier.size(18.dp))
        Text(text, color = color, fontWeight = FontWeight.SemiBold, style = MaterialTheme.typography.bodyMedium)
    }
}

// --- Historique ---

@Composable
fun HistoryScreen(model: AppModel, router: Router) {
    val p = LocalPalette.current
    val context = LocalContext.current
    val inProgress = model.inProgress
    val history = model.state.history
    SubScreen(L("Historique"), router) {
        SectionCard(L("En cours")) {
            if (inProgress.isEmpty()) Text(L("Aucune partie en cours."), color = p.secondaryText, modifier = Modifier.padding(vertical = 10.dp))
            inProgress.forEachIndexed { k, saved ->
                if (k > 0) HorizontalDivider()
                HistoryRow(saved.title, saved.levelValue, L("%lld/81 cases · %@", saved.filledCount, clock(saved.elapsed)),
                    saved.updatedAt, Icons.Rounded.PlayArrow, null,
                    onClick = { router.activeGame = model.resume(saved) },
                    trailing = { IconButton(onClick = { model.deleteSaved(saved) }) { Icon(Icons.Rounded.Delete, L("Supprimer"), tint = p.secondaryText) } })
            }
        }
        SectionCard(L("Terminées"), if (history.any { it.isAbandoned }) L("Touche une partie abandonnée pour la reprendre où tu l'avais laissée.") else null) {
            if (history.isEmpty()) Text(L("Les grilles que tu termines apparaîtront ici."), color = p.secondaryText, modifier = Modifier.padding(vertical = 10.dp))
            history.forEachIndexed { k, entry ->
                if (k > 0) HorizontalDivider()
                val title = GameMode.title(entry.mode, entry.puzzleCode, entry.levelValue)
                val saved = entry.abandoned
                if (saved != null) {
                    HistoryRow(title, entry.levelValue, L("Abandonnée") + " · " + L("%lld/81 cases · %@", saved.filledCount, clock(saved.elapsed)),
                        entry.completedAt, Icons.Rounded.Flag, Color.Gray, onClick = { router.activeGame = model.resumeAbandoned(entry) })
                } else {
                    HistoryRow(title, entry.levelValue, "⏱ ${clock(entry.seconds)} · " + ShareContent.hintsText(entry.hints, entry.hintsEnabled),
                        entry.completedAt, Icons.Rounded.CheckCircle, null, onClick = { router.play { model.replay(entry) } },
                        trailing = { IconButton(onClick = { ShareContent.share(context, ShareContent.inviteMessage(entry.puzzleCode, entry.levelValue.displayName)) }) {
                            Icon(Icons.Rounded.Share, L("Partager cette grille"), tint = p.secondaryText) } })
                }
            }
        }
    }
}

@Composable
private fun HistoryRow(title: String, level: Level, detail: String, date: Long, icon: androidx.compose.ui.graphics.vector.ImageVector,
                       tint: Color?, onClick: () -> Unit, trailing: @Composable () -> Unit = {}) {
    val p = LocalPalette.current
    Row(Modifier.fillMaxWidth().clickable(onClick = onClick).padding(vertical = 10.dp).semantics(mergeDescendants = true) {}.testTag("historyRow"),
        verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
        Icon(icon, null, tint = tint ?: level.tint(p.isDark))
        Column(Modifier.weight(1f)) {
            Text(title, fontWeight = FontWeight.SemiBold)
            Text(detail, color = p.secondaryText, style = MaterialTheme.typography.bodyMedium)
        }
        Text(android.text.format.DateUtils.getRelativeTimeSpanString(date).toString(), color = p.secondaryText, style = MaterialTheme.typography.labelSmall)
        trailing()
    }
}

// --- Classements ---

@Composable
fun LeaderboardScreen(model: AppModel, router: Router) {
    val p = LocalPalette.current
    val gs = model.gameServices
    val boards = listOf(LeaderboardId.DAILY to L("Du jour"), LeaderboardId.DAILY_NO_HINT to L("Du jour, sans indice")) +
        Level.generated.map { LeaderboardId.best(it) to L("Record %@", it.displayName) } + (LeaderboardId.STREAK to L("Plus longue série"))
    var board by remember { mutableStateOf(boards[0]) }
    var menu by remember { mutableStateOf(false) }
    var rows by remember { mutableStateOf<List<LeaderboardRow>?>(null) }
    var mine by remember { mutableStateOf<LeaderboardRow?>(null) }
    LaunchedEffect(board, gs.isAuthenticated) {
        rows = null; mine = null
        rows = gs.loadTop(board.first, model.today)
        mine = gs.loadMine(board.first, model.today)
    }

    SubScreen(L("Classements"), router) {
        Box {
            FilledTonalButton(onClick = { menu = true }) { Text(board.second) }
            DropdownMenu(expanded = menu, onDismissRequest = { menu = false }) {
                boards.forEach { b -> DropdownMenuItem(text = { Text(b.second) }, onClick = { menu = false; board = b }) }
            }
        }
        if (board.first == LeaderboardId.DAILY || board.first == LeaderboardId.DAILY_NO_HINT)
            Text(L("Remis à zéro chaque jour à minuit UTC, avec la grille du jour."), color = p.secondaryText, style = MaterialTheme.typography.labelMedium)
        SectionCard {
            when {
                !gs.isAuthenticated -> Column(Modifier.padding(vertical = 10.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text(L("Connecte-toi à Google Play Jeux pour voir les classements."), color = p.secondaryText)
                    if (gs.isConfigured) FilledTonalButton(onClick = { gs.signIn() }) { Text(L("Google Play Jeux")) }
                    if (gs.signInFailed) Text(L("Connexion à Google Play Jeux impossible pour le moment. Réessaie plus tard."),
                        color = p.error, style = MaterialTheme.typography.labelMedium)
                }
                rows == null -> Text("…", Modifier.padding(vertical = 10.dp))
                rows!!.isEmpty() && mine == null -> Text(L("Aucun score pour l'instant. Sois le premier !"), color = p.secondaryText, modifier = Modifier.padding(vertical = 10.dp))
                else -> (rows!! + listOfNotNull(mine?.takeIf { m -> rows!!.none { it.isMe } })).forEach { r ->
                    Row(Modifier.fillMaxWidth().background(if (r.isMe) p.accent.copy(alpha = 0.1f) else Color.Transparent).padding(vertical = 10.dp),
                        verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        Text(if (r.rank > 0) "${r.rank}" else "–", Modifier.width(32.dp), fontWeight = FontWeight.Bold, color = if (r.rank <= 3) p.flameEnd else p.secondaryText)
                        Text(r.name, Modifier.weight(1f), fontWeight = if (r.isMe) FontWeight.Bold else FontWeight.Normal, maxLines = 1)
                        if (board.first == LeaderboardId.STREAK) {
                            Text("🔥 ${r.value}", color = p.flameStart, fontWeight = FontWeight.SemiBold)
                        } else {
                            r.tag?.let { Text(ShareContent.hintsText(it.hints, it.hintsEnabled), color = p.secondaryText, style = MaterialTheme.typography.labelMedium) }
                            Text(clock((r.value / 1000).toInt()), fontWeight = FontWeight.SemiBold)
                        }
                    }
                }
            }
        }
        if (gs.isAuthenticated) {
            LinkRow(L("Ouvrir Google Play Jeux")) { gs.showAllLeaderboards() }
            LinkRow(L("Voir mes succès")) { gs.showAchievements() }
        }
    }
}

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
