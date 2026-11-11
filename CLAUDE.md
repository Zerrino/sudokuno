# Sudokuno (iOS + Android)

- `ios/` : voir `ios/CLAUDE.md`. `android/` : voir `android/CLAUDE.md`.
- Les deux moteurs (Swift `ios/Packages/SudokuKit`, Kotlin `android/sudokukit`) doivent rester IDENTIQUES bit à bit :
  un code de grille partagé doit donner la même grille sur les deux plateformes. Toute modification du générateur
  se fait des deux côtés et doit passer `Golden.swift` (iOS) et `CrossPlatformTest.kt` (Android).
- Traductions communes : `tools/translations.py` (clé = texte français), puis `python3 tools/translations.py`.
- Textes affichés toujours via `L("…")`, en Swift comme en Kotlin.
