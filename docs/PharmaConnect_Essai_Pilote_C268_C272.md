# PharmaConnect — Essai court de la version de conception (C268 à C272)

**Pour qui :** Achille, avec les deux téléphones et les comptes de l'essai du lot 3.
**État :** guide préparé le 15/10/2026 ; version construite le 15/10/2026 depuis `main` (`a3b3094`) : `PharmaConnect-release-a3b3094-arm64-v8a.apk`, 32,0 Mo. Rien n'a encore été joué sur un téléphone.
**Durée :** environ 35 minutes.
**But :** prouver sur appareil, à la taille de police normale (1,0) puis agrandie (1,3) : C268 (écrans lisibles avec une grande police), C269 (lecture des QR codes sans la bibliothèque de reconnaissance de texte retirée), C270 (catalogue hors connexion), C271 (position gardée au retour d'une fiche), C272 (fiches du catalogue et du stock, pastilles, boutons sur deux lignes) et « Objectifs santé » masqué.

---

## 0. À lire avant de commencer

**L'application parle à la production.** Ne réservez et ne vendez que dans « TEST Officine Lot 3 ».

**Un seul fichier, pour les deux téléphones** : pendant la conception, la version est construite pour les processeurs 64 bits seulement (`arm64-v8a`). Les deux fichiers par type de téléphone viendront avec la version remise aux officines pilotes.

**Stock de Paracétamol : 1 boîte au départ** (fin de l'essai du 14/10), **0 à la fin** : l'essai en consomme une (réservation retirée par scan). Aucune vente ni réservation de Paracétamol hors des étapes de ce guide. Si le stock de départ n'est pas de 1, notez-le et prévenez-moi avant de commencer.

**Le retrait d'une réservation est encaissé sans TVA** (1 500 GNF), la vente au comptoir avec 5 % (C259, toujours en attente de votre décision). Cet essai ne fait pas de vente au comptoir.

**En cas d'écart :** une capture, l'heure, le téléphone (A ou B), le compte et la taille de police (1,0 ou 1,3). Notez, puis continuez si l'étape suivante n'en dépend pas.

| Élément | Rôle |
|---|---|
| Téléphone A | l'officine : compte « pharmacien », puis compte « admin » à la section 6 |
| Téléphone B | le patient |

---

## 1. Installation

1. Copiez `PharmaConnect-release-a3b3094-arm64-v8a.apk` (32,0 Mo, construit depuis `main` au commit `a3b3094`, dossier `build/app/outputs/flutter-apk/`) sur les deux téléphones et installez-le par-dessus la version actuelle.
2. Si Android refuse (« Application non installée », « non compatible ») : le téléphone a un processeur 32 bits ; prévenez-moi, je construirai le fichier `armeabi-v7a` pour lui.
3. **Vous devez voir :** le tableau de bord (ou « Connexion », puis le tableau de bord après le code reçu par e-mail).

**Taille de police :** les sections 2 à 5 se font d'abord à la taille **normale**. La section 7 les reprend avec la **police la plus grande** du téléphone (Paramètres → Affichage → Taille de police, au maximum ; l'application la suit jusqu'à 1,3 fois).

---

## 2. Téléphone B : catalogue, fiche produit et retour (C271, C272)

1. Menu ☰. **Vous devez voir :** « Objectifs santé » **absent** du menu (masqué pendant le pilote) ; « Livraisons » absent aussi.
2. Menu ☰ → « Catalogue ». Choisissez une catégorie, tapez `para` dans la recherche, puis faites défiler la liste vers le bas.
3. Ouvrez la fiche d'un produit visible.

**Vous devez voir (fiche) :** les pastilles (fabricant, « Générique » ou « Princeps », « Sur ordonnance » ou « Libre ») sur une ou deux lignes, **jamais coupées ni hors de l'écran**, texte foncé lisible ; le bouton « Vérifier la disponibilité » en entier.

4. Revenez à la liste (flèche retour ou geste retour).

**Vous devez voir :** la liste **au même endroit**, la même catégorie choisie, `para` toujours dans la recherche, **sans** roue de chargement.

5. Menu ☰ → « Recherche » → `paracetamol`. S'il y a plusieurs résultats, faites défiler, ouvrez un résultat, revenez. **Vous devez voir :** les résultats au même endroit, sans nouvelle recherche.

---

## 3. Téléphone B : catalogue hors connexion (C270)

1. **Activez le mode avion.** Menu ☰ → « Catalogue » (si l'écran est déjà ouvert, touchez une autre catégorie).

**Vous devez voir :** le message « Hors connexion. Vérifiez la connexion et réessayez. » et le bouton « Réessayer » ; **aucun message technique** (ni « Erreur : », ni « ClientException », ni adresse du serveur).

2. **Désactivez le mode avion.** « Réessayer ». **Vous devez voir :** la liste revient.

---

## 4. Téléphone A : « Stock & Lots », fiche d'un produit en stock, caisse (C271, C272)

1. Menu ☰ → « Stock & Lots ». **Vérifiez le stock de Paracétamol : 1 boîte, 0 réservée.**
2. Faites défiler la liste vers le bas, ouvrez la fiche d'un produit, revenez. **Vous devez voir :** la liste au même endroit, sans roue de chargement.
3. Ouvrez la fiche de Paracétamol.

**Vous devez voir :** sous le nom, « dosage • forme » et la pastille d'état, l'une sous l'autre si la place manque, **rien hors de l'écran** ; « Seuil bas » et « Seuil critique » sur deux lignes ; pour chaque lot, « Péremption : … » en entier, la quantité à droite ou en dessous ; les pastilles « Bientôt périmé » ou « Périmé », s'il y en a, en texte foncé lisible.

4. Menu ☰ → « Ouverture de caisse ». Ouvrez la caisse avec un fonds de `10 000`. **Vous devez voir :** le bouton « Ouvrir la caisse » en entier (sur deux lignes au plus, jamais « … »).

---

## 5. Réservation et retrait par scan du QR code (C269)

La lecture des QR codes doit marcher **sans** la bibliothèque de reconnaissance de texte, retirée de cette version (C269) ; la lecture des QR codes et des codes-barres, elle, est restée.

1. **Téléphone B** : « Recherche » → `paracetamol` → fiche → touchez « TEST Officine Lot 3 » → panier → « Passer la commande » → « Confirmer la commande ». **Notez le code.**
2. Menu ☰ → « Réservations » → touchez la carte : le QR code s'affiche. Gardez-le à l'écran.
3. **Téléphone A (pharmacien)** : « File des réservations » → « Retrait » sur la réservation → icône de QR → visez le téléphone B.

**Vous devez voir :** l'appareil photo s'ouvre, le code se remplit **tout seul** et correspond au code noté. « Encaisser et remettre » → reçu de **1 500 GNF**.

4. Si le scan ne remplit pas le code : notez-le (capture, message), saisissez le code à la main pour finir le retrait, et prévenez-moi : c'est le point principal de C269.

---

## 6. Téléphone A, compte « admin » : administration (C268)

Déconnexion, puis connexion avec l'adresse « admin ». Menu ☰ → « Administration ».

**Vous devez voir :** les quatre tuiles en grille 2 × 2, titres entiers ; l'écran défile jusqu'en bas, rien n'est coupé. Reconnectez-vous ensuite avec le compte « pharmacien ».

---

## 7. Police agrandie (C268) : les mêmes écrans à 1,3

Sur les deux téléphones : **Paramètres → Affichage → Taille de police au maximum**, puis revenez dans l'application.

Repassez rapidement, **sans rien réserver ni vendre** :

| Téléphone | Écran | Vous devez voir |
|---|---|---|
| B | Catalogue, puis une fiche produit | noms entiers sur deux lignes au plus, **jamais un mot coupé en deux** (« Parac / étamol ») ; pastilles et boutons entiers |
| B | Recherche → `paracetamol` | carte de résultat : prix et disponibilité sous le nom, nom entier |
| B | Inscription (déconnecté, « Créer un compte »), sans valider | champs et boutons entiers, rien hors de l'écran ; un texte d'aide de champ peut finir par « … » (permis) |
| A | « Stock & Lots » et la fiche de Paracétamol | noms entiers, lots lisibles, la quantité passe sous la date si besoin |
| A | « Ouverture de caisse », « Historique », « Rapport » | montants et **dates jamais coupés** (« 15/10/2026 » d'un seul tenant) |
| A | « Historique des ventes », puis le reçu de la vente de la section 5 | titre et filtres entiers, « Remboursées » non coupé ; reçu : nom du produit lisible, pas une lettre par ligne |
| A | Tout bouton | libellé entier, sur deux lignes au plus, **jamais « … »** ; un libellé très long peut être un peu plus petit |

Remettez ensuite la taille de police habituelle.

---

## 8. Fermeture de la caisse et stock

1. Téléphone A, « Ouverture de caisse ». **Vous devez voir :** « Solde attendu **11 500 GNF** » (10 000 + 1 500). Fermez en saisissant `11 500`. **Vous devez voir :** écart 0.
2. « Stock & Lots » : Paracétamol **0 boîte**, 0 réservée. Une nouvelle réception de stock sera nécessaire avant le prochain essai.

---

## 9. Relevé à me rendre

| # | Point | Écart | Conforme ? |
|---|---|---|---|
| 1 | Installation sur les deux téléphones (fichier `arm64-v8a`) | C269 | |
| 2 | « Objectifs santé » et « Livraisons » absents du menu | pilote | |
| 3 | Catalogue : même position, catégorie et recherche au retour d'une fiche | C271 | |
| 4 | Fiche du catalogue : pastilles et boutons entiers, rien hors de l'écran | C272 | |
| 5 | Recherche : résultats au même endroit au retour | C271 | |
| 6 | Catalogue en mode avion : message lisible, aucun message technique | C270 | |
| 7 | « Stock & Lots » : même position au retour d'une fiche | C271 | |
| 8 | Fiche de Paracétamol : état, seuils, lots lisibles, rien hors de l'écran | C272 | |
| 9 | Scan du QR code : code rempli tout seul, retrait 1 500 GNF | C269 | |
| 10 | Administration : tuiles 2 × 2, défilement jusqu'en bas | C268 | |
| 11 | Police agrandie : aucun mot coupé en deux, dates et montants entiers | C268 | |
| 12 | Police agrandie : boutons entiers, jamais « … » | C268, C272 | |
| 13 | Solde attendu 11 500, fermeture à écart 0 | C258 | |
| 14 | Stock de Paracétamol : 0 à la fin (1 au départ), 0 réservée | stock | |
