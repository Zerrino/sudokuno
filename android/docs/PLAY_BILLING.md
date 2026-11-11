# Dons (Google Play Billing)

Produits **intégrés** (« produits ponctuels ») à créer dans la console Google Play › Monétiser › Produits › Produits intégrés,
avec **les mêmes identifiants qu'iOS** :

| ID produit | Nom | Prix |
|---|---|---|
| `com.alexafer.sudokuno.tip.small` | Petit café | 0,99 € |
| `com.alexafer.sudokuno.tip.medium` | Grand café | 2,99 € |
| `com.alexafer.sudokuno.tip.large` | Café et croissant | 4,99 € |

- L'app les **consomme** après achat : on peut donner plusieurs fois. Ils ne débloquent rien.
- **Montant libre** : sur `tip.small`, activer **« Achat de plusieurs unités »** (multi-quantity). La fenêtre de paiement
  Google Play propose alors de choisir la quantité.
- Il faut d'abord un **profil de paiement** (Paramètres › Profil de paiement) et avoir envoyé au moins un AAB qui contient
  la bibliothèque Billing (c'est le cas).
- Tester : ajouter ton compte dans Paramètres › Test des licences ; les achats de test ne sont pas débités.
- Commission Google : 15 % sur le premier million de dollars de revenus annuels.

## Fait par l'API (11 novembre 2026)
Les trois produits sont créés et **actifs** (titres EN/FR) : `tools/play_tips.py list|create|activate`.
Envoi d'une version sur la piste interne : `tools/play_release_internal.py <aab> <versionCode> <nom>`.
Ces scripts utilisent la clé `~/.config/play-console-mcp/service-account.json`, qui ne doit jamais entrer dans le dépôt.
