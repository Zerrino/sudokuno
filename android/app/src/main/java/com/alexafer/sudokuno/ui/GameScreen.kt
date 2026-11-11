package com.alexafer.sudokuno.ui

import android.view.HapticFeedbackConstants
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.focusable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawingPadding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.rounded.Undo
import androidx.compose.material.icons.rounded.Backspace
import androidx.compose.material.icons.rounded.CheckCircle
import androidx.compose.material.icons.rounded.Close
import androidx.compose.material.icons.rounded.ContentCopy
import androidx.compose.material.icons.rounded.Edit
import androidx.compose.material.icons.rounded.EditNote
import androidx.compose.material.icons.rounded.EmojiEvents
import androidx.compose.material.icons.rounded.Flag
import androidx.compose.material.icons.rounded.HighlightOff
import androidx.compose.material.icons.rounded.Lightbulb
import androidx.compose.material.icons.rounded.LockOpen
import androidx.compose.material.icons.rounded.MoreHoriz
import androidx.compose.material.icons.rounded.Share
import androidx.compose.material.icons.rounded.SportsScore
import androidx.compose.material.icons.rounded.Star
import androidx.compose.material.icons.rounded.Timer
import androidx.compose.material.icons.rounded.Warning
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Badge
import androidx.compose.material3.BadgedBox
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.isCtrlPressed
import androidx.compose.ui.input.key.isMetaPressed
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onPreviewKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.compose.LocalLifecycleOwner
import androidx.lifecycle.repeatOnLifecycle
import com.alexafer.sudokuno.i18n.L
import com.alexafer.sudokuno.kit.Hint
import com.alexafer.sudokuno.kit.Sudoku
import com.alexafer.sudokuno.kit.Technique
import com.alexafer.sudokuno.model.AppModel
import com.alexafer.sudokuno.model.CompletionSummary
import com.alexafer.sudokuno.model.GameMode
import com.alexafer.sudokuno.model.GameSession
import kotlinx.coroutines.delay

@Composable
fun GameScreen(model: AppModel, router: Router, session: GameSession) {
    val p = LocalPalette.current
    val settings = model.settings
    val view = LocalView.current
    var summary by remember(session.id) { mutableStateOf<CompletionSummary?>(null) }
    val focus = remember { FocusRequester() }
    val lifecycle = LocalLifecycleOwner.current

    fun haptic(type: Int) {
        if (!settings.haptics) return
        // CONFIRM / REJECT existent depuis Android 11 ; avant, un simple « tap ».
        view.performHapticFeedback(if (android.os.Build.VERSION.SDK_INT >= 30) type else HapticFeedbackConstants.VIRTUAL_KEY)
    }

    // Chrono : tourne seulement quand l'app est au premier plan
    LaunchedEffect(session.id) {
        lifecycle.repeatOnLifecycle(Lifecycle.State.RESUMED) {
            var ticks = 0
            while (!session.isComplete) {
                delay(1000)
                session.tick()
                if (++ticks % 10 == 0) model.save(session)
            }
        }
    }
    LaunchedEffect(session.lastEvent) {
        when (val e = session.lastEvent) {
            is GameSession.Event.Placed -> haptic(
                if (!e.correct) HapticFeedbackConstants.REJECT
                else if (e.completedUnits > 0) HapticFeedbackConstants.CONFIRM else HapticFeedbackConstants.KEYBOARD_TAP
            )
            GameSession.Event.Completed -> if (summary == null) {
                haptic(HapticFeedbackConstants.CONFIRM)
                summary = model.complete(session)
            }
            null -> {}
        }
    }
    LaunchedEffect(Unit) { runCatching { focus.requestFocus() } }

    BoxWithConstraints(
        Modifier.fillMaxSize().background(p.background).safeDrawingPadding()
            .focusRequester(focus).focusable()
            .onPreviewKeyEvent { ev ->
                if (ev.type != KeyEventType.KeyDown) return@onPreviewKeyEvent false
                handleKey(session, ev.key, ev.isCtrlPressed || ev.isMetaPressed)
            },
    ) {
        val mw = maxWidth
        val wide = maxWidth > maxHeight && maxWidth > 700.dp
        if (wide) {
            Row(Modifier.fillMaxSize().padding(24.dp), horizontalArrangement = Arrangement.spacedBy(28.dp)) {
                Box(Modifier.weight(1f).fillMaxSize(), contentAlignment = Alignment.Center) { Board(model, session) }
                Column(Modifier.width(minOf(400.dp, mw * 0.38f)).fillMaxSize(), verticalArrangement = Arrangement.spacedBy(16.dp)) {
                    Header(model, router, session)
                    InfoRow(session, settings.showMistakes)
                    HintArea(session)
                    Spacer(Modifier.weight(1f))
                    Controls(session)
                    NumberPad(session, grid = true)
                }
            }
        } else {
            Column(
                Modifier.fillMaxSize().padding(horizontal = 16.dp, vertical = 8.dp).widthIn(max = if (mw > 700.dp) 820.dp else 640.dp)
                    .align(Alignment.TopCenter),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                Header(model, router, session)
                InfoRow(session, settings.showMistakes)
                Spacer(Modifier.weight(1f))
                Board(model, session)
                HintArea(session)
                Spacer(Modifier.weight(1f))
                Controls(session)
                NumberPad(session, grid = false)
            }
        }
        summary?.let { CompletionOverlay(model, router, it) }
    }
}

private fun handleKey(session: GameSession, key: Key, command: Boolean): Boolean {
    if (command && key == Key.Z) { session.undo(); return true }
    val digits = mapOf(Key.One to 1, Key.Two to 2, Key.Three to 3, Key.Four to 4, Key.Five to 5, Key.Six to 6,
        Key.Seven to 7, Key.Eight to 8, Key.Nine to 9, Key.NumPad1 to 1, Key.NumPad2 to 2, Key.NumPad3 to 3,
        Key.NumPad4 to 4, Key.NumPad5 to 5, Key.NumPad6 to 6, Key.NumPad7 to 7, Key.NumPad8 to 8, Key.NumPad9 to 9)
    digits[key]?.let { session.input(it); return true }
    when (key) {
        Key.DirectionUp -> session.moveSelection(-1, 0)
        Key.DirectionDown -> session.moveSelection(1, 0)
        Key.DirectionLeft -> session.moveSelection(0, -1)
        Key.DirectionRight -> session.moveSelection(0, 1)
        Key.Backspace, Key.Delete, Key.Zero -> session.erase()
        Key.N -> session.notesMode = !session.notesMode
        Key.H -> session.advanceHint()
        else -> return false
    }
    return true
}

// --- En-tête ---

@Composable
private fun Header(model: AppModel, router: Router, session: GameSession) {
    val p = LocalPalette.current
    val context = LocalContext.current
    val clipboard = LocalClipboardManager.current
    var menu by remember { mutableStateOf(false) }
    var confirmAbandon by remember { mutableStateOf(false) }
    var copied by remember { mutableStateOf(false) }

    Row(verticalAlignment = Alignment.CenterVertically) {
        RoundIcon(Icons.Rounded.Close, L("Fermer"), "closeGame") { model.save(session); router.activeGame = null }
        Column(Modifier.weight(1f), horizontalAlignment = Alignment.CenterHorizontally) {
            Text(GameMode.title(session.mode, session.puzzle.code, session.puzzle.level), fontWeight = FontWeight.SemiBold)
            if (model.settings.showTimer) Text(clock(session.elapsed), color = p.secondaryText, style = MaterialTheme.typography.bodyMedium)
        }
        Box {
            RoundIcon(Icons.Rounded.MoreHoriz, L("Plus d'options"), "gameMenu") { menu = true }
            DropdownMenu(expanded = menu, onDismissRequest = { menu = false }) {
                DropdownMenuItem(text = { Text(L("Copier le code %@", session.puzzle.code.string)) },
                    leadingIcon = { Icon(Icons.Rounded.ContentCopy, null) },
                    onClick = { clipboard.setText(AnnotatedString(session.puzzle.code.string)); copied = true; menu = false })
                DropdownMenuItem(text = { Text(L("Partager cette grille")) },
                    leadingIcon = { Icon(Icons.Rounded.Share, null) },
                    onClick = { menu = false; ShareContent.share(context, ShareContent.inviteMessage(session.puzzle.code, session.puzzle.level.displayName)) })
                if (!session.isComplete) {
                    HorizontalDivider()
                    DropdownMenuItem(text = { Text(L("Abandonner la partie"), color = p.error) },
                        leadingIcon = { Icon(Icons.Rounded.Flag, null, tint = p.error) },
                        onClick = { menu = false; confirmAbandon = true }, modifier = Modifier.testTag("abandonItem"))
                }
            }
        }
    }
    if (confirmAbandon) AlertDialog(
        onDismissRequest = { confirmAbandon = false },
        title = { Text(L("Abandonner cette partie ?")) },
        text = { Text(L("Elle sera rangée dans l'historique avec les parties terminées. Tu pourras la reprendre à tout moment.")) },
        confirmButton = {
            TextButton(onClick = { confirmAbandon = false; model.abandon(session); router.activeGame = null },
                modifier = Modifier.testTag("confirmAbandon")) { Text(L("Abandonner"), color = p.error) }
        },
        dismissButton = { TextButton(onClick = { confirmAbandon = false }) { Text(L("Annuler")) } },
    )
    if (copied) AlertDialog(
        onDismissRequest = { copied = false }, title = { Text(L("Code copié")) }, text = { Text(session.puzzle.code.string) },
        confirmButton = { TextButton(onClick = { copied = false }) { Text(L("OK")) } },
    )
}

@Composable
fun RoundIcon(icon: androidx.compose.ui.graphics.vector.ImageVector, description: String, tag: String, onClick: () -> Unit) {
    val p = LocalPalette.current
    IconButton(onClick = onClick, modifier = Modifier.size(44.dp).clip(CircleShape).background(p.card).testTag(tag)) {
        Icon(icon, description, tint = p.accent)
    }
}

@Composable
private fun InfoRow(session: GameSession, showMistakes: Boolean) {
    val p = LocalPalette.current
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(14.dp)) {
        if (showMistakes) Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.testTag("mistakes")
            .semantics { contentDescription = L("%lld erreurs", session.mistakes) }) {
            Icon(Icons.Rounded.HighlightOff, null, Modifier.size(18.dp), tint = if (session.mistakes > 0) p.error else p.secondaryText)
            Text(" ${session.mistakes}", color = if (session.mistakes > 0) p.error else p.secondaryText, fontWeight = FontWeight.SemiBold)
        }
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Rounded.Lightbulb, null, Modifier.size(18.dp), tint = p.secondaryText)
            Text(if (session.hintsEnabled) " ${session.hintsUsed}/${GameSession.MAX_HINTS}" else " " + L("Sans aide"),
                color = p.secondaryText, fontWeight = FontWeight.SemiBold)
        }
        Spacer(Modifier.weight(1f))
        session.mode.challenge?.let { c ->
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Rounded.SportsScore, null, Modifier.size(18.dp), tint = if (session.elapsed < c.seconds) p.accent else p.error)
                Text(" " + L("Battre %1\$@ · 💡%2\$lld", clock(c.seconds), c.hints), color = if (session.elapsed < c.seconds) p.accent else p.error,
                    fontWeight = FontWeight.SemiBold)
            }
        }
    }
}

// --- Grille ---

@Composable
fun Board(model: AppModel, session: GameSession) {
    val p = LocalPalette.current
    val s = model.settings
    BoxWithConstraints(Modifier.fillMaxWidth().aspectRatio(1f)) {
        val side = minOf(maxWidth, maxHeight)
        val cell = side / 9
        Box(Modifier.size(side).align(Alignment.Center).clip(RoundedCornerShape(14.dp)).background(p.board)
            .border(2.5.dp, p.gridBold, RoundedCornerShape(14.dp))) {
            Column {
                for (r in 0 until 9) Row {
                    for (c in 0 until 9) {
                        val i = r * 9 + c
                        val error = isError(session, s.showMistakes, s.highlightConflicts, i)
                        CellView(session.values[i], session.notes[i], session.isGiven(i), error,
                            background(session, s.highlightSameDigits, s.highlightRelated, error, i), cell,
                            Modifier.clickable { session.select(i) }.testTag("cell-$i").semantics {
                                contentDescription = cellLabel(session, i, error)
                                selected = session.selected == i
                            })
                    }
                }
            }
            GridLines(p)
        }
    }
}

private fun isError(session: GameSession, showMistakes: Boolean, conflicts: Boolean, i: Int): Boolean {
    if (session.isGiven(i) || session.values[i] == 0) return false
    return (showMistakes && session.isWrong(i)) || (conflicts && session.hasConflict(i))
}

private fun background(session: GameSession, same: Boolean, related: Boolean, error: Boolean, i: Int): (Palette) -> Color = { p ->
    val hint = session.activeHint
    val sel = session.selected
    when {
        hint != null && session.hintStage >= 2 && hint.cell == i -> p.hintCell
        hint != null && session.hintStage >= 2 && i in hint.focus -> p.hintCell.copy(alpha = 0.45f)
        hint != null && i in hint.region -> p.hintRegion
        sel == null -> Color.Transparent
        sel == i -> p.selection
        same && session.values[sel] != 0 && session.values[i] == session.values[sel] -> p.sameDigit
        error -> p.errorFill
        related && (Sudoku.row(i) == Sudoku.row(sel) || Sudoku.col(i) == Sudoku.col(sel) || Sudoku.box(i) == Sudoku.box(sel)) -> p.related
        else -> Color.Transparent
    }
}

private fun cellLabel(session: GameSession, i: Int, error: Boolean): String {
    val parts = mutableListOf(L("Ligne %1\$lld, colonne %2\$lld", Sudoku.row(i) + 1, Sudoku.col(i) + 1))
    val v = session.values[i]
    if (v != 0) {
        parts.add(if (session.isGiven(i)) L("%lld, donné", v) else "$v")
        if (error) parts.add(L("erreur"))
    } else {
        parts.add(L("vide"))
        val n = Sudoku.digits(session.notes[i])
        if (n.isNotEmpty()) parts.add(L("notes %@", n.joinToString(" ")))
    }
    return parts.joinToString(", ")
}

@Composable
fun CellView(value: Int, notes: Int, isGiven: Boolean, isError: Boolean, background: (Palette) -> Color, size: Dp, modifier: Modifier) {
    val p = LocalPalette.current
    val fontSize = with(LocalDensity.current) { (size * 0.58f).toSp() }
    Box(modifier.size(size).background(background(p)), contentAlignment = Alignment.Center) {
        if (value != 0) {
            Text("$value", fontSize = fontSize, fontWeight = if (isGiven) FontWeight.SemiBold else FontWeight.Medium,
                color = if (isError) p.error else if (isGiven) p.given else p.entry)
        } else if (notes != 0) {
            NotesGrid(notes, size)
        }
    }
}

/** Notes : grille 3 × 3 de zones égales, chaque chiffre centré dans la sienne (1 en haut à gauche, 9 en bas à droite). */
@Composable
fun NotesGrid(notes: Int, size: Dp) {
    val p = LocalPalette.current
    val noteSize = with(LocalDensity.current) { (size * 0.27f).toSp() }
    val style = androidx.compose.ui.text.TextStyle(
        fontSize = noteSize, lineHeight = noteSize, fontWeight = FontWeight.Medium, color = p.note, textAlign = TextAlign.Center,
        platformStyle = androidx.compose.ui.text.PlatformTextStyle(includeFontPadding = false),
        lineHeightStyle = androidx.compose.ui.text.style.LineHeightStyle(
            androidx.compose.ui.text.style.LineHeightStyle.Alignment.Center,
            androidx.compose.ui.text.style.LineHeightStyle.Trim.Both,
        ),
    )
    Column(Modifier.size(size).padding(size * 0.05f)) {
        for (r in 0 until 3) Row(Modifier.weight(1f).fillMaxWidth()) {
            for (c in 0 until 3) {
                val d = r * 3 + c + 1
                Box(Modifier.weight(1f).fillMaxSize(), contentAlignment = Alignment.Center) {
                    if (notes and Sudoku.bit(d) != 0) Text("$d", style = style, maxLines = 1, softWrap = false)
                }
            }
        }
    }
}

@Composable
fun GridLines(p: Palette) {
    Canvas(Modifier.fillMaxSize()) {
        val step = size.width / 9
        for (k in 1 until 9) {
            val bold = k % 3 == 0
            val w = if (bold) 2.dp.toPx() else 0.75.dp.toPx()
            val color = if (bold) p.gridBold else p.gridLine
            drawLine(color, Offset(k * step, 0f), Offset(k * step, size.height), w)
            drawLine(color, Offset(0f, k * step), Offset(size.width, k * step), w)
        }
    }
}

// --- Contrôles ---

@Composable
private fun Controls(session: GameSession) {
    val p = LocalPalette.current
    Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
        Control(L("Annuler"), Icons.AutoMirrored.Rounded.Undo, "undoButton", session.canUndo, Modifier.weight(1f)) { session.undo() }
        Control(L("Effacer"), Icons.Rounded.Backspace, "eraseButton", !session.isComplete, Modifier.weight(1f)) { session.erase() }
        Control(if (session.notesMode) L("Notes : oui") else L("Notes"), if (session.notesMode) Icons.Rounded.EditNote else Icons.Rounded.Edit,
            "notesButton", !session.isComplete, Modifier.weight(1f), active = session.notesMode) { session.notesMode = !session.notesMode }
        if (session.hintsEnabled) Control(L("Indice"), Icons.Rounded.Lightbulb, "hintButton",
            (session.hintsRemaining > 0 || session.activeHint != null) && !session.isComplete, Modifier.weight(1f), badge = session.hintsRemaining) {
            session.advanceHint()
        }
    }
    @Suppress("UNUSED_EXPRESSION") p
}

@Composable
private fun Control(title: String, icon: androidx.compose.ui.graphics.vector.ImageVector, tag: String, enabled: Boolean, modifier: Modifier,
                    active: Boolean = false, badge: Int? = null, onClick: () -> Unit) {
    val p = LocalPalette.current
    Column(
        modifier.heightIn(min = 56.dp).clip(RoundedCornerShape(28.dp)).background(p.card)
            .clickable(enabled = enabled, onClick = onClick).padding(vertical = 8.dp).alpha(if (enabled) 1f else 0.4f).testTag(tag),
        horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.Center,
    ) {
        BadgedBox(badge = { if (badge != null) Badge(containerColor = if (badge > 0) p.accent else Color.Gray) { Text("$badge") } }) {
            Icon(icon, null, tint = if (active) p.accent else MaterialTheme.colorScheme.onSurface)
        }
        Text(title, style = MaterialTheme.typography.labelSmall, color = if (active) p.accent else MaterialTheme.colorScheme.onSurface, maxLines = 1)
    }
}

@Composable
private fun NumberPad(session: GameSession, grid: Boolean) {
    if (grid) {
        Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
            for (r in 0 until 3) Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                for (c in 1..3) Key(session, r * 3 + c, Modifier.weight(1f).height(72.dp), 34)
            }
        }
    } else {
        Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
            for (d in 1..9) Key(session, d, Modifier.weight(1f).height(60.dp), 26)
        }
    }
}

@Composable
private fun Key(session: GameSession, d: Int, modifier: Modifier, size: Int) {
    val p = LocalPalette.current
    val placed = session.placedCount(d)
    val done = placed >= 9
    Column(
        modifier.clip(RoundedCornerShape(12.dp)).background(p.card).clickable(enabled = !done && !session.isComplete) { session.input(d) }
            .alpha(if (done) 0.3f else 1f).testTag("key-$d")
            .semantics { contentDescription = if (session.notesMode) L("Note %lld", d) else "$d" },
        horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.Center,
    ) {
        Text("$d", fontSize = size.sp, fontWeight = if (session.notesMode) FontWeight.Normal else FontWeight.SemiBold,
            color = if (session.notesMode) p.note else p.entry)
        if (!done) Text("${9 - placed}", fontSize = 11.sp, color = p.secondaryText)
    }
}

// --- Indice ---

@Composable
private fun HintArea(session: GameSession) {
    val hint = session.activeHint
    AnimatedVisibility(hint != null) {
        if (hint != null) HintBanner(hint, session.hintStage, onNext = { session.advanceHint() }, onClose = { session.clearHint() })
    }
}

@Composable
private fun HintBanner(hint: Hint, stage: Int, onNext: () -> Unit, onClose: () -> Unit) {
    val p = LocalPalette.current
    val region = regionName(hint)
    val title = when (hint.kind) {
        Hint.Kind.MISTAKE -> L("Il y a une erreur")
        Hint.Kind.REVELATION -> L("Coup difficile")
        Hint.Kind.PLACEMENT -> hint.technique?.displayName ?: L("Indice")
    }
    val message = when (hint.kind) {
        Hint.Kind.MISTAKE -> if (stage >= 2) L("Ce chiffre ne correspond pas à la solution.") else L("Un des chiffres de ce bloc est faux.")
        Hint.Kind.REVELATION -> if (stage >= 2) L("Cette case est la plus contrainte de la grille.") else L("Aucune technique classique ne s'applique ici. Regarde ce bloc.")
        Hint.Kind.PLACEMENT -> if (stage >= 2) when (hint.technique) {
            Technique.NAKED_SINGLE -> L("Dans cette case, un seul chiffre est encore possible. Lequel ?")
            Technique.HIDDEN_SINGLE -> L("Dans %@, un des chiffres manquants ne peut aller que dans cette case. Lequel ?", region)
            else -> L("Cette case n'a plus qu'une possibilité.")
        } else L("Regarde %@.", region) + (hint.supportingTechnique?.let { " " + L("Pense d'abord à éliminer des candidats (%@).", it.displayName) } ?: "")
    }
    Row(Modifier.fillMaxWidth().card(p).padding(14.dp), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
        Icon(if (hint.kind == Hint.Kind.MISTAKE) Icons.Rounded.Warning else Icons.Rounded.Lightbulb, null,
            tint = if (hint.kind == Hint.Kind.MISTAKE) p.error else p.flameEnd)
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text(title, fontWeight = FontWeight.Bold)
            Text(message, color = p.secondaryText, style = MaterialTheme.typography.bodyMedium)
            Text(
                if (stage >= 2) (if (hint.kind == Hint.Kind.MISTAKE) L("Effacer l'erreur") else L("Révéler le chiffre")) else L("Montrer la case"),
                color = p.accent, fontWeight = FontWeight.SemiBold,
                modifier = Modifier.clickable(onClick = onNext).padding(top = 2.dp).testTag("hintNext"),
            )
        }
        Icon(Icons.Rounded.Close, L("Fermer l'indice"), Modifier.size(18.dp).clickable(onClick = onClose), tint = p.secondaryText)
    }
}

private fun regionName(hint: Hint): String {
    val cells = hint.region.toSet()
    for (u in 0 until 27) if (Sudoku.units[u].toSet() == cells) {
        return when (val k = Sudoku.unitName(u)) {
            is Sudoku.UnitKind.Row -> L("la ligne %lld", k.index + 1)
            is Sudoku.UnitKind.Column -> L("la colonne %lld", k.index + 1)
            is Sudoku.UnitKind.Box -> L("le bloc %lld", k.index + 1)
        }
    }
    return L("cette zone")
}

// --- Fin de partie ---

@Composable
private fun CompletionOverlay(model: AppModel, router: Router, summary: CompletionSummary) {
    val p = LocalPalette.current
    val context = LocalContext.current
    val streak = model.state.streak.current
    Box(Modifier.fillMaxSize().background(Color.Black.copy(alpha = 0.3f)).clickable(enabled = false) {}, contentAlignment = Alignment.Center) {
        Column(
            Modifier.padding(20.dp).widthIn(max = 520.dp).verticalScroll(rememberScrollState())
                .background(p.card, RoundedCornerShape(28.dp)).padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            Icon(if (summary.isPerfect) Icons.Rounded.Star else Icons.Rounded.CheckCircle, null, Modifier.size(64.dp),
                tint = if (summary.isPerfect) p.flameStart else p.success)
            Text(if (summary.isPerfect) L("Parfait !") else L("Bravo !"), fontSize = 32.sp, fontWeight = FontWeight.ExtraBold,
                modifier = Modifier.testTag("completionTitle"))
            Text(when (summary.mode) {
                GameMode.Daily -> if (summary.countsForDaily) L("Sudoku du jour réussi") else L("Grille d'un jour passé réussie")
                GameMode.LevelGame -> L("Grille %@ terminée", summary.level.displayName)
                is GameMode.Shared -> L("Grille partagée terminée")
            }, color = p.secondaryText, fontWeight = FontWeight.SemiBold)
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                Stat(clock(summary.seconds), L("Temps"), Icons.Rounded.Timer, Modifier.weight(1f))
                Stat("${summary.mistakes}", L("Erreurs"), Icons.Rounded.HighlightOff, Modifier.weight(1f))
                Stat(if (summary.hintsEnabled) "${summary.hints}" else "–", L("Indices"), Icons.Rounded.Lightbulb, Modifier.weight(1f))
            }
            val prev = summary.previousBest
            if (summary.isNewRecord && prev != null) Banner(L("Nouveau record ! (avant : %@)", clock(prev)), Icons.Rounded.EmojiEvents, p.flameEnd)
            summary.mode.challenge?.let { c ->
                val won = summary.seconds < c.seconds
                val diff = clock(kotlin.math.abs(c.seconds - summary.seconds))
                Banner(if (won) L("Défi réussi : %@ plus rapide !", diff) else L("Défi raté de %@. Retente ta chance !", diff),
                    Icons.Rounded.SportsScore, if (won) p.success else p.error)
            }
            val s = summary.streak
            if (summary.countsForDaily && s != null) Row(
                Modifier.fillMaxWidth().background(p.flameEnd.copy(alpha = 0.14f), RoundedCornerShape(16.dp)).padding(14.dp),
                verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                FlameBadge(s, false, 48)
                Column {
                    Text(L("%lld jours de série", s), fontWeight = FontWeight.SemiBold)
                    Text(summary.milestone?.let { L("Jalon atteint : %lld jours 🎉", it) } ?: L("Reviens demain pour la prolonger."),
                        color = p.secondaryText, style = MaterialTheme.typography.bodyMedium)
                }
            }
            summary.unlocked?.let { Banner(L("Niveau %@ débloqué !", it.displayName), Icons.Rounded.LockOpen, it.tint(p.isDark)) }
            Button(onClick = { ShareContent.share(context, ShareContent.resultMessage(summary, streak)) },
                colors = ButtonDefaults.buttonColors(containerColor = p.accentStrong), modifier = Modifier.fillMaxWidth().height(48.dp)) {
                Icon(Icons.Rounded.Share, null); Spacer(Modifier.width(8.dp)); Text(L("Partager mon temps"), fontWeight = FontWeight.SemiBold)
            }
            if (summary.mode == GameMode.LevelGame) FilledTonalButton(onClick = { router.play { model.newLevelGame(summary.level) } },
                modifier = Modifier.fillMaxWidth().height(48.dp)) { Text(L("Nouvelle grille %@", summary.level.displayName)) }
            OutlinedButton(onClick = { router.activeGame = null }, modifier = Modifier.fillMaxWidth().height(48.dp).testTag("completionHome")) {
                Text(L("Accueil"), fontWeight = FontWeight.SemiBold)
            }
        }
    }
}

@Composable
private fun Stat(value: String, label: String, icon: androidx.compose.ui.graphics.vector.ImageVector, modifier: Modifier) {
    val p = LocalPalette.current
    Column(modifier.background(p.background, RoundedCornerShape(14.dp)).padding(vertical = 12.dp),
        horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(4.dp)) {
        Icon(icon, null, tint = p.accent)
        Text(value, fontSize = 22.sp, fontWeight = FontWeight.Bold, fontFamily = FontFamily.Default)
        Text(label, color = p.secondaryText, style = MaterialTheme.typography.labelMedium)
    }
}

@Composable
private fun Banner(text: String, icon: androidx.compose.ui.graphics.vector.ImageVector, color: Color) {
    Row(Modifier.fillMaxWidth().background(color.copy(alpha = 0.12f), RoundedCornerShape(14.dp)).padding(12.dp),
        verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        Icon(icon, null, tint = color)
        Text(text, color = color, fontWeight = FontWeight.SemiBold, style = MaterialTheme.typography.bodyMedium)
    }
}
