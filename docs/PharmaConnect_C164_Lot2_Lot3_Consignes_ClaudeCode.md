# C164 — Lots 2/3 : Provider `SalesProvider` + écrans Niveaux 3-4 (D53)

**Rédigé par :** session d'audit (Cowork), 26/09/2026.
**Destinataire :** Claude Code, dépôt `pharma_connect`, sur `main` (état actuel : lot 1/3 déjà réconcilié — `sales_service.dart` a le CRUD complet Customer/Supplier/CustomerOrder/Quotation/SalesInvoice/InvoicePayment, vérifié par lecture directe).
**Rappel de périmètre (D53, déjà confirmé, ne pas redécider) :** Niveau 3 = commandes **clients** uniquement (`OrdersListScreen` sur `CustomerOrder`) ; Niveau 4 = devis (`Quotation`) + factures de vente (`SalesInvoice`). Commandes fournisseurs hors périmètre. Confirmé aussi par lecture directe de `lib/routes/app_router.dart` : seules 3 routes de **liste** sont stubées en commentaire (`/sales/orders`, `/sales/quotations`, `/sales/invoices`) — aucune route de détail ni de création n'existe pour ces 3, contrairement au cluster `returns/` (niveau 1) qui en a. Ce lot construit donc 3 écrans de liste en lecture seule, pas de formulaires de création ni d'écrans de détail séparés — cohérent avec le cadrage d'origine (`PharmaConnect_Cadrage_Cluster_HorsCahier.md`).

**Point de blocage actuel confirmé par lecture directe :** `lib/modules/sales/providers/sales_provider.dart` importe encore `../models/invoice.dart` (fichier qui n'existe plus, renommé `sales_invoice.dart`/`SalesInvoice` lors du lot 1) — **le module ne compile pas actuellement**. Prioriser ce correctif avant tout le reste.

---

## Lot 2/3 — `lib/modules/sales/providers/sales_provider.dart`

Réécrire le fichier en conservant tout ce qui existe déjà (customers, suppliers déclarés mais jamais chargés, getters existants) et en complétant selon le motif déjà établi et vérifié dans `lib/modules/returns/providers/returns_provider.dart` (à relire avant de commencer — mêmes conventions : `_isLoading`/`_error` partagés, `notifyListeners()` avant/après chaque appel service, `try/catch` avec `_error = e.toString()`, insertion en tête de liste après création, remplacement par index après mise à jour, `clearError()`).

1. **Corriger l'import** : `import '../models/invoice.dart';` → `import '../models/sales_invoice.dart';`. Ajouter aussi `import '../models/quotation.dart';` (déjà présent), `import '../models/invoice_payment.dart';`.
2. **Suppliers** — ajouter, sur le modèle exact de `loadCustomers`/`loadCustomer`/`saveCustomer` déjà présents pour `Customer` : `loadSuppliers({String? pharmacyId, String? search})`, `loadSupplier(String id)`, `saveSupplier(Supplier supplier)` (créer si `id.isEmpty || id.startsWith('temp_')`, sinon mettre à jour — même motif que `saveCustomer`).
3. **Commandes clients (`CustomerOrder`)** — ajouter `_selectedCustomerOrder` est déjà déclaré (getter présent) : `loadCustomerOrders({String? pharmacyId, String? customerId, CustomerOrderStatus? status})`, `loadCustomerOrder(String id)`, `createCustomerOrder(CustomerOrder order)` (retourne `bool`, motif `createCustomerReturn`), `updateCustomerOrder(CustomerOrder order)` (retourne `bool`), `deleteCustomerOrder(String id)` (retire de la liste locale après succès).
4. **Devis (`Quotation`)** — ajouter les champs `List<Quotation> _quotations = []` / `Quotation? _selectedQuotation` (remplacer le `_quotations`/`_invoices` existants qui n'ont pas de getter), getters `quotations`/`selectedQuotation`, puis `loadQuotations({String? pharmacyId, String? customerId, QuotationStatus? status})`, `loadQuotation(String id)`, `createQuotation`, `updateQuotation`, `deleteQuotation` — même motif.
5. **Factures de vente (`SalesInvoice`)** — champs `List<SalesInvoice> _salesInvoices = []` / `SalesInvoice? _selectedSalesInvoice`, getters `salesInvoices`/`selectedSalesInvoice`, puis `loadSalesInvoices({String? pharmacyId, String? customerId, SalesInvoiceStatus? status})`, `loadSalesInvoice(String id)`, `createSalesInvoice`, `updateSalesInvoice`, `deleteSalesInvoice`.
6. **Paiements de facture (`InvoicePayment`)** — champ `List<InvoicePayment> _invoicePayments = []`, getter `invoicePayments`, `loadInvoicePayments(String invoiceId)`, `createInvoicePayment(InvoicePayment payment)` (retourne `bool`). **Ne pas** faire recalculer `paidAmount`/`status` de la facture par le provider — point de règle métier explicitement non tranché depuis le lot 1 (cf. registre), ne pas l'inventer ici non plus.
7. **`clearSelected()`** — ajouter une méthode qui remet à `null` `_selectedSupplier`, `_selectedCustomerOrder`, `_selectedQuotation`, `_selectedSalesInvoice` (même motif que `ReturnsProvider.clearSelected()`), plus `clearError()` si absente.

Ne rien renommer d'existant (`customers`, `selectedCustomer`, `saveCustomer`, etc.) — uniquement compléter.

---

## Lot 3/3 — 3 écrans de liste + routes

Créer 3 fichiers dans `lib/modules/sales/screens/`, sur le modèle exact de `lib/modules/returns/screens/customer_returns_list_screen.dart` (déjà vérifié sain, à relire avant de commencer) : en-tête avec retour + titre + `KernelBadge()`, `provider.isLoading` → `CircularProgressIndicator`, `provider.error` → message + bouton réessayer, liste vide → message centré avec icône, sinon `ListView.builder` de `Padding(bottom: 8, child: GlassCard(...))` (jamais de `margin:` sur `GlassCard`, cf. C166). **Aucune de ces 3 routes n'a de route de détail associée dans `app_router.dart`** — ne pas ajouter de `onTap` qui naviguerait vers une route inexistante ; à la place, afficher le détail utile directement dans la carte (voir ci-dessous), ou via un `showModalBottomSheet` local à l'écran si plus de détail est nécessaire — pas de nouvelle route.

### `orders_list_screen.dart` (`OrdersListScreen`)
- Charge au `initState` via `context.read<SalesProvider>().loadCustomerOrders(pharmacyId: 'default_pharmacy')` (même motif `pharmacyId` que les autres écrans du cluster).
- Carte par commande : `order.orderNumber`, badge de statut coloré (`order.status.label`, couleur par `switch` sur `CustomerOrderStatus` — mêmes teintes que `_statusColor` de `ReturnStatus` dans le fichier retours, adapter les 6 valeurs : `draft`→gris, `confirmed`→cyan, `preparing`→orange, `ready`→violet ou cyan clair, `delivered`→vert, `cancelled`→rouge), `order.customerName ?? 'Client'`, montant via `CurrencyFormatter.format(order.totalAmount)`, et si `order.remainingAmount > 0` afficher aussi le reste dû en petit texte secondaire.
- Titre d'écran : `'📦 Commandes clients'`.

### `quotations_list_screen.dart` (`QuotationsListScreen`)
- `context.read<SalesProvider>().loadQuotations(pharmacyId: 'default_pharmacy')`.
- Carte par devis : `quotation.quotationNumber`, badge `quotation.status.label` (couleurs par `QuotationStatus` : `draft`→gris, `sent`→cyan, `accepted`→vert, `rejected`→rouge, `expired`→orange), `quotation.customerName ?? 'Client'`, `CurrencyFormatter.format(quotation.totalAmount)`, et si `quotation.validUntil != null` afficher la date de validité en texte secondaire.
- Titre d'écran : `'📄 Devis'`.

### `invoices_list_screen.dart` (`InvoicesListScreen`)
- `context.read<SalesProvider>().loadSalesInvoices(pharmacyId: 'default_pharmacy')`.
- Carte par facture : `invoice.invoiceNumber`, badge `invoice.status.label` (couleurs par `SalesInvoiceStatus` : `draft`→gris, `sent`→cyan, `paid`→vert, `overdue`→rouge, `cancelled`→gris foncé), `invoice.customerName ?? 'Client'`, `CurrencyFormatter.format(invoice.totalAmount)`, et si `!invoice.isPaid` afficher `CurrencyFormatter.format(invoice.remainingAmount)` restant dû en rouge/orange.
- Titre d'écran : `'🧾 Factures de vente'`.

### Routes (`lib/routes/app_router.dart`)

Décommenter uniquement les 3 imports et les 3 `GoRoute` déjà stubés (lignes ~240-244 pour les imports, ~1543-1559 pour les routes) :
```dart
import '../modules/sales/screens/orders_list_screen.dart';
import '../modules/sales/screens/quotations_list_screen.dart';
import '../modules/sales/screens/invoices_list_screen.dart';
```
```dart
GoRoute(
  path: '/sales/orders',
  name: 'sales-orders',
  builder: (context, state) => const OrdersListScreen(),
),
GoRoute(
  path: '/sales/quotations',
  name: 'sales-quotations',
  builder: (context, state) => const QuotationsListScreen(),
),
GoRoute(
  path: '/sales/invoices',
  name: 'sales-invoices',
  builder: (context, state) => const InvoicesListScreen(),
),
```
Ne pas toucher aux routes `sales-customer-new`/`sales-customer-detail`/`sales-suppliers` (Niveau 2, toujours hors périmètre de ce lot — écrans pas encore construits).

---

## Vérification

1. `flutter analyze lib/` — donner le total exact (dernier connu sur `main` après D54/C174 : à redemander si non gardé en mémoire, ne pas supposer 629).
2. Confirmer par une recherche (`grep -rn "models/invoice.dart" lib/`) qu'aucun fichier ne référence plus l'ancien `invoice.dart`.
3. `flutter test` — donner le résultat exact, comparer au dernier total connu (71 passés / 24 échoués).
4. Un commit pour le lot 2 (`fix(sales): wire SalesProvider to supplier/order/quotation/invoice CRUD (C164 lot 2/3)`), un commit pour le lot 3 (`feat(sales): add read-only list screens for orders/quotations/invoices + routes (C164 lot 3/3)`).

## Registre

Mettre à jour l'entrée C164 pour indiquer les lots 2/3 exécutés et vérifiés, avec les hash de commit. Je vérifie par lecture directe (`git show`) avant de considérer C164 clos dans son ensemble.

## Rapport attendu

Hash des 2 commits, confirmation de la disparition de l'import `invoice.dart`, `flutter analyze lib/` avant/après, `flutter test` avant/après, et toute décision de règle métier rencontrée en cours de route à signaler sans trancher (notamment si un cas imprévu apparaît sur le calcul `paidAmount`/`remainingAmount`).
