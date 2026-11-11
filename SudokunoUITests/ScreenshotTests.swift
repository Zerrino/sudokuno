import XCTest

/// Captures pour l'App Store. Ignoré sauf si la variable SCREENSHOT_LANG est définie :
/// TEST_RUNNER_SCREENSHOT_LANG=fr xcodebuild test … -only-testing:SudokunoUITests/ScreenshotTests
@MainActor
final class ScreenshotTests: XCTestCase {
    private var lang = "fr"

    override func setUp() async throws {
        continueAfterFailure = false
        guard let l = ProcessInfo.processInfo.environment["SCREENSHOT_LANG"] else {
            throw XCTSkip("Captures App Store : définir TEST_RUNNER_SCREENSHOT_LANG")
        }
        lang = l
        XCUIDevice.shared.orientation = .portrait
    }

    private func launch(prefill: Int? = nil, dark: Bool = false, extra: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-debugReset", "YES", "-debugDemo", "YES", "-debugNoGameCenter", "YES",
                               "-appLanguage", lang, "-theme", dark ? "dark" : "light",
                               "-debugElapsed", "251"] + extra
        if let prefill { app.launchArguments += ["-debugPrefillAllBut", "\(prefill)"] }
        app.launch()
        return app
    }

    private func shot(_ name: String) {
        Thread.sleep(forTimeInterval: 0.8) // fin des animations
        let a = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        a.name = name
        a.lifetime = .keepAlways
        add(a)
    }

    private func el(_ app: XCUIApplication, _ id: String) -> XCUIElement {
        app.descendants(matching: .any)[id].firstMatch
    }

    private func firstEmptyCell(_ app: XCUIApplication) -> XCUIElement? {
        let vide = lang == "fr" ? "vide" : "empty"
        return (0..<81).lazy.map { self.el(app, "cell-\($0)") }.first { $0.label.contains(vide) }
    }

    func testAppStoreScreenshots() {
        // 1. Accueil
        var app = launch(prefill: 34)
        XCTAssertTrue(el(app, "dailyPlay").waitForExistence(timeout: 10))
        shot("01-accueil")

        // 2. Partie avec indice
        el(app, "level-D").tap()
        XCTAssertTrue(el(app, "cell-0").waitForExistence(timeout: 30))
        firstEmptyCell(app)?.tap()
        el(app, "hintButton").tap()
        XCTAssertTrue(el(app, "hintNext").waitForExistence(timeout: 5))
        shot("02-partie-indice")
        el(app, "closeGame").tap()

        // 3. Série
        el(app, "streakCard").tap()
        shot("03-serie")
        app.terminate()

        // 4. Victoire du jour avec série
        app = launch(prefill: 1)
        el(app, "dailyPlay").tap()
        XCTAssertTrue(el(app, "cell-0").waitForExistence(timeout: 30))
        el(app, "hintButton").tap()
        el(app, "hintNext").tap()
        el(app, "hintNext").tap()
        XCTAssertTrue(el(app, "completionTitle").waitForExistence(timeout: 10))
        shot("04-victoire")
        app.terminate()

        // 5. Créateur de grilles (grille Difficile valide)
        app = launch(extra: ["-creatorDraft", "3..41.5.7.....84..5..7...2....92..4.9.......1.1..86....7...5..4..36.....1.4.97..2"])
        app.swipeUp()
        let create = app.buttons.element(matching: NSPredicate(format: "label IN %@", ["Créer une grille", "Create a puzzle"]))
        create.tap()
        XCTAssertTrue(el(app, "validPuzzle").waitForExistence(timeout: 10))
        el(app, "create-10").tap()
        shot("05-createur")
        app.terminate()

        // 6. Mode sombre
        app = launch(prefill: 36, dark: true)
        el(app, "level-M").tap()
        XCTAssertTrue(el(app, "cell-0").waitForExistence(timeout: 30))
        let filled = (0..<81).map { el(app, "cell-\($0)") }.first { !$0.label.contains(lang == "fr" ? "vide" : "empty") }
        filled?.tap()
        shot("06-sombre")
        app.terminate()
    }
}
