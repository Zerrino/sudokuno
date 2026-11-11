package com.alexafer.sudokuno

import android.content.Intent
import android.graphics.Bitmap
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.semantics.getOrNull
import androidx.compose.ui.test.SemanticsNodeInteraction
import androidx.compose.ui.test.hasContentDescription
import androidx.compose.ui.test.hasTestTag
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.junit4.ComposeTestRule
import androidx.compose.ui.test.junit4.createEmptyComposeRule
import androidx.compose.ui.test.onAllNodesWithTag
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performScrollTo
import androidx.compose.ui.test.performTextInput
import androidx.test.core.app.ActivityScenario
import androidx.test.platform.app.InstrumentationRegistry
import com.alexafer.sudokuno.kit.DayStamp
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import java.io.File

/** Parcours joués dans l'émulateur (équivalents des tests d'interface iOS), avec captures. */
class SudokunoUiTest {
    @get:Rule val rule = createEmptyComposeRule()
    private var scenario: ActivityScenario<MainActivity>? = null
    private val ctx get() = InstrumentationRegistry.getInstrumentation().targetContext

    @After fun tearDown() { scenario?.close() }

    private fun launch(prefill: Int = 0, language: String? = "fr", theme: String = "light", extra: Intent.() -> Unit = {}) {
        val intent = Intent(ctx, MainActivity::class.java).apply {
            putExtra("debugReset", true)
            putExtra("debugNoGameServices", true)
            putExtra("theme", theme)
            language?.let { putExtra("appLanguage", it) }
            if (prefill > 0) putExtra("debugPrefillAllBut", prefill)
            extra()
        }
        scenario = ActivityScenario.launch(intent)
    }

    private fun snap(name: String) {
        rule.waitForIdle()
        Thread.sleep(400)
        val dir = File(ctx.getExternalFilesDir(null), "screenshots").apply { mkdirs() }
        androidx.test.uiautomator.UiDevice.getInstance(InstrumentationRegistry.getInstrumentation()).takeScreenshot(File(dir, "$name.png"))
    }

    private fun ComposeTestRule.waitTag(tag: String, timeout: Long = 30_000) =
        waitUntil(timeout) { onAllNodesWithTag(tag, useUnmergedTree = true).fetchSemanticsNodes().isNotEmpty() }

    private fun ComposeTestRule.waitText(text: String, timeout: Long = 10_000) =
        waitUntil(timeout) { onAllNodes(hasText(text, substring = true)).fetchSemanticsNodes().isNotEmpty() }

    private fun description(tag: String): String =
        rule.onNodeWithTag(tag).fetchSemanticsNode().config.getOrNull(SemanticsProperties.ContentDescription)?.joinToString() ?: ""

    private fun emptyCells(): List<String> = (0 until 81).map { "cell-$it" }.filter { description(it).contains("vide") }

    private fun useHint() {
        rule.onNodeWithTag("hintButton").performClick()
        rule.waitTag("hintNext", 5_000)
        rule.onNodeWithTag("hintNext").performClick()
        rule.onNodeWithTag("hintNext").performClick()
        rule.waitForIdle()
    }

    private fun tap(tag: String): SemanticsNodeInteraction = rule.onNodeWithTag(tag).performScrollTo().performClick()

    @Test fun t1_partieFacileComplete() {
        launch(prefill = 3)
        rule.waitTag("level-F")
        snap("01-accueil")
        rule.onNodeWithTag("level-F").performClick()
        rule.waitTag("cell-0")
        snap("02-partie")

        // Erreur volontaire puis annulation
        val target = emptyCells().first()
        rule.onNodeWithTag(target).performClick()
        for (d in 1..9) {
            rule.onNodeWithTag("key-$d").performClick()
            rule.waitForIdle()
            if (description("mistakes").startsWith("1")) {
                snap("03-erreur")
                rule.onNodeWithTag("undoButton").performClick()
                rule.waitForIdle()
                assertTrue(description(target).contains("vide"))
                break
            }
            break
        }
        // Notes
        emptyCells().firstOrNull()?.let { cell ->
            rule.onNodeWithTag(cell).performClick()
            rule.onNodeWithTag("notesButton").performClick()
            (1..9).map { "key-$it" }.take(3).forEach { rule.onNodeWithTag(it).performClick() }
            snap("04-notes")
            rule.onNodeWithTag("notesButton").performClick()
        }
        // Indices jusqu'à la fin
        var n = 0
        while (n++ < 6) {
            rule.waitForIdle()
            if (rule.onAllNodesWithTag("completionTitle", useUnmergedTree = true).fetchSemanticsNodes().isNotEmpty()) break
            useHint()
        }
        rule.waitTag("completionTitle", 10_000)
        snap("05-victoire")
        rule.onNodeWithTag("completionHome").performClick()
        rule.waitText("1/5 victoires en Facile pour débloquer")
    }

    @Test fun t2_grilleDuJourEtSerie() {
        launch(prefill = 1)
        rule.waitTag("dailyPlay")
        rule.onNodeWithTag("dailyPlay").performClick()
        rule.waitTag("cell-0")
        useHint()
        rule.waitTag("completionTitle", 10_000)
        rule.waitText("1 jour de série")
        snap("06-victoire-du-jour")
        tap("completionHome")
        rule.waitText("1 jour de série")
        rule.onNodeWithTag("streakCard").performClick()
        val day = DayStamp.today().date.dayOfMonth
        rule.waitUntil(5_000) { rule.onAllNodes(hasContentDescription("$day, réussi")).fetchSemanticsNodes().isNotEmpty() }
        rule.waitUntil(5_000) { rule.onAllNodes(hasContentDescription("1, non joué")).fetchSemanticsNodes().isNotEmpty() || day == 1 }
        snap("07-serie")
    }

    @Test fun t3_codeEtModeSombre() {
        launch(theme = "dark")
        rule.waitTag("level-F")
        snap("08-accueil-sombre")
        tap("shortcut-Entrer un code")
        rule.waitTag("codeField")
        rule.onNodeWithTag("codeField").performTextInput("skn1-d-0000-0000-0000-2j")
        rule.waitText("Grille trouvée")
        snap("09-code")
        tap("playCode")
        rule.waitTag("cell-0")
        assertTrue(description("cell-0").contains("3"))
        snap("10-grille-partagee-sombre")
    }

    @Test fun t4_createur() {
        ctx.getSharedPreferences("creator", 0).edit()
            .putString("draft", ".".repeat(18) + "001806400008102900700000008006708200002609500800203009005010300").commit()
        launch()
        rule.waitTag("level-F")
        tap("shortcut-Créer une grille")
        rule.waitText("Plusieurs solutions possibles")
        snap("11-createur-plusieurs")
        rule.onNodeWithTag("create-0").performClick()
        rule.onNodeWithTag("createKey-7").performClick()
        rule.waitText("Conflit")
        snap("12-createur-conflit")
        rule.onNodeWithTag("createKey-7").performClick()
        // Suivre les suggestions : après chaque ajout, attendre que l'analyse compte un chiffre de plus.
        var clues = 25 // chiffres du brouillon
        var n = 0
        while (rule.onAllNodesWithTag("validPuzzle", useUnmergedTree = true).fetchSemanticsNodes().isEmpty() && n++ < 20) {
            if (rule.onAllNodesWithTag("addSuggestion").fetchSemanticsNodes().isEmpty()) { Thread.sleep(300); continue }
            tap("addSuggestion")
            clues++
            rule.waitText("$clues chiffres")
            rule.waitUntil(5_000) {
                rule.onAllNodesWithTag("addSuggestion").fetchSemanticsNodes().isNotEmpty() ||
                    rule.onAllNodesWithTag("validPuzzle", useUnmergedTree = true).fetchSemanticsNodes().isNotEmpty()
            }
            Thread.sleep(400)
        }
        rule.waitTag("validPuzzle", 5_000)
        rule.onNodeWithTag("customCode").performScrollTo()
        snap("13-createur-valide")
        tap("playCustom")
        rule.waitTag("cell-0")
    }

    @Test fun t5_plusieursPartiesEtHistorique() {
        launch(prefill = 30)
        repeat(2) {
            rule.waitTag("level-F")
            tap("level-F")
            rule.waitTag("cell-0")
            rule.onNodeWithTag("closeGame").performClick()
        }
        rule.waitText("+ 1 autre partie en cours")
        snap("14-deux-parties")
        tap("shortcut-Historique")
        rule.waitText("En cours")
        assertEquals(2, rule.onAllNodesWithTag("historyRow").fetchSemanticsNodes().size)
        snap("15-historique")
        rule.onAllNodesWithTag("historyRow")[0].performClick()
        rule.waitTag("cell-0", 10_000)
    }

    @Test fun t6_abandonEtReprise() {
        launch(prefill = 30)
        rule.waitTag("level-F"); tap("level-F"); rule.waitTag("cell-0")
        val target = emptyCells().first()
        rule.onNodeWithTag(target).performClick()
        rule.onNodeWithTag("notesButton").performClick()
        rule.onNodeWithTag("key-1").performClick()
        rule.onNodeWithTag("notesButton").performClick()
        rule.onNodeWithTag("gameMenu").performClick()
        rule.waitTag("abandonItem", 5_000)
        rule.onNodeWithTag("abandonItem").performClick()
        rule.waitTag("confirmAbandon", 5_000)
        snap("16-confirmation-abandon")
        rule.onNodeWithTag("confirmAbandon").performClick()
        rule.waitTag("level-F")
        assertTrue(rule.onAllNodes(hasText("Reprendre", substring = true)).fetchSemanticsNodes().isEmpty())
        tap("shortcut-Historique")
        rule.waitText("Abandonnée")
        snap("17-historique-abandon")
        rule.onAllNodesWithTag("historyRow")[0].performClick()
        rule.waitTag("cell-0", 10_000)
        assertEquals(30, emptyCells().size)
        val notes = description(target)
        assertTrue("notes conservées : $notes", notes.contains("notes") || !notes.contains("vide"))
        snap("18-partie-reprise")
    }

    @Test fun t7_langues() {
        launch(language = "en")
        rule.waitText("Daily Sudoku")
        rule.waitText("0/5 wins in Easy to unlock")
        snap("19-english")
        scenario?.close()
        launch(language = "zh-Hans")
        rule.waitText("每日数独")
        snap("20-chinese")
        scenario?.close()
        // Changement de langue depuis les réglages
        launch(language = null)
        rule.waitTag("settingsButton")
        rule.onNodeWithTag("settingsButton").performClick()
        tap("languagePicker")
        rule.onNodeWithText("Nederlands").performClick()
        rule.waitText("Instellingen")
        snap("21-instellingen")
        tap("languagePicker")
        rule.onNodeWithText("Français").performClick()
        rule.waitText("Réglages")
        rule.onNodeWithTag("legalLink").performScrollTo()
        rule.waitText("Soutenir Sudokuno")
        snap("22-reglages")
    }
}
