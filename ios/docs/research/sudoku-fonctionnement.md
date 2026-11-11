# Fonctionnement du Sudoku : règles, algorithmes, génération, difficulté

> Document de recherche pour l'app iOS Sudoku (SwiftUI, 100 % hors ligne, sans pub).
> Chaque affirmation chiffrée renvoie à une source primaire listée en fin de document ([S1], [S2]…).

---

## 1. Règles et vocabulaire

**Règle unique** : remplir une grille 9×9 avec les chiffres 1 à 9 de sorte que chaque **ligne**, chaque **colonne** et chaque **bloc** 3×3 contienne chacun des 9 chiffres exactement une fois. Une grille de départ partiellement remplie est donnée ; le joueur complète les cases vides [S10].

| Terme (FR) | Anglais | Définition |
|---|---|---|
| Case / cellule | cell | Une des 81 positions. Notation usuelle `r1c1`…`r9c9` (ligne, colonne) [S7]. |
| Ligne | row | 9 cases horizontales. |
| Colonne | column | 9 cases verticales. |
| Bloc / région / boîte | box / block / region | Sous-grille 3×3 (9 au total). |
| Unité / maison | unit / house | Terme générique : ligne, colonne ou bloc (27 unités) [S6][S7]. |
| Voisines (pairs) | peers | Les 20 cases partageant une unité avec une case donnée [S2]. |
| Bande / pile | band / stack | 3 lignes de blocs horizontaux / 3 colonnes de blocs verticaux. |
| Donnée / indice | given / clue | Chiffre imposé au départ, non modifiable. |
| Candidat | candidate | Chiffre encore possible dans une case vide. |
| Notes / annotations | pencil marks | Candidats notés par le joueur dans la case. |

Structure à retenir : 81 cases, 27 unités, chaque case appartient à 3 unités et a 20 voisines.

---

## 2. Propriétés d'une grille valide

- **Solution unique** : par convention, un « vrai » Sudoku a exactement une solution. Sans unicité, aucune résolution purement logique n'est garantie et les indices/le niveau deviennent incohérents [S6][S7]. **Règle produit : ne jamais publier une grille sans vérifier `nbSolutions == 1`.**
- **Minimum de 17 indices** : McGuire, Tugemann et Civario (2012, publié dans *Experimental Mathematics* 2014) ont prouvé par recherche exhaustive (~7,1 M heures-cœur) qu'**aucune grille à 16 indices n'a de solution unique** ; 17 est donc le minimum [S4]. Gordon Royle a recensé ~49 000 grilles distinctes à 17 indices [S4].
- Le nombre d'indices n'est **ni nécessaire ni suffisant** pour l'unicité : une grille à 30 indices peut avoir plusieurs solutions.
- **Nombre de grilles complètes** : 6 670 903 752 021 072 936 960 ≈ **6,67 × 10²¹** (Felgenhauer & Jarvis, 2005) [S5].
- **Grilles essentiellement différentes** (modulo les symétries du Sudoku, i.e. relabel des chiffres + permutations de lignes/colonnes préservant la structure + transposition) : **5 472 730 538 ≈ 5,47 × 10⁹** (Russell & Jarvis, 2006, via le lemme de Burnside) [S5b][S11].
- **Grille minimale** : grille où retirer n'importe quel indice casse l'unicité. Pas obligatoire pour un jeu, mais utile pour les niveaux élevés.

---

## 3. Algorithmes de résolution utilisables dans l'app

Trois usages distincts du solveur dans l'app :
1. **Vérifier l'unicité** (compter les solutions jusqu'à 2) → pendant la génération.
2. **Obtenir la solution** → détection d'erreurs, révélation de case.
3. **Résolution « humaine »** (par techniques) → notation de difficulté et indices intelligents (§5, §7). C'est un moteur différent.

### 3.1 Backtracking + propagation de contraintes + MRV (recommandé)

Approche décrite par Peter Norvig [S2] :
- **Propagation** : (a) si une case n'a qu'un candidat, on l'élimine de ses 20 voisines ; (b) si un chiffre n'a qu'une place possible dans une unité, on l'y place. Ces deux règles = *naked single* et *hidden single*.
- **Recherche** : quand la propagation stagne, on choisit la case avec **le moins de candidats** (heuristique *Minimum Remaining Values*, MRV) et on essaie chaque valeur récursivement.
- Norvig rapporte la résolution des grilles difficiles en centièmes de seconde en Python, sauf rares cas pathologiques [S2].

**Représentation par masque de bits** (indispensable en Swift) :
- Chaque case : `UInt16` dont les bits 1…9 = candidats. `popcount` (`nonzeroBitCount`) donne le nombre de candidats, `trailingZeroBitCount` le plus petit candidat.
- Par unité : un masque des chiffres déjà placés (`rows[9]`, `cols[9]`, `boxes[9]`). Candidats d'une case = `~(rows[r] | cols[c] | boxes[b]) & 0x1FF`.
- Tables précalculées : `box(r,c)`, liste des 20 voisines par case.
- Utiliser des `struct` à tableaux de taille fixe (ou `ContiguousArray`/tuples / `InlineArray` en Swift 6.2+), éviter `Set`, `Dictionary`, classes et allocations dans la boucle chaude ; état copié par valeur à chaque branchement (81 × 2 octets, trivial).

### 3.2 Dancing Links / Algorithm X (Knuth)

- Le Sudoku est un problème de **couverture exacte** : 729 lignes (case × chiffre) et 324 colonnes de contraintes (81 « case remplie » + 81 « ligne/chiffre » + 81 « colonne/chiffre » + 81 « bloc/chiffre ») [S1][S10].
- **Algorithm X** choisit la colonne la moins couverte (équivalent de MRV) et retire/restaure les lignes ; **DLX** implémente cela avec des listes doublement chaînées circulaires où `cover`/`uncover` sont O(1) [S1].
- Avantages : générique, élégant, compte naturellement toutes les solutions. Inconvénients en Swift : beaucoup d'indices/pointeurs, nécessite des tableaux d'entiers plats (pas de classes chaînées, sinon ARC tue les perfs), code plus difficile à déboguer.

### 3.3 Comparatif et attentes sur iPhone

| Approche | Complexité d'implémentation | Perf. typique (ordre de grandeur, build Release, iPhone récent) | Usage conseillé |
|---|---|---|---|
| Backtracking naïf (ordre fixe) | Très faible | ms à secondes, pire cas très mauvais | À éviter |
| Bitmask + propagation + MRV | Faible/moyenne | ~10–100 µs par grille courante, < quelques ms pour les plus dures | **Choix par défaut** |
| DLX (tableaux plats) | Moyenne | Comparable, ~dizaines à centaines de µs | Alternative si besoin de généricité |
| Solveurs SIMD de pointe (tdoku, JCZSolve) | Élevée | ~µs | Inutile pour une app |

Les solveurs C/C++ optimisés résolvent des centaines de milliers à des millions de grilles par seconde [S12] ; un Swift bitmask bien écrit sera plus lent d'un facteur ~5–20 mais reste **largement** assez rapide : générer + vérifier l'unicité d'une grille prend typiquement < 50 ms. Ces chiffres sont des estimations à valider par un benchmark XCTest (`measure {}`) ; en **Debug**, Swift peut être 10–100× plus lent — toujours mesurer en Release.

Recommandation : solveur bitmask + MRV pour unicité/solution ; solveur logique séparé (§5) pour difficulté et indices. Lancer la génération hors du main thread (`Task.detached` / acteur) pour ne jamais bloquer l'UI.

---

## 4. Génération de grilles

### 4.1 Étape 1 – grille complète aléatoire
- Backtracking **randomisé** : même solveur, mais l'ordre d'essai des candidats est mélangé (Fisher–Yates avec **notre** PRNG, cf. §6).
- Astuce : remplir d'abord les 3 blocs diagonaux (indépendants entre eux) au hasard, puis résoudre le reste.

### 4.2 Étape 2 – retrait d'indices avec contrôle d'unicité
```
cases = permutation aléatoire des 81 cases (ou des paires symétriques)
pour chaque case (ou paire) dans cases :
    sauvegarder la valeur ; vider la case
    si compterSolutions(grille, limite: 2) != 1 : remettre la valeur
```
- `compterSolutions(limite: 2)` s'arrête dès la 2ᵉ solution trouvée → coût faible [S10].
- Résultat : grille minimale (si on parcourt toutes les cases) ou on s'arrête à un nombre d'indices cible.
- Puis **noter la difficulté** avec le solveur logique (§5) ; si le niveau obtenu ne correspond pas à la cible, rejeter et recommencer (ou continuer à retirer). Les niveaux élevés (Expert/Diabolique) sont rares par tirage aléatoire : il faut souvent plusieurs centaines d'essais → **mieux vaut pré-générer** ces grilles hors ligne (sur Mac) et les embarquer.

### 4.3 Symétrie des indices (esthétique)
- **Rotationnelle 180°** (la plus classique dans les publications) : retirer `(r,c)` et `(8−r, 8−c)` ensemble.
- Miroir horizontal/vertical, diagonale, rotation 90°, ou aucune. La symétrie n'affecte ni la validité ni (directement) la difficulté, mais réduit l'espace de recherche et peut rendre plus difficile l'obtention de grilles très minimales.

### 4.4 Transformations préservant validité et difficulté
Une grille valide reste valide **et de même difficulté logique** après [S5b][S11] :
1. **Renommage des chiffres** (permutation de 1…9) : 9! = 362 880.
2. **Permutation des lignes à l'intérieur d'une bande** (3! par bande) et **des colonnes à l'intérieur d'une pile**.
3. **Permutation des bandes** entre elles (3!) et **des piles** (3!).
4. **Transposition** (et donc rotations/miroirs par composition).

Le groupe engendré a 9! × 3!⁸ × 2 = 1 218 998 108 160 éléments (en comptant le relabel) [S11]. Une seule grille « mère » de qualité peut donc donner un très grand nombre de grilles visuellement différentes. Usage pratique : embarquer quelques milliers de grilles mères notées par niveau, et appliquer une transformation aléatoire (seedée) à chaque partie. Limite : un joueur averti ne le remarquera quasiment jamais, mais le *chemin logique* reste identique.

---

## 5. Notation de la difficulté

### 5.1 Pourquoi le nombre d'indices est un mauvais indicateur
Certaines grilles à 17 indices se résolvent avec de simples singletons, tandis que des grilles à 25–30 indices peuvent exiger des chaînes avancées. La difficulté perçue dépend de la **technique la plus difficile requise** et du **nombre d'applications** de techniques avancées, pas du nombre de données [S6][S8][S9]. Le nombre d'indices ne sert qu'en garde-fou secondaire.

### 5.2 Méthode : solveur logique « humain »
Boucle : appliquer à chaque pas **la technique la plus simple qui progresse** (placement ou élimination de candidat), revenir au début de la liste après chaque progrès. La note = technique la plus difficile utilisée (éventuellement pondérée par le nombre d'occurrences). Si le solveur bloque sans backtracking → grille « hors catalogue » (rejetée ou Diabolique).

Techniques par ordre croissant (nomenclature SudokuWiki/HoDoKu) [S6][S8] :
1. **Singleton nu** (*naked single*) – une case n'a qu'un candidat.
2. **Singleton caché** (*hidden single*) – un chiffre n'a qu'une place dans une unité.
3. **Paire/triplet/quadruplet nus** (*naked pair/triple/quad*).
4. **Paire/triplet cachés** (*hidden pair/triple*).
5. **Intersections** : *pointing pair/triple* (bloc → ligne/colonne) et *box/line reduction* (*claiming*, ligne/colonne → bloc).
6. **X-Wing**, **Swordfish**, **Jellyfish** (poissons de taille 2/3/4).
7. **XY-Wing** (*Y-Wing*), **XYZ-Wing**, *W-Wing*.
8. **Rectangle unique** (*Unique Rectangle*, suppose l'unicité), *Simple Coloring*, *Skyscraper*, *2-String Kite*.
9. **Chaînes** : X-Chains, XY-Chains, AIC (*Alternating Inference Chains*), *Nice Loops*.
10. **ALS** (*Almost Locked Sets*), *Forcing chains*, *nets* – niveau « extrême ».

### 5.3 Systèmes de notation établis
- **Sudoku Explainer (SE)** de Nicolas Juillerat : note numérique de 1,0 à ~11+, la note d'une grille = note de la technique la plus difficile nécessaire. Ordres de grandeur : 1,2 hidden single (bloc) ; 1,5 hidden single (ligne/col) ; 2,3 naked single ; 2,6–2,8 intersections ; 3,0 paire nue ; 3,2 X-Wing ; 3,4 paire cachée ; 3,6 triplet nu ; 3,8 Swordfish ; 4,2 XY-Wing ; 4,4 XYZ-Wing ; 4,5+ rectangles uniques ; 6,5+ chaînes/boucles ; 7,0+ forcing chains ; 9,0+ « dynamic » [S9]. Référence de la communauté (forum *Enjoy Sudoku Players*, listes des grilles les plus difficiles).
- **HoDoKu** (Bernhard Hobiger) : 5 niveaux (*Easy, Medium, Hard, Unfair, Extreme*) et un score cumulatif = somme des coûts de chaque technique appliquée ; le niveau est fixé par la technique la plus dure + seuil de score [S8].
- **SudokuWiki** : *Grader* qui pondère les techniques utilisées [S6].

### 5.4 Proposition de barème pour l'app (5 niveaux)

| Niveau | Techniques max autorisées | ≈ SE | Indices typiques* | Contrainte supplémentaire |
|---|---|---|---|---|
| **Facile** | Singletons nus + cachés uniquement | 1,0–1,5 (≤ 2,3) | 36–45 | Résoluble sans notes au début |
| **Moyen** | + paires nues/cachées, intersections (pointing, box/line) | 2,5–3,4 | 30–36 | ≥ 1 technique hors singletons |
| **Difficile** | + triplets/quadruplets, X-Wing, Swordfish, XY-Wing, XYZ-Wing | 3,6–4,4 | 26–32 | ≥ 1 technique de cette tranche |
| **Expert** | + Jellyfish, rectangles uniques, coloring, Skyscraper/Kite, W-Wing, XY-chains/X-chains courtes | 4,5–6,5 | 23–28 | Requiert notes complètes |
| **Diabolique** | + AIC/Nice loops, ALS, forcing chains (pas de backtracking pur) | 6,6–9 | 22–26 | Pré-générer hors ligne, curation |

\*Les plages d'indices sont indicatives (constatées dans les apps/publications courantes), **jamais** un critère de classement. Conseil : implémenter d'abord jusqu'à Difficile (techniques simples à coder), puis étendre ; pour Diabolique, embarquer des grilles notées par un outil externe (HoDoKu en ligne de commande, ou SE) plutôt que de tout réimplémenter.

---

## 6. « Grille du jour » déterministe sans serveur

Objectif : tous les utilisateurs reçoivent la même grille à une date donnée, hors ligne.

### 6.1 Option A – génération seedée
- `seed = f(date)` par ex. `UInt64(yyyy*10000 + mm*100 + dd)` mélangé, ou nombre de jours depuis une époque fixe, combiné à une constante d'app (« sel »).
- PRNG **implémenté par nous** et conforme à `RandomNumberGenerator` :
  - **SplitMix64** (Steele, Lea & Flood 2014) : 64 bits d'état, très simple, excellent pour initialiser [S13][S14].
  - **xoshiro256\*\*** (Blackman & Vigna) : 256 bits d'état, rapide, qualité statistique élevée ; les auteurs recommandent de l'amorcer **via SplitMix64** [S14].
- ⚠️ **Pièges Swift** :
  - `SystemRandomNumberGenerator` est cryptographique et **non seedable** [S15].
  - `Hasher` / `hashValue` sont **randomisés à chaque exécution** du processus ; Apple précise qu'il ne faut pas les persister ni s'y fier d'une exécution à l'autre [S16]. Ne jamais dériver la seed d'un `hashValue` de chaîne.
  - `shuffle(using:)`, `randomElement(using:)`, `Int.random(in:using:)` : l'algorithme de la bibliothèque standard n'est **pas documenté comme stable entre versions de Swift** ; un changement d'implémentation casserait la grille du jour entre versions de l'app/iOS. → Implémenter **notre propre** Fisher–Yates et tirage borné (ex. méthode de Lemire) sur notre PRNG.
  - Ne pas itérer sur un `Set`/`Dictionary` dans le générateur (ordre non déterministe).
  - Arithmétique : utiliser `&+`, `&*`, `>>` sur `UInt64` (wrapping) explicitement.
- **Test de non-régression obligatoire** : figer en tests unitaires les grilles attendues pour quelques dates (« golden tests »). Toute modification du générateur, des tables ou de l'algorithme change toutes les grilles futures → versionner le générateur (`dailyGeneratorVersion`).
- Inconvénient : la difficulté n'est pas garantie sans boucle de rejet (déterministe elle aussi : essais successifs avec la même suite PRNG), et le temps de génération des niveaux élevés est variable.

### 6.2 Option B – pré-génération embarquée (recommandée)
- Générer sur Mac un fichier (JSON ou binaire compact : 81 octets ou 41 octets en nibbles par grille + solution) contenant **≥ 1 an** (366+ jours, idéalement 2–3 ans) de grilles du jour, notées et triées (ex. lundi Facile → dimanche Expert).
- Avantages : difficulté contrôlée et curée, zéro coût CPU, robuste aux changements de code. Coût : < 100 Ko pour plusieurs années.
- Hybride : liste embarquée + **fallback seedé** au-delà de la fin de la liste (ou transformation seedée de la liste : grille `jour mod N` + transformation §4.4 dérivée de la date).

### 6.3 Choix du fuseau horaire
- **UTC** : même grille au même instant pour tous (classements comparables), mais le changement se fait à 1 h du matin à Paris, 19 h la veille à New York – peu intuitif.
- **Heure locale de l'appareil** (choix de Wordle, du NYT Mini…) : la grille change à minuit pour chacun ; deux personnes dans des fuseaux différents peuvent avoir des grilles différentes pendant quelques heures. Pour une app sans classement en ligne, **c'est le meilleur choix UX**.
- Recommandation : clé de date = `Calendar(identifier: .gregorian)` + `TimeZone.current` → composantes `year/month/day` (pas de `Date` brute), calendrier grégorien forcé (ne pas dépendre du calendrier utilisateur, ex. bouddhiste/japonais). Prévoir le changement de fuseau/jour en cours de partie (conserver la grille démarrée). La manipulation de l'horloge par l'utilisateur est acceptable (pas d'enjeu compétitif).

---

## 7. Système d'indices

Niveaux d'aide observés dans les bonnes apps (SudokuWiki, HoDoKu, Good Sudoku de Zach Gage, Sudoku.com) :
1. **Vérifier** : signaler les cases erronées (par rapport à la solution connue).
2. **Révéler une case** : remplir une case avec la bonne valeur. Simple mais peu pédagogique ; choisir de préférence une case **déductible maintenant** (pas une case aléatoire impossible à justifier).
3. **Indice intelligent progressif** (le meilleur) :
   - Palier 1 : « Regardez le bloc central » / « Il existe une *paire nue* » (zone + nom de technique).
   - Palier 2 : surligner les cases et candidats impliqués.
   - Palier 3 : expliquer la conclusion (« donc 7 peut être retiré de r4c5 ») et proposer de l'appliquer.

**Mise en œuvre via le solveur logique** : le même moteur que la notation (§5.2) expose chaque étape sous forme de structure, ex.
```swift
struct HintStep { let technique: Technique; let houses: [House]; let cells: [Cell];
                  let placements: [(Cell, Digit)]; let eliminations: [(Cell, Digit)] }
```
- Appliquer le solveur à **l'état courant du joueur** (ses valeurs + candidats recalculés), pas à la grille initiale.
- Si le joueur a commis une erreur (valeur ≠ solution), l'indice prioritaire est de **la signaler** – sinon le solveur logique peut aboutir à des contradictions.
- Si les notes du joueur sont incomplètes, calculer les candidats réels en interne ; un indice basé sur des éliminations doit présupposer les notes complètes (sinon proposer d'abord « remplir les notes »).
- Comptabiliser les indices (impact sur score/étoiles) plutôt que les limiter arbitrairement – pas de pub, donc pas de monétisation des indices.

---

## 8. UX des bonnes apps (résumé)

- **Mode notes** (crayon) avec bascule claire ; saisie « case puis chiffre » et « chiffre puis cases » (*digit-first*).
- **Suppression automatique des candidats** dans les voisines quand un chiffre est placé (option).
- **Remplissage automatique des notes** (option, souvent désactivé en Facile).
- **Surlignage** : ligne/colonne/bloc de la case sélectionnée ; **toutes les occurrences du même chiffre** (valeurs et notes).
- **Conflits** : surligner en rouge les doublons (règle) ; option distincte « erreurs vs solution ».
- **Compteur d'erreurs** (ex. 3 max) – optionnel, désactivable.
- **Annuler/Rétablir** illimité (pile de commandes incluant notes) ; **effacer**.
- **Chronomètre** (pause automatique en arrière-plan, masquable) ; chiffres restants par valeur sur le pavé (griser quand 9 placés).
- **Sauvegarde automatique** de la partie ; statistiques par niveau ; séries pour la grille du jour.
- Accessibilité : Dynamic Type, VoiceOver (« ligne 3, colonne 5, vide, candidats 2 4 7 »), contraste/daltonisme (pas seulement la couleur rouge), haptique légère, mode sombre.

---

## Niveaux durs : chaînes et grilles légendaires (ajout du 11/11/2026)

### Pourquoi l'ancien Diabolique était inégal
L'ancien Diabolique (v1) acceptait toute grille minimale qui résistait à nos techniques Expert. Mesure sur 200 grilles
v1 avec le nouveau solveur : 49 (25 %) se résolvaient avec un simple Turbot Fish (gratte-ciel, cerf-volant), une
technique plus facile qu'un XY-Wing ; 142 demandaient une vraie chaîne ; 9 résistaient à tout (niveau Légende).

### Les chaînes d'inférences alternées (AIC) [S6, S7, S8]
Un candidat (case, chiffre) est un nœud. **Lien fort** A = B : si A est faux, B est vrai (case à deux candidats, ou
chiffre à deux places dans une unité). **Lien faible** A - B : si A est vrai, B est faux (même case, ou même chiffre
dans deux cases qui se voient). Une chaîne A = … = Z qui alterne fort et faible, et commence et finit par un lien fort,
prouve « A ou Z est vrai ». On élimine alors : le chiffre des cases qui voient A et Z (même chiffre) ; les autres
candidats de la case (même case) ; ou le chiffre de A dans la case de Z et inversement (cases qui se voient).
Cas particuliers : chaîne à un seul chiffre = **X-Chain** (Turbot Fish si 4 nœuds : gratte-ciel, cerf-volant) ;
chaîne de cases à deux candidats = **XY-Chain** (un XY-Wing est une XY-Chain de 3 cases).

Implémentation (`LogicalSolver.chain()`) : parcours en largeur sur les états (nœud, vrai/faux), la chaîne la plus courte
qui élimine quelque chose, 12 nœuds au plus. Chaque maillon est une implication valide, donc le résultat est juste même
si un nœud se répète ; les tests vérifient qu'aucune élimination ne touche le chiffre de la solution.

Nouveau Diabolique (v2) : au moins une vraie chaîne (X-Chain longue, XY-Chain ou AIC) et au moins 3 coups de chaîne.
Sur 200 grilles : de 3 à 21 coups de chaîne par grille, environ 9 ms par grille en Release.

### Les grilles les plus dures connues
Il n'existe pas de classement officiel : la difficulté dépend des techniques admises. Le barème de référence des
passionnés est celui de Sudoku Explainer (SE) [S9] ; les grilles ci-dessous sont toutes au-delà des AIC et figurent
dans le niveau Légende. Toutes ont une solution unique (vérifié par nos tests).

| Grille | Origine |
|---|---|
| AI Escargot | Arto Inkala, 2006 [S18] |
| Inkala 2010 | Arto Inkala, 2010 [S19] |
| Inkala 2012 (« la plus difficile du monde », presse de juin 2012) | Arto Inkala [S18] |
| Easter Monster, Golden Nugget, Platinum Blonde | forums de solveurs (auteurs non vérifiés) [S9] ; Platinum Blonde est jugée la plus dure par Ercsey-Ravasz et Toroczkai [S20] |
| Unsolvable #28, #49 | David Filmer, via SudokuWiki [S18] |

## Sources

- [S1] D. E. Knuth, « Dancing Links », *Millennial Perspectives in Computer Science*, 2000 – https://arxiv.org/abs/cs/0011047
- [S2] P. Norvig, « Solving Every Sudoku Puzzle » – https://norvig.com/sudoku.html
- [S4] G. McGuire, B. Tugemann, G. Civario, « There is no 16-Clue Sudoku: Solving the Sudoku Minimum Number of Clues Problem », 2012 – https://arxiv.org/abs/1201.0749 (*Experimental Mathematics* 23(2), 2014, https://doi.org/10.1080/10586458.2013.870056)
- [S5] B. Felgenhauer, F. Jarvis, « Enumerating possible Sudoku grids », 2005 – http://www.afjarvis.staff.shef.ac.uk/sudoku/sudoku.pdf ; publié sous « Mathematics of Sudoku I », *Mathematical Spectrum* 39 (2006)
- [S5b] E. Russell, F. Jarvis, « There are 5472730538 essentially different Sudoku grids… » – http://www.afjarvis.staff.shef.ac.uk/sudoku/sudgroup.html
- [S6] A. Stuart, SudokuWiki – stratégies et solveur : https://www.sudokuwiki.org/Strategy_Families ; https://www.sudokuwiki.org/sudoku.htm ; ex. https://www.sudokuwiki.org/X_Wing_Strategy , https://www.sudokuwiki.org/Y_Wing_Strategy
- [S7] Sudopedia (miroir) – terminologie et techniques : http://sudopedia.enjoysudoku.com/
- [S8] B. Hobiger, HoDoKu – techniques et niveaux : https://hodoku.sourceforge.net/en/tech_intro.php ; https://hodoku.sourceforge.net/en/docs_cre_levels.php
- [S9] Sudoku Explainer (N. Juillerat) et barème SE : http://sudopedia.enjoysudoku.com/SE.html ; http://sudopedia.enjoysudoku.com/Sudoku_Explainer.html ; forum : http://forum.enjoysudoku.com/
- [S10] Wikipedia, « Sudoku solving algorithms » (couverture exacte, backtracking) – https://en.wikipedia.org/wiki/Sudoku_solving_algorithms
- [S11] Wikipedia, « Mathematics of Sudoku » (énumération, groupe de symétries) – https://en.wikipedia.org/wiki/Mathematics_of_Sudoku
- [S12] T. Dillon, tdoku – benchmarks de solveurs rapides : https://t-dillon.github.io/tdoku/ ; https://github.com/t-dillon/tdoku
- [S13] G. L. Steele, D. Lea, C. H. Flood, « Fast Splittable Pseudorandom Number Generators », OOPSLA 2014 – https://doi.org/10.1145/2660193.2660195
- [S14] D. Blackman, S. Vigna, xoshiro/xoroshiro – https://prng.di.unimi.it/ (code de référence SplitMix64 : https://prng.di.unimi.it/splitmix64.c)
- [S15] Apple, `SystemRandomNumberGenerator` – https://developer.apple.com/documentation/swift/systemrandomnumbergenerator ; `RandomNumberGenerator` – https://developer.apple.com/documentation/swift/randomnumbergenerator
- [S16] Apple, `Hasher` (« hash values are not guaranteed to be equal across different executions ») – https://developer.apple.com/documentation/swift/hasher ; SE-0206 Hashable Enhancements – https://github.com/apple/swift-evolution/blob/main/proposals/0206-hashable-enhancements.md
- [S17] D. Lemire, « Fast Random Integer Generation in an Interval », ACM TOMACS 2019 – https://arxiv.org/abs/1805.10941
- [S18] A. Stuart, SudokuWiki – « Arto Inkala Sudoku » : https://www.sudokuwiki.org/Arto_Inkala_Sudoku ; « AI Escargot » : https://www.sudokuwiki.org/Escargot
- [S19] Gigazine, « The hardest Sudoku in the world that a mathematical expert created over three months », 2010 – https://gigazine.net/gsc_news/en/20100822_hardest_sudoku
- [S20] M. Ercsey-Ravasz, Z. Toroczkai, « The Chaos Within Sudoku », *Scientific Reports* 2, 725 (2012) – https://doi.org/10.1038/srep00725
