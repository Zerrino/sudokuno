# Comment les experts résolvent un sudoku : conséquences pour l'explication, le générateur et l'éditeur

> Note de recherche pour Sudokuno (iOS + Android), rédigée le 12/11/2026. Elle complète
> `sudoku-fonctionnement.md` sans la répéter (règles, algorithmes, AIC, barème en 5 niveaux y sont déjà).
> Chaque affirmation renvoie à une source consultée ce jour-là ([E1], [E2]… en fin de document).
> Ce qui n'a pas pu être vérifié est listé en §8. Aucune source n'est citée sans avoir été lue.

**À retenir en six lignes**

1. Les trois solveurs de référence appliquent tous « la technique la plus simple d'abord », mais ils ne sont pas d'accord sur ce qui est simple : Sudoku Explainer place le singleton caché avant le singleton nu, HoDoKu l'inverse [E13][E11].
2. Une étape bien expliquée contient toujours les mêmes six éléments : nom, cases du motif, chiffres, unités, candidats éliminés, et une phrase « donc » (§2).
3. Selon les mesures d'Andrew Stuart sur 141 672 grilles, le Jellyfish (10 grilles) et les quadruplets (255 et 13) sont presque inutiles ; le coloriage simple (17 747), les rectangles d'unicité (2 135, plus 4 911 « cachés ») et le BUG (1 069) servent bien plus [E3]. L'ordre de priorité demandé mérite d'être inversé (§3).
4. Le moteur trouve déjà les gratte-ciel, cerfs-volants et W-Wing : ce sont des chaînes. Il leur manque seulement leur nom et leur explication propre (§3.3).
5. Une « belle » grille, pour les créateurs, c'est : solution unique, pas de devinette, difficulté tenue sur toute la résolution (pas un seul goulot), symétrie, 32 indices au plus [E1][E19][E21].
6. Le générateur de Sudokuno retire les indices « de haut en bas » : Denis Berthier a montré que cette famille de générateurs est biaisée vers des grilles plus faciles et moins fournies [E22].

---

## 0. Ce que le dépôt contient déjà (constaté en lisant le code, sans rien modifier)

- `ios/Packages/SudokuKit/Sources/SudokuKit/Explainer.swift` existe : il rejoue la résolution coup par coup (`ExplainedStep` : état avant le coup, `LogicStep`, ou case révélée quand la logique est à court).
- `LogicStep` porte déjà `technique`, `placements`, `eliminations`, `unit`, `units`, `focus`, `digits`, `chain`.
- **Le XYZ-Wing est déjà dans le moteur** (`LogicalSolver.xyzWing()`, niveau Expert), contrairement à ce que disait la demande. Il reste donc hors de la liste des manques.
- Ordre actuel : singleton nu, singleton caché, pointing, box-line, paires, triplets, X-Wing, XY-Wing, Swordfish, XYZ-Wing, puis chaînes.
- `PuzzleAnalysis` (éditeur) détecte : conflit, aucune solution, plusieurs solutions (avec un chiffre suggéré), solution unique (niveau, technique la plus dure), et sait lister les indices superflus (`redundantClues`).
- `Generator.minimalPuzzle` retire les indices par paires symétriques (symétrie centrale) puis `generate` **rend des chiffres un par un, sans symétrie**, pour redescendre au niveau visé et ajouter des chiffres « de confort ».

---

## 1. Dans quel ordre les experts cherchent, et pourquoi

### 1.1 Le principe commun : la plus simple d'abord

- **Andrew Stuart (SudokuWiki)** range ses stratégies en quatre groupes, dans l'ordre où son solveur les essaie [E2] :
  - *Basic* : singletons, candidats nus (paires, triplets, quadruplets), candidats cachés, intersections ;
  - *Tough* : X-Wing, Chute Remote Pairs, Simple Colouring, W-Wing, Y-Wing, Rectangle Elimination, Swordfish, XYZ-Wing, BUG, Avoidable Rectangles ;
  - *Diabolical* : X-Cycles, 3D Medusa, Jellyfish, Unique Rectangles, …, Hidden URs, WXYZ-Wing, XY-Chains, Aligned Pair Exclusion ;
  - *Extreme* : Grouped X-Cycles, Finned X-Wing/Swordfish, Inference Chains (AIC), Almost Locked Sets, Sue-de-Coq, Forcing Chains, etc.
- Il précise que cet ordre est en partie subjectif, qu'il représente « le meilleur ordre pour attaquer une grille » et une tentative de « chemin minimal » ; une stratégie non utilisée par le solveur aurait souvent pu servir aussi [E3].
- Ses critères de rang : difficulté à repérer le motif en vrai, fréquence du besoin, et nombre d'éliminations produites [E1].
- Deux exemples de placement motivés : le coloriage simple est cherché avant le 3D Medusa parce qu'il est « plus simple à chercher » [E5] ; le BUG est placé juste avant les XY-Chains parce que, d'après ses tests, toute occurrence de BUG se résout aussi par une XY-Chain, mais que le BUG est « une solution facile si on reconnaît le motif » [E6].
- **Denis Berthier** fait de cette règle le cœur de son approche : à chaque pas, on applique la règle disponible la plus simple (*simplest-first strategy*) [E23].
- **Sudoku Explainer** essaie ses règles par note croissante (§4.1) [E13].

### 1.2 Ils ne sont pas d'accord sur « simple » : tout dépend de la façon de noter

| Coup | Sudoku Explainer [E13] | HoDoKu (score par défaut) [E11] |
|---|---|---|
| Dernière case d'une unité | 1,0 | 4 (*Full House*) |
| Singleton caché dans un bloc | 1,2 | 14 |
| Singleton caché en ligne/colonne | 1,5 | 14 |
| Singleton nu | **2,3** | **4** |

- Sudoku Explainer met le singleton caché **avant** le singleton nu, et il l'essaie en premier [E13]. C'est le point de vue du joueur sans notes : chercher « où peut aller le 8 dans ce bloc » se fait à l'œil, alors que voir qu'une case n'a plus qu'un candidat demande de compter huit chiffres.
- HoDoKu fait l'inverse [E11] : avec tous les candidats affichés, une case à un seul candidat saute aux yeux.
- Stuart décrit le démarrage de toute grille, de la plus facile à la plus dure, comme du « balayage visuel » (*eyeballing*) : d'abord les blocs (« la forme la plus facile »), puis les lignes et colonnes ; les dix ou vingt dernières cases tombent de la même façon [E4].
- Sudoku Explainer a même des techniques « directes » notées bas : *Direct Pointing* 1,7, *Direct Claiming* 1,9, *Direct Hidden Pair* 2,0, *Direct Hidden Triplet* 2,5. Ce sont des éliminations qui donnent immédiatement un singleton caché, donc jouables sans notes [E13]. Le même pointing vaut 2,6 quand il ne fait qu'éliminer.

**Conséquence pour Sudokuno** : notre ordre (singleton nu d'abord) est celui d'un joueur qui a toutes ses notes. En Facile, où l'on joue sans notes, l'explication devrait privilégier la formulation « singleton caché » quand les deux existent pour la même case (voir §7, R3).

### 1.3 Au crayon : trois façons de noter

- **Sans notes** : Stuart en fait un critère de niveau. Sa catégorie *Kids* n'exige aucune prise de notes ; *Gentle* ne demande que « une seule place dans une ligne, colonne ou bloc » ; *Moderate* peut demander paires et triplets [E1].
- **Notes complètes** (*pencilmark grid*) : beaucoup de techniques exigent de connaître tous les candidats [E1][E26]. HoDoKu précise que les sous-ensembles nus se trouvent « au mieux quand tous les candidats restants sont notés » [E8].
- **Filtres par chiffre** : HoDoKu colore les cases où un chiffre est encore possible (ou impossible) ; c'est présenté comme un bon outil pour trouver les singletons et les candidats verrouillés [E12], et comme une aide pour repérer les W-Wing [E7].
- **Notation Snyder** (ne noter un candidat dans un bloc que s'il n'y a que deux places) : je n'ai trouvé **aucune source primaire écrite**. Thomas Snyder en parle dans une vidéo de son site (« The Truth About Snyder Notation », 25/07/2025), dont la page ne contient pas de texte exploitable [E20]. La définition courante vient de guides de seconde main (par exemple [E28]). À traiter comme non vérifié.

### 1.4 En compétition

- Je n'ai trouvé **aucune source primaire écrite** décrivant comment les compétiteurs résolvent (ordre de recherche, notation). La page « Rules and Regulations » de la World Puzzle Federation ne traite que de gouvernance (statuts, adhésion, organisation des championnats) [E27].
- Ce qui est vérifiable touche aux grilles, pas aux joueurs : les règles de conception de GM Puzzles (le site de Thomas Snyder, qui s'y présente comme triple champion du monde de sudoku [E19b]) imposent une solution unique atteignable par la logique seule, 32 indices au plus, et une symétrie ou un thème [E19].
- Stuart note que la perception de difficulté varie : sur son concours quotidien (2 000 à 3 000 réponses par jour), environ 10 % des joueurs peinent sur les grilles faciles et 10 % trouvent certaines diaboliques faciles ; certains « court-circuitent » la logique par reconnaissance de motifs ou intuition [E1].

---

## 2. Comment les solveurs pédagogiques formulent une étape

### 2.1 Sudoku Explainer (Nicolas Juillerat)

Lu dans le code source [E13] :

- **Données d'un indice** (`Hint`, `IndirectHint`) : la case et la valeur à poser s'il y en a ; les **unités** concernées (`getRegions`) ; les **cases sélectionnées** (`getSelectedCells`) ; trois jeux de candidats colorés, **verts** (ceux du motif), **rouges** (ceux qu'on retire), **bleus** ; des **liens** fléchés entre candidats (`getLinks`) ; et plusieurs **vues** pour un même indice (`getViewCount`), utilisées par exemple pour montrer chaque branche d'une chaîne.
- **Trois paliers de révélation** : `getClueHtml(false)` donne seulement « Cherchez un *Singleton nu* » ; `getClueHtml(true)` ajoute la zone ou les cases ; `toHtml()` donne l'explication complète.
- **Rédaction** : un gabarit HTML par technique, où les balises de couleur du texte reprennent les couleurs de la grille. Exemple (paire, triplet ou quadruplet nu), traduit :
  > « Les seules valeurs possibles pour les *N cases X* de *l'unité U* sont les *N valeurs V*. Comme le nombre de valeurs est égal au nombre de cases, ces valeurs doivent occuper ces cases, dans un ordre quelconque. Les *autres positions possibles* de ces valeurs peuvent donc être retirées de l'unité. »
- Exemple XY-Wing : « Quelle que soit la bonne valeur de la case A (x ou y), l'une des deux cases B ou C aura z comme seule valeur possible. Il s'ensuit que B ou C contient z. Les autres z peuvent donc être retirés de toute case qui partage une unité avec B et avec C. »
- Exemple rectangle d'unicité type 1 : le texte explique d'abord pourquoi deux configurations échangeables donneraient une seconde solution, puis conclut « comme un sudoku valide n'a qu'une solution… la seule façon d'éviter ces deux configurations est que la case X ne contienne ni a ni b ».
- Structure constante : **constat** (ce qu'on voit), **raison** (pourquoi cela contraint), **conséquence** (ce qu'on retire).

### 2.2 HoDoKu (Bernhard Hobiger)

- **Trois niveaux d'indice** : *Vague hint* (seulement le nom de la technique), *Concrete hint* (plus de détails, par exemple les candidats touchés), *Show next step* (surbrillance dans la grille + ligne de texte, avec boutons Exécuter / Annuler) [E12].
- **Une ligne par étape**, dans une notation compacte [E9][E7] :
  - `Skyscraper on 4 in r2c5,r8c4 (connected by r28c1) => r1c4<>4`
  - `W-Wing: 4/1 in r1c9,r8c7 connected by 1 in r18c3 => r123c7,r89c9<>4`
  - chaîne : `r4c9 -5- r4c4 -9- r4c8 =9= r8c8 -9- r8c9 -5- r4c9` (`-` lien faible, `=` lien fort).
- **Étapes complexes découpées** : pour les forcing chains, chaque sous-chaîne a sa ligne ; cliquer une ligne n'affiche que cette sous-chaîne, car « le nombre de liens peut rendre l'image inutilisable » [E12][E17].
- **Vocabulaire du texte pédagogique** : pivot et pinces (XY-Wing), ensembles de base et de couverture (poissons), paire conjuguée et couleurs opposées (coloriage), RCC (ALS) [E7][E15][E6b][E16].
- **La preuve est facultative pour le joueur** : après avoir déroulé la logique du gratte-ciel, HoDoKu ajoute « heureusement, il n'est pas nécessaire de refaire ce raisonnement à chaque fois : il suffit d'identifier le motif » [E9].
- **Mode apprentissage** : on choisit une technique, HoDoKu crée une grille qui la contient et la résout automatiquement jusqu'au point où elle s'applique ; le mode entraînement fait de même mais montre la grille depuis le début [E12].
- **« Solve up to »** : exécute automatiquement les étapes que le joueur a déclaré ne pas vouloir chercher lui-même [E12].

### 2.3 SudokuWiki (Andrew Stuart)

- Sortie texte par étape, avec les cases du motif et chaque candidat retiré [E1] :
  - `POINTING PAIR: Between Box 6 and Col 9: 3 taken off C9`
  - `Y-WING 8 taken off C3 - using C2 J2 H3`
  - `X-CYCLE on 9 (Discontinuous Alternating Nice Loop, length 8): +9[H1]-9[H6]+9[F6]… - Contradiction: When H1 is set to 9 the chain implies it cannot be 9 - it can be removed`
- Chaque placement est préfixé par deux nombres : cases résolues à ce moment, et numéro de « tour » (les placements d'un même tour sont indépendants entre eux) [E1].
- Couleurs : vert et bleu pour les deux couleurs d'une chaîne, jaune pour les candidats éliminés [E5].
- Vocabulaire des chaînes : un candidat est ON ou OFF ; liens *bi-location* (deux places pour un chiffre dans une unité) et *bi-value* (deux candidats dans une case) [E5][E2].
- Quand plusieurs raisons mènent au même placement, il les montre toutes (« Pinned! » : dernière place dans le bloc, la ligne et la colonne) [E4].

### 2.4 Synthèse : la fiche d'une étape

Les trois outils affichent les mêmes éléments. Notre `LogicStep` en porte déjà la plupart.

| Élément | SE | HoDoKu | SudokuWiki | `LogicStep` actuel |
|---|---|---|---|---|
| Nom de la technique | oui | oui | oui | `technique` |
| Cases du motif | cases sélectionnées | cases citées | « using C2 J2 H3 » | `focus` |
| Chiffres du motif | candidats verts | « 4/1 » | « on 9 » | `digits` |
| Unités | régions | « connected by r28c1 » | « Between Box 6 and Col 9 » | `unit`, `units` |
| Candidats retirés | rouges | `=> r1c4<>4` | « taken off », jaune | `eliminations` |
| Liens fort/faible | liens fléchés | `=` et `-` | `+`/`-`, ON/OFF | `chain` (ordre seulement) |
| Rôles dans le motif (pivot, pinces, base, couverture) | texte | texte | texte | **absent** : `focus` est une liste plate |
| Révélation progressive | 3 paliers | 3 paliers | non | `Hint` (3 étapes) pour les indices |
| Plusieurs vues pour une étape | oui | oui (sous-chaînes) | non | **absent** |
| Phrase « pourquoi » | gabarit par technique | texte + preuve | texte | à écrire (`L("…")`) |

---

## 3. Techniques : ce qui manque, ce que ça vaut

### 3.1 Les fréquences mesurées renversent l'ordre de priorité

Stuart a compté, sur 141 672 grilles produites au hasard en mai 2024, dans combien de grilles son solveur a eu besoin de chaque stratégie [E3]. Attention : ces chiffres dépendent de **son** ordre d'essai (une stratégie placée tard est moins comptée) et de son solveur ; ils ne valent pas mesure sur notre moteur.

| Stratégie | Grilles concernées (sur 141 672) | Dans Sudokuno |
|---|---|---|
| Simple Colouring | 17 747 | non nommé (voir 3.3) |
| XY-Chain | 16 658 | oui |
| Y-Wing (XY-Wing) | 14 683 | oui |
| Rectangle Elimination | 11 747 | non |
| AIC | 7 995 | oui |
| X-Wing | 7 686 | oui |
| XYZ-Wing | 5 405 | oui |
| Hidden Unique Rectangle | 4 911 | non |
| X-Cycle | 4 605 | oui (X-Chain) |
| Unique Rectangle | 2 135 (type 1 : 32 %, type 4 : 29 %) | non |
| BUG | 1 069 | non |
| Digit / Cell / Unit Forcing Chain | 890 / 830 / 208 | non |
| Swordfish | 846 | oui |
| Naked Quad | 255 | non |
| Hidden Quad | 13 | non |
| Jellyfish | 10 | non |
| Almost Locked Sets | 10 | non |

Autres chiffres du même article : 48,4 % des grilles ne demandent que des singletons ; environ 5 % demandent une stratégie « extrême » ; 4 grilles sur 141 676 résistent à toutes ses stratégies [E3]. Le W-Wing n'apparaît pas dans ce tableau (ajouté au solveur en janvier 2026) [E7b].

**Lecture** : Jellyfish et quadruplets, en tête de la liste demandée, sont les moins utiles. Ils restent très faciles à coder chez nous (`fish(size: 4)`, `nakedSubset(size: 4)`, `hiddenSubset(size: 4)`), donc peu coûteux, mais ils n'amélioreront presque aucune explication. Les rectangles d'unicité et le BUG, placés plus bas dans la demande, apportent davantage.

### 3.2 Fiche de chaque technique

Notes : SE = note Sudoku Explainer 1.2.1 lue dans le code [E13] ; HoDoKu = niveau et score par défaut lus dans `Options.java` [E11] (niveaux : Easy, Medium, Hard, Unfair, Extreme).

**Jellyfish** — SE 5,2 ; HoDoKu Hard, 160.
- Définition : quatre lignes dans lesquelles toutes les places d'un chiffre tiennent dans quatre colonnes (ou l'inverse) [E8b].
- Condition : chaque ligne de base et chaque colonne de couverture contient au moins un candidat du chiffre ; il n'est pas nécessaire que chaque intersection en ait un [E15].
- Élimine : le chiffre dans les quatre colonnes, hors des quatre lignes [E15][E8b].

**Quadruplet nu** — SE 5,0 ; HoDoKu Hard, 120. **Quadruplet caché** — SE 5,4 ; HoDoKu Hard, 150.
- Nu : quatre cases d'une unité qui ne contiennent à elles toutes que quatre chiffres ; on retire ces chiffres des autres cases de l'unité [E8].
- Caché : symétrique (quatre chiffres confinés à quatre cases ; on retire les autres candidats de ces cases) [E8].
- Un « quadruplet verrouillé » n'existe pas : l'intersection d'un bloc et d'une ligne n'a que trois cases [E8].

**XYZ-Wing** — SE 4,4 ; HoDoKu Hard, 180. *Déjà dans le moteur.*
- Pivot à trois candidats XYZ, deux pinces XZ et YZ qui voient le pivot. Z est retiré des cases qui voient les deux pinces **et** le pivot [E7].

**W-Wing** — absent de SE 1.2.1 ; HoDoKu Hard, 150.
- Deux cases à deux candidats identiques {a, b}, reliées par un lien fort sur a (une unité où a n'a que deux places, chacune voyant l'une des deux cases) [E7].
- Élimine : b dans toute case qui voit les deux cases [E7].
- Preuve : l'une des deux extrémités du lien fort est a ; la case qu'elle voit vaut donc b [E7].
- C'est une chaîne (HoDoKu l'écrit comme boucle discontinue) [E7]. Stuart la juge « relativement facile » et la place tôt dans le groupe *Tough* [E7b]. Nommée d'après George Woods (2007) [E7b].

**Skyscraper (gratte-ciel)** — HoDoKu Hard, 130. **2-String Kite (cerf-volant)** — HoDoKu Hard, 150. Turbot Fish générique — HoDoKu Hard, 120. Dans SE : « Turbot Fish », traité comme une chaîne forcée à un chiffre, base 6,6.
- Gratte-ciel : un chiffre, deux lignes (ou colonnes) où il n'a que deux places ; deux de ces places sont dans la même colonne (la « base »). L'une des deux autres est vraie ; on retire le chiffre des cases qui voient ces deux-là [E9].
- Contrainte : les deux sommets doivent être dans la même bande, sinon rien n'est éliminé [E9].
- Cerf-volant : une ligne et une colonne où le chiffre n'a que deux places ; une extrémité de chacune dans le même bloc. On retire le chiffre de la case qui voit les deux autres extrémités [E9].
- Les deux sont des cas particuliers du Turbot Fish ; le gratte-ciel se lit aussi comme deux X-Wing sashimi [E9].
- L'écart SE (6,6) / HoDoKu (130, moins qu'un X-Wing à 140) illustre le désaccord entre barèmes : SE note la chaîne, HoDoKu note le motif reconnaissable.

**Simple Colouring (coloriage simple)** — absent de SE 1.2.1 ; HoDoKu Hard, 150 (Multi Colors : 200).
- Un chiffre ; on relie les paires conjuguées (unités où il n'a que deux places) et on alterne deux couleurs le long des liens. Une des deux couleurs est entièrement vraie, l'autre entièrement fausse [E6b][E5].
- *Color Trap* (règle 4 de Stuart) : une case non colorée qui voit les deux couleurs perd le chiffre [E6b][E5].
- *Color Wrap* (règle 2) : deux cases de même couleur dans une même unité ; toute cette couleur est fausse [E6b][E5].
- Chez Stuart, la règle 4 représente 74,7 % des cas, la règle 2 25,3 % [E3].
- « Toutes les techniques de coloriage sont simplement des méthodes pour trouver des chaînes » ; colorier est « bien plus facile » que chercher les chaînes [E6b].

**Rectangles d'unicité (UR)** — SE 4,5 à 5,0 selon la taille de la boucle, jusqu'à +0,3 pour le type 3 ; HoDoKu Hard, 100 pour chaque type (1 à 6, Hidden Rectangle, Avoidable 1 et 2).
- Prérequis : la grille a **une seule solution**. Ce n'est pas une règle du sudoku mais une contrainte sur le créateur, que le joueur peut exploiter s'il lui fait confiance ; l'usage est controversé [E14][E25].
- Motif : quatre cases sur exactement deux lignes, deux colonnes et **deux blocs**, avec les deux mêmes candidats. Complet, il donnerait deux solutions échangeables [E14]. Erreur fréquente : oublier la règle des deux blocs [E14].
- Type 1 : une seule case a des candidats en plus ; on lui retire les deux candidats du rectangle [E14].
- Type 2 : deux cases non diagonales ont le même candidat en plus ; on le retire des cases qui voient les deux [E14].
- Type 3 : les candidats en plus des deux cases forment, comme une case virtuelle, un sous-ensemble nu avec d'autres cases [E14].
- Type 4 : dans une unité commune aux deux cases « en plus », un des deux chiffres du rectangle n'a pas d'autre place ; on retire l'autre chiffre de ces deux cases [E14].
- Types 5 et 6, Hidden Rectangle : variantes diagonales [E14].
- *Avoidable Rectangle* : certaines cases sont déjà remplies ; ne s'applique que si **aucune n'est un indice de départ** [E14].
- HoDoKu juge ces techniques « faciles à trouver, polyvalentes », et permet de les désactiver d'un clic [E14].

**BUG+1** — SE 5,6 ; HoDoKu Hard, 100.
- BUG : toutes les cases non résolues ont deux candidats et chaque candidat apparaît exactement deux fois par ligne, colonne et bloc ; une telle grille a deux solutions [E14].
- BUG+1 : une seule case a un candidat de plus ; c'est lui qu'il faut poser. Il se reconnaît parce qu'il apparaît trois fois dans la ligne, la colonne et le bloc de la case [E14][E6].
- Même prérequis d'unicité que les UR.

**ALS-XZ** — absent de SE 1.2.1 (Sudopedia note que SE n'a aucune technique ALS [E18]) ; HoDoKu Unfair, 300.
- ALS : N cases d'une même unité contenant N+1 candidats [E16].
- RCC (candidat commun restreint) : chiffre présent dans deux ALS dont toutes les occurrences se voient ; il ne peut être vrai que dans l'un des deux [E16].
- ALS-XZ : deux ALS avec un RCC X et un autre chiffre commun Z ; on retire Z des cases hors ALS qui voient tous les Z des deux ALS [E16].
- Les ALS peuvent se chevaucher, sauf sur un RCC [E16].

**Forcing chains** — SE : Nishio 7,5 ; chaînes multiples 8,0 ; dynamiques 8,5 ; au-delà 9,0 et plus ; s'y ajoute une prime de longueur par paliers au-delà de 4 nœuds. HoDoKu Extreme : 500 (Forcing Net : 700).
- Terme générique pour toute chaîne qui force une conclusion. *Vérité* : plusieurs chaînes partant de tous les candidats d'une case, ou de toutes les places d'un chiffre dans une unité, arrivent à la même conclusion. *Contradiction* : une hypothèse mène à une impossibilité [E17].
- HoDoKu les classe dans « dernier recours » [E17] ; Stuart dans *Extreme* [E2].

### 3.3 Ce que le moteur trouve déjà sans le nommer

- Gratte-ciel et cerf-volant sont des Turbot Fish [E9] : notre `chain()` les renvoie sous `turbotFish`.
- Un W-Wing est une chaîne de six nœuds (b dans la case 1, a dans la case 1, les deux extrémités du lien fort, a dans la case 2, b dans la case 2) [E7] : notre `chain()` doit le renvoyer sous `aic`. **À confirmer par un test**, je n'ai rien exécuté.
- Le *Color Trap* du coloriage simple est une X-Chain [E6b] : déjà trouvé sous `xChain` ou `turbotFish`. Le *Color Wrap* ne correspond pas à une seule de nos éliminations ; à vérifier.
- Pour ces motifs, il n'y a donc pas de technique à ajouter au solveur, seulement une **reconnaissance de forme après coup** dans la couche explication, qui ne touche ni l'ordre ni les grilles générées.

---

## 4. Échelles de difficulté de référence

### 4.1 Sudoku Explainer (SE)

- La note d'une grille est la note de l'étape la plus difficile du chemin trouvé [E13][E24]. Le solveur prend à chaque pas l'indice de note la plus basse [E13].
- Notes lues dans le code de la version 1.2.1 [E13], qui complètent celles de la note précédente :

| Technique | SE |
|---|---|
| Direct Pointing / Direct Claiming | 1,7 / 1,9 |
| Direct Hidden Pair / Triplet | 2,0 / 2,5 |
| Pointing / Claiming | 2,6 / 2,8 |
| Paire nue / X-Wing / paire cachée | 3,0 / 3,2 / 3,4 |
| Triplet nu / Swordfish / triplet caché | 3,6 / 3,8 / 4,0 |
| XY-Wing / XYZ-Wing | 4,2 / 4,4 |
| Unique Rectangle / Loop | 4,5 à 5,0 (+0,1 à +0,3 en type 3) |
| Quadruplet nu / Jellyfish / quadruplet caché | 5,0 / 5,2 / 5,4 |
| BUG type 1 / type 2 | 5,6 / 5,7 |
| Aligned Pair Exclusion | 6,2 |
| Cycles X ou Y / chaîne forcée X ou Y (dont Turbot Fish) | 6,5 / 6,6 (+ longueur) |
| Cycle ou chaîne mêlant X et Y | 7,0 (+ longueur) |
| Nishio / chaînes multiples / dynamiques | 7,5 / 8,0 / 8,5 (+ longueur) |

- **ER / EP / ED** (forum *The New Sudoku Players' Forum*, « Patterns Game ») [E24] :
  - ER : note de l'étape la plus dure de toute la résolution ;
  - EP (*pearl*) : note de l'étape la plus dure nécessaire avant le **premier placement** ;
  - ED (*diamond*) : note de l'étape la plus dure nécessaire avant la **première élimination**.
  - Les ER courants vont de 1,0 à 13,0. Une « perle » ou un « diamant » doit avoir ER > 2,3 [E24].
  - Intérêt : ER seul ne dit pas *où* est la difficulté. Un diamant est dur dès le premier coup.
- Limite relevée par Sudopedia : les techniques de SE sont « à l'ancienne », centrées sur les chaînes forcées ; pas d'ALS [E18].
- SE avertit aussi avant de résoudre [E13] : moins de 8 chiffres distincts parmi les indices (deux chiffres absents sont échangeables, donc plusieurs solutions) ; aucune solution ; plusieurs solutions, avec **deux solutions affichées** pour comparer. L'avertissement « moins de 17 indices » existe dans le code mais y est désactivé.

### 4.2 HoDoKu

- Chaque technique a un **niveau** et un **score** ; le score d'une grille est la **somme** des scores de toutes les étapes [E10].
- Le niveau d'une grille ne peut pas être inférieur à celui de son étape la plus dure. Si le score dépasse le plafond de ce niveau, c'est le score qui fixe le niveau : « une grille avec beaucoup d'étapes dures est plus difficile qu'une grille qui n'en a que quelques-unes » [E10].
- Plafonds par défaut lus dans le code : Easy 800, Medium 1000, Hard 1600, Unfair 1800, Extreme sans limite [E11].
- En création, une grille dont le score est trop bas pour le niveau demandé est **écartée** [E10].
- HoDoKu prévient que son barème est configurable et ne prétend pas mesurer une difficulté absolue ; pour une note stable, il renvoie à Sudoku Explainer [E10].
- Repère : les grilles « Medium » (singletons, candidats verrouillés, paires, triplets) font environ 600 à 1200 points [E10].
- *SSTS* (Simple Sudoku Technique Set) : singletons, candidats verrouillés, sous-ensembles, X-Wing, Swordfish, Jellyfish, XY-Wing, coloriage simple et multiple. Les forums s'en servent pour réduire une grille « jusqu'au point où ça devient intéressant » [E10][E26b].

### 4.3 SudokuWiki (Stuart)

- Deux mesures combinées [E1] :
  1. **Les occasions** : combien de coups indépendants sont possibles à chaque tour. Moins il y en a, plus la grille est dure ; un tour avec une seule déduction possible est un **goulot**.
  2. **Les stratégies nécessaires**, pondérées par candidats retirés et cases résolues.
- Exemple chiffré d'une diabolique : 587 points d'« occasions », 2,5 cases résolues par tour en moyenne, puis `587,2 × (646 / 1000) = 379` [E1]. Les poids exacts ne sont pas publiés (« je ne peux pas donner d'algorithmes ») [E1].
- Six niveaux (Kids, Gentle, Moderate, Tough, Diabolical, Extreme), obtenus en découpant le spectre des scores ; la plupart des grilles aléatoires tombent dans les niveaux bas, avec une longue traîne [E1].
- Calibration sur des temps réels de joueurs : seul le niveau *Tough* montre une forte dispersion des temps [E1].

### 4.4 Ce que dit la recherche

- Pelánek (université Masaryk) compare des métriques aux temps de résolution réels sur environ 2 000 grilles : sa meilleure métrique atteint une corrélation de 0,95. Il identifie **deux sources de difficulté** : la complexité de chaque étape, et la **structure de dépendance entre les étapes** [E29]. C'est la version mesurée des « occasions » de Stuart.
- Berthier : sur un million de grilles minimales, la corrélation entre nombre d'indices et difficulté (SER ou sa propre mesure) n'est que de 0,12 ; la corrélation entre sa mesure et la SER est de 0,895 [E22].

### 4.5 Ce qui fait une « belle » grille pour les créateurs

Les six critères de Stuart [E1], complétés :

1. **Une seule solution.** Exemple d'échec : le sudoku gravé par Sky TV en 2005 avait 1 905 solutions [E1].
2. **Pas de devinette** : chaque déduction doit être certaine [E1]. GM Puzzles : « atteignable par la logique seule » [E19].
3. **Niveau juste** [E1].
4. **La grille tient son niveau sur l'essentiel de la résolution.** « Une grille doit être rejetée si elle est triviale d'un bout à l'autre à l'exception d'un seul goulot très dur » [E1]. Nikoli donne exactement cet exemple pour critiquer les grilles générées : un départ bloqué par une seule déduction obscure, puis plus aucune difficulté [E21].
5. **Minimale** selon Stuart (aucun indice ne peut être retiré) [E1]. Ce critère ne fait pas consensus : Sudopedia note que plus la symétrie est forte, plus il y a d'indices redondants, et qu'il est difficile d'être à la fois symétrique et minimal [E25b].
6. **Symétrique**, critère purement esthétique [E1]. Règle introduite par Nikoli en 1986, après quoi « le puzzle est devenu un grand succès » [E21b].
7. **Nombre d'indices** : Stuart vise une moyenne de 27 et jamais plus de 30 ; il attribue à Nikoli un plafond de 32 [E1]. GM Puzzles : 32 au plus [E19].
8. **Un thème** peut remplacer la symétrie (GM Puzzles) [E19].
9. **Une intention** : pour Nikoli, une bonne grille donne « le sentiment d'une communication entre l'auteur et le joueur » ; l'auteur pense au déroulement de la résolution plus qu'au résultat [E21].

---

## 5. Création manuelle : ce que font les auteurs humains

- **Symétrie.** Types et tailles d'orbites (Sudopedia) [E25b] :

| Symétrie | Orbites | Remarque de Sudopedia |
|---|---|---|
| Rotation 180° | 40 paires + 1 case | la plus populaire, facile à créer, équilibrée |
| Rotation 90° | 20 groupes de 4 + 1 | motifs qui se ressemblent |
| Miroir vertical ou horizontal | 36 paires + 9 cases | le vertical est jugé plus esthétique |
| Diagonale | 36 paires + 9 cases | certains ne la perçoivent pas comme symétrie |
| Deux axes ou deux diagonales | 16 groupes de 4, 8 paires, 1 case | redondance relativement élevée |
| Diédrale complète | — | peu de motifs possibles |

- **Unicité.** C'est la contrainte du créateur [E25]. Les éditeurs peu soigneux publient encore des grilles fautives ; dans tous les courriels reçus par Stuart signalant une « double solution », le lecteur avait mal recopié un indice [E1].
- **17 indices au minimum** (preuve McGuire, Tugemann, Civario) [E1], déjà dans la note précédente. La page Sudopedia « Minimal » est antérieure à la preuve et la dit encore non démontrée [E25c] : source périmée sur ce point.
- **Au moins 8 chiffres distincts** parmi les indices ; avec 7, les deux chiffres absents s'échangent. 8 % des grilles de la bibliothèque de Stuart n'ont que 8 chiffres distincts [E1]. SE fait ce contrôle [E13].
- **Indices redondants.** Une grille minimale peut avoir beaucoup d'indices : Stuart écrit 39 au maximum dans son PDF [E1], mais sa page plus récente signale une grille minimale découverte en 2014 et donne deux grilles ; j'y ai compté 40 indices chacune [E2].
- **Remplir sans utiliser l'unicité.** Stuart n'emploie pas les stratégies d'unicité pendant la construction, « puisque la grille n'aura une solution unique que lorsqu'elle sera presque remplie » [E1].
- **Penser au chemin.** Nikoli : l'auteur pense au processus de résolution [E21]. HoDoKu permet de fabriquer une grille autour d'une technique choisie [E10][E12].

---

## 6. Génération automatique : pratiques et pièges

### 6.1 La méthode de Stuart [E1]

1. Grille pleine : semer 1 à 9 dans neuf cases, puis placer au hasard en re-résolvant logiquement après chaque pose, avec retour arrière. Neuf fois sur dix, cela aboutit vite.
2. Retrait symétrique : **par quatre** pendant les vingt premiers retraits environ, puis **par deux**, puis à partir de 30 indices restants **un par un**, ce qui laisse parfois une légère asymétrie.
3. Test d'unicité par force brute après chaque retrait ; si échec, on remet et on essaie un autre groupe. Une limite d'essais borne la recherche.
4. Cible basse de 20 indices ; en pratique, une distribution en cloche centrée sur 27.
5. Notation ensuite, et **rejet** des grilles à goulot unique.

### 6.2 Cibler une difficulté

- Les grilles dures sont rares : 48,4 % des grilles aléatoires de Stuart ne demandent que des singletons, environ 5 % une stratégie extrême [E3]. Il faut surproduire puis trier [E3].
- HoDoKu écarte une grille dont le score total est trop bas pour le niveau demandé, même si elle contient la technique voulue [E10].
- Pour obtenir une technique précise, HoDoKu filtre sur sa présence ; il avertit qu'une technique placée bas dans l'ordre du solveur n'est presque jamais trouvée, parce qu'une autre fait le travail avant [E10].
- HoDoKu sait exiger la position d'une technique dans le chemin : « seulement des singletons avant et après », etc. [E10]. C'est la façon de produire une grille dont la technique vedette est réellement nécessaire.

### 6.3 Pièges connus

- **Biais des générateurs par retrait.** Berthier compare les générateurs de grilles minimales [E22] :

| Générateur | Nombre moyen d'indices |
|---|---|
| Ascendant (ajout d'indices) | 23,87 |
| Descendant (retrait d'indices) | 24,38 |
| À biais contrôlé | 25,667 |
| Distribution réelle estimée | 26,577 |

  Les générateurs à biais contrôlé, descendant et ascendant sont, dans cet ordre, « de plus en plus biaisés vers des grilles plus faciles avec moins d'indices » [E22]. Le nôtre est descendant.
- **Le nombre d'indices ne mesure pas la difficulté** (corrélation 0,12) [E22].
- **Symétrie contre minimalité** : imposer les deux réduit fortement l'espace [E25b].
- **La note dépend du solveur.** Il y a souvent plusieurs chemins ; ne pas avoir utilisé une stratégie ne prouve pas qu'elle était inutile [E3]. Ajouter une technique au solveur de notation change donc des notes existantes.
- **Techniques d'unicité dans la notation.** Elles « simplifient » des grilles qui demanderaient sinon des techniques très compliquées [E14][E25]. Les inclure dans le classement abaisse le niveau de certaines grilles ; les exclure rend l'explication plus longue. C'est un choix à faire explicitement.
- **Dérive de difficulté** : Stuart constate que ses grilles deviennent plus dures avec le temps, à mesure que son solveur apprend des stratégies (de 80 % de grilles résolues en 2005 à 99,98 %) [E1].
- **Grilles sans chemin logique connu** : environ 1 sur 5 000 chez Stuart en 2012-2023 [E1], 4 sur 141 676 en 2024 [E3]. Il ne les donne pas aux journaux [E1].

---

## 7. Recommandations pour Sudokuno

Rappel de la contrainte du dépôt : `LogicalSolver` (ordre des techniques), `Generator` et `Golden.swift` sont figés ; tout changement se fait à l'identique en Swift et en Kotlin. Les recommandations sont donc triées aussi selon qu'elles touchent ou non au moteur figé.

### Priorité 1 — Mode explication, sans toucher au solveur figé

- **R1. Une fiche d'étape en six éléments** (§2.4) : nom, cases du motif, chiffres, unités, candidats retirés, phrase « donc ». `LogicStep` les porte déjà presque tous. Il manque les **rôles** : `focus` est une liste plate, alors que les trois outils distinguent pivot et pinces, base et couverture, extrémités de chaîne. Ajouter cette information dans les champs réservés à l'explication ne change ni les coups ni leur ordre.
- **R2. Trois paliers de révélation**, comme SE et HoDoKu : (1) nom de la technique, (2) zone et cases, (3) explication et application. Le `Hint` actuel suit déjà ce schéma ; l'explication peut le réutiliser.
- **R3. Texte en trois temps** par technique, sur le modèle des gabarits de SE : constat, raison, conséquence, avec dans le texte les mêmes couleurs que sur la grille (motif, éliminations). Un gabarit `L("…")` par technique, dans `tools/translations.py`.
- **R4. Nommer les motifs que les joueurs connaissent**, par reconnaissance de forme après coup sur les étapes `turbotFish` / `xChain` / `aic` : gratte-ciel, cerf-volant, W-Wing, coloriage simple. Aucun impact sur `Golden`. À précéder d'un test qui confirme que `chain()` renvoie bien ces formes (§3.3).
- **R5. Replier les singletons.** Stuart regroupe les placements par « tour » ; `ExplainedStep.isKey` existe déjà. Afficher par défaut les étapes clés et replier les suites de singletons, avec une option « tout voir ». C'est l'équivalent du *Solve up to* de HoDoKu.
- **R6. Chaînes : une vue par maillon**, comme HoDoKu, plutôt que tous les liens d'un coup. Noter les liens à la manière des outils (fort / faible) et dire en clair « si A est faux, alors B est vrai ».
- **R7. La preuve à la demande.** Montrer d'abord le motif et la conclusion ; la démonstration complète sur un second appui (HoDoKu : « il suffit d'identifier le motif »).

### Priorité 2 — Éditeur de grilles (retours à la personne qui crée)

- **R8. Avertir avant le calcul quand il manque deux chiffres** : moins de 8 chiffres distincts implique plusieurs solutions, avec la raison (« les 1 et les 2 peuvent s'échanger »). Contrôle immédiat, tiré de SE et de Stuart.
- **R9. Montrer *où* la grille est ambiguë** : SE affiche deux solutions. `PuzzleAnalysis` calcule déjà deux solutions ; surligner les cases où elles diffèrent en plus du chiffre suggéré.
- **R10. Symétrie** : détecter et afficher la symétrie de la grille (rotation 180°, miroirs, diagonales), et proposer un mode de saisie symétrique optionnel (la case jumelle est surlignée).
- **R11. Indices superflus** : `redundantClues` existe ; l'afficher (« 3 chiffres peuvent être retirés ») avec un badge « minimale ». Prévenir qu'une grille symétrique est rarement minimale, pour ne pas en faire une obligation.
- **R12. Repère de nombre d'indices** : signaler au-delà de 32 (convention Nikoli / GM Puzzles), sans bloquer.
- **R13. Profil de difficulté, pas seulement le niveau** : nombre d'étapes clés, technique la plus dure, et alerte « un seul passage difficile, le reste est trivial » (critère de rejet de Stuart). Ajouter l'équivalent de ED / EP : « difficile dès le premier coup » ou « démarre facilement ».
- **R14. Bouton « Voir la résolution »** dans l'éditeur, branché sur `Explainer` : l'auteur voit le chemin que suivra le joueur (le conseil de Nikoli).

### Priorité 3 — Nouvelles techniques (profil réservé à l'explication)

- **R15. Un profil de solveur « explication », séparé du profil de classement**, sur le modèle du drapeau `chains` existant. Les nouvelles techniques ne s'activent que dans ce profil : `Golden` et les codes restent intacts. À ne pas mélanger : la technique affichée dans l'explication peut alors différer de celle qui a classé la grille ; le dire dans l'interface ou garder le niveau comme seule référence.
- **R16. Ordre d'ajout conseillé**, d'après les fréquences de §3.1 et non d'après la liste initiale :
  1. Rectangle d'unicité type 1, puis types 2 et 4 (les types 1 et 4 font 61 % des cas chez Stuart) ;
  2. BUG+1 ;
  3. Hidden Unique Rectangle ;
  4. quadruplets nus et Jellyfish (presque gratuits à coder, presque jamais utiles) ;
  5. ALS-XZ et forcing chains, seulement pour réduire les cases « révélées » des grilles Légende.
- **R17. Unicité : n'activer UR et BUG que si la grille est prouvée à solution unique** (toujours vrai pour une grille générée ou validée par l'éditeur). Le dire dans le texte (« parce que cette grille n'a qu'une solution… ») et prévoir un réglage pour les désactiver, comme HoDoKu.

### Priorité 4 — Générateur (uniquement dans une future version 3)

- **R18. Rejeter les grilles à goulot unique** et vérifier que la grille « tient son niveau » : exiger un nombre minimal d'étapes clés par niveau, comme Diabolique v2 le fait déjà pour les chaînes. HoDoKu applique la même idée avec son score minimal par niveau.
- **R19. Rendre les chiffres par paires symétriques.** Aujourd'hui `generate` part d'une grille symétrique puis ajoute des chiffres un par un : la symétrie finale est perdue. Stuart tolère une légère asymétrie, mais retire d'abord par quatre, puis par deux.
- **R20. Mesurer les « occasions par tour »** (Stuart, Pelánek) pour départager Facile et Moyen : deux grilles « singletons seulement » peuvent être très différentes selon que dix cases sont jouables à la fois ou une seule.
- **R21. Connaître le biais du retrait descendant** (Berthier) : notre générateur favorise les grilles peu fournies et plutôt faciles. La boucle de rejet par niveau le corrige pour le niveau, pas pour la variété. Ce n'est pas un défaut à corriger en urgence, mais une raison de mesurer la distribution réelle avant de conclure qu'un niveau est « rare ».
- **R22. Décider explicitement si les techniques d'unicité comptent dans le classement.** Recommandation : non. Elles restent une aide à l'explication (R15), ce qui évite de reclasser les grilles existantes.

---

## 8. Ce que je n'ai pas pu vérifier

- **Notation Snyder** : aucune définition écrite par Thomas Snyder trouvée ; sa publication sur le sujet est une vidéo que je n'ai pas pu lire [E20]. La définition donnée en §1.3 est de seconde main [E28].
- **Résolution en compétition** : aucune source primaire écrite trouvée. La page de règles de la WPF ne contient rien sur les techniques ni sur l'exigence d'unicité [E27]. Je n'ai pas lu les livrets d'instructions des manches du Grand Prix.
- **Site original de Nicolas Juillerat** (`diuf.unifr.ch/…/Sudoku.html`) : inaccessible (pas de réponse). Les notes SE viennent d'une copie du code sur GitHub qui se présente comme la version 1.2.1 avec les modifications *serate* de Glenn Fowler [E13] ; je n'ai pas comparé à l'archive d'origine.
- **Sudopedia (miroir)** : les pages `SE.html` (citée [S9] dans la note précédente, **lien mort aujourd'hui**), `Solving_Technique_Index.html`, `Explainer_Rating`, `Pearl`, `Diamond`, `Proper_puzzle` renvoient « Not Found » ou une page vide. Le site `sudopedia.org` renvoie 404.
- **Scores HoDoKu** : lus dans un miroir GitHub non officiel du code source [E11], pas dans l'archive SourceForge. La page du manuel sur la configuration du solveur (`docs_solve.php`) renvoie 404.
- **Poids exacts du barème SudokuWiki** : non publiés [E1].
- **Tableau des fréquences de Stuart** : les quatre pourcentages de synthèse de l'article (48,4 ; 17,6 ; 6,5 ; 4,0) ne totalisent pas 100 % ; une ligne semble manquer sur la page [E3]. Je n'ai cité que les chiffres présents.
- **Livres de Denis Berthier** (*The Hidden Logic of Sudoku*, *Pattern-Based Constraint Satisfaction*) : non lus ; seuls le résumé arXiv, l'article sur le biais et le README de CSP-Rules l'ont été [E22][E23].
- **Forum *The New Sudoku Players' Forum*** : seule la première page du fil « Patterns Game » a été lue [E24] ; pas les discussions d'origine des techniques (W-Wing, BUG).
- **Couleurs exactes de HoDoKu** par rôle (motif, ailerons, éliminations) : non relevées, faute de page de référence accessible ; seules les mentions des pages lues sont rapportées.
- **Rien n'a été exécuté sur le moteur Sudokuno** : les affirmations de §3.3 (ce que `chain()` trouve déjà) se déduisent des définitions et restent à tester. Les fréquences de §3.1 sont celles du solveur de Stuart.
- **« Rectangle Elimination »** (11 747 grilles chez Stuart) : page non lue ; la technique n'est pas décrite ici.

---

## Sources

Toutes consultées le 12/11/2026.

- [E1] A. Stuart, « Sudoku Creation and Grading », 2007, mis à jour 2012 et 2023 – https://www.sudokuwiki.org/Sudoku_Creation_and_Grading.pdf
- [E2] A. Stuart, SudokuWiki, « Strategy Families » (liste ordonnée des stratégies, grille minimale de 2014) – https://www.sudokuwiki.org/Strategy_Families
- [E3] A. Stuart, « The Relative Incidence of Sudoku Strategies », mis à jour mai 2024 – https://www.sudokuwiki.org/The_Relative_Incidence_of_Sudoku_Strategies
- [E4] A. Stuart, « Getting Started » – https://www.sudokuwiki.org/Getting_Started
- [E5] A. Stuart, « Simple Colouring » – https://www.sudokuwiki.org/Singles_Chains
- [E6] A. Stuart, « BUG+1 » – https://www.sudokuwiki.org/BUG
- [E7b] A. Stuart, « W-Wing Strategy » – https://www.sudokuwiki.org/W_Wing_Strategy
- [E8b] A. Stuart, « Jellyfish Strategy » – https://www.sudokuwiki.org/Jelly_Fish_Strategy
- [E6b] B. Hobiger, HoDoKu, « Coloring » – https://hodoku.sourceforge.net/en/tech_col.php
- [E7] B. Hobiger, HoDoKu, « Wings » (XY-Wing, XYZ-Wing, W-Wing) – https://hodoku.sourceforge.net/en/tech_wings.php
- [E8] B. Hobiger, HoDoKu, « Naked Subsets » – https://hodoku.sourceforge.net/en/tech_naked.php
- [E9] B. Hobiger, HoDoKu, « Single Digit Patterns » (Skyscraper, 2-String Kite, Turbot Fish) – https://hodoku.sourceforge.net/en/tech_sdp.php
- [E10] B. Hobiger, HoDoKu, manuel, chap. 4 « Creating Sudokus » (niveaux et scores, SSTS) – https://hodoku.sourceforge.net/en/docs_cre.php
- [E11] HoDoKu, `Options.java` (scores et niveaux par défaut), miroir GitHub non officiel – https://github.com/PseudoFish/Hodoku/blob/master/src/sudoku/Options.java
- [E12] B. Hobiger, HoDoKu, manuel, « Playing the game » (indices, filtres, modes apprentissage et entraînement) – https://hodoku.sourceforge.net/en/docs_play.php
- [E13] Sudoku Explainer 1.2.1 (N. Juillerat, modifications *serate* de G. Fowler), code source : `solver/Solver.java`, `solver/Hint.java`, `solver/IndirectHint.java`, `solver/Rule.java`, `solver/rules/*Hint.java` et `*.html`, `solver/rules/chaining/`, `solver/rules/unique/`, `solver/checks/` – https://github.com/1to9only/SudokuExplainer
- [E14] B. Hobiger, HoDoKu, « Uniqueness » (UR types 1 à 6, Hidden et Avoidable Rectangle, BUG+1) – https://hodoku.sourceforge.net/en/tech_ur.php
- [E15] B. Hobiger, HoDoKu, « Basic Fish » – https://hodoku.sourceforge.net/en/tech_fishb.php
- [E16] B. Hobiger, HoDoKu, « ALS » – https://hodoku.sourceforge.net/en/tech_als.php
- [E17] B. Hobiger, HoDoKu, « Last Resort » (Forcing Chain, Forcing Net) – https://hodoku.sourceforge.net/en/tech_last.php
- [E18] Sudopedia (miroir), « Sudoku Explainer » – http://sudopedia.enjoysudoku.com/Sudoku_Explainer.html
- [E19] GM Puzzles (T. Snyder), « Sudoku Rules and Info » (règles de conception pour les contributeurs) – https://www.gmpuzzles.com/blog/sudoku-rules-and-info/
- [E19b] GM Puzzles, « About Our Blog » – https://www.gmpuzzles.com/blog/about/
- [E20] GM Puzzles, « Today in Sudoku: The Truth About Snyder Notation », 25/07/2025 (vidéo, contenu non lu) – https://www.gmpuzzles.com/blog/2025/07/today-in-sudoku-the-truth-about-snyder-notation/
- [E21] Nikoli, « Why hand made » (N. Kanamoto, M. Kaji) – https://www.nikoli.co.jp/en/puzzles/sudoku/why_hand_made/
- [E21b] Nikoli, « Sudoku » (règles, histoire, règle de symétrie de 1986) – https://www.nikoli.co.jp/en/puzzles/sudoku/
- [E22] D. Berthier, « Unbiased Statistics of a CSP – A Controlled-Bias Generator », conférence CISSE 2009, déposé sur arXiv en 2011 – https://arxiv.org/abs/1111.4083
- [E23] D. Berthier, CSP-Rules V2.1, README (*simplest-first strategy*) – https://github.com/denis-berthier/CSP-Rules-V2.1 ; résumé de *Pattern-Based Constraint Satisfaction and Logic Puzzles* – https://arxiv.org/abs/1304.1628
- [E24] The New Sudoku Players' Forum, « Patterns Game » (définition de ER / EP / ED) – http://forum.enjoysudoku.com/patterns-game-t6290.html
- [E25] Sudopedia (miroir), « Uniqueness Controversy » – http://sudopedia.enjoysudoku.com/Uniqueness_Controversy.html
- [E25b] Sudopedia (miroir), « Symmetry » – http://sudopedia.enjoysudoku.com/Symmetry.html
- [E25c] Sudopedia (miroir), « Minimal » (antérieure à la preuve des 17 indices) – http://sudopedia.enjoysudoku.com/Minimal.html
- [E26] Sudopedia (miroir), « Pencilmark » – http://sudopedia.enjoysudoku.com/Pencilmark.html
- [E26b] Sudopedia (miroir), « SSTS » – http://sudopedia.enjoysudoku.com/SSTS.html
- [E27] World Puzzle Federation, « Rules and Regulations » (gouvernance uniquement) – https://worldpuzzle.org/rules-and-regulations
- [E28] Sudoku Bliss, « How to Use Snyder Notation in Sudoku » (**source secondaire**, vue seulement dans un résultat de recherche) – https://sudokubliss.com/guides/snyder-notation
- [E29] R. Pelánek, « Difficulty Rating of Sudoku Puzzles by a Computational Model », © 2011 AAAI (actes non vérifiés ; le fichier s'appelle `flairs-sudoku.pdf`) – https://www.fi.muni.cz/~xpelanek/publications/flairs-sudoku.pdf
