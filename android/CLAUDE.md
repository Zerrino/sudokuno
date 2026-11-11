# Sudokuno Android

- Module `sudokukit` : moteur Kotlin pur, traduction exacte du Swift. Tests : `./gradlew :sudokukit:test`.
  `CrossPlatformTest.kt` contient des valeurs calculées par le moteur Swift : ne jamais les modifier.
- Module `app` : Jetpack Compose, Material 3. Navigation maison (`ui/App.kt`, `Router`), état dans `model/AppModel.kt`
  (fichier JSON local), réglages dans `model/Settings.kt`.
- Textes : `L("texte français")` (`i18n/L10n.kt`), traductions dans `../tools/translations.py`.
  Dans une chaîne Kotlin, écrire `%1\$lld` (le `$` doit être échappé).
- Tests d'interface : `./gradlew :app:connectedDebugAndroidTest` (émulateur `Sudokuno_Pixel`). Les extras de debug
  (`debugReset`, `debugDemo`, `debugPrefillAllBut`, `debugElapsed`, `appLanguage`, `theme`, `debugOpenURL`) n'existent qu'en debug.
- Dans le code Compose, pas de `delay()` dans les effets qui doivent tourner pendant les tests : l'horloge des tests est virtuelle.
- Captures Google Play : `ScreenshotTest.kt` (argument `screenshotLang`) puis `swift tools/play_assets.swift`.
- compileSdk 37 (exigé par Compose), targetSdk 36, minSdk 26.
