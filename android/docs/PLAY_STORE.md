# Sudokuno Android : publier sur Google Play

## 1. Compte et vérifications
1. Créer un compte développeur sur https://play.google.com/console (25 $ une fois), en **compte personnel**.
2. **Vérification d'identité** demandée par Google (pièce d'identité, adresse) : à faire dès l'inscription, elle peut prendre quelques jours.
3. **Comptes personnels récents : test fermé obligatoire.** Avant de pouvoir publier en production, Google exige un test fermé avec
   **au moins 12 testeurs inscrits pendant 14 jours d'affilée**. Prévoir ce délai (amis, famille, collègues).

## 2. Clé d'envoi (signature)
Google Play signe l'app lui-même (« Signature d'application par Google Play ») ; toi, tu signes les envois avec une **clé d'envoi** :
```
cd android
keytool -genkeypair -v -keystore upload.jks -alias upload -keyalg RSA -keysize 4096 -validity 10000
```
Puis créer `android/keystore.properties` (ignoré par git, à sauvegarder en lieu sûr avec `upload.jks`) :
```
storeFile=upload.jks
storePassword=…
keyAlias=upload
keyPassword=…
```
**Ne perds jamais cette clé ni les mots de passe** (Google peut la réinitialiser, mais c'est long).

## 3. Construire le bundle
```
cd android
./gradlew :app:bundleRelease        # → app/build/outputs/bundle/release/app-release.aab
```
Avant chaque nouvelle version : augmenter `versionCode` (entier, +1) et `versionName` dans `app/build.gradle.kts`.

## 4. Créer l'app dans la console
Toutes les apps › Créer une application : nom **Sudokuno**, langue par défaut **Français (France)**, **Jeu**, **Gratuite**.
Le nom de package est fixé au premier envoi : `com.alexafer.sudokuno`.

## 5. Fiche Play Store (Présence sur le Store › Fiche principale)

| Champ | Français | English |
|---|---|---|
| Nom (30 car.) | Sudokuno | Sudokuno |
| Description courte (80 car.) | Le Sudoku du jour, sans pub : série, défis entre amis et grilles à créer. | Daily Sudoku with no ads: streaks, friend challenges and your own puzzles. |
| Description complète | Reprendre la description de `ios/docs/APP_STORE.md` en remplaçant « Game Center » par « Google Play Jeux » et « iPhone et iPad » par « téléphones et tablettes Android ». | Same, English version. |

- **Icône 512 × 512** : `docs/play-icon-512.png`
- **Image de présentation 1024 × 500** : `docs/PlayStore/feature-graphic-fr.png` / `-en.png`
- **Captures de téléphone** (2 à 8, format ≤ 2:1) : `docs/PlayStore/screenshots/fr/` et `en/`
- **Catégorie** : Jeux › Réflexion. **Tags** : Sudoku, Logique, Casse-tête.
- **Coordonnées** : site https://zerrino.github.io/sudokuno/ ; une adresse e-mail est **obligatoire** (elle est publique).

## 6. Contenu de l'application (questionnaires obligatoires)
| Rubrique | Réponse |
|---|---|
| Règles de confidentialité | https://zerrino.github.io/sudokuno/privacy.html |
| Publicités | **Non**, l'app ne contient pas de publicités |
| Accès à l'application | Toutes les fonctionnalités sont accessibles sans identifiants |
| Classification du contenu (IARC) | Jeu de réflexion, aucun contenu sensible → PEGI 3 / Tout public |
| Public cible | 13 ans et plus (évite le programme « Familles », plus contraignant) |
| Sécurité des données | Aucune donnée collectée ni partagée par le développeur. Les achats passent par Google Play ; Play Jeux est un service Google facultatif. Données chiffrées en transit : sans objet. Suppression : les données sont locales, désinstaller l'app les efface. |
| Applications d'actualité / santé / etc. | Non |
| Achats intégrés | Oui : dons facultatifs (voir `PLAY_BILLING.md`) |

## 7. Tests puis production
1. **Tests › Test fermé** : créer une piste, ajouter l'AAB, une liste de testeurs (adresses Gmail) ; partager le lien d'inscription.
2. Attendre les **14 jours avec au moins 12 testeurs**, corriger si besoin, répondre au questionnaire « Accès en production ».
3. **Production** : créer une version avec le même AAB (ou un plus récent), choisir les pays, envoyer pour examen
   (quelques heures à quelques jours).

Pays : ne pas cocher la **Chine** (Google Play n'y est pas disponible de toute façon).
