# Sudokuno Android

- Module `sudokukit` : moteur Kotlin pur, traduction exacte du Swift. Tests : `./gradlew :sudokukit:test`.
  `CrossPlatformTest.kt` contient des valeurs calculées par le moteur Swift : ne jamais les modifier.
  Versions du générateur, chaînes et Légende : voir `../ios/CLAUDE.md` (mêmes règles des deux côtés).
- Module `app` : Jetpack Compose, Material 3. Navigation maison (`ui/App.kt`, `Router`), état dans `model/AppModel.kt`
  (fichier JSON local), réglages dans `model/Settings.kt`.
- Textes : `L("texte français")` (`i18n/L10n.kt`), traductions dans `../tools/translations.py`.
  Dans une chaîne Kotlin, écrire `%1\$lld` (le `$` doit être échappé).
- Tests d'interface : `./gradlew :app:connectedDebugAndroidTest` (émulateur `Sudokuno_Pixel`). Les extras de debug
  (`debugReset`, `debugDemo`, `debugPrefillAllBut`, `debugElapsed`, `debugFillNotes`, `debugUnlockAll`, `debugLeaderboard` (classements d'exemple), `appLanguage`, `theme`, `debugOpenURL`) n'existent qu'en debug.
  Les tests désinstallent l'app à la fin : relancer `./gradlew :app:installDebug` ensuite pour que l'utilisateur la retrouve.
- Tout état affiché par Compose doit être un état observé (`mutableStateOf`…) : sinon l'écran ne se met pas à jour (bug du bouton Annuler).
- Dans le code Compose, pas de `delay()` dans les effets qui doivent tourner pendant les tests : l'horloge des tests est virtuelle.
- Captures Google Play : `ScreenshotTest.kt` (argument `screenshotLang`) puis `swift tools/play_assets.swift`.
- compileSdk 37 (exigé par Compose), targetSdk 36, minSdk 26.
- Les identifiants Play Jeux (`games-ids.xml`) sont lus par leur nom (`getIdentifier`) : `res/raw/keep.xml` empêche le
  build Release de les supprimer. Sans lui, aucun score ni succès n'est envoyé (bug des versions 1.0.1 à 1.0.6).
  Après un test de l'APK release sur l'émulateur, le désinstaller avant les tests (signature différente).
- Écrans : un fichier par écran dans `ui/` ; les éléments partagés (`SectionCard`, `LinkRow`, `ChevronRow`, `StatusLine`…) sont dans
  `ui/Components.kt`, le cadre de grille commun `BoardFrame` dans `ui/GameScreen.kt`.
- Explication pas à pas : `ui/ExplainScreen.kt` (extra de debug `debugExplain` = grille de 81 caractères). Mêmes phrases qu'iOS (`StepText`).
- Classements : seules les grilles parfaites sont envoyées, voir `AppModel.complete` et `../ios/CLAUDE.md`.
- Légendes expliquées par l'absurde (`kit/ForcingChains.kt`) et replay de l'historique (`ui/PlaybackScreen.kt`, journal `Move` dans
  `model/GameSession.kt`) : mêmes règles qu'iOS, voir `../ios/CLAUDE.md`.
