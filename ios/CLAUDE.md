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
- Légende : grilles célèbres de `Legends` (jamais générées), jouées et partagées avec leur code `SKN1-C-…`. Classement au score seulement (`sudokuno.score.L`). Identifiants Game Center / Play Jeux : `Level.servicesLetter` (Diabolique reste « X »).
- Jamais de `SystemRandomNumberGenerator`, `shuffle()`, `Hasher` ni d'itération de `Set` dans la génération.
- La grille du jour et la série utilisent les jours UTC (`DayStamp`).
- Interface en français ; grille opaque, Liquid Glass seulement pour les contrôles.

## Traductions
- Tout texte affiché passe par `L("texte français")` (ou `L("format %@", arg)`), voir `Sudokuno/Model/Localization.swift`.
- Les traductions (communes iOS et Android) sont dans `../tools/translations.py` ; depuis la racine du dépôt, `python3 tools/translations.py` régénère `ios/Sudokuno/Localizable.xcstrings` et `android/app/src/main/assets/i18n.json`. Le script échoue s'il manque une traduction.

## Codes de grille
- `SKN1-F/M/D/E/Z-…` : graine du générateur (`X` = ancien Diabolique v1, toujours lu) ; `SKN1-J-AAAAMMJJ` : grille du jour ; `SKN1-C-…` : grille créée ou Légende, le code contient la grille.

## Explication pas à pas et classements
- `Explainer.explain` (moteur) déroule toute la résolution ; `LogicStep.digits / units / chain` ne servent qu'à l'expliquer et ne doivent
  jamais influencer les coups trouvés. Les phrases sont dans `Features/Explain/StepText.swift` (copie exacte : `ui/ExplainScreen.kt` côté Android).
- Toutes les grilles (jeu, créateur, explication) passent par `BoardFrame`.
- Classements : seules les grilles parfaites sont envoyées (sans indice, sans erreur, jamais terminée ni abandonnée avant), voir `AppModel.complete`.
  `LevelStats.bestRankedSeconds` et `DailyResult.ranked` servent au renvoi à la connexion.
- Recherche : `docs/research/sudoku-experts-et-explication.md` (techniques à ajouter, pistes pour un générateur v3).
- Grilles Légende : quand `LogicalSolver.nextStep` est à court, `Explainer` utilise des preuves par l'absurde (`ForcingChains.swift`,
  techniques `forcingChain` / `forcingNet`). Elles ne servent QU'À l'explication : jamais dans `nextStep`, `Grader` ni le générateur.
  Les 8 Légendes s'expliquent sans aucune case révélée (tests des deux côtés, preuves rejouées par un vérificateur indépendant).
  Le calcul prend quelques secondes : `Explainer.explain(onStep:)` livre les étapes au fur et à mesure.
- Replay : `GameSession` tient un journal des coups (`Move.packed`, `Model/Playback.swift`), enregistré dans `SavedGame.moves`
  et `HistoryEntry.playback` ; écran `Features/Playback/PlaybackView.swift`. Une partie reprise d'une sauvegarde sans journal n'a pas de replay.
- Dans une `List`, ne jamais mettre un bouton à l'intérieur du bouton d'une ligne : le placer à côté (voir `HistoryView.reviewButton`).
- Coach : `StepText.tip` (« Comment le repérer ») et l'hypothèse déroulée sur la grille (`ForcingProof.state(after:)`, grille fixée
  en haut de l'écran). Sources et pistes restantes (SK-loop, chaînes groupées, Exocet) : `docs/research/sudoku-coach-et-grilles-extremes.md`.
- Motifs d'experts (`ExpertPatterns.swift` / `.kt`) : SK-loop et chaînes groupées, essayés par `Explainer` avant les preuves par l'absurde.
  Explication seulement, comme elles. La SK-loop d'Easter Monster (13 éliminations) sert de test de référence.

## Règles de jeu, score, historique
- Erreurs : `Level.mistakeLimit` (5 en Facile, 3 en Moyen, 1 en Difficile et Expert) ; une erreur de plus et la grille est ratée
  (`GameSession.isFailed`, `AppModel.fail`, `HistoryEntry.failed`). Une grille ratée n'est jamais une victoire : utiliser `HistoryEntry.isWin`.
- Mode validation (`GameSession.strict`) : toujours à partir de Diabolique, partout avec le réglage « Mode difficile ». RIEN ne doit trahir
  une erreur avant `validate()` : pas de compteur, pas de rouge, notes effacées et touches grisées comme si le chiffre était juste.
- Indices : `GameSession.hintsEnabled` suit le réglage tant qu'aucun indice n'a servi dans la partie (`syncHints`). Plus de bouton Annuler.
- Score v2 : `Scoring` / `ScoreTracker` (moteur, identique des deux côtés, valeurs dans `CrossPlatformTest.scoresMatchSwift`).
  Chaque chiffre juste est jugé quand il est posé : déductible, il rapporte les points de la technique la plus simple qui
  permettait alors d'avancer dans la grille (`Scoring.points`, le « goulot » : remplir d'abord les cases dures ne rapporte pas
  plus), × 0,5 à 1,5 selon le temps depuis le chiffre juste précédent ; sinon c'est un coup de chance (2 points), de même
  qu'un chiffre trouvé après un essai faux dans la case. −25 par erreur. En Légende, la recherche va jusqu'aux preuves par
  l'absurde (score seulement : jamais dans `nextStep`, `Grader` ni le générateur). Changer le calcul = incrémenter
  `Scoring.version` (l'historique est recalculé au lancement).
- Score calculé en arrière-plan après la victoire (`AppModel.scoreWin`), enregistré dans `HistoryEntry.score`, puis envoyé aux
  classements notés dans `HistoryEntry.boards`. Tous les classements sont au score (version 1.0.14, identifiants neufs : les
  anciens au temps ne servent plus). Total = meilleur score de chaque grille réussie (`PersistedState.scoredCodes`).
- Score en direct (`GameSession.liveScore`, réglage « Afficher le score en jouant ») : jamais en mode validation.
  Replay : `Scoring.analyze` commente chaque coup (technique, plus simple ailleurs, chance, indice).
- Historique : toucher une partie finie ouvre `PlaybackView` sur la grille telle qu'elle a été laissée. Les grilles partagées réussies
  comptent dans les statistiques de leur niveau (pas dans les records ni le déblocage).
- Bac à sable = l'ancien créateur (`CreatorView`), avec import du presse-papiers (81 chiffres ou code Sudokuno).
- Réglage « Grand écran » (`SettingKey.bigScreen`) : marges réduites, touches et notes agrandies.
