# Game Center : à créer dans App Store Connect

App Store Connect › ton app › Services › Game Center. Les identifiants doivent être **exactement** ceux-ci
(ils sont dans `Sudokuno/Features/GameCenter/GameCenterService.swift`).

## Classements

| Identifiant | Nom | Type | Format | Tri |
|---|---|---|---|---|
| `sudokuno.daily` | Sudoku du jour | **Récurrent** : début 00:00 **UTC**, durée 1 jour | Temps écoulé (secondes) | Croissant (le plus bas gagne) |
| `sudokuno.daily.nohint` | Sudoku du jour, sans indice | Récurrent, 00:00 UTC, 1 jour | Temps écoulé (secondes) | Croissant |
| `sudokuno.best.F` | Record Facile | Classique | Temps écoulé (secondes) | Croissant |
| `sudokuno.best.M` | Record Moyen | Classique | Temps écoulé (secondes) | Croissant |
| `sudokuno.best.D` | Record Difficile | Classique | Temps écoulé (secondes) | Croissant |
| `sudokuno.best.E` | Record Expert | Classique | Temps écoulé (secondes) | Croissant |
| `sudokuno.best.X` | Record Diabolique | Classique | Temps écoulé (secondes) | Croissant |
| `sudokuno.streak` | Plus longue série | Classique | Entier | Décroissant (le plus haut gagne) |

Le champ `context` de chaque score contient les indices (bits 0-7), « aides désactivées » (bit 8) et les erreurs
(bits 16-31). L'écran Classements de l'app les affiche ; l'interface Game Center standard ne montre que le temps.

## Succès

| Identifiant | Nom suggéré |
|---|---|
| `sudokuno.unlock.M` / `.D` / `.E` / `.X` | Niveau Moyen / Difficile / Expert / Diabolique débloqué |
| `sudokuno.streak.7` / `.30` / `.100` / `.365` | Série de 7 / 30 / 100 / 365 jours |
| `sudokuno.perfect` | Parfait : une grille sans indice ni erreur |
| `sudokuno.diabolique.first` | Première grille Diabolique |
| `sudokuno.challenge.won` | Premier défi gagné |
| `sudokuno.streak.1000` | Série de 1000 jours |
| `sudokuno.solved.100` | 100 grilles résolues (progressif : l'app envoie le pourcentage) |
| `sudokuno.created.1` / `.5` / `.10` / `.25` / `.50` / `.100` | Grilles créées avec l'éditeur (progressif) |

Chaque succès demande une image 512×512 (ou 1024×1024) et un texte FR/EN. Les images sont prêtes dans
`android/docs/achievements/` (même nom que l'identifiant, sans `sudokuno.` : `streak_7.png`, `created_25.png`…),
générées par `swift android/tools/achievement_icons.swift`.
