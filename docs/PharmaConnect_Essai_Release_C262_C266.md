# PharmaConnect — Essai court de la version « release » (C262 à C267)

**Pour qui :** Achille, avec les deux téléphones et les comptes de l'essai du lot 3.
**État :** guide préparé le 14/10/2026, avant la construction de la version. Rien n'a encore été joué sur un téléphone.
**Durée :** environ 40 minutes, migration comprise.
**But :** reprouver sur appareil C262 (remise bloquée), C263 (aucun message technique), C264 (QR code immédiat hors connexion), C265 (tuiles, textes et contrastes), C266 (catalogue) et C267 (montants « 1 575 GNF »), mode avion compris ; puis appliquer la migration C262 en production.

---

## 0. À lire avant de commencer

**L'application parle à la production.** Ne réservez et ne vendez que dans « TEST Officine Lot 3 ».

**L'ordre compte** : la migration C262 (section 7) ne s'applique qu'**après** l'installation de la nouvelle version sur le téléphone A (section 1). La version actuelle a encore la réglette de remise : avec la migration, une vente avec remise y serait refusée.

**La vente au comptoir ajoute toujours 5 % de TVA** (C259, en attente de votre décision) : une boîte à 1 500 GNF est encaissée 1 575 GNF au comptoir, 1 500 GNF au retrait d'une réservation.

**En cas d'écart :** une capture, l'heure, le téléphone (A ou B) et le compte. Notez, puis continuez si l'étape suivante n'en dépend pas.

| Élément | Rôle |
|---|---|
| Téléphone A | l'officine : compte « pharmacien », puis compte « admin » à la section 6 |
| Téléphone B | le patient |

---

## 1. Installation

1. Copiez `PharmaConnect-release-<commit>.apk` sur les deux téléphones et installez-le par-dessus la version actuelle.
2. **Vous devez voir :** le tableau de bord (ou l'écran « Connexion », puis le tableau de bord après le code reçu par e-mail).

---

## 2. Téléphone A : « Stock & Lots » et caisse (C265)

1. Menu ☰ → « Stock & Lots ».

**Vous devez voir :**

- Les quatre tuiles sous « Historique » en **grille 2 × 2** : « Produits », « Unités », « Stock faible », « Ruptures », **titres entiers**, **une seule icône** par tuile.
- Dans la liste, des noms de produits sur deux lignes au plus ; les lignes « Stock : … » et « Réservés : … » lisibles.
- **Notez le stock de Paracétamol** (4 boîtes attendues après l'essai du 12-13/10, 0 réservée) : il sert au contrôle de la section 8.

2. Menu ☰ → « Ouverture de caisse ». Si une caisse est ouverte, fermez-la (solde réel = solde attendu affiché). Ouvrez la caisse avec un fonds saisi `10 000` (avec l'espace : C267, la saisie doit être acceptée).

**Vous devez voir :** les pastilles « Ouverte » et les chiffres lisibles, texte foncé sur fond clair. Les montants sont écrits avec un séparateur des milliers : « 10 000 GNF », jamais « 10000 GNF », et ne sont jamais coupés en fin de ligne (C267).

---

## 3. Téléphone A : vente au comptoir sans remise (C262)

1. Tableau de bord → « Caisse » (vente au comptoir).

**Vous devez voir :** **aucune réglette de remise**, et aucune ligne « Remise » dans le résumé. Le texte d'aide du champ de recherche, « Produit ou DCI », tient en entier.

2. Touchez « Paracétamol ». Faites défiler l'écran de haut en bas plusieurs fois, en partant de différents endroits.

**Vous devez voir :** « À payer **1 575 GNF** », inchangé après chaque défilement.

3. « Finaliser la vente ». **Vous devez voir :** le reçu, **1 575 GNF**, sans remise.

---

## 4. Téléphone B : recherche, fiche produit et catalogue (C265, C266)

1. Menu ☰ → « Catalogue ».

**Vous devez voir :** **deux colonnes** de cartes ; les noms de produits lisibles en entier (deux lignes au plus), à la même taille que dans « Stock & Lots » ; **le dosage et la forme jamais coupés** ; pastilles « Générique », « Libre », « Ordonnance » lisibles.

2. Menu ☰ → « Recherche » → `paracetamol` → ouvrez la fiche du produit.

**Vous devez voir :** la ligne « TEST Officine Lot 3 » avec son nom et son adresse sur deux lignes au plus ; les pastilles « Disponible », « 24h/24 », « Garde » lisibles ; le prix en entier.

---

## 5. Téléphone B : QR code hors connexion (C263, C264)

1. Sur la fiche Paracétamol, touchez « TEST Officine Lot 3 » → panier → « Passer la commande » → « Confirmer la commande ». **Notez le code.** Quittez l'écran de validation.
2. Menu ☰ → « Réservations ». Touchez la carte de la réservation : le QR code s'ouvre. Revenez à la liste.
3. **Activez le mode avion.** Touchez **la même carte**.

**Vous devez voir, tout de suite** (sans attendre) : le QR code et le code noté, puis la mention « Hors connexion — dernières données enregistrées. L'état et l'échéance affichés sont les derniers connus. »

4. Revenez à la liste.

**Vous devez voir :** **aucun message technique** (ni « Exception », ni « Socket », ni adresse du serveur, ni identifiant). S'il y a un bandeau, il dit seulement « Hors connexion — dernières données enregistrées ».

5. Tirez la liste vers le bas, toujours en mode avion. **Vous devez voir :** la roue, puis au plus ce même bandeau, jamais un message technique.
6. **Désactivez le mode avion.** Tirez la liste vers le bas. **Vous devez voir :** le bandeau disparaît.
7. Rouvrez la carte, gardez le QR code affiché pour la section 6.

---

## 6. Retrait par scan, puis administration (C263, C265)

**Téléphone A (pharmacien)** : « File des réservations » → « Retrait » sur la réservation → icône de QR → visez le téléphone B. **Vous devez voir :** le code rempli tout seul. « Encaisser et remettre » → reçu de **1 500 GNF**.

**Téléphone A, compte « admin »** (déconnexion, puis connexion avec l'adresse « admin ») : menu ☰ → « Administration ».

**Vous devez voir :** les quatre tuiles « Utilisateurs », « Pharmacies », « En attente », « Audit » en **grille 2 × 2**, titres entiers, une seule icône par tuile.

Reconnectez-vous ensuite avec le compte « pharmacien ».

---

## 7. Migration C262 en production (Achille, éditeur SQL)

**Seulement maintenant**, la nouvelle version étant installée sur le téléphone A.

1. **Requête de lecture** (rien n'est modifié) :

```sql
select
  md5(replace(p.prosrc, E'\r', ''))      as empreinte,
  length(replace(p.prosrc, E'\r', ''))   as longueur
from pg_proc p
where p.oid = 'public.pos_create_sale(uuid,text,integer,integer,integer,integer,jsonb,uuid,text)'::regprocedure;
```

**Attendu :** empreinte `a06dab4e02660dc95079c353bade2dc3`, longueur `11556`. **Envoyez-moi le résultat et attendez mon « conforme »** ; s'il diffère, ne remplacez rien.

2. **Migration** : collez et exécutez le contenu exact du fichier `supabase/migrations/20261013000000_pos_no_discount.sql`.

3. **Requête de contrôle** (rien n'est modifié) :

```sql
select
  md5(replace(p.prosrc, E'\r', ''))                    as empreinte,
  length(replace(p.prosrc, E'\r', ''))                 as longueur,
  p.prosrc like '%remise non autorisee%'               as refus_de_remise_present,
  p.prosecdef                                          as security_definer,
  has_function_privilege('authenticated', p.oid, 'execute') as appelable_par_les_comptes,
  has_function_privilege('anon', p.oid, 'execute')          as appelable_sans_compte
from pg_proc p
where p.oid = 'public.pos_create_sale(uuid,text,integer,integer,integer,integer,jsonb,uuid,text)'::regprocedure;
```

**Attendu :** `d8e2ce7df2d2ee398db2eb4b1187f384`, `11673`, `true`, `true`, `true`, `false`.

4. **Téléphone A** : une seconde vente au comptoir d'une boîte de Paracétamol. **Vous devez voir :** reçu de 1 575 GNF : la vente sans remise passe toujours après la migration.

---

## 8. Fermeture de la caisse et stock

1. Téléphone A, « Ouverture de caisse ». **Vous devez voir :** « Solde attendu **14 650 GNF** » (10 000 + 1 575 + 1 500 + 1 575), le même chiffre dans le message de fermeture. Fermez en saisissant `14 650` (avec l'espace). **Vous devez voir :** écart 0.
2. « Stock & Lots » : Paracétamol **3 boîtes de moins** qu'au départ (section 2), 0 réservée : une réservation retirée et deux ventes au comptoir.

---

## 9. Relevé à me rendre

| # | Point | Écart | Conforme ? |
|---|---|---|---|
| 1 | Installation, connexion des deux téléphones | — | |
| 2 | « Stock & Lots » : tuiles 2 × 2, titres entiers, une icône | C265 | |
| 3 | Vente au comptoir : pas de réglette ni de ligne « Remise » | C262 | |
| 4 | « À payer 1 575 GNF » inchangé après défilement, reçu 1 575 | C262 | |
| 5 | Catalogue : deux colonnes, noms lisibles, dosage et forme entiers | C266, C265 | |
| 6 | Fiche produit : nom et adresse d'officine, pastilles lisibles | C265 | |
| 7 | Mode avion : QR code tout de suite, mention « Hors connexion » | C264 | |
| 8 | Retour sur la liste : aucun message technique | C263 | |
| 9 | Retour du réseau : bandeau disparu | C263 | |
| 10 | Scan du QR code, retrait 1 500 GNF | C256, C248 | |
| 11 | Administration : tuiles 2 × 2 | C265 | |
| 12 | Requête de lecture : empreinte conforme | C262 | |
| 13 | Requête de contrôle après migration conforme | C262 | |
| 14 | Vente sans remise acceptée après migration | C262 | |
| 15 | Solde attendu 14 650, fermeture à écart 0 | C258 | |
| 16 | Stock : 3 boîtes de moins, 0 réservée | stock | |
| 17 | Montants avec séparateur des milliers (« 10 000 GNF ») ; saisie « 10 000 » et « 14 650 » acceptée | C267 | |
