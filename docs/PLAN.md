# Sudokuno : plan d'approche

> Statut : v3 (10/11/2026). V1 codée, voir la section 0.
> Recherche sur le fonctionnement du Sudoku : [`docs/research/sudoku-fonctionnement.md`](research/sudoku-fonctionnement.md)

## 0. État d'avancement (10/11/2026)

**Fait et testé :**
- moteur `SudokuKit` avec 31 tests (`cd Packages/SudokuKit && swift test`) ;
- app iPhone et iPad : accueil, 5 niveaux à débloquer, grille du jour en UTC, série avec gels et jalons, indices en 3 étapes, codes de grille et défis, partage, Game Center (classements avec les indices, succès), réglages avec mode sombre, statistiques, rappel local ;
- icône (clair, sombre, teintée), manifeste de confidentialité.

**Changements par rapport au plan v2 :**
- **Plus de grilles embarquées.** La génération est très rapide (environ 0,5 ms par grille en Release, Diabolique compris), donc l'app génère tous les niveaux et la grille du jour à partir d'une graine. Les tests de référence (`Golden.swift`) figent le générateur v1.
- **Pas de domaine.** Les liens partagés utilisent `sudokuno://p/<code>?t=…&h=…`, et l'écran « Entrer un code » accepte le message entier collé. La politique de confidentialité est dans `site/index.html`, à publier sur GitHub Pages.
- **Persistance.** Un fichier JSON local remplace SwiftData : plus simple, et suffisant ici.
- **Niveaux et techniques réellement codés :** Facile = singletons ; Moyen = pointage, bloc-ligne, paires ; Difficile = triplets, X-Wing ; Expert = XY-Wing, Swordfish, XYZ-Wing ; Diabolique = au-delà de ces techniques.

**Ajouté le 11/11/2026 :**
- 5 langues (français, anglais, néerlandais, portugais du Portugal, chinois simplifié), choix dans les réglages, changement immédiat ;
- créateur de grilles : détection des conflits, de l'absence de solution et des solutions multiples (avec chiffre suggéré), niveau calculé automatiquement, code `SKN1-C-…` qui contient la grille entière ;
- historique : plusieurs parties en cours à la fois, grilles terminées à rejouer ou partager ;
- pot à pourboires en achat intégré (3 dons consommables à 0,99 €, 2,99 € et 4,99 €) à la place du lien Ko-fi, conforme à la règle 3.1.1. Configuration : `docs/IN_APP_PURCHASES.md`.

**Reste à faire :**
- vérification visuelle sur iPad en paysage ;
- choix du chiffre d'abord puis des cases (mode de saisie optionnel) ;
- widget (V1.1) ;
- configuration Game Center dans App Store Connect (`docs/GAME_CENTER.md`) ;
- publication de la politique de confidentialité et mise à jour de son URL dans `SettingsView` ;
- équipe de signature dans Xcode ;
- captures d'écran, TestFlight.

## 1. Vision et contraintes

**Sudokuno** : une app de Sudoku **complète, gratuite et propre** pour **iPhone et iPad**, publiable sur l'App Store :

- **Aucune publicité, aucun tracking, aucun compte à créer.** Seuls achats intégrés : des dons facultatifs qui ne débloquent rien. Le jeu fonctionne hors ligne, seul Game Center utilise le réseau.
- Des grilles générées automatiquement, avec des **niveaux qui se débloquent**.
- **Chaque grille a un code** : on le partage avec son temps et ses indices, et n'importe qui peut jouer la même grille.
- **Game Center** : classements (avec le nombre d'indices utilisés) et succès.
- Un **Sudoku du jour** identique pour tous les joueurs, avec une **série (streak) à la Duolingo**.
- **3 indices gratuits par grille**, qu'on peut activer ou désactiver dans les réglages.
- Mode **clair / sombre / système**.
- Une interface native iOS soignée (Liquid Glass, SF Pro, haptique, accessibilité).

Conséquence importante : on n'a **aucun serveur à nous**. Game Center est hébergé par Apple, et le partage passe par un code ou par un lien vers une page statique. L'app ne collecte rien elle-même, donc pas de coût d'hébergement et un examen Apple plus simple.

## 2. Choix techniques

| Sujet | Choix | Pourquoi |
|---|---|---|
| Langage / UI | Swift 6 + SwiftUI | Natif, moderne, suffisant pour tout |
| iOS minimum | **iOS 26** | Liquid Glass natif, `@Observable`, SwiftData mature. Une seule base de code, sans `if #available` |
| État | `@Observable` (Observation) | Plus simple que `ObservableObject` |
| Persistance | **SwiftData** (parties, stats, série) + `@AppStorage` (réglages) | Local, sans serveur |
| Logique Sudoku | **Package Swift local `SudokuKit`** sans dépendance à SwiftUI | Testable seul, rapide à compiler, réutilisable pour un widget |
| Tests | Swift Testing (`@Test`) avec une approche TDD sur le moteur | Le moteur doit être correct à 100 % |
| Dépendances externes | **Aucune** | Pas de risque de confidentialité ni de maintenance |

> ⚠️ Xcode installé : 26.6. Apple impose régulièrement le dernier SDK pour les nouvelles soumissions. Vérifie l'exigence en vigueur avant de publier et mets Xcode à jour si besoin.

### Structure du projet

```
IOS-APP/
├── Sudokuno.xcodeproj
├── Sudokuno/                     # Cible app (iPhone + iPad)
│   ├── App/                      # @main, ModelContainer, navigation racine
│   ├── Features/
│   │   ├── Home/                 # Accueil : carte du jour, série, "Nouvelle partie"
│   │   ├── Game/                 # Plateau, pavé numérique, notes, indices, chrono
│   │   ├── Levels/               # Choix de la difficulté, reprise de partie
│   │   ├── Daily/                # Sudoku du jour + calendrier
│   │   ├── Streak/               # Flamme, jalons, gels de série
│   │   ├── Stats/                # Statistiques par niveau
│   │   ├── Share/                # Code de grille, carte de partage, ouverture de liens
│   │   ├── GameCenter/           # Authentification, envoi des scores, classements dans l'app
│   │   └── Settings/             # Thème, indices, aides, haptique, notifications
│   ├── DesignSystem/             # Couleurs, typographie, composants
│   └── Resources/                # Assets, daily_puzzles.json, Localizable.xcstrings
├── Packages/SudokuKit/           # Moteur pur Swift
│   ├── Sources/SudokuKit/
│   │   ├── Grid.swift            # Représentation 81 cases + bitmasks de candidats
│   │   ├── Solver.swift          # Solveur rapide (backtracking + propagation)
│   │   ├── Generator.swift       # Grille pleine → retrait d'indices → unicité
│   │   ├── LogicalSolver.swift   # Solveur "humain" par techniques
│   │   ├── Grader.swift          # Difficulté = technique la plus dure requise
│   │   ├── HintEngine.swift      # Prochain coup logique + explication
│   │   ├── SeededRandom.swift    # PRNG déterministe (SplitMix64 / xoshiro256**)
│   │   ├── PuzzleCode.swift      # Encodage / décodage du code de grille
│   │   └── Transformations.swift # Permutations qui préservent difficulté et unicité
│   └── Tests/SudokuKitTests/
├── Tools/DailyPuzzleBuilder/     # Exécutable : daily_puzzles.json + grilles de base Expert / Diabolique
└── site/                         # Page statique (GitHub Pages) : confidentialité, liens de partage, apple-app-site-association
```

## 3. Le moteur Sudoku (`SudokuKit`)

C'est le cœur de l'app, et on le construit **en premier, test par test** (skill `tdd`).

1. **Représentation** : tableau de 81 `UInt8` plus des masques de bits de 9 bits par ligne, colonne et bloc. Vérifier un placement prend un seul `&`.
2. **Solveur rapide** : backtracking avec propagation de contraintes et heuristique MRV (on choisit d'abord la case qui a le moins de candidats). Il compte les solutions **jusqu'à 2** pour vérifier l'unicité.
3. **Générateur** :
   1. on remplit une grille complète au hasard (backtracking avec ordre des chiffres mélangé) ;
   2. on retire des indices, de façon symétrique si possible, en vérifiant après chaque retrait qu'il reste **une seule solution** ;
   3. on évalue la grille avec le `Grader`. Si elle ne tombe pas dans le niveau demandé, on recommence.
4. **Solveur logique et évaluation** : on résout comme un humain, technique par technique, de la plus simple à la plus dure. Le niveau est donné par **la technique la plus difficile nécessaire**, pas par le nombre d'indices.
5. **Performance** : la génération des niveaux difficiles peut prendre du temps. On génère donc en tâche de fond (`Task.detached`) et on garde **un tampon d'une ou deux grilles prêtes par niveau**, ce qui rend le lancement d'une partie instantané.

### Niveaux

| Niveau | Techniques requises (au plus) | Indices (environ) |
|---|---|---|
| Facile | Singletons nus et cachés uniquement | 36–45 |
| Moyen | + Paires, pointage / réduction bloc-ligne | 30–35 |
| Difficile | + Triplets, X-Wing, Swordfish, XY/XYZ-Wing | 27–31 |
| Expert | + Jellyfish, rectangles d'unicité, coloriage, chaînes courtes | 23–27 |
| Diabolique | + AIC, ALS, chaînes forcées | 17–24 |

*Les plages d'indices sont seulement indicatives : c'est le Grader qui décide. Les grilles Expert et Diabolique sont pré-générées hors ligne et embarquées dans l'app, parce que leur génération dans l'app peut être lente.*

**Règles du PRNG** (voir la recherche, §6) : on écrit nous-mêmes SplitMix64 / xoshiro256**, le mélange de Fisher–Yates et le tirage borné. On n'utilise jamais `SystemRandomNumberGenerator`, `Hasher`, `shuffle()` de la bibliothèque standard ni l'ordre d'itération d'un `Set`. Des **tests de référence** figent la sortie pour une graine donnée, et le générateur porte un numéro de version.

### Déblocage des niveaux ✅ décidé

| Niveau | Condition de déblocage |
|---|---|
| Facile | Ouvert dès le départ |
| Moyen | 5 grilles Facile réussies |
| Difficile | 10 grilles Moyen réussies |
| Expert | 10 grilles Difficile réussies |
| Diabolique | 10 grilles Expert réussies |

- Les seuils sont des constantes, à ajuster après TestFlight. Les indices utilisés ne bloquent pas la progression.
- On voit les niveaux verrouillés, avec un cadenas et une barre de progression (« 3 / 10 »). Au déblocage : une animation, un succès Game Center et un retour haptique.
- **La grille du jour et les grilles partagées par code sont toujours jouables, même si leur niveau est verrouillé.** Elles ne comptent pas pour le déblocage, ce qui évite de « tricher » en se faisant envoyer des codes.

## 4. Sudoku du jour, commun à tous

**Problème** : tous les joueurs doivent avoir la même grille le même jour, **sans serveur**.

**Solution retenue : grilles pré-générées et embarquées dans l'app.**
- Un petit outil (`Tools/DailyPuzzleBuilder`) génère **3 à 5 ans de grilles du jour** dans `daily_puzzles.json` : date, grille, solution, niveau. Cela représente environ 1 800 × 170 octets, soit à peu près 300 Ko.
- ⚠️ **Changement lié à Game Center : la grille du jour suit la date UTC.** Elle change à **minuit UTC**, soit 1 h du matin à Paris en hiver et 2 h en été.
  - **Pourquoi :** un classement Game Center récurrent se remet à zéro à la même heure UTC pour tout le monde. Si la grille suivait la date locale, un joueur de Tokyo et un joueur de Paris joueraient deux grilles différentes dans le même classement.
  - La date se calcule avec un calendrier grégorien forcé en UTC.
  - Une grille commencée reste la même même si on passe minuit en cours de partie. En revanche, le score n'est envoyé au classement du jour que si la grille est **finie avant la remise à zéro**.
- **Avantages** : on peut vérifier chaque grille à l'avance (unicité, niveau), et une mise à jour du générateur ne change jamais les grilles passées.
- La difficulté suit la semaine, comme les journaux : lundi Facile, puis une montée progressive jusqu'à dimanche Expert.
- **Solution de secours** : si le fichier est épuisé, on génère à partir d'une graine dérivée de la date, avec notre propre PRNG. Le générateur de nombres aléatoires de Swift et `Hasher` **ne sont pas déterministes** d'une exécution ou d'une version à l'autre.
- La grille du jour a aussi un code de partage (voir section 6).

## 5. Série à la Duolingo

On s'appuie sur le skill `streak-tracker` (apple-skills) pour le squelette.

- **Règle** : la série augmente de 1 quand on **termine la grille du jour** pendant sa journée UTC. La série est donc liée à la grille, pas à l'heure locale. C'est cohérent avec Game Center et ça résiste aux voyages.
- **Flamme** sur l'accueil, avec son compteur et une animation au moment où elle augmente : confettis légers, haptique `.success`, chiffre animé avec `contentTransition(.numericText())`.
- **Calendrier** : un mois en grille avec les jours réussis, gelés ou manqués, et la possibilité de **rejouer les grilles du jour passées**. Ces rattrapages ne comptent pas pour la série.
- **Gels de série** : on en gagne 1 tous les 7 jours de série, avec 2 au maximum en stock. Un gel s'utilise automatiquement le jour où l'on n'a pas joué.
- **Jalons** : 3, 7, 14, 30, 50, 100 et 365 jours, chacun avec un badge.
- **Rappel** (optionnel, désactivé par défaut) : une notification locale vers 20 h si la grille du jour n'est pas faite. Elle reste locale, donc aucune donnée n'est collectée.
- **Widget** (V1.1) : la flamme et l'état de la grille du jour sur l'écran d'accueil.
- **Anti-triche minimal** : on enregistre la date de complétion, et une date système modifiée vers le passé n'augmente pas la série. Il n'y a pas d'enjeu, donc on ne va pas plus loin.

## 6. Code de grille et partage ✅ décidé

**Principe** : chaque grille, qu'elle soit de niveau, du jour ou partagée, a un **code court**. Saisir ce code recrée **exactement la même grille** sur n'importe quel appareil, dans n'importe quelle version de l'app.

### Format du code

`SKN1-D-7KQ2-9XFA-3T`

| Partie | Sens |
|---|---|
| `SKN1` | Préfixe + **version du générateur** (1) |
| `D` | Niveau : F, M, D, E, X (X = Diabolique) |
| `7KQ2-9XFA-3T` | Graine de 64 bits en base 32 de Crockford (pas de O/0 ni I/1 ambigus), plus 1 caractère de contrôle pour repérer les fautes de frappe |

- **Facile, Moyen, Difficile** : la graine alimente directement le générateur.
- **Expert, Diabolique** : la graine choisit une **grille de base embarquée** (`graine % nombre`) et une **transformation** (chiffres renumérotés, lignes et colonnes permutées, transposition). La génération est instantanée, avec des milliards de variantes, et la difficulté ne change pas.
- **Grille du jour** : son code est `SKN1-J-20261110`.
- **Règle d'or** : une fois publié, le générateur v1 **ne change plus jamais**. Si on l'améliore, il devient v2, et le code v1 continue de passer par l'ancien générateur, conservé dans le code de l'app. Des **tests de référence** vérifient qu'un ensemble de codes donne toujours les mêmes grilles.
- **Contrôle d'intégrité** : on calcule une empreinte de la solution. Si un lien contient une empreinte qui ne correspond pas, l'app affiche « grille incompatible » au lieu d'une grille différente.

### Partager après une victoire

L'écran de fin a un bouton **Partager** (`ShareLink`) qui envoie un message sans rien dévoiler de la grille, à la Wordle :

```
Sudokuno · Difficile 🔥12
⏱ 6:42 · 💡 1 indice
À toi de battre mon temps :
https://sudokuno.app/p/SKN1-D-7KQ2-9XFA-3T?t=402&h=1
```

- On partage aussi une **image** de la carte (`ImageRenderer`) avec le niveau, le temps, les indices et une mini-grille floutée.
- **Lien universel** : si l'app est installée, le lien l'ouvre directement sur la grille. Sinon, il ouvre une page web statique qui affiche le défi (« Battre 6:42 avec 1 indice ») et un bouton vers l'App Store.
  - Il faut un **domaine**, environ 10 €/an, ou GitHub Pages avec un domaine personnalisé. Le domaine héberge aussi `apple-app-site-association` et la politique de confidentialité.
  - Sans domaine au départ, on se rabat sur l'écran **« Entrer un code »** de l'app et le schéma `sudokuno://`.
- **Mode défi** : quand on ouvre une grille partagée, l'app affiche « Défi : battre 6:42 · 1 indice ». À la fin, elle compare les deux résultats (« Tu as gagné de 38 s ! »).
- Ces informations restent **dans le lien**. Rien ne passe par un serveur à nous.

## 7. Game Center ✅ décidé (V1)

- **Connexion** : `GKLocalPlayer.authenticateHandler` au lancement, sans bloquer l'app. Elle fonctionne parfaitement sans Game Center (hors ligne, ou si le joueur refuse).
- **Classements** (à créer dans App Store Connect) :

| Classement | Type | Score |
|---|---|---|
| Grille du jour | **Récurrent, 24 h**, démarrage à 00:00 UTC | Temps en secondes, le plus bas gagne |
| Grille du jour, sans indice | Récurrent, 24 h | Temps, uniquement si 0 indice |
| Meilleur temps : Facile / Moyen / Difficile / Expert / Diabolique | Classique | Temps |
| Plus longue série | Classique | Jours, le plus haut gagne |

- **Afficher les indices dans Game Center** : l'interface standard de Game Center n'affiche que le score, elle ne peut pas montrer d'information en plus. On fait donc deux choses :
  1. le **nombre d'indices** et le mode (indices activés ou non) sont enregistrés dans le champ `context` du score, un `UInt64` ;
  2. l'app a **son propre écran de classement** en SwiftUI (via `GKLeaderboard.loadEntries`) qui affiche pour chaque joueur son **temps, ses 💡 indices** et une mention « sans aide » si les indices étaient désactivés.
  - Le classement « sans indice », séparé, permet aussi de voir la différence dans l'interface Game Center standard.
- **Succès** : niveaux débloqués, séries de 7, 30, 100 et 365 jours, « Parfait » (aucun indice, aucune erreur), première grille Diabolique, premier défi gagné.
- **Limite connue** : sans serveur, on ne peut pas vérifier les temps. Un tricheur déterminé pourrait envoyer un faux score. On limite le problème en rejetant les temps impossibles (par exemple moins de 60 s en Diabolique), et on accepte ce risque pour un jeu gratuit.

## 8. Indices (3 gratuits par grille)

- Chaque grille a **3 indices**, et le compteur est affiché sur le bouton (ampoule avec un badge).
- **Indice « intelligent »** : un indice se déroule en 3 étapes, calculées sur l'état **actuel** de la grille du joueur :
  1. on désigne **la zone et la technique** (« Singleton caché dans ce bloc ») ;
  2. on **surligne les cases et les candidats** concernés ;
  3. on **explique et on applique** le coup.
- Si le joueur a fait une erreur, l'indice la signale en priorité.
- **Réglages** : un seul interrupteur, « Indices » (activé/désactivé). Activés, on a 3 indices par grille. Le nombre d'indices utilisés apparaît à l'écran de fin, dans le message partagé et dans le classement Game Center.
- Si les indices sont désactivés, le score porte la mention « sans aide ».
- Une grille terminée sans indice reçoit un badge « Parfait ».

## 9. Expérience de jeu

- **Saisie** : on tape une case puis un chiffre, ou un chiffre puis plusieurs cases (deux modes, à choisir dans les réglages).
- **Mode notes** (crayon), avec retrait automatique des notes quand on place un chiffre.
- **Surlignage** de la ligne, de la colonne et du bloc, et des chiffres identiques.
- **Conflits** affichés en rouge (activable) et **compteur d'erreurs** (optionnel, sans « game over » imposé).
- **Annuler / Refaire** sans limite, et **Effacer**.
- **Chrono** mis en pause automatiquement quand l'app passe en arrière-plan.
- **Pavé numérique** : un chiffre est grisé quand ses 9 exemplaires sont placés.
- **Sauvegarde automatique** de la partie en cours (SwiftData) et reprise à l'accueil.
- **Fin de partie** : temps, erreurs, indices utilisés, record personnel, mise à jour de la série.
- **Statistiques** par niveau : parties, taux de réussite, meilleur temps, temps moyen.
- Le **code de la grille** est toujours visible dans le menu « … » de la partie : on peut le copier ou le partager avant même d'avoir fini.

## 10. Réglages

| Section | Options |
|---|---|
| Apparence | **Thème : Système / Clair / Sombre** (`preferredColorScheme`), couleur d'accent |
| Aides | Indices (activé/désactivé), surligner les conflits, surligner les chiffres identiques, retrait auto des notes, compteur d'erreurs |
| Jeu | Mode de saisie, chrono visible, verrouiller les chiffres corrects |
| Retours | Haptique, sons |
| Notifications | Rappel de série (heure réglable) |
| Game Center | État de la connexion, accès aux classements et aux succès |
| À propos | Version, politique de confidentialité, contact, « Noter l'app », réinitialiser les statistiques |

## 11. Design

Skills à utiliser : `liquid-glass`, `no-ui-slop`, `design`, `typography`, `sf-symbols`, `game-feel`, `accessibility-generator`.

- **La grille reste opaque et nette.** Liquid Glass sert seulement aux éléments autour d'elle : barre d'outils, pavé numérique, feuilles. Il ne doit jamais se trouver sous les chiffres.
- **Typographie** : SF Pro Rounded en `monospacedDigit()`. Les chiffres donnés au départ sont en gras, ceux du joueur dans la couleur d'accent, les notes en petit et en gris.
- **Couleurs** : un ensemble de couleurs sémantiques (fond, grille, sélection, surlignage, erreur, accent) défini pour **clair et sombre** dans l'Asset Catalog. En sombre, on évite le noir pur pour la grille et on garde un contraste AA.
- **Haptique** : légère quand on place un chiffre, `.error` sur un conflit, `.success` quand une ligne ou un bloc est complété.
- **Accessibilité** : Dynamic Type sur tout ce qui entoure la grille, VoiceOver (« Ligne 3, colonne 5, vide, notes 2 4 7 »), indicateurs qui ne reposent pas uniquement sur la couleur, Réduire les animations respecté.
- **iPad (V1)** :
  - en portrait, même mise en page que sur iPhone, mais plus grande ;
  - en paysage, la grille à gauche et le pavé et les outils dans une colonne à droite (`ViewThatFits`, ou une mise en page selon `horizontalSizeClass`) ;
  - **clavier physique** : touches 1 à 9, flèches pour se déplacer, N pour les notes, ⌘Z pour annuler ;
  - survol au pointeur sur les cases, prise en charge de Stage Manager et du multifenêtrage.
- **Langues** : français et anglais dès la V1 (String Catalog).
- **Icône** : à concevoir, sobre (grille stylisée avec la flamme).

## 12. Publication App Store

1. **Apple Developer Program** : 99 $/an. C'est indispensable pour publier.
2. **Confidentialité** :
   - étiquette « Aucune donnée collectée » : l'app ne collecte rien elle-même. ⚠️ **À vérifier au moment de remplir l'étiquette** : ce qu'Apple demande de déclarer pour Game Center ;
   - `PrivacyInfo.xcprivacy` qui déclare l'usage d'`UserDefaults` (raison `CA92.1`) ;
   - une **URL de politique de confidentialité**, obligatoire même sans collecte. Elle va sur le site `sudokuno.app` (section 6). Skills : `privacy-policy`, `privacy-publish`, `privacy-manifests`.
3. **Classification** : 4+. Pas de chiffrement non standard, donc `ITSAppUsesNonExemptEncryption = NO`.
4. **Risque de la règle 4.3 (spam)** : les apps de Sudoku sont très nombreuses. Pour se démarquer, il faut une vraie différence (pas de pub, grille du jour commune, série, **défis par code**, classements avec indices, indices pédagogiques, design soigné) et la mettre en avant dans la description et les captures.
5. **Nom** : vérifier que « Sudokuno » est libre sur App Store Connect (réserver le nom en créant la fiche tôt), ainsi que le domaine.
6. **Ressources** : captures pour iPhone 6,9" **et iPad 13"**, sous-titre, mots-clés. Skills : `app-store-assets`, `app-store`.
7. **Avant de soumettre** : skill `release-review`, test sur un vrai appareil, puis **TestFlight** avec quelques amis pendant au moins une semaine.

## 13. Étapes de réalisation

| # | Étape | Livrable | Durée indicative |
|---|---|---|---|
| 0 | Mise en place | Projet Xcode, package `SudokuKit`, git, `CLAUDE.md` | 0,5 j |
| 1 | **Moteur** (TDD) | Grid, Solver, Generator, unicité, PRNG déterministe | 2–3 j |
| 2 | Évaluation + indices | LogicalSolver, Grader, HintEngine, calibrage des 5 niveaux | 3–4 j |
| 3 | Plateau jouable | Grille, pavé, notes, annuler, conflits, chrono, sauvegarde | 3–4 j |
| 4 | Niveaux + accueil | Choix du niveau, **déblocage**, tampon de grilles, reprise, fin de partie, stats | 2 j |
| 5 | Grille du jour | DailyPuzzleBuilder, JSON embarqué, carte du jour, calendrier | 2 j |
| 6 | Série | Streak, gels, jalons, animations, notification locale | 2 j |
| 7 | Code + partage | PuzzleCode, transformations, tests de référence, ShareLink, carte image, « Entrer un code », mode défi | 2–3 j |
| 8 | Game Center | Connexion, classements (dont du jour, en UTC), `context` avec les indices, écran de classement dans l'app, succès | 2–3 j |
| 9 | Réglages + thème | Toutes les options, mode sombre, haptique | 1–2 j |
| 10 | iPad | Mise en page paysage, clavier physique, pointeur | 1–2 j |
| 11 | Finition | Liquid Glass, accessibilité, FR/EN, icône, onboarding court | 3 j |
| 12 | Site + publication | Domaine, page de partage, apple-app-site-association, confidentialité, manifest, captures, TestFlight, soumission | 2–3 j |
| V1.1 | Bonus | Widget, thèmes de grille, Apple Watch ? | — |

Chaque étape se termine par des tests verts et une démo dans le simulateur. On peut découper ces étapes en tickets avec le skill `to-tickets`.

## 14. Risques

| Risque | Parade |
|---|---|
| Génération Diabolique trop lente | Tampon en tâche de fond, ou grilles Diabolique pré-générées dans le bundle |
| Niveaux mal calibrés | Calibrer le Grader sur des grilles de référence notées (SE rating) et tester sur de vrais joueurs via TestFlight |
| Rejet 4.3 (app trop similaire) | Différenciation claire et soin du design |
| La grille du jour diffère entre versions | Grilles **embarquées**, plutôt que régénérées |
| Un code partagé donne une autre grille après une mise à jour | Générateur versionné et figé, tests de référence, empreinte de la solution dans le lien |
| Faux scores Game Center | Temps minimums plausibles, risque accepté |
| Grille du jour en UTC peu intuitive (change à 1 h ou 2 h du matin) | Compte à rebours « Prochaine grille dans 3 h 12 » affiché à l'accueil |
| Série cassée par un fuseau horaire ou un voyage | Logique fondée sur la date locale du calendrier, avec des tests sur le changement d'heure et de fuseau |

## 15. Décisions prises (10/11/2026)

| Question | Décision |
|---|---|
| Niveaux | Déblocage progressif (section 3) |
| iPad | Oui, dès la V1 |
| Game Center | Oui, dès la V1, avec les indices visibles dans les classements (section 7) |
| Nom | **Sudokuno** |
| Indices | Simple interrupteur activé/désactivé, 3 par grille |
| Partage | Code de grille + temps + indices, mode défi (section 6) |

## 16. Questions restantes

Décidé le 10/11/2026 : pas de domaine (code + `sudokuno://`), grille du jour en UTC, seuils 5 / 10 / 10 / 10.
