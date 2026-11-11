# Dons (pot à pourboires) : à configurer dans App Store Connect

Les dons sont des achats intégrés **consommables** : ils ne débloquent rien (règle 3.1.1 respectée).
Code : `Sudokuno/Features/Settings/TipJar.swift`. Test local : `Sudokuno/Tips.storekit` (utilisé par ⌘R dans Xcode).

## Avant tout
1. App Store Connect › Accords, taxes et banques : signer le **Paid Apps Agreement**, renseigner banque et formulaires fiscaux.
2. (Recommandé) S'inscrire au **App Store Small Business Program** : commission de 15 % au lieu de 30 %.

## Produits à créer (Monétisation › Achats intégrés › +, type « Consommable »)

| ID produit (exactement) | Nom de référence | Prix |
|---|---|---|
| `com.alexafer.sudokuno.tip.small` | Petit café | 0,99 € |
| `com.alexafer.sudokuno.tip.medium` | Grand café | 2,99 € |
| `com.alexafer.sudokuno.tip.large` | Café et croissant | 4,99 € |

## Noms et descriptions affichés (localisations App Store)

| | Petit café | Grand café | Café et croissant | Description |
|---|---|---|---|---|
| Français | Petit café | Grand café | Café et croissant | Un don pour soutenir Sudokuno |
| English | Small coffee | Large coffee | Coffee & croissant | A tip to support Sudokuno |
| Nederlands | Kleine koffie | Grote koffie | Koffie met croissant | Een fooi om Sudokuno te steunen |
| Português (Portugal) | Café pequeno | Café grande | Café e croissant | Um donativo para apoiar o Sudokuno |
| 简体中文 | 小杯咖啡 | 大杯咖啡 | 咖啡加可颂 | 支持 Sudokuno 的打赏 |

Chaque produit demande aussi une **capture d'écran pour l'examen** (celle de la section « Soutenir Sudokuno » des réglages)
et une note pour Apple, par exemple : « Optional tip, consumable, unlocks no content or features. »

## Soumission
- Le premier achat intégré doit être **soumis avec une version de l'app** (cocher les produits dans la page de la version).
- Description de l'app : préciser « gratuit, sans publicité ; dons facultatifs ».

## Montant libre
Le sélecteur « Montant libre » achète le produit `tip.small` en **quantité** (1 à 10, limite de l'App Store pour un consommable),
donc de 0,99 € à 9,90 €. Aucun produit supplémentaire à créer. Apple n'autorise pas un montant saisi librement.
