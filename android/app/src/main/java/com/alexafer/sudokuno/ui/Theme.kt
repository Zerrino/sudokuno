package com.alexafer.sudokuno.ui

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Bolt
import androidx.compose.material.icons.rounded.Eco
import androidx.compose.material.icons.rounded.LocalFireDepartment
import androidx.compose.material.icons.rounded.Star
import androidx.compose.material.icons.rounded.TheaterComedy
import androidx.compose.material.icons.rounded.WorkspacePremium
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.Immutable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import com.alexafer.sudokuno.i18n.L
import com.alexafer.sudokuno.kit.Level
import com.alexafer.sudokuno.kit.Technique
import com.alexafer.sudokuno.model.AppTheme

/** Couleurs sémantiques de Sudokuno (identiques à Palette sur iOS). */
@Immutable
data class Palette(
    val background: Color, val card: Color, val board: Color, val gridLine: Color, val gridBold: Color,
    val given: Color, val entry: Color, val note: Color, val selection: Color, val related: Color,
    val sameDigit: Color, val error: Color, val errorFill: Color, val hintRegion: Color, val hintCell: Color,
    val accent: Color, val accentStrong: Color, val secondaryText: Color, val flameStart: Color, val flameEnd: Color,
    val freeze: Color, val success: Color, val isDark: Boolean,
) {
    val flame: Brush get() = Brush.verticalGradient(listOf(flameEnd, flameStart))
}

private fun c(hex: Long) = Color(0xFF000000 or hex)

val LightPalette = Palette(
    background = c(0xF3F2FA), card = c(0xFFFFFF), board = c(0xFFFFFF), gridLine = c(0xD6D4E6), gridBold = c(0x3A3D9E),
    given = c(0x17172B), entry = c(0x4B3FD9), note = c(0x6E6C85), selection = c(0xC9C4FF), related = c(0xEFEDFB),
    sameDigit = c(0xDDD9FF), error = c(0xD93A40), errorFill = c(0xFDE3E4), hintRegion = c(0xFFF3DC), hintCell = c(0xFFD27A),
    accent = c(0x4B3FD9), accentStrong = c(0x4B3FD9), secondaryText = c(0x6B6982), flameStart = c(0xFF4D2E), flameEnd = c(0xFFB23F),
    freeze = c(0x2E9BE6), success = c(0x1F9D55), isDark = false,
)

val DarkPalette = Palette(
    background = c(0x0F0F17), card = c(0x1B1A27), board = c(0x1B1A27), gridLine = c(0x34334A), gridBold = c(0x7C77E6),
    given = c(0xEDECFA), entry = c(0xA49DFF), note = c(0x9C9AB5), selection = c(0x463F9C), related = c(0x24233A),
    sameDigit = c(0x343070), error = c(0xFF6B70), errorFill = c(0x4A1D22), hintRegion = c(0x3A2F17), hintCell = c(0x8A6118),
    accent = c(0xA49DFF), accentStrong = c(0x5B4FE6), secondaryText = c(0x9C9AB5), flameStart = c(0xFF5A3C), flameEnd = c(0xFFC05A),
    freeze = c(0x5DB8FF), success = c(0x4ADE80), isDark = true,
)

val LocalPalette = staticCompositionLocalOf { LightPalette }

@Composable
fun SudokunoTheme(theme: AppTheme, content: @Composable () -> Unit) {
    val dark = when (theme) {
        AppTheme.SYSTEM -> isSystemInDarkTheme()
        AppTheme.LIGHT -> false
        AppTheme.DARK -> true
    }
    val p = if (dark) DarkPalette else LightPalette
    val scheme = if (dark) {
        darkColorScheme(primary = p.accentStrong, onPrimary = Color.White, secondary = p.accent, background = p.background,
            surface = p.card, surfaceContainer = p.card, surfaceContainerHigh = p.card, surfaceContainerLow = p.background,
            onSurfaceVariant = p.secondaryText, error = p.error)
    } else {
        lightColorScheme(primary = p.accentStrong, onPrimary = Color.White, secondary = p.accent, background = p.background,
            surface = p.card, surfaceContainer = p.card, surfaceContainerHigh = p.card, surfaceContainerLow = p.background,
            onSurfaceVariant = p.secondaryText, error = p.error)
    }
    // Icônes de la barre d'état adaptées au thème de l'app (pas seulement à celui du téléphone)
    val view = androidx.compose.ui.platform.LocalView.current
    if (!view.isInEditMode) androidx.compose.runtime.SideEffect {
        val window = (view.context as? android.app.Activity)?.window ?: return@SideEffect
        androidx.core.view.WindowCompat.getInsetsController(window, view).apply {
            isAppearanceLightStatusBars = !dark
            isAppearanceLightNavigationBars = !dark
        }
    }
    CompositionLocalProvider(LocalPalette provides p) {
        MaterialTheme(colorScheme = scheme) {
            // Couleur de texte par défaut lisible sur le fond, en clair comme en sombre
            androidx.compose.material3.Surface(color = p.background, contentColor = if (dark) p.given else p.given, content = content)
        }
    }
}

// --- Libellés ---

val Level.displayName: String
    get() = when (this) {
        Level.FACILE -> L("Facile")
        Level.MOYEN -> L("Moyen")
        Level.DIFFICILE -> L("Difficile")
        Level.EXPERT -> L("Expert")
        Level.DIABOLIQUE -> L("Diabolique")
        Level.LEGENDE -> L("Légende")
    }

val Level.summary: String
    get() = when (this) {
        Level.FACILE -> L("Singletons : idéal pour démarrer")
        Level.MOYEN -> L("Paires et interactions bloc-ligne")
        Level.DIFFICILE -> L("Triplets et X-Wing")
        Level.EXPERT -> "Swordfish, XY-Wing, XYZ-Wing"
        Level.DIABOLIQUE -> L("Chaînes : X-Chain, XY-Chain, AIC")
        Level.LEGENDE -> L("Les grilles les plus dures du monde")
    }

val Level.icon: ImageVector
    get() = when (this) {
        Level.FACILE -> Icons.Rounded.Eco
        Level.MOYEN -> Icons.Rounded.LocalFireDepartment
        Level.DIFFICILE -> Icons.Rounded.Bolt
        Level.EXPERT -> Icons.Rounded.WorkspacePremium
        Level.DIABOLIQUE -> Icons.Rounded.TheaterComedy
        Level.LEGENDE -> Icons.Rounded.Star
    }

fun Level.tint(dark: Boolean): Color = when (this) {
    Level.FACILE -> if (dark) c(0x4ADE80) else c(0x1F9D55)
    Level.MOYEN -> if (dark) c(0x5DB8FF) else c(0x2E9BE6)
    Level.DIFFICILE -> if (dark) c(0xA996FF) else c(0x7B5CF0)
    Level.EXPERT -> if (dark) c(0xFFB23F) else c(0xE08A00)
    Level.DIABOLIQUE -> if (dark) c(0xFF6B70) else c(0xD93A40)
    Level.LEGENDE -> if (dark) c(0xF472D0) else c(0xB0249A)
}

val Technique.displayName: String
    get() = when (this) {
        Technique.NAKED_SINGLE -> L("Singleton nu")
        Technique.HIDDEN_SINGLE -> L("Singleton caché")
        Technique.POINTING -> L("Pointage")
        Technique.BOX_LINE_REDUCTION -> L("Réduction bloc-ligne")
        Technique.NAKED_PAIR -> L("Paire nue")
        Technique.HIDDEN_PAIR -> L("Paire cachée")
        Technique.NAKED_TRIPLE -> L("Triplet nu")
        Technique.HIDDEN_TRIPLE -> L("Triplet caché")
        Technique.X_WING -> "X-Wing"
        Technique.XY_WING -> "XY-Wing"
        Technique.SWORDFISH -> "Swordfish"
        Technique.XYZ_WING -> "XYZ-Wing"
        Technique.TURBOT_FISH -> "Turbot Fish"
        Technique.X_CHAIN -> "X-Chain"
        Technique.XY_CHAIN -> "XY-Chain"
        Technique.AIC -> L("Chaîne d'inférences (AIC)")
        Technique.FORCING_CHAIN -> L("Chaîne forcée")
        Technique.FORCING_NET -> L("Réseau forcé")
        Technique.SK_LOOP -> "SK-Loop"
        Technique.GROUPED_CHAIN -> L("Chaîne groupée")
    }

fun clock(seconds: Int): String {
    val h = seconds / 3600; val m = (seconds % 3600) / 60; val s = seconds % 60
    return if (h > 0) "%d:%02d:%02d".format(h, m, s) else "%d:%02d".format(m, s)
}

fun String.capitalizedFirst(): String = replaceFirstChar { it.uppercase() }
