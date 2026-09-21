# PharmaConnect — Audit de clôture Module 3 : Catalogue Produits & Référentiel Médicaments (CAT)

**Date** : 29/08/2026
**Périmètre inspecté** : `lib/modules/catalog/**` (models, providers, screens, services, widgets), `lib/shared/models/product.dart`, `supabase/migrations/20260827000300_catalog.sql`, `lib/routes/app_router.dart` (routes `/catalog`, `/catalog/:id`, `/stock/adjust/:productId`), `lib/app.dart` (enregistrement des providers)
**Méthodologie** : conforme à la Règle d'or, directive standing « privilégier le mode hors-ligne tant que cela est possible », registre unique des écarts tenu à jour en parallèle (`claude/PharmaConnect_Registre_Ecarts_A_Verifier.md`)

---

## 1. Inspection & Rapport de situation

Le module est simple et complet fonctionnellement : deux écrans (liste, détail), un provider, un service, deux modèles de référentiel (`Category`, `Manufacturer`), et le modèle `Product` partagé avec REC (`lib/shared/models/product.dart`). `public.products` est bien le référentiel unique déjà identifié conforme à RG-CAT-01 (aucune duplication de ses champs métier dans une autre table — `stock_items` ne fait que le référencer par `product_id`).

Trois constats structurants ressortent de l'inspection :

**A. RG-CAT-02 totalement absent (Critique).** Comme déjà signalé lors de l'audit REC (Module 2) et consigné dans le registre, `public.products` ne portait aucune colonne de classification réglementaire distincte de `is_prescription_required`. Un produit stupéfiant/psychotrope apparaissait donc dans le catalogue et dans la recherche de disponibilité exactement comme n'importe quel médicament libre, en violation directe de la règle.

**B. `ProductImage` construit mais jamais consommé.** Le widget existe déjà avec placeholder et gestion d'erreur réseau (`cached_network_image`), mais `ProductGridItem` affichait une icône générique statique à la place — `products.image_url`, pourtant modélisé et alimentable, n'était jamais montré à l'utilisateur.

**C. Bouton « Gérer le stock » sans garde de rôle.** `CatalogDetailScreen` affichait ce bouton pour tout utilisateur authentifié, y compris un `patient`. La RLS (`is_pharmacy_staff`, corrigée au Module 0) empêche bien toute écriture réelle sur `stock_items`, mais rien n'empêchait un rôle non pertinent d'atteindre un écran qui ne pouvait que se solder par un refus.

**D. Découverte en marge, hors périmètre strict de CAT :** `app.dart` déclare `AuthProvider`, `DashboardProvider` et `SearchProvider` chacun deux fois dans la liste `MultiProvider`. Repéré en câblant `AuthProvider` dans `catalog_detail_screen.dart` pour le correctif C. Analyse : sans effet observable aujourd'hui (le mécanisme de résolution du package `provider` fait que seule l'instance la plus interne, la seconde occurrence, est jamais lue par les écrans), mais latent — documenté dans le registre plutôt que corrigé ici, `app.dart` relevant du Module 0 (fondations transverses), déjà clos et validé.

## 2. Analyse comparative avec le cahier de conception

| Règle | Statut avant ce module | Statut après |
|---|---|---|
| RG-CAT-01 (référentiel produit unique/centralisé) | Conforme par construction | Inchangé, confirmé conforme |
| RG-CAT-02 (stupéfiant/psychotrope non affichable sans ordonnance) | Non implémenté | Classification ajoutée (`regulatory_class`) + masquage RLS pour le rôle patient |
| RG-CAT-03 (propagation automatique des changements de statut réglementaire) | N/A (champ inexistant) | Conforme par construction — `regulatory_class` n'est dupliqué nulle part ; toute mise à jour se répercute immédiatement partout où `products` est lu |

Aucune règle de gestion nouvelle n'a été inventée : RG-CAT-02 est appliquée avec le vocabulaire le plus proche possible de l'existant (`is_prescription_required` reste la distinction d'affichage pour les produits sur ordonnance simple ; `regulatory_class` n'intervient que pour la catégorie stupéfiant/psychotrope, strictement plus restrictive).

## 3. Sécurité & Résilience

| # | Constat | Sévérité | Statut |
|---|---|---|---|
| 1 | Aucun filtre réglementaire sur les produits stupéfiants/psychotropes en lecture publique (RG-CAT-02) | Critique | **Corrigé** — policy RLS `products_select_scoped` |
| 2 | Bouton « Gérer le stock » accessible à tout rôle depuis le catalogue, y compris patient | Moyenne (UX/impasse, pas une fuite de données — la RLS bloquait déjà l'écriture) | **Corrigé** — bouton masqué hors rôle `pharmacien` |
| 3 | `app.dart` : providers dupliqués (`AuthProvider`/`DashboardProvider`/`SearchProvider`) | Faible aujourd'hui, latent | Documenté dans le registre (item C12), non corrigé — hors périmètre de CAT, territoire Module 0 déjà clos |

**Choix d'implémentation pour RG-CAT-02 — justification.** Le mécanisme d'ordonnance vérifiable n'existe pas encore dans le projet (module ORD/Prescriptions non audité, aucune table ne permet de savoir si un patient a une ordonnance valide pour un produit donné). Plutôt que d'inventer un mécanisme de vérification prématurément — ce qui aurait été une nouvelle règle métier non demandée — la règle est appliquée de façon conservative : les produits classés stupéfiant/psychotrope sont retirés de la visibilité de tout compte `patient`, et restent visibles pour les rôles opérationnels (pharmacien, grossiste, livreur, professionnel, régulateur) et le back-office GSG. C'est la lecture la plus stricte et la plus sûre de « non affichable sans ordonnance » tant qu'aucune ordonnance n'est vérifiable : zéro affichage plutôt qu'un affichage non contrôlé. Le Module 5 (ORD) pourra affiner cette policy vers une exception ciblée (patient + ordonnance valide pour ce produit précis) une fois ce mécanisme construit.

**Propagation automatique à REC, sans rouvrir le module.** Le filtre est posé au niveau RLS sur `public.products`, pas dans le code client. `search_service.dart` (Module 2, déjà audité et clos) lit cette même table sans filtre applicatif dédié pour la classification réglementaire — il bénéficie donc immédiatement et automatiquement de la restriction, sans qu'aucune ligne de ce fichier n'ait eu besoin d'être modifiée. C'est précisément pour cette raison que le correctif a été posé en RLS plutôt que dupliqué dans chaque service consommateur.

## 4. Optimisation & Améliorations

### 4.1 Réalisées ce tour
- Affichage réel des images produit (`ProductImage` désormais consommé par `ProductGridItem`) — correction d'un écart entre un composant déjà construit et son intégration.
- Ajout de `products.barcode` (GTIN), unique et nullable — complète le référentiel pour une future vraie recherche code-barres (actuellement une heuristique côté REC, non modifiée ici — voir §7 et registre item B3).
- Badges visuels « Stupéfiant/Psychotrope » ajoutés dans la grille et le détail produit, visibles uniquement par les rôles déjà autorisés à voir ces lignes (la RLS retire la ligne du réseau pour un patient — le badge ne peut donc structurellement jamais leur être montré).

### 4.2 Recommandées, non appliquées (à valider avant intégration)
- **Pagination du catalogue.** `CatalogService.getProducts()` charge l'intégralité de `products` à chaque appel, sans `limit`/`range` PostgREST ; `PaginationControls` existe comme composant mais n'est câblé dans aucun écran. Fonctionnera correctement au volume actuel, mais représente la même classe de dette de performance déjà signalée pour REC (registre, item C4) — proposé comme piste future (pagination serveur via `.range()`), pas implémenté ici pour ne pas modifier la logique de chargement sans validation explicite.
- **Mode hors-ligne (directive standing).** Le catalogue n'a aujourd'hui aucun mécanisme de cache — chaque ouverture d'écran refait un appel réseau complet, sans dégradation gracieuse en cas de coupure (contrairement au correctif déjà posé sur `SearchProvider` au Module 2). Le référentiel produit est pourtant un excellent candidat au cache local : il change rarement comparé au stock ou à la disponibilité. Recommandé pour une prochaine passe (peut réutiliser le même patron `_isOffline`/préservation des résultats déjà validé sur `SearchProvider`), non implémenté ici pour rester dans le périmètre strict des écarts identifiés à ce tour.
- **`app.dart` — providers dupliqués.** Signalé en §3 et dans le registre (C12) ; nettoyage trivial mais volontairement non fait ici, `app.dart` étant du ressort du Module 0 déjà clos.

## 5. Documentation API

**`CatalogService`** (`lib/modules/catalog/services/catalog_service.dart`) — inchangé dans sa signature ; `getProducts()`/`getProduct()` bénéficient automatiquement des nouveaux champs `regulatory_class`/`barcode` via le `select('*')` déjà en place, et de la policy RLS mise à jour (aucune modification de ce fichier n'a été nécessaire).

**`Product`** (`lib/shared/models/product.dart`) — nouveaux champs : `String regulatoryClass` (`'libre' | 'sur_ordonnance' | 'stupefiant' | 'psychotrope'`, défaut `'libre'`), `String? barcode`. Nouveau getter : `bool get isControlledSubstance`.

**Migration `20260829014000_catalog_regulatory_classification.sql`** :
- `products.regulatory_class` (text, check, défaut `'libre'`).
- `products.barcode` (text, unique, nullable).
- Policy `products_select_scoped` (remplace `products_select_authenticated`) : un produit stupéfiant/psychotrope n'est visible que par un rôle non-patient ou `is_gsg_admin()`.

## 6. Scénarios de test

**RG-CAT-01**
- Deux écrans distincts (catalogue, recherche) lisant le même produit renvoient des données identiques après une mise à jour — pas de désynchronisation possible puisqu'il n'existe qu'une seule ligne source.

**RG-CAT-02**
- Un produit `regulatory_class = 'libre'` ou `'sur_ordonnance'` reste visible pour un compte `patient` (aucune régression sur le comportement existant).
- Un produit `regulatory_class = 'stupefiant'` ou `'psychotrope'` : invisible en `SELECT` pour un compte `patient` (ligne absente de la réponse, pas seulement masquée côté UI) ; visible pour un compte `pharmacien`/`grossiste`/`livreur`/`professionnel`/`regulateur` ; visible pour un compte `admin_users` actif via `is_gsg_admin()`.
- Le même produit stupéfiant, recherché via `SearchService.search()` (Module 2) par un patient, n'apparaît pas non plus dans les résultats — preuve que la propagation RLS fonctionne sans modification du code REC.

**RG-CAT-03**
- Modifier `regulatory_class` d'un produit existant (`'libre' → 'stupefiant'`) et vérifier qu'un patient qui le voyait à l'instant précédent ne le voit plus à la requête suivante, sans action de synchronisation supplémentaire.

**Affichage image**
- Produit avec `image_url` renseigné → `ProductGridItem` affiche l'image réelle (pas l'icône générique) ; `image_url` vide ou URL en erreur → repli sur le placeholder (`ProductImage._buildPlaceholder`), pas de crash.

**Bouton « Gérer le stock »**
- Compte `pharmacien` → bouton visible.
- Compte `patient`/`grossiste`/`livreur`/`professionnel`/`regulateur` → bouton absent (pas seulement désactivé — retiré de l'arbre de widgets).

## 7. Livrables de ce module

- `supabase/migrations/20260829014000_catalog_regulatory_classification.sql` (nouveau)
- `lib/shared/models/product.dart` (modifié)
- `lib/modules/catalog/widgets/product_grid_item.dart` (modifié)
- `lib/modules/catalog/screens/catalog_detail_screen.dart` (modifié)
- Ce rapport (`claude/PharmaConnect_Module3_Audit_CAT.md`)
- Registre des écarts mis à jour (`claude/PharmaConnect_Registre_Ecarts_A_Verifier.md`) : B2 passé en 🟢 résolu, B3 passé en 🟡 partiel (schéma prêt, code REC non modifié), deux nouveaux items ajoutés (C11 — pagination catalogue non câblée, C12 — providers dupliqués dans `app.dart`)

**Écarts documentés et explicitement différés** (à ne pas considérer comme oubliés) :
- Migration de `search_service.dart:searchByBarcode()` vers la nouvelle colonne `products.barcode` (Module 2, déjà clos — non rouvert ici).
- Pagination réelle du catalogue (`PaginationControls` reste du code mort).
- Cache/dégradation hors-ligne pour le catalogue.
- Nettoyage des providers dupliqués dans `app.dart` (Module 0, déjà clos).
- Raffinement futur de RG-CAT-02 vers une vraie vérification d'ordonnance patient-par-produit, quand le Module 5 (ORD) sera audité.

---

**Le module Catalogue Produits & Référentiel Médicaments (Module 3 — CAT) est-il totalement clos et validé pour passer au suivant (Module 4 — STK, Gestion des Stocks) ?**
