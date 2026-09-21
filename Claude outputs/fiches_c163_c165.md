# Fiches d'incidents légères — Catégorisation des 151 erreurs `flutter analyze lib/` pré-existantes

**Périmètre :** `lib/modules/pos/` (91 erreurs) et `lib/modules/sales/` (51 erreurs), soit 142 des 151 erreurs pré-existantes (les 9 restantes — `cash_dashboard_screen.dart` 5, `returns` 2, `business` 1, `offline_sales_service.dart` 1 — sont hors périmètre de cette action, déjà notées au registre).
**Méthode :** lecture directe de tous les fichiers concernés (pas de `flutter analyze` disponible côté audit) ; chaque constat ci-dessous a été vérifié fichier par fichier, pas seulement estimé.
**Résultat :** aucun correctif appliqué à ce stade — catégorisation et ouverture de tickets uniquement, conformément à la demande.

---

## `pos/` (91 erreurs) — aucun nouveau ticket, entièrement pré-couvert

Pas de découpage par niveau ici : `pos/` n'entre pas dans les niveaux D53 (ses écrans existent déjà). Tout le foyer se réduit à un seul fichier fautif.

| Thématique | Fichier | Ticket | Statut |
|---|---|---|---|
| Imports PDF/intl/CurrencyFormatter manquants + chaînage Postgrest (`getSales()`) | `pos_service.dart` | **C160** (existant, complété ce jour) | Ouvert, non corrigé |
| `sqlExpr()` inexistant (×2 : `_updateStock`, `refundSale`) | `pos_service.dart` | **C156** (existant) | Ouvert, en attente de l'architecture RPC (D51) |

**Complément vérifié aujourd'hui, ajouté à C160** : le paquet `pdf` est absent à la fois de `pubspec.yaml` et de `pubspec.lock` — ni dépendance directe ni transitive. Contrairement à `intl` (présent en transitif, utilisable dès l'ajout de l'import), la correction de C160 nécessitera un `flutter pub add pdf` avant que l'import puisse seulement se résoudre. Autre détail ajouté : `Uint8List` (type de retour de `_buildReceiptPDF()`) manque aussi son import (`dart:typed_data`).

**Reste du module, vérifié sain** (aucun défaut trouvé, aucun ticket à ouvrir) : les 8 écrans `pos/` (appels provider tous conformes à l'API réelle de `POSProvider`), `offline_pos_provider.dart` (6 méthodes appelées, toutes vérifiées contre `OfflineSalesService`), `offline_pos_indicator.dart`, `pos_sale.dart` (hors l'import déjà connu C159), `pos_receipt.dart`, `pos_sale_item.dart`.

---

## `sales/` (51 erreurs) — 3 nouveaux tickets (C163, C164, C165)

### Niveau 2 concerné (clients/fournisseurs)

**C163 — `sales_service.dart` (chaînage Postgrest) + `sales_provider.dart` (getters manquants)**

- `sales_service.dart` : motif déjà connu C151/C155/C162 — `.order()` appelé avant les filtres, 3 fois (`getCustomers`, `getSuppliers`, `getCustomerOrders`).
- `sales_provider.dart` : même anti-pattern que C161 avant correction — un commentaire `// Getters...` sans aucun accesseur public réel, alors que `customers_list_screen.dart` appelle déjà `provider.isLoading` / `provider.error` / `provider.customers` (5 sites d'usage, tous en erreur `undefined_getter`).
- Modèle `Customer` vérifié sain.
- Correctif : mécanique, même patron que C151 + C161, aucune décision de règle métier nécessaire.

### Niveaux ultérieurs (commandes/devis/factures)

**C164 — Modèles `Quotation`/`Invoice`/`SupplierOrder` inexistants**

- `sales_service.dart` et `sales_provider.dart` importent 3 fichiers modèles qui n'existent pas sous `lib/modules/sales/models/` (un `invoice.dart` existe, mais dans `payments/`, mauvais module).
- `sales_service.dart` s'arrête explicitement à `getCustomerOrders()`, suivi de `// Continue with order creation, quotations, invoices, supplier orders...` — rien n'a jamais été codé au-delà.
- Cohérent avec D53 §4/§5 (niveaux 3-4 et tables orphelines déjà actées comme à construire plus tard).
- Pas de correctif mécanique possible : nécessite la construction des modèles + CRUD, à traiter avec la préparation des niveaux 3-4.

### Hors périmètre niveaux (cluster IA, Module 11 / D48)

**C165 — Cluster IA : 4 modèles inexistants + getters manquants + paramètre non conforme**

- `sales_ai_provider.dart`, `sales_ai_service.dart`, `demand_prediction_chart.dart` importent `demand_prediction.dart` / `price_recommendation.dart` / `fraud_alert.dart` / `product_recommendation.dart` — aucun n'existe. `sales_ai_service.dart` (265 lignes) est construit quasi entièrement autour de ces types : c'est très probablement la plus grosse concentration d'erreurs du foyer `sales`.
- Même anti-pattern getters manquants que C161/C163 sur `sales_ai_provider.dart`.
- `sales_ai_service.dart::predictDemand()` : paramètre nommé `String productName` sans `required` ni valeur par défaut — erreur de compilation indépendante.
- Ne relève pas des niveaux D53 (clients → factures) : c'est la frontière Module 11/D48 (prévision de demande par IA), un chantier à part. Aucun écran autre que `demand_prediction_chart.dart` ne semble le consommer actuellement (non vérifié exhaustivement).
- Pas de correctif mécanique : nécessite soit la construction du modèle IA complet, soit une décision du porteur du projet sur le périmètre réel de ce module avant d'investir dedans.

---

## Point de vigilance non ticketé (rappel, déjà connu avant cette session)

`Customer.code` est un `String` non-nullable en Dart alors que la colonne `code` en base autorise le null (constat C154, jamais isolé en ticket propre) — pas une erreur `flutter analyze` (ce n'est pas un défaut statique), mais un risque de crash runtime si une ligne `customers` a `code IS NULL`. Signalé ici pour mémoire, pas d'action proposée sans arbitrage.
