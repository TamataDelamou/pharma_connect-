# Session de cadrage — Cluster hors-cahier (`business`/`pos`/`cash`/`sales`/`returns`)

**Préparé le 20/09/2026**, en amont de la session de 30 min annoncée depuis l'audit Module 0 (28-29/08/2026) et rappelée à chaque ticket C148-C156. Objectif de la session : documenter ce cluster au même niveau que les 34 modules du cahier (objectif, écrans, règles de gestion numérotées `RG-POS-xx`/`RG-BUS-xx`), pour qu'il puisse ensuite entrer dans la séquence d'audit module-par-module normale — aujourd'hui, aucun défaut de ce cluster ne peut être confronté à une RG numérotée, contrairement aux modules cahier.

---

> **Mise à jour du 20/09/2026 — décisions D51 et D52 du porteur du projet.** Le point 2 (question centrale) et les 4 lignes du tableau du point 3 (STK, PAY, BIZ, RES/ORD) sont désormais **tous tranchés** — voir le résumé au sommet de chaque section concernée ci-dessous, et **D51**/**D52** au registre pour le texte intégral des décisions (D52 ouvre aussi **C157**/**C158** pour les deux modifications de schéma qu'elle implique). Le point 4 (écrans) et le point 5 (tables sans code) restent ouverts — c'est tout ce qui reste de cette session de cadrage. **Mise à jour du 21/09/2026** : constat des points 4 et 5 revérifié directement (lecture disque, pas la liste d'origine) — périmètre réel plus large que ce qui avait été noté (11 écrans classés par niveau de préparation réel du backend ; 13 tables sans modèle Dart, pas 4). Décisions toujours en attente du porteur du projet.

## 1. Acquis — pas à rediscuter

- Ajout volontaire confirmé par le porteur du projet, développé en parallèle de l'audit (Module 0).
- 5 dossiers : `business` (CRM B2B/institutionnel — hôpitaux, cliniques, grossistes, assurances), `pos` (point de vente/caisse officine), `cash` (gestion de caisse), `sales` (clients/fournisseurs/commandes), `returns` (retours clients/fournisseurs).
- `business` **≠** Module 9/BIZ du cahier (tableau de bord officine) — mapping erroné corrigé le 29/08. BIZ reste un module cahier séparé, clos comme non entamé le 20/09/2026 (`PharmaConnect_Module9_Audit_Cloture.md`).
- Tous les providers du cluster sont enregistrés dans `app.dart` — pas de bug « provider jamais déclaré ».
- Défauts de compilation mécaniques déjà soldés (20/09/2026) : modèles `returns` complétés (C150/C153), modèles `cash`/`sales` complétés (C154), ordre des filtres Postgrest sur `returns_service.dart` (C155, 2/3). Détail complet dans `PharmaConnect_Registre_Ecarts_A_Verifier.md`.

## 2. Question centrale de périmètre — TRANCHÉ (D51, 20/09/2026)

**Réponse retenue : option (a).** Le cluster est reconnu comme module complémentaire de vente au comptoir (« In-Store POS »), distinct et non concurrent du parcours patient réservation → paiement (`ORD`/`RES`/`PAY`). Une série `RG-POS-xx`/`RG-BUS-xx` est officiellement créée (reste à écrire) pour que ce cluster ait, comme les 34 modules du cahier, une référence contre laquelle auditer son code.

Le cahier de conception couvre déjà un parcours patient réservation → paiement (Modules `ORD`/`RES`/`PAY`, tous codés et audités). Ce cluster ajoute `pos`/`cash`/`sales`/`returns`. Deux lectures possibles, à trancher explicitement :

- **(a)** Un flux volontairement différent — vente « au comptoir » en officine, sans réservation préalable (client qui entre acheter directement), complémentaire du parcours patient existant.
- **(b)** Une reconstruction non coordonnée du même besoin, écrite sans relecture du cahier existant, qui ferait doublon.

Si (a) : le cluster mérite sa propre numérotation `RG-POS-xx` légitime, en complément du cahier. Si (b) : une partie du travail déjà écrit risque de devoir être fusionnée avec l'existant plutôt qu'intégrée telle quelle — à identifier avant d'investir davantage dessus.

## 3. Articulation avec les modules cahier déjà codés

| Point | Constat factuel | Décision à prendre |
|---|---|---|
| **STK (stock, Module 4)** — **TRANCHÉ (D51)** | `pos_service.dart` écrit directement sur `stock_batches.quantity` (même table que `StockProvider`) — stock partagé confirmé au niveau données. | Refus explicite de toute logique de mouvement de stock dupliquée par module : `pos`, `returns` et `offline_sales_service.dart` devront tous passer par l'unique procédure RPC atomique centralisée de C156 une fois écrite. La question FEFO reste néanmoins à vérifier explicitement lors de l'écriture de cette RPC. |
| **PAY (paiements, Module 8, déjà codé et audité)** — **TRANCHÉ (D52, RG-POS-01)** | Aucun lien trouvé entre `cash_movements` et la table `payments` du Module 8 — deux systèmes qui semblent ignorer l'existence l'un de l'autre. | `payments` reste le registre central de tous les flux financiers (omnicanal App + POS). Tout paiement comptoir en espèces génère une ligne `payments` (méthode = ESPÈCES/CASH) **et** une entrée `cash_movements` référençant son `payment_id`. FK optionnelle `payment_id` à ajouter dans `cash_movements` — voir **C157** (non implémenté). |
| **BIZ (Module 9, non entamé)** — **TRANCHÉ (D52, RG-BUS-01/RG-POS-02)** | Le futur tableau de bord officine (cahier) n'a aucun code ; `get_pharmacy_daily_stats()` (Module 28/BI) existe déjà comme point de départ possible. | Le futur Module 9 intégrera nativement les flux omnicanaux : numérique/réservation (ORD/RES/PAY) et comptoir/in-store (POS/CASH/SALES/RETURNS), en s'appuyant sur `payments` (CA global) et les mouvements de stock unifiés via la RPC C156. Aucun impact code immédiat — Module 9 toujours sans code ; note à reporter dans son futur audit d'ouverture. |
| **RES/ORD (réservations/ordonnances)** — **TRANCHÉ (D52, RG-POS-03)** | `sales.customers` est une table indépendante, aucune référence croisée trouvée vers les patients du parcours réservation. | `sales.customers` reste une entité autonome et distincte de `patients` (ventes anonymes, clients de passage, fidélité POS). Chaînage optionnel via un champ `patient_id` nullable ajouté à `sales.customers` : `NULL` pour une vente anonyme/passager, renseigné explicitement pour une vente rattachée à un dossier médical/ordonnance. Voir **C158** (non implémenté). |

## 4. Écrans manquants — à trancher individuellement

**Correction au constat initial (21/09/2026)** : la formulation « actuellement désactivés, route commentée » laissait entendre que ces 11 écrans existaient et étaient simplement débranchés. Vérification directe (`find` sur chaque dossier `screens/`) : **aucun des 11 fichiers d'écran n'existe sur le disque** — les imports/routes sont commentés parce que rien n'a jamais été écrit, pas parce que du code existant a été désactivé. La décision à prendre est donc « construire de zéro / différer / abandonner », pas « réintégrer ». En contrepartie, le code sous-jacent (modèle, service, provider) est loin d'être à zéro partout — vérifié fichier par fichier, classé ci-dessous par niveau de préparation réel, du moins cher au plus cher à construire :

**Niveau 1 — backend 100 % prêt (modèle + service + provider déjà complets), seul l'écran manque :**
- `CompanyCreateScreen` (business, route `company/new` + `company/edit/:id`) — `BusinessCompany`, `business_service.dart::createCompany()/updateCompany()`, `business_provider.dart::saveCompany()` tous déjà écrits et fonctionnels.
- `CashHistoryScreen` (cash) — `cash_service.dart::getSessions()` + `cash_provider.dart::loadSessions()` déjà écrits.
- `CashReportScreen` (cash) — `cash_service.dart::getCashReport()` + `cash_provider.dart::loadReport()` déjà écrits.
- `CustomerReturnDetailScreen` (returns) — `returns_service.dart`/`returns_provider.dart` : lecture + `updateCustomerReturnStatus()` déjà écrits.
- `CustomerReturnCreateScreen` (returns) — `returns_service.dart::createCustomerReturn()` + `returns_provider.dart::createCustomerReturn()` déjà écrits.

**Niveau 2 — modèle + CRUD service complets, mais le provider n'expose pas encore tout (câblage provider à compléter avant l'écran) :**
- `CustomerDetailScreen` / `CustomerCreateScreen` (sales) — `Customer`/`sales_service.dart` : CRUD complet (`getCustomer`/`createCustomer`/`updateCustomer`/`deleteCustomer`). `sales_provider.dart` n'expose que `loadCustomer`/`saveCustomer` (pas de suppression). Point de vigilance déjà signalé en C154, non corrigé : `Customer.code` non-nullable côté Dart alors que la colonne `code` n'a pas de contrainte `not null` en base — latent, se manifestera dès qu'un vrai formulaire de création sera branché dessus.
- `SuppliersListScreen` (sales) — `Supplier`/`sales_service.dart` : CRUD complet également (`getSuppliers`/`createSupplier`/`updateSupplier`/`deleteSupplier`), mais `sales_provider.dart` n'expose **aucune** méthode fournisseur — à ajouter avant l'écran.

**Niveau 3 — modèle prêt, service partiel (lecture seule), provider vide :**
- `OrdersListScreen` (sales) — `CustomerOrder`/`CustomerOrderItem` existent, `sales_service.dart::getCustomerOrders()` (liste seule, pas de création/mise à jour/suppression), rien côté provider.

**Niveau 4 — rien n'existe (ni modèle, ni service, ni provider), à construire intégralement :**
- `QuotationsListScreen` (sales) — tables `quotations`/`quotation_items` migrées, zéro code Dart.
- `InvoicesListScreen` (sales) — tables `sales_invoices`/`invoice_payments` migrées, zéro code Dart.

**TRANCHÉ (D53, 21/09/2026)** : les 11 écrans sont à construire, dans l'ordre des niveaux ci-dessus. Exécution par lots — niveau 1 en premier (aucune décision de règle métier supplémentaire requise), consignes Claude Code préparées niveau par niveau.

## 5. Tables migrées sans code Dart correspondant

**Correction au constat initial (21/09/2026)** : la liste ci-dessous ne comptait que 4 tables. Un inventaire exhaustif (toutes les migrations `business`/`cash`/`sales_management`/`returns`/`pos`, table par table, contre les fichiers `lib/modules/*/models/`) en révèle **13**, pas 4 :

- **business** (`20260829004000_business.sql`, 6 tables migrées, 2 seulement ont un modèle) : `business_kyc`, `business_contacts`, `business_activities` **et `business_pricing`** (absente de la liste initiale) — aucune n'a de modèle ni de service Dart.
- **sales** (`sales_management.sql`, 10 tables migrées, 4 seulement ont un modèle) : `quotations`, `quotation_items`, `sales_invoices`, `invoice_payments`, `supplier_orders`, `supplier_order_items` — **6 tables entièrement absentes de la liste initiale**, dont 2 (`supplier_orders`/`supplier_order_items`) qui n'ont même jamais eu d'écran prévu au point 4 ci-dessus — périmètre non couvert du tout jusqu'ici.
- **returns** (6 tables migrées, 4 ont un modèle) : `supplier_return_items` (déjà connue) **et `return_tracking`** (absente de la liste initiale).
- **pos** (4 tables migrées, 3 ont un modèle) : `pos_cash_sessions` (absente de la liste initiale et de tout le périmètre §4/§5 précédent).

**TRANCHÉ (D53, 21/09/2026)** : par défaut, documentées comme tables migrées non exploitées — pas de construction de modèle systématique. Exception mécanique, pas une dérogation à la décision : `quotations`/`sales_invoices` et leurs tables liées seront construites de facto au niveau 4 du point 4 ci-dessus.

## 6. Dette technique transposable dans la foulée (mécanique, faible coût une fois le périmètre acté)

- **C148** : boutons morts pointant vers des routes désactivées (`business`) — se résout avec la décision du point 4.
- **C149** : `company.status ?? 'pending'` / `contract.status ?? 'draft'` sur des champs non nullables (`business_service.dart`) — `??` mort, cosmétique.
- **C151** — 🟢 **résolu (21/09/2026, commit `ba8f7da`)** : `business_service.dart` corrigé à l'identique du motif C155 ; `business_provider.dart`/`business_provider_test.dart` alignés sur le motif `@visibleForTesting` déjà en usage ; `pos_provider_test.dart`, simple import manquant (pas de champ privé accédé, contrairement au constat initial ci-dessus). Découverte au passage, non corrigée : **C159** (`pos_sale.dart`, import `POSSaleItem` manquant) et **C160** (`pos_service.dart::_buildReceiptPDF()`, imports `pdf`/`intl`/`CurrencyFormatter` manquants + même motif Postgrest dans `getSales()`).
- **C156** : cible déjà tranchée (RPC atomique, `SECURITY DEFINER`) — bon moment pour rédiger la migration pendant cette session plutôt que d'ouvrir un chantier séparé, puisque le périmètre (3 fichiers : `returns_service.dart`, `pos_service.dart` ×2, `offline_sales_service.dart`) est déjà confirmé.

## 7. Sortie attendue de la session

1. Réponse au point 2 (nature du cluster — complémentaire ou doublon).
2. Décision point par point sur le point 3 (articulation STK/PAY/BIZ/RES-ORD).
3. Pour chaque écran du point 4 : construire / différer / abandonner.
4. Pour les tables du point 5 : construire le code manquant / retirer la table.
5. Une liste de règles de gestion numérotées (`RG-POS-01...`/`RG-BUS-01...`), même format que les 66 RG du cahier — c'est ce qui manque aujourd'hui pour que ce cluster puisse être audité comme un module normal plutôt que traité à part.
6. Une fois cadré : insertion dans la séquence d'audit module-par-module (après Module 29/CSR, ou plus tôt si le porteur du projet préfère).

---

**Note de méthode** : ce document consolide des constats déjà vérifiés par exécution réelle (lecture directe des fichiers, `flutter analyze`/`flutter test`, migrations SQL) au fil des correctifs C148-C156 — rien n'y est une supposition non vérifiée. Les décisions elles-mêmes (sections 2 à 5) restent entièrement au porteur du projet.
