package com.alexafer.sudokuno

import android.content.Intent
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.semantics.getOrNull
import androidx.compose.ui.test.junit4.createEmptyComposeRule
import androidx.compose.ui.test.onAllNodesWithTag
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performScrollTo
import androidx.test.core.app.ActivityScenario
import androidx.test.platform.app.InstrumentationRegistry
import androidx.test.uiautomator.UiDevice
import org.junit.Assume.assumeTrue
import org.junit.Rule
import org.junit.Test
import java.io.File

/**
 * Captures pour Google Play. Ignoré sauf avec l'argument d'instrumentation screenshotLang :
 * ./gradlew :app:connectedDebugAndroidTest -Pandroid.testInstrumentationRunnerArguments.screenshotLang=fr \
 *   -Pandroid.testInstrumentationRunnerArguments.class=com.alexafer.sudokuno.ScreenshotTest
 */
class ScreenshotTest {
    @get:Rule val rule = createEmptyComposeRule()
    private val ctx get() = InstrumentationRegistry.getInstrumentation().targetContext
    private val lang: String? = InstrumentationRegistry.getArguments().getString("screenshotLang")
    private var scenario: ActivityScenario<MainActivity>? = null

    private fun launch(prefill: Int = 0, dark: Boolean = false) {
        scenario?.close()
        scenario = ActivityScenario.launch(Intent(ctx, MainActivity::class.java).apply {
            putExtra("debugReset", true); putExtra("debugDemo", true); putExtra("debugNoGameServices", true)
            putExtra("debugElapsed", 251); putExtra("appLanguage", lang); putExtra("theme", if (dark) "dark" else "light")
            if (prefill > 0) putExtra("debugPrefillAllBut", prefill)
        })
    }

    private fun shot(name: String) {
        rule.waitForIdle(); Thread.sleep(700)
        val dir = File(ctx.getExternalFilesDir(null), "playstore/$lang").apply { mkdirs() }
        UiDevice.getInstance(InstrumentationRegistry.getInstrumentation()).takeScreenshot(File(dir, "$name.png"))
    }

    private fun waitTag(tag: String, t: Long = 30_000) =
        rule.waitUntil(t) { rule.onAllNodesWithTag(tag, useUnmergedTree = true).fetchSemanticsNodes().isNotEmpty() }

    private fun firstEmpty(): String = (0 until 81).map { "cell-$it" }.first {
        rule.onNodeWithTag(it).fetchSemanticsNode().config.getOrNull(SemanticsProperties.ContentDescription)
            ?.joinToString()?.let { d -> d.contains("vide") || d.contains("empty") || d.contains("空") || d.contains("leeg") || d.contains("vazia") } == true
    }

    @Test fun playStoreScreenshots() {
        assumeTrue(lang != null)
        launch(prefill = 34)
        waitTag("dailyPlay")
        shot("01-accueil")
        rule.onNodeWithTag("level-D").performScrollTo().performClick()
        waitTag("cell-0")
        rule.onNodeWithTag(firstEmpty()).performClick()
        rule.onNodeWithTag("hintButton").performClick()
        waitTag("hintNext", 5_000)
        shot("02-partie-indice")
        rule.onNodeWithTag("closeGame").performClick()
        rule.onNodeWithTag("streakCard").performClick()
        shot("03-serie")

        launch(prefill = 1)
        waitTag("dailyPlay")
        rule.onNodeWithTag("dailyPlay").performClick()
        waitTag("cell-0")
        rule.onNodeWithTag("hintButton").performClick()
        waitTag("hintNext", 5_000)
        rule.onNodeWithTag("hintNext").performClick()
        rule.onNodeWithTag("hintNext").performClick()
        waitTag("completionTitle", 10_000)
        shot("04-victoire")

        ctx.getSharedPreferences("creator", 0).edit()
            .putString("draft", "3..41.5.7.....84..5..7...2....92..4.9.......1.1..86....7...5..4..36.....1.4.97..2").commit()
        launch()
        waitTag("level-F")
        rule.onAllNodesWithTag("shortcut-", useUnmergedTree = false)
        rule.onNodeWithTag(createShortcutTag()).performScrollTo().performClick()
        waitTag("validPuzzle", 10_000)
        rule.onNodeWithTag("create-10").performClick()
        shot("05-createur")

        launch(prefill = 36, dark = true)
        waitTag("level-M")
        rule.onNodeWithTag("level-M").performScrollTo().performClick()
        waitTag("cell-0")
        rule.onNodeWithTag("cell-0").performClick()
        shot("06-sombre")
        scenario?.close()
    }

    /** Le raccourci « Bac à sable » porte le texte traduit dans son identifiant. */
    private fun createShortcutTag(): String = "shortcut-" + when (lang) {
        "en" -> "Sandbox"; "nl" -> "Zandbak"; "pt-PT" -> "Caixa de areia"; "zh-Hans" -> "沙盒"; else -> "Bac à sable"
    }
}
