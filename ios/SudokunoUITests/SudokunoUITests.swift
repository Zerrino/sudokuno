import XCTest

/// Parcours joués automatiquement dans le simulateur, avec une capture à chaque étape.
@MainActor
final class SudokunoUITests: XCTestCase {

    override func setUp() async throws {
        continueAfterFailure = false
    }

    private func launch(prefill: Int? = nil, dark: Bool = false, language: String? = "fr", extra: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-debugReset", "YES", "-debugNoGameCenter", "YES", "-theme", dark ? "dark" : "light"] + extra
        if let language { app.launchArguments += ["-appLanguage", language] }
        if let prefill { app.launchArguments += ["-debugPrefillAllBut", "\(prefill)"] }
        app.launch()
        return app
    }

    private func snap(_ name: String) {
        let a = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        a.name = name
        a.lifetime = .keepAlways
        add(a)
    }

    private func element(_ app: XCUIApplication, _ id: String) -> XCUIElement {
        app.descendants(matching: .any)[id].firstMatch
    }

    private func emptyCells(_ app: XCUIApplication) -> [XCUIElement] {
        (0..<81).map { element(app, "cell-\($0)") }.filter { $0.label.contains("vide") }
    }

    /// Utilise un indice complet (3 étapes). Retourne false si le bouton est indisponible.
    private func useHint(_ app: XCUIApplication, snapPrefix: String? = nil) -> Bool {
        let hint = element(app, "hintButton")
        guard hint.isEnabled else { return false }
        hint.tap()
        let next = element(app, "hintNext")
        XCTAssertTrue(next.waitForExistence(timeout: 5), "Le bandeau d'indice doit apparaître")
        if let p = snapPrefix { snap("\(p) - indice étape 1 (zone)") }
        next.tap()
        if let p = snapPrefix {
            _ = element(app, "hintNext").waitForExistence(timeout: 2)
            Thread.sleep(forTimeInterval: 0.6)
            snap("\(p) - indice étape 2 (case)")
        }
        element(app, "hintNext").tap()
        return true
    }

    func test1_PartieFacileComplete() {
        let app = launch(prefill: 3)
        snap("01 Accueil")

        element(app, "level-F").tap()
        XCTAssertTrue(element(app, "cell-0").waitForExistence(timeout: 30), "La grille doit s'afficher")
        snap("02 Partie Facile")

        // Annuler : grisé au départ, actif dès qu'on place un chiffre
        XCTAssertFalse(element(app, "undoButton").isEnabled, "Annuler doit être grisé au départ")
        let free = emptyCells(app)[1]
        let freeID = free.identifier
        free.tap()
        (1...9).map { element(app, "key-\($0)") }.first(where: \.isEnabled)!.tap()
        XCTAssertTrue(element(app, "undoButton").isEnabled, "Annuler doit s'activer après un chiffre")
        element(app, "undoButton").tap()
        XCTAssertTrue(element(app, freeID).label.contains("vide"))

        // Erreur volontaire puis annulation
        var empties = emptyCells(app)
        XCTAssertEqual(empties.count, 3)
        let target = empties[0]
        let targetID = target.identifier
        target.tap()
        snap("03 Case sélectionnée")
        for d in 1...9 {
            let key = element(app, "key-\(d)")
            guard key.isEnabled else { continue }
            let before = element(app, "mistakes").label
            key.tap()
            if element(app, "mistakes").label != before {
                snap("04 Erreur affichée en rouge")
                element(app, "undoButton").tap()
                XCTAssertTrue(element(app, targetID).label.contains("vide"), "Annuler doit vider la case")
                break
            }
            // Chiffre juste par hasard : on garde.
            break
        }

        // Notes
        empties = emptyCells(app)
        if let noteCell = empties.first {
            noteCell.tap()
            element(app, "notesButton").tap()
            let keys = (1...9).map { element(app, "key-\($0)") }.filter(\.isEnabled)
            XCTAssertFalse(keys.isEmpty)
            for key in keys.prefix(3) { key.tap() }
            snap("05 Notes")
            XCTAssertTrue(element(app, noteCell.identifier).label.contains("notes"))
            element(app, "notesButton").tap()
        }

        // Indices jusqu'à la fin
        var first = true
        while !element(app, "completionTitle").exists {
            XCTAssertTrue(useHint(app, snapPrefix: first ? "06" : nil), "Il doit rester des indices")
            first = false
        }
        XCTAssertTrue(element(app, "completionTitle").waitForExistence(timeout: 5))
        snap("07 Victoire")

        element(app, "completionHome").tap()
        XCTAssertTrue(app.staticTexts["1/5 victoires en Facile pour débloquer"].waitForExistence(timeout: 5))
        snap("08 Accueil après victoire")
    }

    func test2_GrilleDuJourEtSerie() {
        let app = launch(prefill: 1)
        element(app, "dailyPlay").tap()
        XCTAssertTrue(element(app, "cell-0").waitForExistence(timeout: 30))
        snap("10 Grille du jour")
        XCTAssertTrue(useHint(app))
        XCTAssertTrue(element(app, "completionTitle").waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["1 jour de série"].exists, "La série doit passer à 1")
        snap("11 Victoire du jour avec série")

        element(app, "completionHome").tap()
        XCTAssertTrue(app.staticTexts["1 jour de série"].waitForExistence(timeout: 5))
        snap("12 Accueil avec flamme")
        element(app, "streakCard").tap()
        snap("13 Écran série")
        app.swipeUp()
        XCTAssertTrue(app.buttons["1, non joué"].waitForExistence(timeout: 5), "Le 1er novembre doit être dans le calendrier")
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC")!
        let day = utc.component(.day, from: Date())
        XCTAssertTrue(app.buttons["\(day), réussi"].exists, "Aujourd'hui doit être marqué réussi")
        snap("14 Calendrier")
    }

    func test3_CodeEtModeSombre() {
        let app = launch(dark: true)
        snap("20 Accueil sombre")
        app.buttons["Entrer un code"].tap()
        let field = app.textFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText("skn1-d-0000-0000-0000-2j")
        XCTAssertTrue(app.staticTexts["Niveau, Difficile"].waitForExistence(timeout: 5), "Le code doit être reconnu")
        if app.buttons["Continue"].exists { app.buttons["Continue"].tap() } // bulle d'aide du clavier iOS
        snap("21 Code reconnu")
        app.buttons["Jouer"].tap()
        XCTAssertTrue(element(app, "cell-0").waitForExistence(timeout: 30))
        XCTAssertTrue(element(app, "cell-0").label.contains("3"), "Même grille que la référence")
        snap("22 Grille partagée sombre")
        element(app, "closeGame").tap()

        // La grille reçue apparaît dans « Mes grilles ».
        app.navigationBars.buttons.firstMatch.tap()
        app.swipeUp()
        app.buttons["Mes grilles"].tap()
        app.buttons["Reçues"].tap()
        XCTAssertTrue(app.staticTexts["Grille partagée · Difficile"].waitForExistence(timeout: 5), "La grille reçue doit être listée")
        XCTAssertTrue(app.staticTexts["En cours"].exists)
        snap("24 Mes grilles reçues")
        app.navigationBars.buttons.firstMatch.tap()
        app.swipeDown()
        app.buttons["Réglages"].tap()
        snap("23 Réglages")
    }

    func test5_LanguesEtSoutien() {
        // Changement de langue depuis les réglages (sans argument de lancement, pour que le choix s'applique).
        let app = launch(language: nil)
        app.buttons["Réglages"].firstMatch.tap()
        let picker = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Langue'")).firstMatch
        XCTAssertTrue(picker.waitForExistence(timeout: 5))
        let support = app.staticTexts["Soutenir Sudokuno"]
        var swipes = 0
        while !support.exists && swipes < 6 { app.swipeUp(); swipes += 1 }
        XCTAssertTrue(support.exists, "Section de soutien attendue")
        snap("40 Réglages : soutien")
        while !picker.isHittable && swipes > -6 { app.swipeDown(); swipes -= 1 }
        picker.tap()
        app.buttons["English"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5), "L'interface doit passer en anglais")
        snap("41 Settings in English")
        app.terminate()

        for (lang, title) in [("nl", "42 Nederlands"), ("pt-PT", "43 Português"), ("zh-Hans", "44 中文")] {
            let a = launch(language: lang)
            XCTAssertTrue(a.buttons.matching(identifier: "dailyPlay").firstMatch.waitForExistence(timeout: 10))
            snap(title)
            a.terminate()
        }
        let en = launch(language: "en")
        XCTAssertTrue(en.staticTexts["Daily Sudoku"].waitForExistence(timeout: 10))
        XCTAssertTrue(en.staticTexts["0/5 wins in Easy to unlock"].exists)
    }

    func test6_Createur() {
        // Brouillon : grille de référence avec 4 chiffres retirés (plusieurs solutions).
        let draft = String(repeating: ".", count: 18) + "001806400008102900700000008006708200002609500800203009005010300"
        let app = launch(extra: ["-creatorDraft", draft])
        app.buttons["Créer une grille"].tap()
        XCTAssertTrue(app.staticTexts["Analyse"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Plusieurs solutions possibles : ajoute des chiffres pour qu'il n'y en ait qu'une."].waitForExistence(timeout: 10))
        snap("50 Créateur : plusieurs solutions")

        // Conflit : un 7 en haut de la colonne 1, qui contient déjà un 7.
        element(app, "create-0").tap()
        element(app, "createKey-7").tap()
        XCTAssertTrue(app.staticTexts["Conflit : un chiffre apparaît deux fois dans une ligne, une colonne ou un bloc."].waitForExistence(timeout: 5))
        snap("51 Créateur : conflit")
        element(app, "createKey-7").tap() // retaper le même chiffre l'efface

        // Suivre les suggestions jusqu'à une grille valide.
        var n = 0
        while !element(app, "validPuzzle").exists && n < 20 {
            let add = app.buttons["addSuggestion"].firstMatch
            if add.waitForExistence(timeout: 3) { add.tap() }
            n += 1
        }
        XCTAssertTrue(element(app, "validPuzzle").waitForExistence(timeout: 5), "La grille doit devenir valide")
        app.swipeUp()
        XCTAssertTrue(element(app, "customCode").label.hasPrefix("SKN1-C-"))
        snap("52 Créateur : grille valide et code")

        element(app, "playCustom").tap()
        XCTAssertTrue(element(app, "cell-0").waitForExistence(timeout: 30))
        snap("53 Grille créée en jeu")
    }

    func test7_PlusieursPartiesEtHistorique() {
        let app = launch(prefill: 30)
        for _ in 0..<2 {
            element(app, "level-F").tap()
            XCTAssertTrue(element(app, "cell-0").waitForExistence(timeout: 30))
            element(app, "closeGame").tap()
        }
        XCTAssertTrue(app.staticTexts["+ 1 autre partie en cours"].waitForExistence(timeout: 5))
        snap("60 Accueil : deux parties en cours")
        app.swipeUp()
        app.buttons["Historique"].tap()
        XCTAssertTrue(app.staticTexts["En cours"].waitForExistence(timeout: 5) || app.staticTexts["EN COURS"].exists)
        snap("61 Historique")
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Facile, '")).firstMatch.tap()
        XCTAssertTrue(element(app, "cell-0").waitForExistence(timeout: 10), "Reprise depuis l'historique")
    }

    /// Le fichier StoreKit de test n'est appliqué que par Xcode (⌘R), pas par `xcodebuild test`.
    /// Ici on vérifie la section ; l'achat se teste à la main dans Xcode.
    func test8_Dons() throws {
        let app = launch()
        app.buttons["Réglages"].firstMatch.tap()
        let header = app.staticTexts["Soutenir Sudokuno"]
        var swipes = 0
        while !header.exists && swipes < 8 { app.swipeUp(); swipes += 1 }
        XCTAssertTrue(header.waitForExistence(timeout: 5))
        XCTAssertFalse(app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS 'Ko-fi'")).firstMatch.exists,
                       "Le lien Ko-fi doit avoir disparu")
        let small = app.buttons["tip-com.alexafer.sudokuno.tip.small"]
        let unavailable = app.staticTexts["Dons indisponibles pour le moment."]
        XCTAssertTrue(small.waitForExistence(timeout: 10) || unavailable.exists)
        snap("70 Pot à pourboires")
        guard small.exists else { throw XCTSkip("StoreKit de test non chargé hors de Xcode : achat à vérifier avec ⌘R") }
        small.tap()
        XCTAssertTrue(app.alerts["Merci ! 💜"].waitForExistence(timeout: 30))
        snap("72 Merci")
    }

    func test9_AbandonEtReprise() {
        let app = launch(prefill: 30)
        element(app, "level-F").tap()
        XCTAssertTrue(element(app, "cell-0").waitForExistence(timeout: 30))
        // Une note, pour vérifier que tout l'état est conservé
        let target = emptyCells(app)[0]
        let targetID = target.identifier
        target.tap()
        element(app, "notesButton").tap()
        let key = (1...9).map { element(app, "key-\($0)") }.first(where: \.isEnabled)!
        key.tap()
        XCTAssertTrue(element(app, targetID).label.contains("notes"))
        element(app, "notesButton").tap()
        snap("79 Avant le menu")

        app.buttons["Plus d'options"].tap()
        let item = app.buttons["Abandonner la partie"]
        XCTAssertTrue(item.waitForExistence(timeout: 5))
        snap("79b Menu ouvert")
        item.tap()
        let confirm = app.buttons.matching(NSPredicate(format: "label == 'Abandonner'")).firstMatch
        XCTAssertTrue(confirm.waitForExistence(timeout: 5), "La confirmation doit apparaître")
        snap("80 Confirmation d'abandon")
        confirm.tap()

        // Retour à l'accueil : plus de partie en cours
        XCTAssertTrue(element(app, "dailyPlay").waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Reprendre'")).firstMatch.exists)
        app.swipeUp()
        app.buttons["Historique"].tap()
        let row = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Abandonnée'")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5), "La partie abandonnée doit être dans l'historique")
        snap("81 Historique avec partie abandonnée")

        // Reprise : même état (30 cases vides, la note est là)
        row.tap()
        XCTAssertTrue(element(app, "cell-0").waitForExistence(timeout: 10))
        XCTAssertEqual(emptyCells(app).count, 30)
        XCTAssertTrue(element(app, targetID).label.contains("notes"), "Les notes doivent être conservées")
        snap("82 Partie reprise")
        element(app, "closeGame").tap()

        // Elle est de nouveau « en cours » et n'est plus dans les terminées
        XCTAssertTrue(app.staticTexts["En cours"].waitForExistence(timeout: 5) || app.staticTexts["EN COURS"].exists)
        XCTAssertFalse(app.buttons.matching(NSPredicate(format: "label CONTAINS 'Abandonnée'")).firstMatch.exists)
    }

    func test4_IPadPaysage() throws {
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .pad, "iPad uniquement")
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = launch(prefill: 20)
        snap("30 iPad accueil paysage")
        element(app, "level-F").tap()
        XCTAssertTrue(element(app, "cell-0").waitForExistence(timeout: 30))
        let cell = emptyCells(app).first!
        let id = cell.identifier
        cell.tap()
        snap("31 iPad partie paysage")
        // Clavier physique : N active les notes, 1 pose une note
        app.typeKey("n", modifierFlags: [])
        app.typeKey("1", modifierFlags: [])
        XCTAssertTrue(element(app, id).label.contains("notes"), "Les raccourcis clavier doivent fonctionner")
        XCUIDevice.shared.orientation = .portrait
    }

    /// Niveau Légende : débloqué, liste des grilles célèbres, une grille jouée jusqu'au bout.
    func test10_Legende() {
        let app = launch(prefill: 1, extra: ["-debugUnlockAll", "YES"])
        app.swipeUp()
        let row = element(app, "level-L")
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        snap("90 Accueil avec Légende")
        row.tap()
        let escargot = element(app, "legend-escargot")
        XCTAssertTrue(escargot.waitForExistence(timeout: 5), "La liste des Légendes doit s'afficher")
        XCTAssertTrue(app.staticTexts["AI Escargot"].exists)
        XCTAssertTrue(app.staticTexts["Pas encore résolue"].firstMatch.exists)
        snap("91 Liste des Légendes")
        escargot.tap()
        XCTAssertTrue(element(app, "cell-0").waitForExistence(timeout: 30))
        XCTAssertTrue(app.staticTexts["AI Escargot"].waitForExistence(timeout: 5), "Le titre doit être le nom de la grille")
        snap("92 Partie AI Escargot")
        // Dernière case : on essaie les chiffres jusqu'à la victoire.
        emptyCells(app)[0].tap()
        for d in 1...9 {
            let key = element(app, "key-\(d)")
            guard key.isEnabled else { continue }
            key.tap()
            if element(app, "completionTitle").waitForExistence(timeout: 1) { break }
            if element(app, "undoButton").isEnabled { element(app, "undoButton").tap() }
        }
        XCTAssertTrue(element(app, "completionTitle").waitForExistence(timeout: 5))
        snap("93 Légende réussie")
        element(app, "completionHome").tap()
        // Retour à la liste des Légendes (la navigation y est restée).
        if !element(app, "legend-escargot").waitForExistence(timeout: 3) {
            app.swipeUp()
            XCTAssertTrue(element(app, "level-L").waitForExistence(timeout: 5))
            element(app, "level-L").tap()
        }
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Résolue'")).firstMatch.waitForExistence(timeout: 5))
        snap("94 Légende résolue dans la liste")
    }
}
