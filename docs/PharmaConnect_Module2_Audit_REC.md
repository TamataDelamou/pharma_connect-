# PharmaConnect — Audit de clôture Module 2 : Recherche & Disponibilité en temps réel (REC)

**Date** : 29/08/2026
**Périmètre inspecté** : `lib/modules/search/**` (models, providers, screens, services, widgets), `supabase/migrations/20260827001500_search.sql`, `supabase/migrations/20260827000300_catalog.sql`, `supabase/migrations/20260827000600_stock.sql`
**Méthodologie** : conforme à la Règle d'or (module isolé, validation utilisateur requise avant progression), directive standing « privilégier le mode hors-ligne tant que cela est possible » (approuvée à la clôture du Module 0)

---

## 1. Inspection & Rapport de situation

### 1.1 Architecture du module

Le module REC n'a pas de table dédiée en base : `SearchResult`, `AvailabilityResult` et `SearchSuggestion` sont des objets calculés à la volée côté client à partir de `products`, `stock_items` et `pharmacies`. Seul `search_history` est réellement persisté (par utilisateur, dédoublonné à l'insertion). Ce choix est documenté dans la migration elle-même et cohérent avec l'absence de moteur de recherche dédié (pas d'Elasticsearch/Algolia, pas de `pg_trgm` — la recherche est un `contains()` en mémoire sur la liste complète des produits).

`SearchService._fetchAllProducts()` charge l'intégralité de la table `products` à chaque recherche, puis filtre en Dart. `SearchService._fetchStocksFor()` fait ensuite une jointure `stock_items ⋈ pharmacies` filtrée par la liste des `product_id` déjà matchés.

Le scoring de pertinence (`relevance`) est une somme pondérée simple (nom 1.0, DCI 0.9, fabricant 0.5, catégorie 0.4, dosage 0.3) sur des `contains()` insensibles à la casse — pas de recherche floue, pas de gestion des fautes de frappe ni des synonymes DCI/nom commercial. Fonctionnel pour le stade actuel, mais à noter comme limite connue plutôt que défaut bloquant.

### 1.2 Constats — trois écarts corrigés dans ce tour

**A. RG-AUT-04 non appliquée (Critique, corrigé)**
`_fetchStocksFor()` joignait `pharmacies(*)` sans aucun filtre sur `status`. Une officine `suspended`, `rejected`, `underReview`, ou même `pending` (candidature en auto-inscription non encore revue — cf. Module 1, `PharmacyService.submitLicenseVerification`) apparaissait dans les résultats de recherche patients au même titre qu'une officine `active`. Techniquement, un simple `.eq('pharmacy.status', 'active')` sur une ressource imbriquée sans `!inner` est un no-op silencieux côté PostgREST (il nullifie l'objet embarqué au lieu de filtrer la ligne) — c'est la cause probable pour laquelle ce filtre, s'il avait été tenté avant, n'aurait de toute façon pas fonctionné.

**B. RG-REC-01 non appliquée (Critique, corrigé)**
`PharmacyStock.isOutdated` (délai ≥ 24h depuis `lastUpdated`) existait déjà comme getter mais n'était consulté nulle part dans le module. `stockLabel`/`stockColor` ignoraient totalement la fraîcheur de la donnée et affichaient un niveau de stock ("Disponible", "Stock faible"...) même quand la donnée avait plusieurs jours de retard.

**C. RG-REC-02 non appliquée (Standard, corrigé)**
Le prix affiché dans `PharmacyListTile` apparaissait comme une valeur définitive, sans aucune mention de son caractère indicatif tant que la pharmacie n'a pas confirmé la réservation.

### 1.3 Constats — deux écarts identifiés, non corrigés (hors périmètre du module actuel)

**D. RG-REC-03 (garde officielle) — non implémentable en l'état**
`Pharmacy.isOnDuty` existe côté modèle Dart mais n'a aucune source de vérité en base : aucune table ne porte de planning de garde, et le cahier exige que l'affichage corresponde au planning officiel de l'Ordre National des Pharmaciens/DNPM — une source externe qu'aucun module actuel n'intègre. Documenté comme dépendance bloquante, à traiter quand une intégration externe (webhook/API DNPM, ou table `duty_schedules` alimentée manuellement par un back-office ADM) sera scopée. Ne pas fixer prématurément dans REC : ce serait inventer une source de données qui n'a pas d'autorité métier reconnue.

**E. RG-CAT-02 (stupéfiant/psychotrope) — dépendance Module 3 (CAT)**
Le cahier interdit l'affichage en disponibilité publique d'un produit stupéfiant/psychotrope sans ordonnance. `public.products` (`20260827000300_catalog.sql`) n'a aujourd'hui aucune colonne de classification réglementaire (type stupéfiant, statut prescription renforcée). Cette classification est du ressort du référentiel produit (Module 3 — CAT), pas de la recherche : REC doit *consommer* un champ que CAT n'a pas encore modélisé. Flaggé explicitement pour l'audit du Module 3 ; REC devra alors ajouter le filtre correspondant dans `_fetchAllProducts`/`search()` une fois le champ disponible.

### 1.4 Mode hors-ligne (directive standing)

Avant correctif, `SearchProvider.search()` traitait toute exception réseau de façon identique, qu'il existe ou non des résultats déjà affichés à l'écran : `_results` était systématiquement écrasé par un état d'erreur vide (`SearchStatus.error`), forçant l'utilisateur à revoir un écran blanc même s'il consultait une liste de résultats valide une seconde avant une coupure de connexion.

Corrigé : `search()` distingue maintenant deux cas dans son `catch` :
- s'il existe déjà des résultats affichés (`_results.isNotEmpty`), ils sont **conservés**, un flag `_isOffline` est levé, et un message informatif ("Connexion indisponible — résultats précédents affichés, possiblement pas à jour.") est exposé via `_error` sans faire basculer l'écran en état d'erreur (`_status` reste `loaded`) ;
- sinon (aucun résultat préalable), le comportement d'erreur dur existant est conservé — il n'y a rien de pertinent à préserver.

`_isOffline` est réinitialisé à `false` en début et en cas de succès d'une nouvelle recherche, pour ne pas laisser un état hors-ligne périmé traîner après reconnexion.

Ce correctif ne prétend pas résoudre l'ensemble du sujet hors-ligne du module REC (aucun cache local des derniers résultats n'est mis en place — la préservation ne joue que le temps où le provider reste en mémoire, pas après un redémarrage de l'app), mais applique fidèlement le principe de dégradation gracieuse demandé : ne jamais remplacer une donnée valide affichée par un écran vide sur un simple aléa réseau.

---

## 2. Analyse comparative (cahier de conception vs implémentation)

| Exigence (cahier) | État avant ce tour | État après ce tour |
|---|---|---|
| RG-AUT-04 — officine suspendue retirée des résultats | Non appliqué | Appliqué (`!inner` + `.eq('pharmacy.status','active')`) |
| RG-REC-01 — disponibilité >24h → "à confirmer" | Calculé mais jamais lu | Appliqué dans `stockLabel`/`stockColor` |
| RG-REC-02 — prix indicatif avant confirmation | Absent | Mention "Prix indicatif" ajoutée |
| RG-REC-03 — garde conforme planning officiel ONP/DNPM | Aucune source de données | Non implémentable sans intégration externe — documenté, différé |
| RG-CAT-01/02/03 — classification réglementaire produit | Aucun champ en base | Dépendance Module 3 — documenté, différé |

Écart de dette technique restant : le scan complet de `products` à chaque frappe (`_fetchAllProducts`) n'a pas de pagination ni d'index texte ; fonctionnera correctement au volume actuel du catalogue mais deviendra un point de performance à surveiller si le catalogue grossit significativement (voir §4.2).

---

## 3. Sécurité & Résilience

| # | Faille | Sévérité | Statut |
|---|---|---|---|
| 1 | Officines non actives visibles en recherche publique (RG-AUT-04) | Critique | **Corrigé** |
| 2 | Filtre PostgREST sur ressource imbriquée non appliqué sans `!inner` (classe de bug réutilisable ailleurs dans le code) | Élevée | Corrigé ici ; **à vérifier systématiquement** dans tout autre point de requête joignant `pharmacies` sans `!inner` — aucun autre point de ce type identifié dans REC, mais non vérifié hors périmètre du module |
| 3 | Écran de recherche vidé en cas de coupure réseau malgré des résultats déjà valides en mémoire | Moyenne | **Corrigé** (préservation + flag `_isOffline`) |
| 4 | Absence de classification stupéfiant/psychotrope en recherche publique (RG-CAT-02) | Critique, mais hors périmètre REC | Documenté, différé au Module 3 |
| 5 | Garde officielle non vérifiable (RG-REC-03) | Critique, mais bloquée par absence de source externe | Documenté, différé |

Politique RLS `stock_items_select_authenticated`/`stock_batches_...`/`stock_movements_...`/`stock_adjustments_...` : `for select to authenticated using (true)` — tout utilisateur authentifié (y compris un `patient`) peut lire l'intégralité de `stock_movements`/`stock_adjustments`, qui contiennent des informations opérationnelles internes (mouvements, ajustements, `user_id`, `notes`) sans rapport avec la recherche publique. Ce n'est pas un écart par rapport à REC en soi (REC ne lit que `stock_items`), mais c'est une sur-exposition constatée en marge de l'inspection : à signaler pour un futur audit du module Stock (accès `select` non scopé par `is_pharmacy_staff`), car un patient authentifié peut aujourd'hui interroger directement ces tables hors de toute UI applicative.

---

## 4. Optimisation & Améliorations

### 4.1 Réalisées ce tour
- Filtrage RLS-cohérent des officines par statut au niveau de la requête (pas de filtrage a posteriori côté client, qui aurait laissé fuiter les données dans la réponse réseau).
- Dégradation gracieuse hors-ligne dans `SearchProvider`.

### 4.2 Recommandées, non appliquées (à valider avant intégration)
- **Performance recherche** : à mesure que `products` grossit, `_fetchAllProducts()` + scan en mémoire à chaque frappe deviendra coûteux. Piste : recherche côté serveur via `ilike`/`websearch_to_tsquery` sur un index `pg_trgm`/`tsvector`, avec debounce déjà existant à vérifier côté UI. Non appliqué ici pour ne pas modifier la logique de scoring sans validation explicite — changement d'architecture, pas une correction de bug.
- **Cache hors-ligne persistant** : le correctif actuel ne préserve les résultats que le temps de vie du `SearchProvider` en mémoire ; un cache local (Hive/SharedPreferences) des dernières recherches réussies irait plus loin dans l'esprit de la directive hors-ligne, mais represente une nouvelle brique d'infrastructure — proposé comme piste future, pas fixé d'autorité dans ce tour.
- **`searchByBarcode`** reste une heuristique de comparaison d'ID (`p$barcode`), pas une vraie recherche code-barres (absence de colonne GTIN sur `products` — dépendance Module 3/CAT également).

---

## 5. Documentation API (services concernés)

**`SearchService`** (`lib/modules/search/services/search_service.dart`)
- `search({query, filters?, userLat?, userLon?}) → List<SearchResult>` — recherche pondérée en mémoire + jointure stock filtrée par officines actives (RG-AUT-04).
- `getSuggestions(String query) → List<SearchSuggestion>` — suggestions produit/DCI/catégorie, non filtrées par disponibilité.
- `searchByBarcode(String barcode) → Product?` — heuristique, pas un vrai lookup GTIN.
- `getSearchHistory()/addToHistory()/clearHistory()` — persistance par utilisateur (`search_history`), RLS scoping par `user_id` déjà en place (vérifié conforme, hors périmètre des corrections de ce tour).
- `getProductAvailability(String productId) → AvailabilityResult?` — même filtrage RG-AUT-04 que `search()`.
- `getGenericAlternatives(String productId) → List<Product>` — substitution par DCI, non affectée par les corrections de ce tour.

**`SearchProvider`** (nouveau getter) : `bool get isOffline` — expose l'état de dégradation gracieuse ; les écrans consommateurs (`search_results_screen.dart` etc.) peuvent l'utiliser pour afficher un bandeau "hors-ligne" au lieu de re-router entièrement l'UI — câblage de l'affichage laissé aux écrans, non modifié dans ce tour pour rester dans le périmètre strict des corrections identifiées.

---

## 6. Scénarios de test

**RG-AUT-04**
- Officine `active` avec stock > 0 sur un produit recherché → apparaît dans les résultats.
- Officine `suspended`/`rejected`/`underReview`/`pending` avec le même stock → **n'apparaît plus**.
- Recherche sans aucune officine active pour le produit → `pharmacyStocks` vide, `hasAvailableStock=false`, badge "Rupture" affiché (pas de faux positif).

**RG-REC-01**
- `PharmacyStock.lastUpdated` < 24h, stock > 0 → label reflète le niveau réel ("Disponible"/"Stock faible"/etc.).
- `lastUpdated` ≥ 24h (quel que soit le niveau de stock) → label "À confirmer", couleur ambre, y compris si stock=0 (la fraîcheur prime sur le calcul de rupture, conforme à la formulation RG-REC-01 "le statut passe automatiquement à 'à confirmer'").

**RG-REC-02**
- Toute ligne `PharmacyListTile` avec `isAvailable=true` affiche la mention "Prix indicatif" sous le prix.
- Ligne en rupture (`isAvailable=false`) : pas de prix affiché, donc pas de mention (cohérent, rien à indiquer).

**Mode hors-ligne**
- Recherche réussie initiale (résultats non vides) → coupure réseau simulée sur une recherche suivante (ex. changement de filtre déclenchant un nouvel appel) → `_results` inchangés, `_status=loaded`, `isOffline=true`, `_error` porte le message informatif (pas un throw brut).
- Première recherche de la session en échec réseau (aucun résultat préalable) → comportement inchangé : `_status=error`, écran d'erreur classique.
- Recherche réussie après une période hors-ligne → `_isOffline` repasse à `false`, message informatif effacé.

---

## 7. Livrables de ce tour

- `lib/modules/search/models/availability_result.dart` — RG-REC-01
- `lib/modules/search/widgets/pharmacy_list_tile.dart` — RG-REC-02
- `lib/modules/search/services/search_service.dart` — RG-AUT-04
- `lib/modules/search/providers/search_provider.dart` — dégradation gracieuse hors-ligne
- Ce rapport (`claude/PharmaConnect_Module2_Audit_REC.md`)

**Écarts documentés et explicitement différés** (à ne pas considérer comme oubliés) :
- RG-REC-03 (garde officielle) — bloqué par absence d'intégration externe ONP/DNPM.
- RG-CAT-02 (stupéfiant/psychotrope) — dépendance directe du Module 3 (CAT), à traiter à son tour.
- Sur-exposition RLS de `stock_movements`/`stock_adjustments` à tout utilisateur authentifié — signalé pour un futur audit du module Stock.
- Performance du scan produit en mémoire — recommandation d'optimisation, non un défaut bloquant au volume actuel.

---

**Le module Recherche & Disponibilité en temps réel (Module 2 — REC) est-il totalement clos et validé pour passer au suivant (Module 3 — CAT, Catalogue Produits & Référentiel Médicaments) ?**
