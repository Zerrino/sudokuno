# Sudokuno

App iOS/iPadOS de Sudoku (SwiftUI, iOS 26+), gratuite, sans pub ni tracking. Plan : `docs/PLAN.md`.

- `Packages/SudokuKit` : moteur pur Swift (copie Kotlin dans `../android/sudokukit`, à garder identique) (solveur, générateur, évaluation, indices, codes, série). Tests : `cd Packages/SudokuKit && swift test`.
- `Sudokuno/` : l'app. Le projet Xcode est généré par XcodeGen depuis `project.yml` : après ajout/suppression de fichiers, lancer `xcodegen generate`.
- Build simulateur : `xcodebuild -project Sudokuno.xcodeproj -scheme Sudokuno -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath build CODE_SIGNING_ALLOWED=NO build`
- Ouvrir une grille au lancement (Debug) : `xcrun simctl launch <udid> com.alexafer.sudokuno -debugOpenURL "sudokuno://p/<code>"`

## Règles
- Le générateur est FIGÉ : les codes partagés et la grille du jour en dépendent. Ne jamais modifier le comportement de `SeededRandom`, `Solver.randomSolution`, `Generator`, `LogicalSolver` (ordre des techniques) ni `DailySchedule` sans créer une nouvelle version. `Golden.swift` doit toujours passer.
- Versions : v1 = Diabolique d'origine (codes `SKN1-X-…`, `PuzzleCode.diaboliqueV1`, `Generator.generate(version: 1)`). v2 = Diabolique avec chaînes obligatoires (au moins 3 coups de chaîne dont une vraie chaîne, codes `SKN1-Z-…`). Facile → Expert et la grille du jour sont identiques dans les deux versions : jusqu'à Expert, le classement se fait sans les chaînes.
- Les chaînes (`LogicalSolver.chain()`, AIC la plus courte, 12 nœuds max) sont essayées en dernier ; une nouvelle technique se place toujours après les existantes.
- Légende : grilles célèbres de `Legends` (jamais générées), jouées et partagées avec leur code `SKN1-C-…`. Pas de classement Game Center pour la Légende. Identifiants Game Center / Play Jeux : `Level.servicesLetter` (Diabolique reste « X »).
- Jamais de `SystemRandomNumberGenerator`, `shuffle()`, `Hasher` ni d'itération de `Set` dans la génération.
- La grille du jour et la série utilisent les jours UTC (`DayStamp`).
- Interface en français ; grille opaque, Liquid Glass seulement pour les contrôles.

## Traductions
- Tout texte affiché passe par `L("texte français")` (ou `L("format %@", arg)`), voir `Sudokuno/Model/Localization.swift`.
- Les traductions (communes iOS et Android) sont dans `../tools/translations.py` ; depuis la racine du dépôt, `python3 tools/translations.py` régénère `ios/Sudokuno/Localizable.xcstrings` et `android/app/src/main/assets/i18n.json`. Le script échoue s'il manque une traduction.

## Codes de grille
- `SKN1-F/M/D/E/Z-…` : graine du générateur (`X` = ancien Diabolique v1, toujours lu) ; `SKN1-J-AAAAMMJJ` : grille du jour ; `SKN1-C-…` : grille créée ou Légende, le code contient la grille.
