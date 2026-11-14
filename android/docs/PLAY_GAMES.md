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

## Classements au score (14 novembre 2026, version 1.0.14)
Créés par `tools/play_games.py create` : `leaderboard_score_daily`, `_best`, `_total`, `_F/_M/_D/_E/_X/_L` (numériques,
le plus haut gagne). Les anciens classements au temps sont publiés : impossibles à supprimer ou à remettre à zéro, ils
restent dans Play Jeux mais l'app ne s'en sert plus. **Publier** la configuration Play Jeux pour rendre les nouveaux
visibles hors testeurs.

Classement du jour : la valeur envoyée est `jour × 1 000 000 + score` dans un classement « depuis toujours ». Le meilleur
de chaque joueur est donc son dernier jour joué, et l'app ne garde que les valeurs du jour (UTC). Cela remplace le
classement quotidien de Play Jeux, remis à zéro à minuit heure du Pacifique (9 h à Paris) : les parties jouées entre
1 h et 9 h y disparaissaient. L'interface Play Jeux standard affiche ce nombre brut ; l'écran de l'app le décode.

## Particularité : classement du jour (ancienne version, au temps)
Play Jeux remet ses classements quotidiens à zéro à minuit **heure du Pacifique**, alors que la grille du jour change à
minuit **UTC**. Chaque score porte donc un « tag » (`h1e1m0d20261111` : indices, aides, erreurs, jour de la grille) et
l'écran Classements de l'app n'affiche que les scores de la grille du jour. Le tag sert aussi à afficher les indices.

## Fait par l'API (11 novembre 2026)
Projet Play Jeux `772167638482`. Les 8 classements et 11 succès ont été créés par `tools/play_games.py` (en anglais
seulement : ajouter le français dans Configuration › Propriétés, puis passer `LOCALES` à `{"en-US", "fr-FR"}` et relancer
le script), et `games-ids.xml` est rempli. Restent à faire dans la console : identifiants OAuth Android (SHA-1),
testeurs, icônes des succès (facultatif), puis **Publier** la configuration Play Jeux.

## Succès ajoutés et icônes (11 novembre 2026)
Ajoutés par l'API : `streak_1000`, `solved_100` (progressif, 100 étapes), `created_1` (normal) et `created_5/10/25/50/100`
(progressifs). Total : 910 points sur 1000 possibles. Une grille « créée » compte quand elle est jouée, partagée ou copiée
depuis l'éditeur (`AppModel.recordCreated`) ; les succès progressifs sont recalculés à chaque victoire et à chaque connexion.

**Icônes** : `docs/achievements/<succès>.png` (512 × 512), générées par `swift tools/achievement_icons.swift`.
L'API de configuration ne permet plus d'envoyer d'images : dans la console, Play Games Services › Achievements,
ouvrir chaque succès et déposer l'image du même nom.
