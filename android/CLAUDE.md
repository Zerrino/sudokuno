# Sudokuno Android

- Module `sudokukit` : moteur Kotlin pur, traduction exacte du Swift. Tests : `./gradlew :sudokukit:test`.
  `CrossPlatformTest.kt` contient des valeurs calculées par le moteur Swift : ne jamais les modifier.
- Module `app` : Jetpack Compose, Material 3. Navigation maison (`ui/App.kt`, `Router`), état dans `model/AppModel.kt`
  (fichier JSON local), réglages dans `model/Settings.kt`.
- Textes : `L("texte français")` (`i18n/L10n.kt`), traductions dans `../tools/translations.py`.
  Dans une chaîne Kotlin, écrire `%1\$lld` (le `$` doit être échappé).
- Tests d'interface : `./gradlew :app:connectedDebugAndroidTest` (émulateur `Sudokuno_Pixel`). Les extras de debug
  (`debugReset`, `debugDemo`, `debugPrefillAllBut`, `debugElapsed`, `debugFillNotes`, `appLanguage`, `theme`, `debugOpenURL`) n'existent qu'en debug.
  Les tests désinstallent l'app à la fin : relancer `./gradlew :app:installDebug` ensuite pour que l'utilisateur la retrouve.
- Tout état affiché par Compose doit être un état observé (`mutableStateOf`…) : sinon l'écran ne se met pas à jour (bug du bouton Annuler).
- Dans le code Compose, pas de `delay()` dans les effets qui doivent tourner pendant les tests : l'horloge des tests est virtuelle.
- Captures Google Play : `ScreenshotTest.kt` (argument `screenshotLang`) puis `swift tools/play_assets.swift`.
- compileSdk 37 (exigé par Compose), targetSdk 36, minSdk 26.
