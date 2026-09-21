# C163 — `sales/` Niveau 2 : chaînage Postgrest (`sales_service.dart`) + getters manquants (`sales_provider.dart`)

**Rédigé par :** session d'audit (Cowork). Diagnostic entièrement fait par lecture directe des fichiers (pas de `flutter`/`dart` disponible dans mon pont machine) — aucune investigation supplémentaire n'est requise avant de corriger, les emplacements ci-dessous sont donnés avec leur contenu exact avant/après.
**Destinataire :** Claude Code, exécuté localement avec `flutter`/`dart` installés.
**Date :** 21/09/2026
**Contexte :** catégorisation des 151 erreurs `flutter analyze lib/` pré-existantes sous `pos/`/`sales/` (voir `docs/PharmaConnect_Fiches_C163-C165.md`). C163 est le seul des 3 tickets ouverts dans ce lot qui soit un correctif purement mécanique, sans décision de règle métier ni construction de modèle — identique dans son principe à C151/C155/C162 (chaînage) et C161 (getters manquants), déjà validés sur ce dépôt.

---

## 0. Périmètre

2 fichiers, aucun autre :
- `lib/modules/sales/services/sales_service.dart`
- `lib/modules/sales/providers/sales_provider.dart`

Ne rien toucher d'autre. En particulier :
- Ne pas toucher `lib/modules/sales/screens/customers_list_screen.dart` — il appelle déjà `provider.isLoading`, `provider.error`, `provider.customers` correctement ; une fois les getters ajoutés au provider (section 2 ci-dessous), cet écran doit compiler sans aucune modification.
- Ne pas toucher aux imports `../models/quotation.dart` / `../models/invoice.dart` dans `sales_provider.dart`, ni au champs `_quotations`/`_invoices`, ni ajouter de getters `quotations`/`invoices` : ces deux modèles n'existent pas encore (ticket **C164**, séparé, hors périmètre de ce correctif — nécessite la construction des modèles, pas un simple ajout de getter). Les laisser strictement tels quels.
- Ne pas ajouter de nouvelle méthode au provider ou au service (pas de `deleteCustomer`, pas de méthodes fournisseurs/commandes côté provider) : ce ticket corrige uniquement ce qui est décrit ci-dessous, pas un complément fonctionnel.

## 1. `lib/modules/sales/services/sales_service.dart` — chaînage Postgrest (même motif que C151/C155/C162)

Même défaut que déjà corrigé 3 fois sur ce dépôt : `.order()` est appelé sur le query builder **avant** les filtres `.eq()`/`.or()`, alors que `.order()` retourne un `PostgrestTransformBuilder` qui n'expose plus ces méthodes ensuite. 3 occurrences dans ce fichier.

**`getCustomers()` :**

Avant :
```dart
      var query = _client
          .from('customers')
          .select()
          .order('created_at', ascending: false);

      if (pharmacyId != null) {
        query = query.eq('pharmacy_id', pharmacyId);
      }
      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }
      if (search != null && search.isNotEmpty) {
        query = query.or(
          'first_name.ilike.%$search%,'
          'last_name.ilike.%$search%,'
          'code.ilike.%$search%,'
          'phone.ilike.%$search%',
        );
      }

      final response = await query;
```

Après :
```dart
      var query = _client
          .from('customers')
          .select();

      if (pharmacyId != null) {
        query = query.eq('pharmacy_id', pharmacyId);
      }
      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }
      if (search != null && search.isNotEmpty) {
        query = query.or(
          'first_name.ilike.%$search%,'
          'last_name.ilike.%$search%,'
          'code.ilike.%$search%,'
          'phone.ilike.%$search%',
        );
      }

      final response = await query.order('created_at', ascending: false);
```

**`getSuppliers()` :** même correction, avec `.order('name', ascending: true)`.

Avant :
```dart
      var query = _client
          .from('suppliers')
          .select()
          .order('name', ascending: true);

      if (pharmacyId != null) {
        query = query.eq('pharmacy_id', pharmacyId);
      }
      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }
      if (search != null && search.isNotEmpty) {
        query = query.or(
          'name.ilike.%$search%,'
          'code.ilike.%$search%,'
          'contact_person.ilike.%$search%',
        );
      }

      final response = await query;
```

Après :
```dart
      var query = _client
          .from('suppliers')
          .select();

      if (pharmacyId != null) {
        query = query.eq('pharmacy_id', pharmacyId);
      }
      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }
      if (search != null && search.isNotEmpty) {
        query = query.or(
          'name.ilike.%$search%,'
          'code.ilike.%$search%,'
          'contact_person.ilike.%$search%',
        );
      }

      final response = await query.order('name', ascending: true);
```

**`getCustomerOrders()` :** même correction, avec `.order('order_date', ascending: false)`. Attention, ici le `.select()` porte un argument (embed Supabase) — ne pas le perdre.

Avant :
```dart
      var query = _client
          .from('customer_orders')
          .select('*, customers:customer_id(first_name, last_name)')
          .order('order_date', ascending: false);

      if (pharmacyId != null) {
        query = query.eq('pharmacy_id', pharmacyId);
      }
      if (customerId != null) {
        query = query.eq('customer_id', customerId);
      }
      if (status != null) {
        query = query.eq('status', status.name);
      }

      final response = await query;
```

Après :
```dart
      var query = _client
          .from('customer_orders')
          .select('*, customers:customer_id(first_name, last_name)');

      if (pharmacyId != null) {
        query = query.eq('pharmacy_id', pharmacyId);
      }
      if (customerId != null) {
        query = query.eq('customer_id', customerId);
      }
      if (status != null) {
        query = query.eq('status', status.name);
      }

      final response = await query.order('order_date', ascending: false);
```

Ne rien changer d'autre dans ce fichier (en particulier, ne pas toucher aux imports en tête de fichier, même si 3 d'entre eux — `quotation.dart`, `invoice.dart`, `supplier_order.dart` — sont actuellement orphelins : c'est C164, séparé).

## 2. `lib/modules/sales/providers/sales_provider.dart` — getters manquants (même anti-pattern que C161)

Le fichier actuel contient un unique commentaire `// Getters...` à la place de tout accesseur public, alors que tous les champs d'état sont privés :

```dart
  List<Customer> _customers = [];
  Customer? _selectedCustomer;
  List<Supplier> _suppliers = [];
  Supplier? _selectedSupplier;
  List<CustomerOrder> _customerOrders = [];
  CustomerOrder? _selectedCustomerOrder;
  List<Quotation> _quotations = [];
  List<Invoice> _invoices = [];
  bool _isLoading = false;
  String? _error;

  // Getters...
```

Remplacer la ligne `  // Getters...` par (ne toucher à rien d'autre, en particulier laisser `_quotations`/`_invoices` sans getter — voir périmètre ci-dessus) :

```dart
  List<Customer> get customers => _customers;
  Customer? get selectedCustomer => _selectedCustomer;
  List<Supplier> get suppliers => _suppliers;
  Supplier? get selectedSupplier => _selectedSupplier;
  List<CustomerOrder> get customerOrders => _customerOrders;
  CustomerOrder? get selectedCustomerOrder => _selectedCustomerOrder;
  bool get isLoading => _isLoading;
  String? get error => _error;
```

Ces 8 noms de getters sont imposés par l'usage déjà existant dans `customers_list_screen.dart` (`provider.isLoading`, `provider.error`, `provider.customers`) — ne pas en changer l'orthographe. Les 4 getters `selectedCustomer`/`suppliers`/`selectedSupplier`/`customerOrders`/`selectedCustomerOrder` ne sont consommés par aucun écran existant aujourd'hui, mais correspondent 1:1 aux champs privés déjà présents dans la classe : les exposer maintenant évite une régression identique le jour où `SuppliersListScreen`/`CustomerDetailScreen` (niveau 2, D53) seront construits.

Aucun setter `@visibleForTesting` n'est nécessaire : il n'existe pas de fichier `test/unit/providers/sales_provider_test.dart` dans le dépôt à ce jour (vérifié) — si `flutter analyze`/`flutter test` en révèle un après cet ajout, ne pas improviser, le consigner en section 6 ci-dessous.

## 3. Vérification et commit

1. `flutter analyze lib/modules/sales/services/sales_service.dart lib/modules/sales/providers/sales_provider.dart lib/modules/sales/screens/customers_list_screen.dart`
2. Puis `flutter analyze lib/` et `flutter test` complets, pour confirmer qu'aucune régression n'a été introduite ailleurs et obtenir le nouveau total (dernier connu : 151 erreurs restantes, dont 51 sous `sales/` — ce correctif doit en réduire une partie, sans viser 0 : `sales_service.dart` garde ses 3 imports orphelins C164, et `sales_provider.dart`/`customers_list_screen.dart` peuvent encore porter des erreurs non liées à C163 si `flutter analyze` en révèle).
3. Un seul commit, fichiers listés explicitement (pas de `git add -A`) :
   `fix(sales): correct Postgrest filter chaining and provider getters (C163)`

## 4. Décisions de règle métier remontées (à remplir par Claude Code en cours de route)

*(Section à compléter uniquement si un point de règle métier apparaît en cours de correctif — ne pas trancher, décrire et attendre l'arbitrage du porteur du projet.)*

---

**Rapport attendu en retour :** confirmation du diff appliqué (ou explication précise si un point ne correspond pas à ce qui est décrit ci-dessus), + nombre d'erreurs `flutter analyze lib/` avant/après (global, et si possible détail du foyer `sales`), + résultat `flutter test`. Je mets à jour le registre (C163 → résolu) une fois ce retour vérifié.
