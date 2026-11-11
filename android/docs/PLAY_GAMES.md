# Google Play Jeux (classements et succès)

Équivalent de Game Center. Facultatif : tant que `res/values/games-ids.xml` contient `0` comme identifiant de projet,
l'app fonctionne sans classements.

## Configuration (console Google Play › Croissance › Play Jeux › Configuration)
1. Créer un projet Play Jeux pour Sudokuno et **ajouter les identifiants Android** (OAuth) avec l'empreinte **SHA-1**
   de la clé de signature Google Play (Configuration › Intégrité de l'app) **et** de la clé de debug pour tester :
   `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android`.
2. **Classements** à créer :

| Nom (FR / EN) | Format | Ordre | Ressource dans games-ids.xml |
|---|---|---|---|
| Sudoku du jour / Daily Sudoku | Temps (millisecondes) | Croissant (le plus bas gagne) | `leaderboard_daily` |
| Du jour, sans indice / Daily, no hints | Temps (ms) | Croissant | `leaderboard_daily_nohint` |
| Record Facile … Diabolique (5) | Temps (ms) | Croissant | `leaderboard_best_F`, `_M`, `_D`, `_E`, `_X` |
| Plus longue série / Longest streak | Numérique | Décroissant | `leaderboard_streak` |

3. **Succès** (mêmes que sur iOS) : `achievement_perfect`, `achievement_diabolique_first`, `achievement_challenge_won`,
   `achievement_unlock_M/D/E/X`, `achievement_streak_7/30/100/365`.
4. Cliquer sur **« Obtenir les ressources »** : la console donne un XML. Recopier l'identifiant du projet
   (`app_id`) dans `game_services_project_id` et chaque identifiant (`CgkI…`) dans la ressource correspondante de
   `app/src/main/res/values/games-ids.xml`.
5. Ajouter les testeurs (Play Jeux › Testeurs) puis **publier** la configuration Play Jeux en même temps que l'app.

## Particularité : classement du jour
Play Jeux remet ses classements quotidiens à zéro à minuit **heure du Pacifique**, alors que la grille du jour change à
minuit **UTC**. Chaque score porte donc un « tag » (`h1e1m0d20261111` : indices, aides, erreurs, jour de la grille) et
l'écran Classements de l'app n'affiche que les scores de la grille du jour. Le tag sert aussi à afficher les indices.

## Fait par l'API (11 novembre 2026)
Projet Play Jeux `772167638482`. Les 8 classements et 11 succès ont été créés par `tools/play_games.py` (en anglais
seulement : ajouter le français dans Configuration › Propriétés, puis passer `LOCALES` à `{"en-US", "fr-FR"}` et relancer
le script), et `games-ids.xml` est rempli. Restent à faire dans la console : identifiants OAuth Android (SHA-1),
testeurs, icônes des succès (facultatif), puis **Publier** la configuration Play Jeux.
