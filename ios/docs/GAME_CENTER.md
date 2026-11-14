# Game Center : à créer dans App Store Connect

App Store Connect › ton app › Services › Game Center. Les identifiants doivent être **exactement** ceux-ci
(ils sont dans `Sudokuno/Features/GameCenter/GameCenterService.swift`).

## Classements (au score, depuis la version 1.0.14)

Tout est classé au score (`Scoring`, voir `../CLAUDE.md`). Les anciens classements au temps (`sudokuno.daily`,
`sudokuno.daily.nohint`, `sudokuno.best.F/M/D/E/X`) ne sont plus utilisés : les retirer de la version de l'app
dans App Store Connect (un classement en ligne ne se modifie ni ne se remet à zéro, d'où les nouveaux identifiants).

| Identifiant | Nom | Type | Format | Tri |
|---|---|---|---|---|
| `sudokuno.score.daily` | Score du jour | **Récurrent** : début 00:00 **UTC**, durée 1 jour | Entier | Décroissant (le plus haut gagne) |
| `sudokuno.score.best` | Meilleure partie | Classique | Entier | Décroissant |
| `sudokuno.score.total` | Total des scores | Classique | Entier | Décroissant |
| `sudokuno.score.F` / `.M` / `.D` / `.E` / `.X` / `.L` | Record Facile … Diabolique, Légende | Classique | Entier | Décroissant |
| `sudokuno.streak` | Plus longue série | Classique | Entier | Décroissant (le plus haut gagne) |

Le champ `context` de chaque score contient « aides désactivées » (bit 8) ; l'écran Classements de l'app l'affiche.

## Succès

| Identifiant | Nom suggéré |
|---|---|
| `sudokuno.unlock.M` / `.D` / `.E` / `.X` | Niveau Moyen / Difficile / Expert / Diabolique débloqué |
| `sudokuno.streak.7` / `.30` / `.100` / `.365` | Série de 7 / 30 / 100 / 365 jours |
| `sudokuno.perfect` | Parfait : une grille sans indice ni erreur |
| `sudokuno.diabolique.first` | Première grille Diabolique |
| `sudokuno.challenge.won` | Premier défi gagné |
| `sudokuno.streak.1000` | Série de 1000 jours |
| `sudokuno.unlock.L` | Légende débloquée |
| `sudokuno.legend.first` | Légendaire ! Une grille de la Légende résolue |
| `sudokuno.solved.100` | 100 grilles résolues (progressif : l'app envoie le pourcentage) |
| `sudokuno.created.1` / `.5` / `.10` / `.25` / `.50` / `.100` | Grilles créées avec l'éditeur (progressif) |

Chaque succès demande une image 512×512 (ou 1024×1024) et un texte FR/EN. Les images sont prêtes dans
`android/docs/achievements/` (même nom que l'identifiant, sans `sudokuno.` : `streak_7.png`, `created_25.png`…),
générées par `swift android/tools/achievement_icons.swift`.
