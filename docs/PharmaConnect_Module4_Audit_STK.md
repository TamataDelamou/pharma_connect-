# PharmaConnect — Audit de clôture Module 4 : Gestion des Stocks (STK)

**Date** : 29/08/2026
**Périmètre inspecté** : `lib/modules/stock/**` (models, providers, services, screens, widgets — hors `forecast_*`, voir §1.4), `lib/core/services/offline_sync_service.dart`, `supabase/migrations/20260827000600_stock.sql`, `20260827002000_staff_write_policies.sql`
**Méthodologie** : Règle d'or, registre unique des écarts (`claude/PharmaConnect_Registre_Ecarts_A_Verifier.md`), et à partir de ce module, quatre directives standing supplémentaires données par le porteur du projet : rechercher des améliorations UX à chaque module, tenir le registre à jour, **implémenter** (et non plus seulement documenter) le mode hors-ligne quand c'est raisonnable, rechercher et implémenter des fonctionnalités plus attrayantes.

---

## 1. Inspection & Rapport de situation

### 1.1 Le problème central : aucun scoping par officine

Le code lui-même documentait déjà le trou (commentaires dans `StockItem.fromJson` et `StockService`) : `stock_items.pharmacy_id` est `NOT NULL` en base, mais **aucune requête côté client ne filtrait jamais par pharmacie**. Concrètement :

- `StockService.getStockItems()` lisait le stock de **toutes les officines mélangées** dans une même liste. Un pharmacien de l'officine A voyait — et, dans l'UI, pouvait tenter d'ajuster — le stock de l'officine B.
- Plus grave : `getStockItemByProduct(productId)` utilisait `.maybeSingle()` en filtrant uniquement sur `product_id`. Le modèle multi-officines autorise explicitement plusieurs officines à stocker le même produit (contrainte unique `(pharmacy_id, product_id)`, pas `product_id` seul). Dès qu'une **deuxième** officine stocke un produit déjà stocké ailleurs — situation normale et attendue — cet appel lève une exception (PostgREST refuse `.maybeSingle()` sur plusieurs lignes). Tout ce qui en dépend (réservation, confirmation, annulation, ajustement) était donc structurellement fragile dès que le système dépasse une seule officine active.
- `transferStock(fromPharmacyId, toPharmacyId, ...)` recevait déjà ces deux paramètres mais **ne les utilisait jamais** : il décrémentait le premier stock trouvé pour le produit (potentiellement la mauvaise officine) et ne créditait **nulle part** l'officine destinataire — un transfert faisait disparaître la quantité transférée sans laisser de trace.

### 1.2 Un bug qui corrompait silencieusement les données à chaque utilisation

`stock_adjustment_screen.dart` appelait `provider.adjustStock(..., userId: 'admin', userName: 'Admin')` — littéralement codé en dur, avec un commentaire `// TODO: récupérer de l'auth`. Or `stock_movements.user_id` et `stock_adjustments.user_id` sont des colonnes `uuid references auth.users(id)`. La chaîne `'admin'` n'est pas un UUID valide : **l'insertion échouait systématiquement**, avec une exception Postgres (`invalid input syntax for type uuid`).

Le problème n'est pas seulement que l'écran affichait une erreur : `StockService.adjustStock()` modifie d'abord `stock_items.total_quantity` (réussi), puis seulement ensuite insère la ligne `stock_adjustments` (échec) — la quantité de stock était donc **déjà modifiée en base** au moment où l'exception remontait à l'écran sous la forme « Erreur lors de l'ajustement ». Un pharmacien voyant cette erreur et retentant l'opération aurait ajusté deux fois. C'est le défaut le plus sévère trouvé dans ce module : chaque ajustement de stock, depuis que cet écran existe, corrompait silencieusement la quantité affichée tout en semblant échouer.

### 1.3 Sur-lecture RLS déjà signalée (registre, item C1)

`stock_batches`/`stock_movements`/`stock_adjustments` avaient une policy `for select to authenticated using (true)` — tout compte, y compris `patient`, pouvait lire l'intégralité de ces journaux internes (notes, identifiants utilisateur, ajustements). `stock_items` reste volontairement ouvert : c'est la table que `search_service.dart` (Module 2, déjà clos) lit pour la disponibilité publique.

### 1.4 Découverte en marge : le module IA/forecasting existe, mal cartographié

`lib/modules/stock/` contient aussi `models/demand_forecast.dart`, `providers/forecast_provider.dart`, `services/forecast_service.dart`, `widgets/forecast_chart.dart`, `screens/demand_forecast_screen.dart`. Le plan modulaire de l'Étape 1 indiquait le Module 29 (IA/forecasting) comme « non entamé, dossier `forecasting` inexistant » — c'est inexact : le code existe, simplement rangé sous `stock/` plutôt que dans son propre dossier. Non audité en détail ce tour (hors périmètre strict de STK) ; signalé dans le registre (item C16) pour corriger le plan modulaire avant l'audit de ce module.

---

## 2. Analyse comparative avec le cahier de conception

| Règle | Statut avant ce module | Statut après |
|---|---|---|
| RG-STK-01 (FEFO par défaut) | Non vérifié (flaggé Étape 1) | **Vérifié conforme** — `reserveStock`/`confirmReservation` trient les lots par date de péremption croissante et consomment les plus proches en premier |
| Modèle multi-officines (fondation implicite de tout le cahier) | Non respecté en pratique côté lecture/écriture client, malgré une base de données correctement modélisée | Corrigé — toute opération est désormais scopée par `pharmacy_id` |
| Traçabilité des mouvements (prolongement de RG-AUT-03) | `user_id` codé en dur, insertion en échec systématique | Corrigé — identifiant réel de l'utilisateur authentifié |

Aucune règle de gestion nouvelle n'a été inventée : le scoping par officine applique une contrainte que le schéma imposait déjà (`pharmacy_id NOT NULL`, contrainte unique `(pharmacy_id, product_id)`) mais que le code client n'exploitait pas.

---

## 3. Sécurité & Résilience

| # | Constat | Sévérité | Statut |
|---|---|---|---|
| 1 | Aucun filtrage par officine — stock de toutes les pharmacies mélangé, écriture cross-officine possible côté client (bloquée seulement par la RLS au moment du UPDATE) | Critique | **Corrigé** |
| 2 | `.maybeSingle()` sans filtre officine — exception garantie dès la deuxième officine stockant un même produit | Critique (fiabilité) | **Corrigé** |
| 3 | `transferStock` : perte de stock silencieuse (décrément non scopé, aucun crédit destinataire) | Critique (intégrité des données) | **Corrigé** |
| 4 | `userId`/`userName` codés en dur, invalides — corruption silencieuse de `stock_items.total_quantity` à chaque ajustement, échec systématique de la traçabilité | Critique | **Corrigé** |
| 5 | `stock_batches`/`stock_movements`/`stock_adjustments` lisibles par tout authentifié, y compris patient | Élevée | **Corrigé** (RLS scopée `is_pharmacy_staff`/`is_gsg_admin`) |
| 6 | `sqlExpr(...)` inexistant dans `offline_sync_service.dart:markFailed()` — toute tentative de synchronisation échouée levait elle-même une exception | Élevée (fiabilité de l'infrastructure hors-ligne) | **Corrigé** |
| 7 | `OfflineSyncService.syncAll()` n'était déclenché nulle part dans l'application | Moyenne | Palliatif posé (déclenché après toute lecture stock réussie) — solution générale recommandée, voir §4.2 |

---

## 4. Optimisation & Améliorations

### 4.1 Mode hors-ligne — implémenté (directive standing)

Conformément à la nouvelle consigne d'implémenter le hors-ligne plutôt que seulement le documenter, et au constat de l'Étape 1 que le stock d'officine est le cas d'usage prioritaire du cahier pour l'offline-first :

- **Lecture** : `StockProvider.loadStock()`/`loadAlerts()` mettent en cache local (nouvelle table sqflite `cache_stock_items`) chaque lecture réseau réussie, et s'y replient automatiquement en cas d'échec réseau — même patron `isOffline`/message informatif déjà validé sur `SearchProvider` (Module 2), pour rester cohérent dans toute l'application.
- **Écriture** : un ajustement de stock effectué hors-ligne (`adjustStock`) est appliqué optimistiquement au cache local et mis en file d'attente via le mécanisme générique déjà existant (`sync_queue`/`OfflineSyncService.syncAll`) — trois écritures en attente (mise à jour `stock_items`, insertion `stock_adjustments`, insertion `stock_movements`), rejouées telles quelles à la reconnexion par le mécanisme déjà présent dans le projet, sans dupliquer sa logique.
- **Limite assumée** : seul l'ajustement manuel simple est couvert hors-ligne (pas de sélection de lot — cohérent avec l'écran actuel, qui n'en propose pas). Réservation, confirmation, annulation et transfert restent en ligne uniquement — signalé au registre (item C13) comme extension naturelle possible, non faite ce tour pour contenir le périmètre.
- **Un bug bloquant corrigé au passage** : `OfflineSyncService.markFailed()` appelait `sqlExpr(...)`, une fonction qui n'existe nulle part dans le projet — toute synchronisation échouée provoquait elle-même une exception. Le même bug existe dans `offline_sales_service.dart` (module hors-cahier `pos`/`sales`, non corrigé ici, déjà signalé au registre en B5).
- **`syncAll()` n'était jamais appelé nulle part dans l'app** avant ce module — corrigé a minima (déclenché en tâche de fond après toute lecture stock réseau réussie) ; un vrai listener de connectivité applicatif reste recommandé pour couvrir tous les modules hors-ligne, pas seulement STK (registre, item C14).

### 4.2 Améliorations UX (directive standing)

- **`StockSummaryCard` câblé** : ce composant existait déjà (produits, unités, alertes faible/rupture) mais n'était affiché nulle part. Intégré en en-tête de `stock_list_screen.dart` — un pharmacien a maintenant une vue d'ensemble immédiate de son inventaire sans ouvrir un écran séparé.
- **Icônes de mouvement corrigées** : les flèches de `stock_detail_screen.dart`/`stock_movements_screen.dart` étaient inversées par rapport au signe/à la couleur affichés juste à côté (texte "+X" vert avec une flèche vers le bas). Corrigé pour une lecture visuelle cohérente.
- **État vide dédié** : un pharmacien dont la candidature n'est pas encore vérifiée (`pharmacyId == null`) voyait auparavant un écran de stock vide ou mélangé sans explication. Affiche maintenant un message clair expliquant pourquoi et ce qu'il faut attendre.
- **Bandeau hors-ligne** : quand les données affichées viennent du cache local, un bandeau discret (icône + message) le signale, plutôt qu'un silence qui laisserait croire à des données fraîches.
- **Message de confirmation différencié** : un ajustement réussi en ligne et un ajustement mis en file d'attente hors-ligne affichent désormais des messages et couleurs distincts, pour que l'utilisateur sache si l'opération est déjà synchronisée ou en attente.

### 4.3 Recommandées, non appliquées

- Étendre le mode hors-ligne aux autres actions d'écriture (`reserveStock`/`confirmReservation`/`cancelReservation`/`transferStock`) — registre C13.
- Remplacer le déclenchement opportuniste de `syncAll()` par un vrai listener `connectivity_plus` au niveau applicatif — registre C14.
- Auditer `forecast_*` (Module 29 IA, mal cartographié dans le plan modulaire) — registre C16.
- `StockBatchTile`/`StockStatusChip`/`PharmacyGroup` n'ont reçu qu'une revue partielle ou nulle ce tour — registre C17.

---

## 5. Documentation API

**`StockService`** — signatures modifiées : `getStockItems`/`getStockItemByProduct`/`reserveStock`/`confirmReservation`/`cancelReservation`/`adjustStock`/`getLowStockItems`/`getOutOfStockItems`/`getExpiringBatches`/`searchStock` acceptent désormais `pharmacyId` (requis pour `getStockItemByProduct` et les opérations d'écriture, optionnel ailleurs — `null` reste une vue toutes-officines pour un futur usage back-office). Nouvelle méthode publique statique `StockService.computeStockStatus(...)` (anciennement privée). Nouvelle méthode `getStockItemsRaw(...)` (JSON brut, utilisée par le cache hors-ligne). `transferStock` crédite désormais réellement l'officine destinataire (création de la ligne `stock_items` si elle n'existait pas encore).

**`StockProvider`** — nouveau getter `bool get isOffline`. `loadStock`/`loadAlerts`/`adjustStock`/etc. acceptent `pharmacyId` ; `adjustStock` exige désormais un `userId` réel (non nullable).

**`OfflineSyncService`** — nouvelles méthodes publiques : `queueOperation(...)` (expose la primitive de file d'attente déjà existante), `cacheStockItems(...)`, `getCachedStockItems(...)`, `patchCachedStockItem(...)`. Version de base sqflite passée à 3 (nouvelle table `cache_stock_items`).

**Migration `20260829015000_stock_module_fixes.sql`** : remplace les policies `select` ouvertes de `stock_batches`/`stock_movements`/`stock_adjustments` par des policies scopées `is_pharmacy_staff`/`is_gsg_admin`.

---

## 6. Scénarios de test

**Scoping multi-officines**
- Deux officines actives stockent le même produit : un pharmacien de l'officine A ne voit que le stock de son officine dans `/stock`, `/stock/alerts`, `/stock/adjust/:id` ; `getStockItemByProduct` ne lève plus d'exception.
- Un pharmacien de l'officine A ne peut pas modifier une ligne `stock_items` appartenant à l'officine B (déjà garanti par la RLS du Module 0, non régressé).

**Transfert**
- Transfert de 10 unités de l'officine A vers l'officine B pour un produit déjà stocké dans les deux : le total de A diminue de 10, le total de B augmente de 10, deux mouvements `transfer` (un par officine) sont enregistrés.
- Même transfert vers une officine B qui n'a jamais stocké ce produit : une nouvelle ligne `stock_items` est créée pour B avec la quantité transférée.

**Traçabilité**
- Un ajustement de stock réussit désormais (ne levait plus d'exception à l'insertion) et `stock_adjustments.user_id`/`stock_movements.user_id` portent l'UUID réel de l'utilisateur authentifié, pas la chaîne `'admin'`.

**RLS lecture**
- Un compte `patient` : `SELECT` sur `stock_batches`/`stock_movements`/`stock_adjustments` ne retourne aucune ligne. `SELECT` sur `stock_items` continue de fonctionner (nécessaire à la recherche publique).

**Mode hors-ligne**
- Chargement réussi en ligne → coupure réseau simulée → nouvel ajustement : appliqué au cache local, mis en file d'attente, `isOffline == true`, message différencié affiché.
- Reconnexion → chargement réussi → `syncAll()` déclenché en tâche de fond → les trois écritures en attente apparaissent en base (stock_items à jour, stock_adjustments et stock_movements insérés). *(Non exécuté dans cette session, faute d'appareil/émulateur — voir registre, item A7.)*
- Ajustement hors-ligne sur un produit jamais chargé en ligne sur cet appareil (pas de cache) : retourne `false` avec un message explicite, plutôt que d'échouer silencieusement.

---

## 7. Livrables de ce module

- `supabase/migrations/20260829015000_stock_module_fixes.sql` (nouveau)
- `lib/core/services/offline_sync_service.dart` (modifié — bug `sqlExpr`, cache stock, `queueOperation`)
- `lib/modules/stock/models/stock_item.dart` (modifié — `pharmacyId`)
- `lib/modules/stock/services/stock_service.dart` (modifié — scoping, `transferStock`, `computeStockStatus` public)
- `lib/modules/stock/providers/stock_provider.dart` (modifié — scoping, mode hors-ligne, `isOffline`)
- `lib/modules/stock/screens/stock_list_screen.dart` (modifié — scoping, `StockSummaryCard`, bandeau hors-ligne, état vide)
- `lib/modules/stock/screens/stock_adjustment_screen.dart` (modifié — traçabilité réelle, messages différenciés)
- `lib/modules/stock/screens/stock_alerts_screen.dart` (modifié — scoping)
- `lib/modules/stock/screens/stock_detail_screen.dart` (modifié — icônes corrigées)
- `lib/modules/stock/screens/stock_movements_screen.dart` (modifié — icônes corrigées)
- Ce rapport (`claude/PharmaConnect_Module4_Audit_STK.md`)
- Registre des écarts mis à jour : B7 et B9 résolus, C1 résolu, cinq nouveaux items (C13-C17), deux nouveaux points de test à exécuter (A7-A8)

**Écarts documentés et explicitement différés** :
- Mode hors-ligne non étendu à réservation/confirmation/annulation/transfert (C13).
- `syncAll()` sans vrai listener de connectivité applicatif (C14).
- Module IA/forecasting mal cartographié dans le plan modulaire, non audité (C16).
- `StockBatchTile`/`StockStatusChip`/`PharmacyGroup` non revus en détail (C17).
- Test de bout en bout du hors-ligne sur appareil réel (A7), rejeu de file d'attente avec changement de compte (A8).

---

**Le module Gestion des Stocks (Module 4 — STK) est-il totalement clos et validé pour passer au suivant (Module 5 — ORD, Gestion des Ordonnances) ?**
