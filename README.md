# Sudokuno

Sudoku pour iPhone et iPad : gratuit, sans publicité, sans suivi.

- Sudoku du jour commun à tous (UTC), série à la Duolingo avec gels
- 5 niveaux à débloquer, grilles générées dans l'app et classées par technique
- Indices pédagogiques en 3 étapes
- Codes de grille pour défier ses amis, créateur de grilles avec vérification et difficulté automatique
- Game Center (classements avec indices, succès), dons facultatifs en achat intégré
- Français, anglais, néerlandais, portugais, chinois simplifié · mode sombre

Site, confidentialité et mentions légales : https://zerrino.github.io/sudokuno/

## Développement

Prérequis : Xcode 26, [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`).

```
xcodegen generate                      # génère Sudokuno.xcodeproj depuis project.yml
open Sudokuno.xcodeproj                # puis ⌘R
cd Packages/SudokuKit && swift test    # tests du moteur
```

| Dossier | Contenu |
|---|---|
| `Packages/SudokuKit` | Moteur : solveur, générateur, évaluation, indices, codes, série |
| `Sudokuno/` | App SwiftUI |
| `SudokunoUITests/`, `SudokunoTests/` | Tests d'interface, captures App Store, test StoreKit |
| `site/` | Site GitHub Pages (aide, confidentialité, mentions légales) |
| `docs/` | Plan, recherche, guides App Store, Game Center, achats intégrés |
| `Tools/` | Icône, traductions, export des captures |

Publication : voir [`docs/APP_STORE.md`](docs/APP_STORE.md).
