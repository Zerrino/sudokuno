# Sudokuno : publier sur l'App Store

Tout ce qu'il faut pour soumettre l'app : textes de la fiche (FR et EN), captures, réponses aux questionnaires et étapes.

## Liens à renseigner

| Champ App Store Connect | Valeur |
|---|---|
| URL d'assistance (obligatoire) | https://zerrino.github.io/sudokuno/ |
| URL de la politique de confidentialité (obligatoire) | https://zerrino.github.io/sudokuno/privacy.html |
| URL marketing (facultatif) | https://zerrino.github.io/sudokuno/ |
| Mentions légales (dans l'app, Réglages › À propos) | https://zerrino.github.io/sudokuno/legal.html |

Le site est publié automatiquement depuis le dossier `site/` par GitHub Actions (`.github/workflows/pages.yml`).

## Informations générales

| Champ | Valeur |
|---|---|
| Nom | Sudokuno |
| Identifiant de lot (bundle ID) | `com.alexafer.sudokuno` |
| SKU | `sudokuno` |
| Langue principale | Français |
| Catégorie principale | Jeux › Réflexion (Puzzle) |
| Catégorie secondaire | Jeux › Jeux de société (Board) |
| Prix | Gratuit |
| Copyright | 2026 Zerrino |
| Classification par âge | 4+ (répondre « Non » à toutes les questions) |
| Chiffrement (export) | Aucun chiffrement non exempté (déjà déclaré dans Info.plist) |

## Textes de la fiche

### Français

**Sous-titre** (30 car. max) : `Sudoku du jour, sans pub`

**Texte promotionnel** (170 car. max) :
> Un nouveau Sudoku chaque jour, le même pour tout le monde. Entretiens ta série, défie tes amis par code et crée tes propres grilles. Gratuit, sans pub.

**Description** :
> Sudokuno, c'est le Sudoku comme il devrait être : beau, intelligent et entièrement gratuit. Pas de publicité, pas d'abonnement, pas de compte.
>
> LE SUDOKU DU JOUR
> Chaque jour, une nouvelle grille, la même pour tous les joueurs. Réussis-la pour entretenir ta série, gagne des gels qui la protègent si tu oublies un jour, et grimpe dans le classement Game Center du jour.
>
> 5 NIVEAUX À DÉBLOQUER
> De Facile à Diabolique, chaque grille est générée dans l'app et classée selon les techniques qu'elle demande : singletons, paires, X-Wing, Swordfish, XY-Wing… Gagne pour débloquer le niveau suivant.
>
> DES INDICES QUI T'APPRENNENT
> 3 indices par grille. Au lieu de donner la réponse tout de suite, un indice te montre d'abord la zone et la technique à utiliser, puis la case, et seulement ensuite le chiffre. Tu peux aussi les désactiver.
>
> DÉFIE TES AMIS
> Chaque grille a un code. Partage-le avec ton temps : tes amis jouent exactement la même grille et tentent de te battre.
>
> CRÉE TES GRILLES
> Compose ta propre grille : Sudokuno vérifie en direct qu'elle a une solution unique, calcule sa difficulté et te donne un code à partager.
>
> ET AUSSI
> • Mode notes, annuler illimité, surlignage des conflits et des chiffres identiques
> • Plusieurs parties en cours à la fois et historique de tes grilles
> • Mode sombre, iPhone et iPad, clavier physique
> • Classements et succès Game Center
> • Statistiques détaillées par niveau
> • Disponible en français, anglais, néerlandais, portugais et chinois
>
> Sudokuno ne collecte aucune donnée. Les dons facultatifs, dans les réglages, aident à financer son développement et ne débloquent rien.

**Mots-clés** (100 car. max, sans espaces) :
`sudoku,grille,logique,casse-tête,chiffres,cerveau,défi,quotidien,série,réflexion,puzzle,jeu`

### English

**Subtitle**: `Daily Sudoku, no ads`

**Promotional text**:
> A new Sudoku every day, the same for everyone. Keep your streak alive, challenge friends with a code and create your own puzzles. Free, no ads.

**Description**:
> Sudokuno is Sudoku the way it should be: beautiful, smart and completely free. No ads, no subscription, no account.
>
> DAILY SUDOKU
> A new puzzle every day, the same for every player. Solve it to keep your streak going, earn freezes that protect it if you miss a day, and climb the daily Game Center leaderboard.
>
> 5 LEVELS TO UNLOCK
> From Easy to Diabolical, every puzzle is generated in the app and graded by the techniques it requires: singles, pairs, X-Wing, Swordfish, XY-Wing… Win to unlock the next level.
>
> HINTS THAT TEACH
> 3 hints per puzzle. Instead of giving the answer away, a hint first shows you the area and the technique to use, then the cell, and only then the number. You can also turn them off.
>
> CHALLENGE YOUR FRIENDS
> Every puzzle has a code. Share it with your time: your friends play the exact same puzzle and try to beat you.
>
> CREATE YOUR OWN PUZZLES
> Build your own grid: Sudokuno checks live that it has a unique solution, grades its difficulty and gives you a code to share.
>
> AND MORE
> • Notes mode, unlimited undo, conflict and same-number highlighting
> • Several games in progress at once, plus your puzzle history
> • Dark mode, iPhone and iPad, hardware keyboard
> • Game Center leaderboards and achievements
> • Detailed statistics per level
> • Available in English, French, Dutch, Portuguese and Chinese
>
> Sudokuno collects no data. Optional tips, in Settings, help fund development and unlock nothing.

**Keywords**:
`sudoku,puzzle,logic,daily,brain,numbers,classic,streak,challenge,offline,free,game`

> Les autres langues (néerlandais, portugais, chinois) peuvent être ajoutées plus tard dans App Store Connect. Sans fiche dans une langue, l'App Store affiche la fiche anglaise.

## Captures d'écran

Générées automatiquement dans `docs/AppStore/screenshots/` :

| Dossier | Appareil exigé | Taille |
|---|---|---|
| `fr/iphone-6.9`, `en/iphone-6.9` | iPhone 6,9" | 1320 × 2868 |
| `fr/ipad-13`, `en/ipad-13` | iPad 13" | 2064 × 2752 |

Ordre conseillé : 01 accueil, 02 partie avec indice, 04 victoire, 05 créateur, 03 série, 06 mode sombre.

Pour les régénérer (par exemple après un changement d'interface) :
```
TEST_RUNNER_SCREENSHOT_LANG=fr xcodebuild test -project Sudokuno.xcodeproj -scheme Sudokuno \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' -resultBundlePath /tmp/shots.xcresult \
  -only-testing:SudokunoUITests/ScreenshotTests
python3 Tools/export_screenshots.py /tmp/shots.xcresult docs/AppStore/screenshots/fr/iphone-6.9
```

## Confidentialité de l'app (questionnaire App Store Connect)

- « Collectez-vous des données depuis cette app ? » → **Non, nous ne collectons pas de données.**
  L'app n'a ni serveur ni outil d'analyse. Game Center et les achats intégrés sont gérés par Apple.
- Le manifeste `PrivacyInfo.xcprivacy` est déjà dans l'app.

## Notes pour l'examen (App Review)

À copier dans « Informations pour la vérification de l'app » :
> Sudokuno requires no account. Game Center is optional (leaderboards and achievements).
> Optional tips are consumable in-app purchases (Settings › Support Sudokuno) that unlock no content.
> To try a shared puzzle: Home › Enter a code › `SKN1-D-0000-0000-0000-2J`.
> Levels unlock after winning puzzles of the previous level; the Daily Sudoku is always available.

## Points d'attention avant de publier

1. **Nom affiché comme vendeur** : avec un compte développeur individuel, l'App Store affiche ton nom légal (prénom et nom) comme vendeur.
2. **Union européenne (DSA)** : App Store Connect te demande si tu es un « commerçant » (trader). Comme l'app propose des dons payants, Apple considère généralement qu'il s'agit d'une activité de commerçant. Dans ce cas, ton adresse, ton téléphone et ton e-mail sont affichés sur la fiche dans l'UE. Si tu ne veux pas les publier, il faut retirer les dons ou ne pas distribuer dans l'UE.
3. **Chine continentale** : un jeu ne peut pas y être distribué sans licence de jeu (numéro ISBN chinois). Dans « Tarifs et disponibilité », **décoche la Chine continentale**. La traduction chinoise reste utile pour Taïwan, Hong Kong, Singapour, etc.
4. **Identifiant de lot** : `com.alexafer.sudokuno` (et les identifiants des dons qui en dépendent) ne pourra plus changer après le premier envoi. Si tu préfères `com.zerrino.sudokuno`, il faut le changer **avant** (dans `project.yml`, `TipJar.swift`, `Tips.storekit` et les docs).
5. **Xcode** : Apple impose régulièrement un SDK minimum pour les nouveaux envois. Xcode 26.6 convient à la date du 11/11/2026. Vérifie l'exigence en vigueur au moment de l'envoi.

## Étapes de soumission

1. **Compte développeur** : s'inscrire à l'Apple Developer Program (99 $/an) sur developer.apple.com, en tant que particulier.
2. **Xcode** : ouvrir `Sudokuno.xcodeproj`, cible Sudokuno › *Signing & Capabilities*, choisir ton équipe (*Team*). Xcode crée l'identifiant de l'app et active Game Center et les achats intégrés.
3. **Accords** : App Store Connect › *Accords, taxes et banques*, signer le *Paid Apps Agreement* (nécessaire pour les dons) et remplir banque et fiscalité.
4. **Créer l'app** : App Store Connect › *Apps* › **+** › *Nouvelle app* : plateforme iOS, nom « Sudokuno », langue principale Français, bundle ID `com.alexafer.sudokuno`, SKU `sudokuno`.
5. **Game Center** : créer les classements et succès de `docs/GAME_CENTER.md`.
6. **Dons** : créer les 3 achats intégrés de `docs/IN_APP_PURCHASES.md`.
7. **Fiche** : renseigner les textes ci-dessus (FR, puis ajouter l'anglais), les URL, les captures, la catégorie, la classification par âge, la confidentialité, le prix (gratuit) et la disponibilité (sans la Chine continentale).
8. **Envoyer la version** : dans Xcode, choisir la destination *Any iOS Device (arm64)*, puis *Product › Archive*. Dans l'organiseur qui s'ouvre : *Distribute App › App Store Connect › Upload*.
9. **TestFlight** (conseillé) : la version apparaît dans App Store Connect après 10 à 30 minutes de traitement. L'installer sur ton iPhone via TestFlight et faire un vrai tour : grille du jour, Game Center, don en mode test (Sandbox).
10. **Soumettre** : dans la page de la version 1.0, choisir la version envoyée, cocher les 3 achats intégrés et Game Center, remplir les notes pour l'examen, puis *Ajouter pour vérification* › *Soumettre*. L'examen prend en général 24 à 48 h.
11. **Publication** : une fois l'app acceptée, elle est publiée automatiquement, ou manuellement si tu as choisi cette option.

Pour une mise à jour : augmenter `MARKETING_VERSION` (ex. 1.1) et `CURRENT_PROJECT_VERSION` dans `project.yml`, lancer `xcodegen generate`, puis refaire les étapes 8 à 10.
