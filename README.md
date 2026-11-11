# Sudokuno

Sudoku pour **iPhone, iPad et Android** : gratuit, sans publicité, sans suivi.

- Sudoku du jour commun à tous (UTC), série à la Duolingo avec gels
- 5 niveaux à débloquer, grilles générées dans l'app et classées par technique (Diabolique : chaînes d'inférences obligatoires)
- Niveau Légende : les grilles célèbres pour leur difficulté (AI Escargot, Easter Monster, Golden Nugget…)
- Indices pédagogiques en 3 étapes, créateur de grilles avec analyse et difficulté automatique
- Codes de grille pour défier ses amis : **un même code donne la même grille sur iOS et Android**
- Historique, plusieurs parties en cours, abandon et reprise
- Game Center / Google Play Jeux, dons facultatifs en achat intégré
- Français, anglais, néerlandais, portugais, chinois simplifié · mode sombre

Site, confidentialité et mentions légales : https://zerrino.github.io/sudokuno/

## Organisation

| Dossier | Contenu |
|---|---|
| `ios/` | App iOS/iPadOS (SwiftUI) et moteur `SudokuKit` en Swift. Publication : `ios/docs/APP_STORE.md` |
| `android/` | App Android (Jetpack Compose) et moteur `sudokukit` en Kotlin. Publication : `android/docs/PLAY_STORE.md` |
| `tools/translations.py` | Traductions communes : génère le catalogue iOS et `android/app/src/main/assets/i18n.json` |
| `site/` | Site GitHub Pages (aide, confidentialité, mentions légales) |

## iOS
Prérequis : Xcode 26, XcodeGen (`brew install xcodegen`).
```
cd ios && xcodegen generate && open Sudokuno.xcodeproj      # puis ⌘R
cd ios/Packages/SudokuKit && swift test                     # moteur
```

## Android
Prérequis : JDK 21, SDK Android (plateformes 36 et 37). Gradle passe par le wrapper.
```
cd android
./gradlew :sudokukit:test                  # moteur, dont les tests de compatibilité avec iOS
./gradlew :app:installDebug                # installe sur l'émulateur ou le téléphone branché
./gradlew :app:connectedDebugAndroidTest   # tests d'interface sur l'émulateur
```
Ou ouvrir le dossier `android/` dans Android Studio.
