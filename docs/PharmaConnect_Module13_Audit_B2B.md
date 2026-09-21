# PharmaConnect — Audit Module 13 (B2B — Marketplace B2B Grossistes ↔ Pharmacies)

**Date :** 29/08/2026
**Méthodologie :** Inspection & rapport de situation → Analyse comparative → Sécurité & résilience → Optimisation & améliorations → Documentation API → Scénarios de test → Livrables.

---

## 1. Inspection & rapport de situation

### 1.1 État du code à l'ouverture

Le module trouvé en base est un **tableau d'offres pharmacie-à-pharmacie** — modèles `B2BOffer`, `B2BOrder`/`B2BOrderItem`, `B2BNegotiation` (`lib/modules/marketplace/models/`), `MarketplaceService` (lecture/écriture Supabase), `MarketplaceProvider`, écrans `marketplace_home_screen.dart` (catalogue + mes offres + mes commandes, onglets), `offer_create_screen.dart`, `offer_detail_screen.dart`, `order_detail_screen.dart`. La migration de base (`b2b_offers`/`b2b_orders`/`b2b_order_items`/`b2b_negotiations`) existe avec RLS déjà présente en apparence — mais structurellement défaillante (voir §3.1).

Fichiers inspectés : `lib/modules/marketplace/models/*.dart` (4), `services/marketplace_service.dart`, `providers/marketplace_provider.dart`, `screens/marketplace_home_screen.dart`, `screens/offer_create_screen.dart`, `screens/offer_detail_screen.dart`, `screens/order_detail_screen.dart`, plus les points d'intégration transverses (`app_router.dart`, `dashboard_screen.dart`, `offline_sync_service.dart`).

### 1.2 Défauts constatés

1. **Bug d'identité RLS critique (`auth.uid()` au lieu de `pharmacy_id`)** — les 8 policies de la migration de base comparaient `auth.uid()` directement à `seller_pharmacy_id`/`buyer_pharmacy_id`, deux colonnes qui contiennent l'identifiant de l'**officine**, jamais celui de l'utilisateur authentifié. Cette comparaison est **structurellement toujours fausse** (aucun compte pharmacien n'a `profiles.id = pharmacy_id`) : personne, y compris le staff légitime d'une officine, ne pouvait jamais créer, lire ou modifier une offre/commande/négociation qui lui appartient réellement. Voir §3.1 pour le détail et la distinction avec les occurrences précédentes de la série RLS.
2. **Policy manquante à 100 % pour la mise à jour d'une commande par l'acheteur** — `b2b_orders` n'avait qu'une policy UPDATE côté vendeur ; aucune n'existait pour que l'acheteur puisse par exemple annuler ou confirmer réception de sa propre commande.
3. **Deux blocages de compilation** :
   - `offer_detail_screen.dart` importait `'../models/b2b_order_item.dart'`, fichier inexistant — la classe `B2BOrderItem` vit dans `b2b_order.dart`, déjà importé par ailleurs.
   - `marketplace_home_screen.dart` référençait des widgets `OfferCard`/`OrderCard` dont **aucun fichier n'existait** (`lib/modules/marketplace/widgets/` était vide).
4. **Routes dupliquées dans `app_router.dart`** — le bloc `GoRoute` du marketplace était déclaré deux fois (imports et déclarations), provoquant une exception `go_router` au démarrage (noms de route dupliqués) — variante plus sévère du même anti-motif que la duplication de provider déjà connue (C12).
5. **Bug AND-vs-OR dans `MarketplaceService.getOrders()`** — `marketplace_home_screen.dart` appelait `loadOrders(buyerPharmacyId: pharmacyId, sellerPharmacyId: pharmacyId)`, deux paramètres combinés par le service via deux `.eq()` chaînés — donc en **ET** logique côté PostgREST, alors que l'intention est « acheteur OU vendeur ». Une officine n'étant jamais simultanément acheteur ET vendeur de la même commande, l'onglet « Mes commandes » retournait toujours un résultat vide.
6. **Confusion identifiant utilisateur / identifiant officine** — `_loadMyOffers()`/`_loadMyOrders()` (accueil), `_createOffer()` (création), `_createOrder()`/`_showNegotiationDialog()` (détail d'offre), `isBuyer`/`isSeller` (détail de commande) utilisaient tous `SupabaseService().currentUser?.id`, jamais `AuthProvider.pharmacyId` — même motif de bug déjà rencontré et corrigé dans plusieurs modules précédents cette session.
7. **Bouton « Modifier » sans effet** sur l'écran de détail d'une offre — présent visuellement mais sans action câblée derrière (`onPressed` vide/TODO).
8. **`deleteOffer()` orphelin** (`MarketplaceService`) — méthode fonctionnelle, jamais appelée depuis aucun écran, même motif que C11 (code mort/jamais relié à l'UI) ; risque de suppression en cascade documenté plutôt que corrigé ce module (voir §3.5).
9. **Aucun point d'entrée de navigation** vers `/marketplace` dans le menu unique de l'application (`dashboard_screen.dart`) — **13ème occurrence** de la série D6 (module routé mais inatteignable depuis le menu), voir §3.6.
10. **Aucun mode hors-ligne** — le module ne s'appuyait sur aucun cache local, contrairement à tous les modules précédents disposant d'une lecture consultable hors-ligne.

---

## 2. Analyse comparative au cahier de conception

### 2.1 Écart de périmètre majeur — arbitré avec le porteur du projet

Le cahier de conception décrit un **véritable marketplace B2B grossistes-répartiteurs ↔ pharmacies** : entité **Fournisseur** distincte (grossiste-répartiteur, avec statut d'agrément réglementaire), vérification d'agrément avant toute mise en relation (**RG-B2B-01**), comparateur de prix entre fournisseurs pour un même produit, **commande groupée** entre plusieurs pharmacies pour bénéficier de tarifs de gros (**RG-B2B-02**), et évaluation/notation des fournisseurs.

Le code trouvé ne réalise **aucun** de ces éléments : il n'existe pas de notion de « Fournisseur » dans le schéma (seule une relation `seller_pharmacy_id → pharmacies` existe), pas de statut d'agrément, pas de comparateur, pas de commande groupée, pas de notation. Le module construit est fonctionnellement un troc/négociation **pharmacie-à-pharmacie**, structurellement incompatible avec un ajout incrémental de ces règles (elles supposent une table `suppliers`/`fournisseurs` avec ses propres policies RLS, son propre cycle de vie d'agrément, et un moteur de comparaison qui n'a de sens qu'avec plusieurs fournisseurs pour un même produit).

**Arbitrage porteur du projet (AskUserQuestion, 29/08/2026)** : *« Corriger l'existant, différer le reste »* — corriger tous les bugs bloquants/sécurité sur le périmètre déjà construit (offres, négociations, commandes pharmacie-à-pharmacie), et consigner l'écart complet au cahier (entité Fournisseur, RG-B2B-01, comparateur, RG-B2B-02, évaluation fournisseur) comme dette différée dans le registre, en vue d'un module dédié ultérieur — même logique que le report du POS au Module 12 (D22). Voir registre **D24**.

### 2.2 Règles de gestion

| RG | Exigence | Constat |
|---|---|---|
| **RG-B2B-01** | Vérification de l'agrément du fournisseur avant mise en relation | 🔴 Hors périmètre — aucune entité Fournisseur n'existe (D24) |
| **RG-B2B-02** | Commande groupée entre plusieurs pharmacies pour tarif de gros | 🔴 Hors périmètre — aucun mécanisme de groupement, le modèle `B2BOrder` est strictement bilatéral (D24) |

### 2.3 Fonctionnalités clés du cahier

| Fonctionnalité (cahier) | Constat |
|---|---|
| Catalogue d'offres consultable | 🟢 Existait déjà, fonctionnel — corrigé ce module (RLS, hors-ligne) |
| Négociation d'une offre (contre-proposition) | 🟢 Existait déjà (`B2BNegotiation`), fonctionnel — corrigé ce module (RLS, identité) |
| Commande à partir d'une offre | 🟢 Existait déjà, fonctionnel — corrigé ce module (RLS, bug AND/OR, identité) |
| Modification d'une offre existante | 🟡 Bouton présent mais non câblé — **construit ce module** (flux d'édition) |
| Comparateur de prix multi-fournisseurs | 🔴 Hors périmètre (D24) |
| Commande groupée | 🔴 Hors périmètre (D24) |
| Évaluation/notation fournisseur | 🔴 Hors périmètre (D24) |
| Vérification d'agrément fournisseur | 🔴 Hors périmètre (D24) |

### 2.4 Écrans principaux (cahier)

| Écran (cahier) | Constat |
|---|---|
| Catalogue / accueil marketplace | 🟢 Existait déjà — corrigé ce module (bandeau hors-ligne, masquage erreur/hors-ligne) |
| Détail d'une offre (négocier/commander) | 🟢 Existait déjà — corrigé ce module (identité, bouton Modifier câblé) |
| Détail d'une commande | 🟢 Existait déjà — corrigé ce module (identité) |
| Création/édition d'une offre | 🟡 Création existait déjà ; **édition construite ce module** |
| Sélection/comparaison fournisseur | 🔴 Absent — dépend de l'entité Fournisseur (D24) |

---

## 3. Sécurité & résilience

### 3.1 RLS — bug d'identité, distinct de la série « migration incomplète »

Les 8 policies de la migration de base (`b2b_offers`/`b2b_orders`/`b2b_order_items`/`b2b_negotiations`) n'étaient **pas absentes** (contrairement aux occurrences C35/C37/C39/C41 de la série « migration de base incomplète en écriture ») — elles existaient, mais comparaient `auth.uid()` (l'identifiant du compte utilisateur) directement à `seller_pharmacy_id`/`buyer_pharmacy_id` (l'identifiant de l'**officine**). Ces deux valeurs ne coïncident jamais dans le modèle de données de PharmaConnect (`profiles.pharmacy_id` est la colonne de rattachement, `profiles.id` est distinct). Le résultat n'est pas une sur-exposition (comme C1) ni une absence de policy (comme C35 et consorts) mais une policy **structurellement toujours fausse** : blocage total, y compris pour le propriétaire légitime. Classé séparément en **C43** au registre, plus sévère que les occurrences précédentes car il ne s'agit pas d'un oubli d'écriture mais d'une fonctionnalité entièrement inopérante malgré une RLS en apparence complète.

**Corrigé** : migration `20260829040000_marketplace_rls_fixes.sql` (additive) — les 8 policies sont supprimées et recréées en utilisant `public.is_pharmacy_staff(seller_pharmacy_id)`/`public.is_pharmacy_staff(buyer_pharmacy_id)`, l'helper déjà établi et réutilisé dans tous les modules précédents. Une nouvelle policy UPDATE « Buyers update orders » est ajoutée sur `b2b_orders` (absente de la migration d'origine, §1.2 point 2) : `for update using (public.is_pharmacy_staff(buyer_pharmacy_id)) with check (public.is_pharmacy_staff(buyer_pharmacy_id))`.

### 3.2 Contrôle d'accès applicatif

Les identifiants `userId` utilisés en lieu et place de `pharmacyId` dans 4 écrans (§1.2 point 6) n'étaient pas seulement un bug fonctionnel : combinés à la RLS défaillante (§3.1), il était impossible de distinguer un comportement de bug applicatif d'un blocage RLS pendant l'investigation — les deux masquaient le même symptôme (« rien ne s'affiche/rien ne s'enregistre »). Corrigés ensemble ce module via `AuthProvider.pharmacyId`, seule source correcte déjà établie dans le projet.

### 3.3 Compilation — blocages classés avec C38

Les deux blocages de compilation (§1.2 point 3 — import mort vers un fichier inexistant, widgets référencés jamais créés) sont classés **C44**, comparés en sévérité à C38 (précédent blocage de compilation identifié cette session) : un module inatteignable en pratique dès l'ouverture de l'écran d'accueil marketplace, avant même toute question de RLS.

### 3.4 Démarrage de l'application — routes dupliquées

Les déclarations `GoRoute` dupliquées (§1.2 point 4) sont classées **C45** : à la différence de C12 (duplication de provider, dégradation silencieuse), une duplication de nom de route dans `go_router` lève une exception au démarrage — l'application entière ne démarre pas, pas seulement le module marketplace. Corrigé en supprimant les imports/déclarations en double ; une nouvelle route `/marketplace/offer/edit/:id` est ajoutée pour le flux d'édition (§4).

### 3.5 Code orphelin — `deleteOffer()`

`MarketplaceService.deleteOffer()` est fonctionnel et correctement scopé côté service, mais n'est appelé depuis aucun écran (**C47**, même motif que C11). Non corrigé ce module (aucune UI de suppression ajoutée) — signalé avec une réserve spécifique : `b2b_order_items` référence `offer_id` sans contrainte `ON DELETE` explicite documentée dans la migration inspectée ; si cette méthode devient un jour accessible depuis l'UI sans vérification préalable de commandes liées, une suppression d'offre pourrait laisser des lignes de commande orphelines ou échouer silencieusement selon le comportement par défaut de la contrainte. À vérifier avant toute mise en service d'un bouton « Supprimer ».

### 3.6 Navigation — 13ème occurrence de la série D6

Le module marketplace n'apparaissait dans aucune entrée du menu de navigation unique (`dashboard_screen.dart`, `_navItems`), reproduisant le même motif déjà rencontré 12 fois (Modules 8, 10, 11, 12 ×2). **Corrigé** ce module par l'ajout d'une entrée « Marketplace B2B » (icône `storefront`, route `/marketplace`), placée après « Rappels » et avant « Alertes ». Comme signalé dans le registre (D6, note de clôture), il ne s'agit toujours que d'un correctif réactif au cas par cas — la revue exhaustive des ~36 dossiers sous `lib/modules/` recommandée depuis trois occurrences consécutives n'a toujours pas été réalisée.

### 3.7 Mode hors-ligne

Directive standing « privilégier le mode hors-ligne » appliquée uniquement au catalogue global d'offres (lecture consultable), pas à « Mes offres »/« Mes commandes » (écritures propriétaire, coverage partielle assumée et documentée — **C46**, même famille que C13/C21/C28/C33) :

- **Lecture du catalogue global** (`cache_b2b_offers`, même patron que les autres modules) : repli automatique en cas d'échec réseau, bandeau « Hors ligne » affiché sur le premier onglet.
- **Corrigé au passage** : le motif de masquage erreur/hors-ligne déjà rencontré au Module 5 (`_error` utilisé à la fois pour une vraie erreur et pour le message informatif hors-ligne, provoquant l'affichage d'un écran d'erreur plein écran par-dessus les données mises en cache) a été retrouvé et corrigé ici (`marketplace_home_screen.dart` : garde `provider.error != null && !provider.isOffline`).
- **« Mes offres »/« Mes commandes »/négociation/commande** : aucune mise en file d'attente hors-ligne — écritures propriétaire non couvertes ce module, signalé au registre (C46) plutôt que traité en silence.

---

## 4. Optimisation & améliorations livrées

1. **Migration `20260829040000_marketplace_rls_fixes.sql`** — 8 policies RLS recréées avec `is_pharmacy_staff()`, nouvelle policy UPDATE acheteur sur `b2b_orders` (§3.1).
2. **`offer_detail_screen.dart`** — suppression de l'import mort `b2b_order_item.dart` ; migration vers `AuthProvider.pharmacyId` ; bouton « Modifier » câblé vers le nouveau flux d'édition ; correctifs `userId`→`pharmacyId` dans `_createOrder()`/`_showNegotiationDialog()`.
3. **`lib/modules/marketplace/widgets/offer_card.dart`** (nouveau) — `OfferCard`, modelé sur `DeliveryCard` (GlassCard, badge de statut, nom du produit, vendeur, prix, quantité).
4. **`lib/modules/marketplace/widgets/order_card.dart`** (nouveau) — `OrderCard`, même patron visuel (résumé des articles, badge de statut, acheteur→vendeur, total, date).
5. **`offer_create_screen.dart`** — nouveau paramètre `B2BOffer? existingOffer` + mode édition (pré-remplissage, conservation de l'id/vendeur/statut/date de création existants pour que le routage création-vs-mise-à-jour de `MarketplaceProvider.saveOffer()` fonctionne correctement) ; migration vers `AuthProvider.pharmacyId`.
6. **`order_detail_screen.dart`** — migration vers `AuthProvider.pharmacyId` pour `isBuyer`/`isSeller`.
7. **`marketplace_service.dart`** — `getOrders()` accepte un nouveau paramètre `involvedPharmacyId`, utilisant `.or('buyer_pharmacy_id.eq.$id,seller_pharmacy_id.eq.$id')` au lieu de deux `.eq()` chaînés (bug AND/OR, §1.2 point 5).
8. **`marketplace_provider.dart`** — `loadOrders()` transmet `involvedPharmacyId` ; `loadOffers()` détecte le catalogue global, met en cache via `_cacheOffers()`, synchronise en arrière-plan (`syncAll()`), et bascule sur `_tryOfflineFallback()` en cas d'échec réseau (catalogue global uniquement) avec un message informatif distinct d'une vraie erreur.
9. **`offline_sync_service.dart`** — version de schéma 10→11 ; nouvelle table `cache_b2b_offers` (création + upgrade) ; méthodes `cacheB2BOffers()`/`getCachedB2BOffers()` ; ajout au `clearAll()`.
10. **`marketplace_home_screen.dart`** — migration vers `AuthProvider.pharmacyId` pour `_loadMyOffers()`/`_loadMyOrders()` (avec `involvedPharmacyId`) ; bandeau hors-ligne sur l'onglet catalogue ; correctif du masquage erreur/hors-ligne (§3.7) ; utilisation des nouveaux `OfferCard`/`OrderCard`.
11. **`app_router.dart`** — suppression des imports/déclarations de route dupliqués ; nouvelle route `/marketplace/offer/edit/:id` (nom `marketplace-offer-edit`).
12. **`dashboard_screen.dart`** — entrée de navigation « Marketplace B2B » ajoutée (§3.6) ; correction au passage d'une erreur de numérotation auto-introduite dans un commentaire du Module 12 (« treizième » renommé « douzième » pour le correctif de rappel, la 13ème occurrence réelle étant celle de ce module).

---

## 5. Documentation API — `MarketplaceService` (méthodes nouvelles/modifiées)

| Méthode | Paramètres | Retour | Notes |
|---|---|---|---|
| `getOrders` | `buyerPharmacyId?`, `sellerPharmacyId?`, `involvedPharmacyId?` | `List<B2BOrder>` | Modifiée — `involvedPharmacyId` utilise `.or()` (acheteur OU vendeur) ; les deux anciens paramètres restent disponibles séparément (ET logique, comportement inchangé) pour les usages qui en ont réellement besoin |
| `deleteOffer` | `offerId` | `void` | Inchangée, toujours orpheline (C47) — non appelée depuis l'UI |

## 5.1 Documentation API — `OfflineSyncService` (ajouts)

| Méthode | Paramètres | Retour | Notes |
|---|---|---|---|
| `cacheB2BOffers` | `rawItems: List<Map<String,dynamic>>` | `Future<void>` | Nouvelle — remplace intégralement `cache_b2b_offers` (delete + insert) |
| `getCachedB2BOffers` | — | `Future<List<Map<String,dynamic>>>` | Nouvelle |

---

## 6. Livrables et écarts documentés

Livrés ce module : correctif RLS d'identité sur 4 tables/8 policies (C43), policy UPDATE acheteur manquante ajoutée, correctif de deux blocages de compilation (C44), correctif des routes dupliquées bloquant le démarrage de l'application (C45), correctif du bug AND/OR sur « Mes commandes », migration `userId`→`pharmacyId` sur 4 écrans, flux d'édition d'offre (bouton « Modifier » câblé), mode hors-ligne partiel (catalogue global, C46 documente la limite), correctif du masquage erreur/hors-ligne (même motif que Module 5), entrée de navigation « Marketplace B2B » (13ème occurrence série D6), correction d'une erreur de numérotation auto-introduite au Module 12.

Écarts assumés et documentés, par arbitrage explicite du porteur du projet (D24) : l'écart complet au cahier — entité Fournisseur, RG-B2B-01 (vérification d'agrément), comparateur de prix, RG-B2B-02 (commande groupée), évaluation fournisseur — n'est **pas construit** ce module ; il est différé en dette technique documentée, en vue d'un module dédié ultérieur, même logique que D22 (report POS, Module 12). `deleteOffer()` reste orphelin (C47, non corrigé). La couverture hors-ligne reste partielle (C46, catalogue global uniquement).

Voir `PharmaConnect_Module13_Protocole_Test_E2E.md` pour les scénarios de validation et `PharmaConnect_Module13_PV_Recette.md` pour l'état de recette provisoire.

---

## 7. Addendum — deuxième passe de clôture (29/08/2026)

Le porteur du projet a refusé la clôture initiale, pointant deux réserves à lever plutôt qu'à différer : la suppression d'offre sans UI (`deleteOffer()` orphelin, C47) et l'asymétrie du mode hors-ligne (catalogue global seulement, C46). Arbitrage recueilli par question à choix — pour chacune des deux réserves, l'option recommandée a été retenue.

### 7.1 Réserve levée — suppression d'offre (C47)

Un bouton de suppression avec confirmation a été ajouté dans l'onglet « Mes offres » (`OfferCard.onDelete`, non exposé dans le catalogue global — un vendeur ne peut supprimer que ses propres offres). Avant confirmation, deux contrôles diagnostiques best-effort avertissent explicitement le vendeur :

- `MarketplaceService.countOrderItemsForOffer` (nouveau) — nombre de lignes `b2b_order_items` référençant l'offre. `offer_id` y est `on delete set null` : la suppression ne perd aucune donnée de commande, mais détache l'offre de son historique.
- `MarketplaceProvider.countNegotiationsForOffer` (nouveau, réutilise `getNegotiationsForOffer`) — nombre de négociations liées. **Découverte en construisant ce contrôle** : `b2b_negotiations.offer_id` est, contrairement à `b2b_order_items`, `on delete cascade` (migration de base) — sans cet avertissement, supprimer une offre effacerait silencieusement et définitivement tout son historique de négociation, y compris une négociation en cours (`status = 'pending'`).

Les deux contrôles sont combinés dans un seul message de confirmation, qui ne s'affiche que si l'un des deux compteurs est non nul ; sinon, une confirmation simple suffit.

### 7.2 Réserve levée — mode hors-ligne étendu (C46)

Deux nouvelles tables de cache local, sur le même patron `owner_key` que `cache_prescriptions`/`cache_reservations` (schéma v11→v12) :

- `cache_my_b2b_offers` (owner_key = `sellerPharmacyId`) — repli de lecture pour l'onglet « Mes offres ».
- `cache_b2b_orders` (owner_key = `involvedPharmacyId`) — repli de lecture pour l'onglet « Mes commandes ».

`MarketplaceProvider.loadOffers()`/`loadOrders()` mettent désormais en cache et se replient sur ces tables selon le même mécanisme déjà en place pour le catalogue global (best-effort, ne fait jamais échouer un chargement réseau par ailleurs réussi). Le bandeau « Hors connexion » de `marketplace_home_screen.dart`, jusqu'ici limité au premier onglet, couvre désormais les trois, avec un libellé adapté à l'onglet actif. Reste hors périmètre, assumé (inchangé) : toutes les écritures (créer/modifier/supprimer une offre, négocier, commander, changer un statut) restent strictement en ligne.

### 7.3 Découverte en cours de route — embed PostgREST invalide (C48)

En construisant le cache de « Mes commandes », relecture complète de `MarketplaceService.getOrders()`/`getOrder()` : l'embed `items:order_items(*)` référence une table `order_items`, qui n'existe pas — la table réelle est `b2b_order_items`. PostgREST rejette toute requête embarquant une relation inexistante (erreur 400) : ces deux méthodes échouaient **dans leur intégralité**, pas seulement le champ `items`, quels que soient les filtres appliqués. Ce bug est distinct et plus sévère que le bug AND/OR déjà corrigé sur ce même onglet en première passe (§1.2 point 5 du corps du rapport) — celui-ci empêchait un filtre de fonctionner correctement, celui-ci empêchait la requête d'aboutir purement et simplement. Sans ce correctif, la couverture hors-ligne de « Mes commandes » construite au §7.2 aurait masqué le fait que la lecture réseau elle-même n'avait jamais fonctionné, une fois le premier cache peuplé. Corrigé : `items:b2b_order_items(*)` dans `getOrders()` et `getOrder()`.

### 7.4 Nouveaux livrables (deuxième passe)

`MarketplaceService.countOrderItemsForOffer` (nouveau) ; `MarketplaceProvider.countLinkedOrdersForOffer`/`countNegotiationsForOffer` (nouveaux) ; `OfferCard.onDelete` (nouveau paramètre optionnel) ; `marketplace_home_screen.dart:_confirmDeleteOffer` (nouveau, dialogue de confirmation à deux contrôles) ; `offline_sync_service.dart` (schéma v11→v12, `cache_my_b2b_offers`/`cache_b2b_orders` + méthodes associées, `clearAll()` mis à jour) ; `MarketplaceProvider.loadOffers()`/`loadOrders()` étendus (cache/repli « Mes offres »/« Mes commandes ») ; bandeau hors-ligne étendu aux trois onglets ; correctif de l'embed `b2b_order_items` dans `MarketplaceService.getOrders()`/`getOrder()`.

### 7.5 Nouvel écart formel

Aucun. Les deux réserves de la clôture initiale sont levées ; aucun nouvel écart de périmètre cahier n'a été introduit par cette deuxième passe (D24 reste inchangé). La découverte C48 était un bug de correction, pas une décision de périmètre.

---

**Le module Marketplace B2B (B2B) est-il totalement clos et validé pour passer au suivant ?**
