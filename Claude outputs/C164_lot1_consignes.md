# C164 (rectifié) — Lot 1/3 : Modèles + Services CRUD pour Devis (`Quotation`) et Factures de vente (`SalesInvoice`), complétion `CustomerOrder`

**Rédigé par :** session d'audit (Cowork). Diagnostic et schéma vérifiés par lecture directe des migrations Supabase (`supabase/migrations/20260829008000_sales_management.sql`) et des modèles déjà existants (`customer_order.dart`, `customer_return.dart`/`returns_service.dart` comme patrons établis) — pas de `flutter`/`dart` disponible dans mon pont machine, mais le diagnostic ne nécessitait pas de l'exécuter.
**Destinataire :** Claude Code, exécuté localement avec `flutter`/`dart` installés.
**Date :** 21/09/2026
**Contexte :** rectification actée avec le porteur du projet — **les commandes fournisseurs (`supplier_orders`) restent hors périmètre** (tables orphelines, non exploitées par défaut, décision D53 inchangée). Ce lot couvre uniquement : (1) les devis (`quotations`/`quotation_items`), (2) les factures de vente (`sales_invoices`/`invoice_payments`), (3) la complétion CRUD des commandes clients (`customer_orders`/`customer_order_items`, modèle déjà existant, service en lecture seule jusqu'ici — niveau 3 du cadrage D53).

**Découverte importante lors de la vérification du schéma, à respecter impérativement** : la table `sales_invoices` s'appelait à l'origine `invoices`, renommée lors d'un audit antérieur (Module 19/INF, ticket C83, voir le commentaire en tête de la table dans la migration) précisément pour éviter une collision avec `public.invoices`, une table totalement différente déjà consommée par `lib/modules/payments/models/invoice.dart` (`class Invoice`, reçu de transaction patient — rien à voir avec une facture de vente B2B). **Le modèle Dart pour `sales_invoices` doit donc s'appeler `SalesInvoice`, pas `Invoice`** — reprendre le nom générique `Invoice` recréerait exactement la confusion que ce renommage visait à éviter, même si techniquement les deux classes vivent dans des fichiers différents. Les références existantes à `Invoice`/`invoice.dart` dans `sales_service.dart` et `sales_provider.dart` (jamais compilées jusqu'ici, donc rien de cassé) sont à renommer en conséquence — voir sections 2 et 4.

---

## 0. Périmètre de ce lot (1/3)

Ce lot ne touche QUE les modèles et le service. **Ne pas toucher** à `sales_provider.dart` (lot 2) ni créer d'écran ou de route (lot 3) — ces deux lots suivront une fois ce lot-ci vérifié, même principe que D53 niveau 1 (construction par lots, chacun vérifié avant le suivant).

Fichiers à créer :
- `lib/modules/sales/models/quotation.dart`
- `lib/modules/sales/models/quotation_item.dart`
- `lib/modules/sales/models/sales_invoice.dart`
- `lib/modules/sales/models/invoice_payment.dart`

Fichier à modifier :
- `lib/modules/sales/services/sales_service.dart`

Ne rien toucher d'autre — en particulier ne pas renommer/supprimer `lib/modules/payments/models/invoice.dart` (module différent, aucun rapport, ne pas y toucher).

## 1. Nouveaux modèles

Suivre exactement la structure déjà en place dans `lib/modules/sales/models/customer_order.dart` (`Equatable`, `copyWith`, `toJson`, `fromJson`, enum de statut avec extension `label`/`icon`) — même style, mêmes conventions de nommage (camelCase Dart ↔ snake_case JSON), champs dérivés (`items`, `customerName`) inclus volontairement dans `toJson()` avec la même note de commentaire que `CustomerOrder`, à charge du service de les retirer avant insert/update (motif déjà établi, voir section 2).

### 1.1 `lib/modules/sales/models/quotation.dart`

Schéma réel (`public.quotations`, migration `20260829008000_sales_management.sql`) :
```sql
create table public.quotations (
  id uuid primary key default gen_random_uuid(),
  pharmacy_id uuid not null references public.pharmacies(id) on delete cascade,
  customer_id uuid references public.customers(id) on delete set null,
  quotation_number text unique not null,
  quotation_date timestamptz not null default now(),
  valid_until date,
  total_amount integer not null,
  status text not null check (status in ('draft', 'sent', 'accepted', 'rejected', 'expired')),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);
```

Construire `Quotation` avec exactement ces champs (types Dart en miroir : `uuid`/`text` → `String`, `text?`/`uuid?` → `String?`, `timestamptz` → `DateTime`, `date` nullable → `DateTime?`, `integer` → `int`), plus les 2 champs dérivés `List<QuotationItem>? items` et `String? customerName` (comme `CustomerOrder`). Ajouter un enum `QuotationStatus { draft, sent, accepted, rejected, expired }` avec une extension `QuotationStatusExtension` exposant `label` (texte + emoji, même esprit que `CustomerOrderStatusExtension` — libre choix des emojis, cohérents avec le reste de l'app) et `icon`. Constructeur, `copyWith`, `toJson` (avec `status.name`, `items`/`customer_name` inclus conditionnellement comme `CustomerOrder.toJson()`), `fromJson` (avec `CustomerOrder.fromJson()` comme modèle pour la reconstruction de `customerName` depuis un embed `customers:customer_id(first_name,last_name)` et le parsing de `items` si présent — copier ce bloc de logique tel quel, en l'adaptant à `QuotationItem`), `props`.

### 1.2 `lib/modules/sales/models/quotation_item.dart`

Schéma réel (`public.quotation_items`) :
```sql
create table public.quotation_items (
  id uuid primary key default gen_random_uuid(),
  quotation_id uuid not null references public.quotations(id) on delete cascade,
  product_id uuid references public.products(id) on delete set null,
  product_name text not null,
  quantity integer not null,
  unit_price integer not null,
  total_price integer not null,
  notes text,
  created_at timestamptz not null default now(),
  gsg_id text,
  gsg_org_id text
);
```

Structure identique à `lib/modules/sales/models/customer_order_item.dart` (déjà dans le dépôt, sert de patron exact — mêmes champs, juste `orderId` → `quotationId`). Le copier et l'adapter par recherche-remplacement mécanique (`CustomerOrderItem` → `QuotationItem`, `orderId`/`order_id` → `quotationId`/`quotation_id`).

### 1.3 `lib/modules/sales/models/sales_invoice.dart`

Schéma réel (`public.sales_invoices`) :
```sql
create table public.sales_invoices (
  id uuid primary key default gen_random_uuid(),
  pharmacy_id uuid not null references public.pharmacies(id) on delete cascade,
  customer_id uuid references public.customers(id) on delete set null,
  sale_id uuid references public.pos_sales(id) on delete set null,
  invoice_number text unique not null,
  invoice_date timestamptz not null default now(),
  due_date date,
  total_amount integer not null,
  paid_amount integer default 0,
  status text not null check (status in ('draft', 'sent', 'paid', 'overdue', 'cancelled')),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  gsg_id text,
  gsg_org_id text
);
```

Classe **`SalesInvoice`** (pas `Invoice` — voir l'avertissement en tête de document). Champs en miroir exact du schéma (`saleId` optionnel, `paidAmount` avec défaut `0` comme `CustomerOrder.paidAmount`), plus champ dérivé `String? customerName` (même motif d'embed que `Quotation`/`CustomerOrder` — pas de champ `items`, une facture n'a pas de lignes dans ce schéma, seulement des paiements liés séparément). Enum `SalesInvoiceStatus { draft, sent, paid, overdue, cancelled }` avec extension `label`/`icon`. Ajouter, comme `CustomerOrder`, deux getters calculés :
```dart
  int get remainingAmount => totalAmount - paidAmount;
  bool get isPaid => paidAmount >= totalAmount;
```
Constructeur, `copyWith`, `toJson`, `fromJson`, `props` — même style que les autres modèles de ce module.

### 1.4 `lib/modules/sales/models/invoice_payment.dart`

Schéma réel (`public.invoice_payments`) :
```sql
create table public.invoice_payments (
  id uuid primary key default gen_random_uuid(),
  invoice_id uuid not null references public.sales_invoices(id) on delete cascade,
  amount integer not null,
  payment_date timestamptz not null default now(),
  payment_method text not null check (payment_method in ('cash', 'mobile_money', 'card', 'bank_transfer')),
  reference text,
  notes text,
  created_at timestamptz not null default now(),
  gsg_id text,
  gsg_org_id text
);
```

**Important : `paymentMethod` reste un `String`, pas un enum.** C'est la convention déjà utilisée ailleurs dans ce module pour ce même concept (`POSSale.paymentMethod`, `lib/modules/pos/models/pos_sale.dart` — commentaire `// cash, mobile_money, card, insurance, credit`, type `String`) — rester cohérent avec l'existant plutôt que d'introduire un nouveau style pour la même notion. Classe `InvoicePayment` avec les champs en miroir exact (`invoiceId`, `amount`, `paymentDate`, `paymentMethod` en `String`, `reference` optionnel, `notes` optionnel, `createdAt`, `gsgId`/`gsgOrgId` optionnels). Constructeur, `copyWith`, `toJson`, `fromJson`, `props`.

## 2. `lib/modules/sales/services/sales_service.dart` — compléter le CRUD

### 2.1 Imports

Remplacer le bloc d'imports actuel :
```dart
import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:uuid/uuid.dart';
import '../models/customer.dart';
import '../models/supplier.dart';
import '../models/customer_order.dart';
import '../models/customer_order_item.dart';
import '../models/quotation.dart';
import '../models/invoice.dart';
import '../models/supplier_order.dart';
```
par :
```dart
import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:uuid/uuid.dart';
import '../models/customer.dart';
import '../models/supplier.dart';
import '../models/customer_order.dart';
import '../models/customer_order_item.dart';
import '../models/quotation.dart';
import '../models/quotation_item.dart';
import '../models/sales_invoice.dart';
import '../models/invoice_payment.dart';
```
(`../models/invoice.dart` → `../models/sales_invoice.dart` + ajout de `quotation_item.dart`/`invoice_payment.dart` ; **suppression pure et simple de `../models/supplier_order.dart`**, hors périmètre — ce fichier `supplier_order.dart` n'est ni créé ni référencé nulle part dans ce lot).

### 2.2 Compléter les commandes clients (`customer_orders`)

Le fichier a aujourd'hui uniquement `getCustomerOrders()` (lecture liste, corrigée en C163). Ajouter, juste après cette méthode :

```dart
  Future<CustomerOrder?> getCustomerOrder(String id) async {
    try {
      final response = await _client
          .from('customer_orders')
          .select('*, customers:customer_id(first_name, last_name)')
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return CustomerOrder.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load customer order: $e');
    }
  }

  Future<CustomerOrder> createCustomerOrder(CustomerOrder order) async {
    try {
      final now = DateTime.now().toUtc();
      final id = _uuid.v4();
      final data = order
          .copyWith(
            id: id,
            createdAt: now,
            updatedAt: now,
            createdBy: SupabaseService().currentUser?.id,
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      data.removeWhere((key, value) => key == 'items' || key == 'customer_name');

      final response = await _client
          .from('customer_orders')
          .insert(data)
          .select()
          .single();

      if (order.items != null) {
        for (final item in order.items!) {
          await _createCustomerOrderItem(id, item);
        }
      }

      return CustomerOrder.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create customer order: $e');
    }
  }

  Future<void> _createCustomerOrderItem(
    String orderId,
    CustomerOrderItem item,
  ) async {
    final itemData = item
        .copyWith(id: _uuid.v4(), orderId: orderId, createdAt: DateTime.now().toUtc())
        .toJson();
    await _client.from('customer_order_items').insert(itemData);
  }

  Future<CustomerOrder> updateCustomerOrder(CustomerOrder order) async {
    try {
      final data = order
          .copyWith(updatedAt: DateTime.now().toUtc(), updatedBy: SupabaseService().currentUser?.id)
          .toJson();
      data.removeWhere((key, value) => key == 'items' || key == 'customer_name');
      final response = await _client
          .from('customer_orders')
          .update(data)
          .eq('id', order.id)
          .select()
          .single();
      return CustomerOrder.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update customer order: $e');
    }
  }

  Future<void> deleteCustomerOrder(String id) async {
    try {
      await _client.from('customer_orders').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete customer order: $e');
    }
  }
```

Motif repris tel quel de `returns_service.dart::createCustomerReturn()`/`_createCustomerReturnItem()` (déjà validé et fonctionnel sur ce dépôt) — ne pas improviser une autre façon de faire.

### 2.3 Devis (`quotations`)

Ajouter, à la suite :

```dart
  // ---- Quotations ----

  Future<List<Quotation>> getQuotations({
    String? pharmacyId,
    String? customerId,
    QuotationStatus? status,
  }) async {
    try {
      var query = _client
          .from('quotations')
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

      final response = await query.order('quotation_date', ascending: false);
      return (response as List)
          .map((e) => Quotation.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load quotations: $e');
    }
  }

  Future<Quotation?> getQuotation(String id) async {
    try {
      final response = await _client
          .from('quotations')
          .select('*, customers:customer_id(first_name, last_name)')
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return Quotation.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load quotation: $e');
    }
  }

  Future<Quotation> createQuotation(Quotation quotation) async {
    try {
      final now = DateTime.now().toUtc();
      final id = _uuid.v4();
      final data = quotation
          .copyWith(
            id: id,
            createdAt: now,
            updatedAt: now,
            createdBy: SupabaseService().currentUser?.id,
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      data.removeWhere((key, value) => key == 'items' || key == 'customer_name');

      final response = await _client
          .from('quotations')
          .insert(data)
          .select()
          .single();

      if (quotation.items != null) {
        for (final item in quotation.items!) {
          await _createQuotationItem(id, item);
        }
      }

      return Quotation.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create quotation: $e');
    }
  }

  Future<void> _createQuotationItem(String quotationId, QuotationItem item) async {
    final itemData = item
        .copyWith(id: _uuid.v4(), quotationId: quotationId, createdAt: DateTime.now().toUtc())
        .toJson();
    await _client.from('quotation_items').insert(itemData);
  }

  Future<Quotation> updateQuotation(Quotation quotation) async {
    try {
      final data = quotation
          .copyWith(updatedAt: DateTime.now().toUtc(), updatedBy: SupabaseService().currentUser?.id)
          .toJson();
      data.removeWhere((key, value) => key == 'items' || key == 'customer_name');
      final response = await _client
          .from('quotations')
          .update(data)
          .eq('id', quotation.id)
          .select()
          .single();
      return Quotation.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update quotation: $e');
    }
  }

  Future<void> deleteQuotation(String id) async {
    try {
      await _client.from('quotations').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete quotation: $e');
    }
  }
```

### 2.4 Factures de vente (`sales_invoices`) et paiements (`invoice_payments`)

Ajouter, à la suite :

```dart
  // ---- Sales Invoices ----

  Future<List<SalesInvoice>> getSalesInvoices({
    String? pharmacyId,
    String? customerId,
    SalesInvoiceStatus? status,
  }) async {
    try {
      var query = _client
          .from('sales_invoices')
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

      final response = await query.order('invoice_date', ascending: false);
      return (response as List)
          .map((e) => SalesInvoice.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load sales invoices: $e');
    }
  }

  Future<SalesInvoice?> getSalesInvoice(String id) async {
    try {
      final response = await _client
          .from('sales_invoices')
          .select('*, customers:customer_id(first_name, last_name)')
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return SalesInvoice.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load sales invoice: $e');
    }
  }

  Future<SalesInvoice> createSalesInvoice(SalesInvoice invoice) async {
    try {
      final now = DateTime.now().toUtc();
      final data = invoice
          .copyWith(
            id: _uuid.v4(),
            createdAt: now,
            updatedAt: now,
            createdBy: SupabaseService().currentUser?.id,
            updatedBy: SupabaseService().currentUser?.id,
          )
          .toJson();
      data.removeWhere((key, value) => key == 'customer_name');
      final response = await _client
          .from('sales_invoices')
          .insert(data)
          .select()
          .single();
      return SalesInvoice.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create sales invoice: $e');
    }
  }

  Future<SalesInvoice> updateSalesInvoice(SalesInvoice invoice) async {
    try {
      final data = invoice
          .copyWith(updatedAt: DateTime.now().toUtc(), updatedBy: SupabaseService().currentUser?.id)
          .toJson();
      data.removeWhere((key, value) => key == 'customer_name');
      final response = await _client
          .from('sales_invoices')
          .update(data)
          .eq('id', invoice.id)
          .select()
          .single();
      return SalesInvoice.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update sales invoice: $e');
    }
  }

  Future<void> deleteSalesInvoice(String id) async {
    try {
      await _client.from('sales_invoices').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete sales invoice: $e');
    }
  }

  // ---- Invoice Payments ----

  Future<List<InvoicePayment>> getInvoicePayments(String invoiceId) async {
    try {
      final response = await _client
          .from('invoice_payments')
          .select()
          .eq('invoice_id', invoiceId)
          .order('payment_date', ascending: false);
      return (response as List)
          .map((e) => InvoicePayment.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load invoice payments: $e');
    }
  }

  Future<InvoicePayment> createInvoicePayment(InvoicePayment payment) async {
    try {
      final data = payment
          .copyWith(id: _uuid.v4(), createdAt: DateTime.now().toUtc())
          .toJson();
      final response = await _client
          .from('invoice_payments')
          .insert(data)
          .select()
          .single();
      return InvoicePayment.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create invoice payment: $e');
    }
  }
```

**Point de règle métier non tranché, à ne pas improviser** : `createInvoicePayment()` ci-dessus enregistre un paiement de façon isolée — elle ne met **pas** à jour `sales_invoices.paid_amount` ni `status` automatiquement (ex. passage à `paid` quand la somme des paiements atteint `total_amount`). C'est délibéré : le porteur du projet n'a pas encore tranché si cette synchronisation doit être automatique (déclencheur SQL ? recalcul côté service après insertion ? mise à jour manuelle côté UI ?). **Ne pas ajouter cette logique de son propre chef** — implémenter `createInvoicePayment()` exactement comme ci-dessus (insertion simple) et signaler ce point en section 4 ci-dessous si ce n'est pas déjà fait.

Supprimer le commentaire final `// Continue with order creation, quotations, invoices, supplier orders...` (devenu obsolète) et la fermeture `}` de la classe reste la dernière ligne du fichier.

## 3. Vérification et commit

1. `flutter analyze lib/modules/sales/` — les 4 nouveaux modèles + le service étendu doivent compiler sans erreur. Ne pas s'inquiéter des éventuelles erreurs restantes dans `sales_provider.dart`/`customers_list_screen.dart`/etc. si `flutter analyze` en signale (elles seront traitées au lot 2/3) — mais les lister dans le rapport si elles apparaissent, ne rien corriger dessus dans ce lot.
2. Puis `flutter analyze lib/` et `flutter test` complets, pour obtenir le nouveau total (dernier connu : 134 erreurs) et confirmer l'absence de régression ailleurs.
3. Un seul commit, fichiers listés explicitement (pas de `git add -A`) :
   `feat(sales): add Quotation/SalesInvoice/InvoicePayment models and complete CustomerOrder/Quotation/SalesInvoice CRUD (C164 lot 1/3)`

## 4. Décisions de règle métier remontées (à remplir par Claude Code en cours de route)

- Le point sur `createInvoicePayment()`/synchronisation `paid_amount`/`status` (section 2.4 ci-dessus) doit apparaître ici, même s'il est déjà signalé plus haut — ne pas le laisser seulement dans le corps du document.
- *(Ajouter tout autre point de règle métier qui apparaîtrait en cours de route — ne pas trancher, décrire et attendre l'arbitrage du porteur du projet.)*

---

**Rapport attendu en retour :** confirmation des 4 fichiers modèles créés (contenu conforme au schéma, un extrait suffit si tout est conforme), diff exact de `sales_service.dart`, + nombre d'erreurs `flutter analyze lib/` avant/après, + résultat `flutter test`. Une fois ce lot vérifié, je prépare le lot 2/3 (câblage `sales_provider.dart`) puis le lot 3/3 (écrans + routes).
