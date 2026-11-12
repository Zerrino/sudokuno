# Jouer comme un expert : méthode, livres, grilles extrêmes

Recherche du 12/11/2026, pour le mode « Explication pas à pas » (conseils « Comment le repérer », preuves par l'absurde).
Complète `sudoku-fonctionnement.md` et `sudoku-experts-et-explication.md`. Chaque affirmation renvoie à la page lue ;
ce qui n'a pas pu être vérifié est dit comme tel.

## 1. Comment un joueur cherche une technique à la main

- **Singleton caché (quadrillage)** : se concentrer sur un chiffre et un bloc, barrer mentalement les lignes et colonnes qui
  contiennent déjà ce chiffre ; s'il ne reste qu'une case, elle est pour lui. HoDoKu note qu'à la main les singletons cachés
  sont faciles à trouver, alors que les singletons nus demandent plus de temps (il faut compter les chiffres vus par une case,
  ou noter tous les candidats). [H1]
- **Chaînes groupées** : un maillon peut être un groupe de deux ou trois cases d'un même bloc (dans 90 % des cas c'est une
  seule case) ; un groupe « promeut » les liens voisins en liens forts. [W4]
- **Ordre des techniques** : Andrew Stuart reconnaît que la difficulté est subjective mais nécessaire pour ordonner les
  stratégies d'un solveur ; son site les range en quatre paliers (Basic, Tough, Diabolical, Extreme). [W5]
- **Notation de Snyder, méthode de compétition** : non vérifié. Thomas Snyder (triple champion du monde) détaille sa façon de
  parcourir et d'annoter une grille dans une conférence vidéo (SudokuCon) ; la page qui la présente n'en donne pas le contenu,
  et son billet « The Truth About Snyder Notation » n'était lisible qu'en résumé. [G1] [G2] Les définitions trouvées ailleurs
  (noter un chiffre seulement quand il n'a que deux places dans un bloc) sont de seconde main et ne concordent pas entre elles.

## 2. Les grilles extrêmes (Golden Nugget, Easter Monster…)

- **Ce que font les solveurs de référence** : quand les motifs ne suffisent plus, ils raisonnent par hypothèse et
  contradiction (« forcing chains », « forcing nets »).
- **Ce n'est pas de la devinette** : Denis Berthier démontre que ses « braids » ont exactement la puissance de l'essai-erreur
  sans devinette (T&E) : toute élimination obtenue par hypothèse puis contradiction correspond à un motif logique, et
  inversement. [B1] C'est la famille utilisée par `ForcingChains.swift`.
- **SK-loop** : motif découvert en résolvant Easter Monster. Quatre cases résolues ou données en rectangle sur quatre blocs ;
  huit liens (un par bloc, par ligne et par colonne) ; les seize cases de la boucle forment un ensemble verrouillé, ce qui
  permet d'éliminer le long de chaque alignement. Les liens peuvent être simples, doubles ou triples tant que leur somme ne
  dépasse pas 16. La page dit elle-même que sa formulation est à corriger. [W1] Vu ailleurs comme un ensemble verrouillé
  multi-secteurs d'ordre 8. [M1]
- **Exocet (Junior Exocet)** : deux cases de base alignées dans un bloc (3 ou 4 candidats au total), deux cases cibles qui
  contiennent tous les chiffres de base sans se voir ni voir les bases, des cases compagnes sans aucun chiffre de base, et
  chaque chiffre de base présent au plus deux fois dans les « cases S ». Éliminations : tout candidat non-base d'une cible,
  etc. La page de SudokuWiki est marquée « documentation complète à venir » ; plusieurs règles n'y figurent pas. [W2]
- **Golden Nugget** : une page de SudokuOne en donne une résolution par « logique d'ensembles » en forme libre, pas par une
  liste de techniques nommées, et note que sa boucle est plus compliquée que la SK-loop d'origine. [S1] Je n'ai trouvé aucune
  source confirmant qu'un Exocet s'y applique.
- **ALS-XZ** : deux ensembles presque verrouillés (N cases, N + 1 candidats) partagent un chiffre X restreint ; leur autre
  chiffre commun Z disparaît des cases qui voient tous les Z des deux ensembles. [W3] [H2]
  **Mesuré dans Sudokuno** : essayée avant les preuves par l'absurde, elle ne remplace que 0 à 2 preuves sur une quarantaine
  par grille Légende. Elle n'a pas été gardée.

## 3. Livres

- **Andrew C. Stuart, *The Logic of Sudoku*** (2007 d'après l'auteur ; 256 pages, 58 stratégies, 196 illustrations,
  68 exercices ; épuisé). Chapitres dans l'ordre : paires/triplets/quadruplets nus puis cachés, paires pointantes, réduction
  bloc-ligne, X-Wing, Swordfish, Jellyfish, coloriage simple et multiple, Y-Wing, XYZ-Wing, WXYZ-Wing, chaînes XY, forcing
  chains, X-Cycles, X-Cycles groupés, chaînes d'inférences alternées, ensembles presque verrouillés, poissons à ailette,
  Pattern Overlay, Aligned Pair Exclusion, Empty Rectangles, Sue-de-Coq, Death Blossom, rectangles d'unicité, BUG. [W6]
  C'est aussi un ordre d'apprentissage : chaque chapitre s'appuie sur les précédents.
- **Denis Berthier, *The Hidden Logic of Sudoku*** : vue systématique des fondements logiques et des symétries du sudoku ;
  généralise la chaîne XY en familles de chaînes de complexité croissante. [B2] Suite théorique :
  *Pattern-Based Constraint Satisfaction and Logic Puzzles* (whips, braids, classement par longueur de chaîne). [B3]
- **Thomas Snyder, *The Art of Sudoku*** (2012) : recueil de grilles composées à la main par un champion du monde. Le contenu
  de l'extrait PDF n'a pas pu être lu. [G3]
- Cités par des listes de recommandations, non vérifiés : Peter Gordon et Frank Longo, *Mensa Guide to Solving Sudoku* ;
  les recueils Nikoli (grilles composées à la main).

## 4. Ce que Sudokuno en fait

1. **« Comment le repérer »** sous chaque étape : un conseil de recherche par technique (`StepText.tip`), tiré de [H1] pour
   les singletons et des définitions de SudokuWiki pour le reste.
2. **Preuves par l'absurde assumées comme dernier recours**, et présentées comme telles au joueur ; justifiées par [B1].
3. **Hypothèse déroulée sur la grille** : la preuve se suit coup par coup, grille fixée en haut de l'écran.
4. **SK-loop et chaînes groupées** (`ExpertPatterns.swift` / `.kt`), essayées avant les preuves par l'absurde, pour
   l'explication seulement. Mesuré sur les 8 Légendes (12/11/2026) :
   - la SK-loop n'existe que sur Easter Monster, où elle est la première étape et retire les 13 candidats décrits dans [W1] ;
     les preuves par l'absurde y passent de 42 à 33 (imbriquées : 6 → 1 ; plus longue : 192 → 77 conséquences) ;
   - les chaînes groupées remplacent 1 à 6 preuves sur sept grilles (aucune sur Inkala 2012) ;
   - Golden Nugget change peu : 45 → 44 preuves, la plus longue reste à 303 conséquences.
5. **Piste non faite** : l'Exocet, qui demande une source plus complète que [W2] avant d'être codé.

## Sources (consultées le 12/11/2026)

- [H1] HoDoKu, Singles : https://hodoku.sourceforge.net/en/tech_singles.php
- [H2] HoDoKu, Almost Locked Sets : https://hodoku.sourceforge.net/en/tech_als.php
- [W1] SudokuWiki, SK Loops : https://www.sudokuwiki.org/SK_Loops
- [W2] SudokuWiki, Exocet : https://www.sudokuwiki.org/Exocet
- [W3] SudokuWiki, Almost Locked Sets : https://www.sudokuwiki.org/Almost_Locked_Sets
- [W4] SudokuWiki, Grouped X-Cycles : https://www.sudokuwiki.org/Grouped_X_Cycles
- [W5] SudokuWiki, Strategy Families : https://www.sudokuwiki.org/Strategy_Families
- [W6] SudokuWiki, The Logic of Sudoku : https://www.sudokuwiki.org/The_Logic_of_Sudoku
- [B1] D. Berthier, *From Constraints to Resolution Rules, Part II* : https://arxiv.org/abs/1304.3210 (lu en résumé de recherche)
- [B2] D. Berthier, *The Hidden Logic of Sudoku* : https://hal.archives-ouvertes.fr/hal-00430229 (notice, lue en résumé de recherche)
- [B3] D. Berthier, *Pattern-Based Constraint Satisfaction and Logic Puzzles* : https://arxiv.org/pdf/1304.1628 (lu en résumé de recherche)
- [G1] GM Puzzles, How to Solve Sudoku Like a World Champion : https://www.gmpuzzles.com/blog/?p=32642
- [G2] GM Puzzles, The Truth About Snyder Notation : https://www.gmpuzzles.com/blog/?p=33536
- [G3] GM Puzzles, extrait de The Art of Sudoku : https://www.gmpuzzles.com/other/TAoS-Sampler.pdf (illisible)
- [M1] Gidoo, Multi-Sector Locked Sets : https://gidoo-code.github.io/Sudoku_Solver_Generator_v6/page60.html (lu en résumé de recherche)
- [S1] SudokuOne, Golden Nugget : https://sudokuone.com/sweb/old/a_gn.htm (lu en résumé de recherche)
