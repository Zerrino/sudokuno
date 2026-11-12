package com.alexafer.sudokuno

import android.content.Intent
import android.graphics.Bitmap
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.semantics.getOrNull
import androidx.compose.ui.test.SemanticsNodeInteraction
import androidx.compose.ui.test.assertIsEnabled
import androidx.compose.ui.test.assertIsNotEnabled
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

        // Plus de bouton Annuler : on corrige avec Effacer.
        assert(rule.onAllNodesWithTag("undoButton").fetchSemanticsNodes().isEmpty())
        val target = emptyCells().first()
        rule.onNodeWithTag(target).performClick()
        val firstFree = emptyCells()[1]
        rule.onNodeWithTag(firstFree).performClick()
        val freeKey = (1..9).first { d ->
            !rule.onNodeWithTag("key-$d").fetchSemanticsNode().config.contains(SemanticsProperties.Disabled)
        }
        rule.onNodeWithTag("key-$freeKey").performClick()
        rule.waitForIdle()
        rule.onNodeWithTag("eraseButton").performClick()
        rule.waitForIdle()
        assertTrue("Effacer doit vider la case", description(firstFree).contains("vide"))
        rule.onNodeWithTag(target).performClick()
        for (d in 1..9) {
            val before = description("mistakes")
            rule.onNodeWithTag("key-$d").performClick()
            rule.waitForIdle()
            if (description("mistakes") != before) {
                snap("03-erreur")
                rule.onNodeWithTag("eraseButton").performClick()
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
        // La grille reçue apparaît dans « Mes grilles ».
        rule.onNodeWithTag("closeGame").performClick()
        rule.waitTag("back")
        rule.onNodeWithTag("back").performClick()
        rule.waitTag("level-F")
        tap("shortcut-Mes grilles")
        rule.onNode(hasText("Reçues")).performClick()
        rule.waitText("Grille partagée · Difficile")
        rule.waitText("En cours")
        snap("11-mes-grilles-recues")
    }

    @Test fun t4_createur() {
        ctx.getSharedPreferences("creator", 0).edit()
            .putString("draft", ".".repeat(18) + "001806400008102900700000008006708200002609500800203009005010300").commit()
        launch()
        rule.waitTag("level-F")
        tap("shortcut-Bac à sable")
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
        // Terminé : la grille est enregistrée, l'éditeur repart à vide, elle est dans « Mes grilles ».
        rule.onNodeWithTag("closeGame").performClick()
        rule.waitTag("creatorDone")
        tap("creatorDone")
        rule.waitText("Grille enregistrée")
        rule.onNodeWithTag("savedOk").performClick()
        rule.waitUntil(5_000) { rule.onAllNodesWithTag("creatorDone").fetchSemanticsNodes().isEmpty() }
        snap("13b-createur-termine")
        rule.onNodeWithTag("back").performClick()
        rule.waitTag("level-F")
        tap("shortcut-Mes grilles")
        rule.waitText("Grille créée")
        snap("13c-mes-grilles-creees")
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

    /** Niveau Légende : débloqué, liste des grilles célèbres, une grille jouée jusqu'au bout. */
    @Test fun t8_legende() {
        launch(prefill = 1) { putExtra("debugUnlockAll", true) }
        rule.waitTag("level-L")
        snap("90-accueil-legende")
        tap("level-L")
        rule.waitTag("legend-escargot")
        rule.waitText("Pas encore résolue")
        snap("91-liste-legendes")
        tap("legend-escargot")
        rule.waitTag("cell-0")
        rule.waitText("AI Escargot")
        snap("92-partie-escargot")
        // Légende : mode validation. Rien n'est signalé, et la grille pleine ne se termine pas toute seule.
        rule.onNodeWithTag("strictMode", useUnmergedTree = true).assertExists()
        useHint()
        rule.waitTag("validateButton", 10_000)
        assert(rule.onAllNodesWithTag("completionTitle", useUnmergedTree = true).fetchSemanticsNodes().isEmpty())
        rule.onNodeWithTag("validateButton").performClick()
        rule.waitTag("completionTitle", 10_000)
        snap("93-legende-reussie")
        tap("completionHome")
        rule.waitTag("legend-escargot")
        rule.waitText("Résolue")
        snap("94-legende-resolue")
    }

    @Test fun t9_explicationEtAidesDuCreateur() {
        // Créateur : complétion automatique, chiffres en trop, puis résolution expliquée de la grille créée.
        ctx.getSharedPreferences("creator", 0).edit()
            .putString("draft", ".".repeat(18) + "001806400008102900700000008006708200002609500800203009005010300").commit()
        launch()
        rule.waitTag("level-F")
        tap("shortcut-Bac à sable")
        rule.waitTag("autoComplete")
        tap("autoComplete")
        rule.waitTag("validPuzzle", 10_000)
        rule.waitTag("explainCustom", 10_000)
        rule.onNodeWithTag("explainCustom").performScrollTo()
        snap("95-createur-aides")
        tap("explainCustom")
        rule.waitTag("explainProgress")
        rule.waitText("Étape 1 sur")
        snap("96-explication-debut")
        tap("explainNext")
        rule.waitText("Étape 2 sur")
        tap("explainPrevious")
        rule.waitText("Étape 1 sur")
        rule.onNodeWithTag("back").performClick()
        rule.waitTag("validPuzzle")
        scenario?.close()

        // Grille Diabolique : on saute aux étapes clés, puis on va jusqu'au bout.
        launch { putExtra("debugExplain", ".146..2....72.5...5.....8.64....9....9.1.3.7....4....11.2.....4...8.29....8..476.") }
        rule.waitTag("explainProgress")
        rule.waitText("sur 63")
        var keys = 0
        while (rule.onAllNodesWithTag("explainNextKey").fetchSemanticsNodes().isNotEmpty() && keys < 40) {
            tap("explainNextKey")
            rule.waitForIdle()
            if (keys == 0) rule.onNodeWithTag("explainTechnique").assertExists()
            if (++keys == 6) snap("97-explication-chaine")
        }
        assert(keys in 5..30) { "étapes clés : $keys" }
        var guard = 0
        while (rule.onAllNodesWithTag("explainDone").fetchSemanticsNodes().isEmpty() && guard++ < 80) {
            tap("explainNext")
            rule.waitForIdle()
        }
        rule.waitTag("explainDone")
        rule.waitText("Grille résolue")
        snap("98-explication-fin")
        scenario?.close()

        // Fin de partie : le bouton mène à la résolution expliquée de la grille jouée.
        launch(prefill = 1)
        rule.waitTag("level-F")
        tap("level-F")
        rule.waitTag("cell-0")
        useHint()
        rule.waitTag("completionExplain", 10_000)
        tap("completionExplain")
        rule.waitTag("explainProgress")
        rule.waitText("Étape 1 sur")
    }

    @Test fun t10_historiqueErreursEtReplay() {
        launch(prefill = 3)
        rule.waitTag("level-F")
        tap("level-F")
        rule.waitTag("cell-0")
        // Deux chiffres différents dans la même case : au moins l'un des deux est une erreur.
        val target = emptyCells().first()
        rule.onNodeWithTag(target).performClick()
        val keys = (1..9).filter { d -> !rule.onNodeWithTag("key-$d").fetchSemanticsNode().config.contains(SemanticsProperties.Disabled) }
        for (d in keys.take(2)) { rule.onNodeWithTag("key-$d").performClick(); rule.waitForIdle() }
        rule.onNodeWithTag("eraseButton").performClick()
        rule.waitForIdle()
        var n = 0
        while (n++ < 4 && rule.onAllNodesWithTag("completionTitle", useUnmergedTree = true).fetchSemanticsNodes().isEmpty()) useHint()
        rule.waitTag("completionTitle", 10_000)
        tap("completionHome")
        rule.waitTag("level-F")
        tap("shortcut-Historique")
        // L'historique affiche le nombre d'erreurs de la partie.
        rule.waitText("erreur")
        snap("99-historique-erreurs")
        // Toucher la partie terminée montre la grille telle qu'elle a été laissée : pleine, avec ses erreurs comptées.
        rule.onAllNodesWithTag("historyRow")[0].performClick()
        rule.waitTag("playbackProgress")
        rule.waitTag("playbackSummary")
        rule.waitText("erreur")
        assert(rule.onAllNodes(hasText("Coup 0 sur", substring = true)).fetchSemanticsNodes().isEmpty()) { "on doit ouvrir sur la fin de la partie" }
        tap("playbackNextMistake")
        rule.waitText("pas le bon chiffre")
        snap("99b-replay-erreur")
        tap("playbackNext")
        rule.waitForIdle()
        tap("playbackPrevious")
        rule.waitText("pas le bon chiffre")
    }

    @Test fun t11_legendeExpliqueeParLAbsurde() {
        // AI Escargot : plus aucune case « révélée », les coups durs sont des preuves par l'absurde rédigées.
        launch { putExtra("debugExplain", "100007090030020008009600500005300900010080002600004000300000010040000007007000300") }
        rule.waitTag("explainProgress", 60_000)
        var found = false
        val end = System.currentTimeMillis() + 120_000
        while (!found && System.currentTimeMillis() < end) {
            found = rule.onAllNodesWithTag("explainProof", useUnmergedTree = true).fetchSemanticsNodes().isNotEmpty()
            if (found) break
            if (rule.onAllNodesWithTag("explainNextKey").fetchSemanticsNodes().isNotEmpty()) tap("explainNextKey") else Thread.sleep(500)
            rule.waitForIdle()
        }
        assertTrue("Une preuve par l'absurde doit être affichée", found)
        rule.waitText("Supposons que")
        rule.waitText("Contradiction")
        snap("99c-explication-legende")
        // Le coach : comment repérer la technique, puis l'hypothèse déroulée sur la grille.
        rule.onNodeWithTag("explainTip", useUnmergedTree = true).assertExists()
        tap("explainWalk")
        rule.waitTag("explainHypothesis")
        repeat(3) { if (rule.onAllNodesWithTag("explainWalkForward").fetchSemanticsNodes().isNotEmpty()) tap("explainWalkForward"); rule.waitForIdle() }
        snap("99d-hypothese-deroulee")
        tap("explainWalkStop")
        rule.waitTag("explainBoard")
    }

    @Test fun t12_limiteDErreursEtGrilleRatee() {
        // Facile : 5 erreurs tolérées, la sixième rate la grille.
        launch(prefill = 3)
        rule.waitTag("level-F")
        tap("level-F")
        rule.waitTag("cell-0")
        rule.onNodeWithTag(emptyCells().first()).performClick()
        var guard = 0
        // Dans une même case, au plus un chiffre est juste : tous les autres sont des erreurs.
        while (rule.onAllNodesWithTag("failureTitle", useUnmergedTree = true).fetchSemanticsNodes().isEmpty() && guard++ < 4) {
            for (d in 1..9) {
                if (rule.onAllNodesWithTag("failureTitle", useUnmergedTree = true).fetchSemanticsNodes().isNotEmpty()) break
                val key = rule.onNodeWithTag("key-$d")
                if (key.fetchSemanticsNode().config.contains(SemanticsProperties.Disabled)) continue
                key.performClick()
                rule.waitForIdle()
            }
        }
        rule.waitTag("failureTitle", 5_000)
        rule.waitText("maximum de 5")
        snap("99e-grille-ratee")
        // On peut regarder ses erreurs, puis rouvrir l'écran ; la grille ne se joue plus.
        tap("failureShow")
        rule.waitTag("failureReopen")
        assertTrue(description("mistakes").contains("6"))
        rule.onNodeWithTag("failureReopen").performClick()
        rule.waitTag("failureHome")
        tap("failureHome")
        rule.waitTag("level-F")
        // Pas de victoire comptée ; l'historique la montre comme ratée.
        rule.waitText("0/5 victoires en Facile")
        tap("shortcut-Historique")
        rule.waitText("Ratée")
    }

    @Test fun t13_modeDifficileValidationEtScore() {
        // Mode difficile : une grille pleine mais fausse ne dit rien tant qu'on ne la valide pas.
        launch { putExtra("debugHardMode", true); putExtra("debugFillWithError", true) }
        rule.waitTag("level-F")
        tap("level-F")
        rule.waitTag("validateButton", 30_000)
        rule.onNodeWithTag("strictMode", useUnmergedTree = true).assertExists()
        assert(rule.onAllNodesWithTag("mistakes", useUnmergedTree = true).fetchSemanticsNodes().isEmpty()) { "aucun compteur d'erreurs en mode validation" }
        assert(rule.onAllNodesWithTag("failureTitle", useUnmergedTree = true).fetchSemanticsNodes().isEmpty())
        rule.onNodeWithTag("validateButton").performClick()
        rule.waitTag("failureTitle", 5_000)
        rule.waitText("1 chiffres faux")
        snap("99f-validation-ratee")
        tap("failureHome")
        scenario?.close()

        // Même mode, grille juste : la validation gagne la partie, et le score s'affiche.
        launch(prefill = 1) { putExtra("debugHardMode", true) }
        rule.waitTag("level-F")
        tap("level-F")
        rule.waitTag("cell-0")
        useHint()
        rule.waitTag("validateButton", 10_000)
        rule.onNodeWithTag("validateButton").performClick()
        rule.waitTag("completionTitle", 10_000)
        rule.waitTag("completionScore", 30_000)
        snap("99g-score")
        tap("completionHome")
        scenario?.close()

        // Grand écran : la partie s'affiche et reste jouable.
        launch(prefill = 2) { putExtra("debugBigScreen", true) }
        rule.waitTag("level-F")
        tap("level-F")
        rule.waitTag("cell-0")
        rule.onNodeWithTag("key-1").assertExists()
        rule.onNodeWithTag("eraseButton").assertExists()
        snap("99h-grand-ecran")
    }

    @Test fun t14_bacASableImportEtHistorique() {
        // Importer une grille copiée (81 caractères) dans le bac à sable : elle est analysée aussitôt.
        val grid = ".1.9..5..6.3.58...89.41..36.59.214..1..3.58...82.497..56..8...4...56...1.37..2.5."
        InstrumentationRegistry.getInstrumentation().runOnMainSync {
            val cm = ctx.getSystemService(android.content.Context.CLIPBOARD_SERVICE) as android.content.ClipboardManager
            cm.setPrimaryClip(android.content.ClipData.newPlainText("sudoku", grid))
        }
        launch()
        rule.waitTag("level-F")
        tap("shortcut-Bac à sable")
        rule.waitTag("sandboxImport")
        rule.onNodeWithTag("sandboxImport").performClick()
        rule.waitTag("validPuzzle", 10_000)
        rule.waitText("38 chiffres")
        snap("99i-bac-a-sable-import")
    }
}
