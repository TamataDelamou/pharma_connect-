# D53 — Niveau 1 : construction des 5 écrans à backend 100% prêt (business/cash/returns)

**Rédigé par :** session d'audit (Cowork), sans `flutter`/`dart` disponible dans son pont machine — diagnostic fait par lecture directe des fichiers (modèles, services, providers, routes commentées, écrans de référence existants), pas par exécution.
**Destinataire :** Claude Code, exécuté localement avec `flutter`/`dart` installés.
**Date :** 21/09/2026
**Contexte :** décision **D53** du porteur du projet (registre) — les 11 écrans manquants du cluster hors-cahier sont à construire, par lots classés par niveau de préparation backend réelle. Ce document couvre le **niveau 1** : les 5 écrans dont modèle + service + provider existent déjà en quasi-totalité, seule l'UI manque. Les niveaux 2 à 4 (sales : clients, fournisseurs, commandes, devis, factures) feront l'objet de consignes séparées une fois celui-ci vérifié.

**Nature de ce document, à bien distinguer des consignes C150-C156/C151** : celles-là étaient des correctifs mécaniques sur du code déjà écrit, diff exact fourni à l'avance. Ceci est de la **construction d'écran neuve** — je donne le contrat exact (signature de constructeur imposée par les routes déjà écrites, champs de modèle disponibles, méthodes provider à appeler, écran de référence à imiter pour le style), pas un diff. Le detail visuel (mise en page exacte, espacement) reste à l'appréciation de Claude Code, **à condition de suivre fidèlement les widgets et le style déjà en usage dans le reste de l'app** (voir écrans de référence ci-dessous) — pas de nouvelle bibliothèque UI, pas de nouveau design system.

---

## 0. Préalable obligatoire — C161 : `returns_provider.dart` n'a aucun getter public

Découvert en préparant ce document (lecture complète du fichier, pas seulement le total `flutter analyze`) : `lib/modules/returns/providers/returns_provider.dart` a une section entière laissée en commentaire placeholder (`// Getters...`, ligne 19) — **aucun getter n'a jamais été écrit**. Ça bloque déjà, de fait, l'écran existant `customer_returns_list_screen.dart` qui appelle `provider.isLoading`/`provider.error`/`provider.customerReturns`, et ça bloquerait les deux écrans `returns` de ce lot (besoin de `selectedCustomerReturn`, `reasons`).

**À ajouter, juste après la ligne `String? _error;` (ligne 17), avant la ligne `// Getters...`** (motif identique à `business_provider.dart`/`cash_provider.dart`, mêmes fichiers déjà alignés dessus) :

```dart
  List<CustomerReturn> get customerReturns => _customerReturns;
  CustomerReturn? get selectedCustomerReturn => _selectedCustomerReturn;
  List<SupplierReturn> get supplierReturns => _supplierReturns;
  SupplierReturn? get selectedSupplierReturn => _selectedSupplierReturn;
  List<ReturnReason> get reasons => _reasons;
  bool get isLoading => _isLoading;
  String? get error => _error;
```

Supprimer le commentaire `// Getters...` (remplacé par le code ci-dessus). Vérifier avec `flutter analyze lib/modules/returns/ test/` avant de passer à la suite — si `customer_returns_list_screen.dart` a d'autres erreurs révélées par ce correctif (peu probable mais possible), les signaler en section 6, ne pas les corriger à l'aveugle.

## 1. `CompanyCreateScreen` (business) — création **et** édition

Route déjà écrite, commentée, dans `lib/routes/app_router.dart` (~ligne 1397 et ~1411) — la décommenter telle quelle, elle impose la signature exacte :
```dart
GoRoute(
  path: '/business/company/new',
  name: 'business-company-new',
  builder: (context, state) => const CompanyCreateScreen(),
),
// ...
GoRoute(
  path: '/business/company/edit/:id',
  name: 'business-company-edit',
  builder: (context, state) {
    final id = state.pathParameters['id']!;
    return CompanyCreateScreen(companyId: id);
  },
),
```
Donc : `CompanyCreateScreen({super.key, String? companyId})` — `companyId == null` → mode création, sinon → mode édition (charger la société via `BusinessProvider.loadCompany(companyId)` dans `initState`, préremplir les champs).

**Fichier à créer :** `lib/modules/business/screens/company_create_screen.dart`
**Import à ajouter/décommenter dans `app_router.dart`** (~ligne 202, actuellement absent de la liste d'imports) : `import '../modules/business/screens/company_create_screen.dart';`

**Champs du formulaire**, tirés de `lib/modules/business/models/business_company.dart` :
- Requis : `name` (texte), `type` (menu déroulant — valeurs vues en usage dans le modèle : `hospital`, `clinic`, `wholesaler`, `laboratory`, `pharmacy_chain`, `insurance`, `other`).
- Optionnels : `legalName`, `registrationNumber`, `taxId`, `address`, `city`, `country`, `phone`, `email`, `website`, `contactPersonName`, `contactPersonPhone`, `contactPersonEmail`, `notes`, `logoUrl`.
- **Ne pas exposer `status`** dans le formulaire de création : le backend le défaute déjà à `'pending'` (`business_service.dart::createCompany()`, voir aussi C149, dette cosmétique déjà connue, hors périmètre ici). En **édition**, `status` peut être exposé (menu déroulant `active`/`inactive`/`pending`/`suspended`/`archived`) puisque changer le statut d'une société existante est un besoin réel — si ce point vous semble discutable, le signaler en section 6 plutôt que de trancher.

**Appels provider** (`BusinessProvider`, déjà tous prêts) :
- Création : construire un `BusinessCompany` avec un `id` vide (`''`) et les champs du formulaire, `createdAt`/`updatedAt` peu importe (le service les recalcule), puis `context.read<BusinessProvider>().saveCompany(company)` — `saveCompany()` route déjà vers `createCompany()` si `id.isEmpty`.
- Édition : même `saveCompany()`, avec l'`id` réel — route déjà vers `updateCompany()`.
- Après succès (`saveCompany()` retourne `true`) : `context.pop()` ou `context.go('/business/company/${provider.selectedCompany!.id}')` selon ce qui est le plus cohérent avec la navigation déjà en usage ailleurs dans le module business — vérifier `company_detail_screen.dart` pour le style de retour déjà utilisé.

**Écran de référence à imiter pour le style** : `lib/modules/chains/screens/group_create_screen.dart` (formulaire simple avec `GlassInput`, `PrimaryButton`, `TertiaryButton`, `GlassCard`, validation via `Form`/`GlobalKey<FormState>`). Pour l'en-tête/mise en page générale, s'inspirer aussi de `lib/modules/business/screens/company_detail_screen.dart` (déjà dans le module business, cohérence visuelle).

**Bouton d'accès** : `business_dashboard_screen.dart`/`company_detail_screen.dart` ont déjà des boutons vers ces routes, actuellement morts (**C148**, déjà consigné) — vérifier qu'ils pointent bien vers `/business/company/new` et `/business/company/edit/:id`, les reconnecter si besoin (probablement déjà corrects, juste inertes tant que la route était commentée).

## 2. `CashHistoryScreen` (cash)

Route déjà écrite, commentée (~ligne 1538 de `app_router.dart`) :
```dart
GoRoute(
  path: '/cash/history',
  name: 'cash-history',
  builder: (context, state) => const CashHistoryScreen(),
),
```
**Fichier à créer :** `lib/modules/cash/screens/cash_history_screen.dart`
**Appel provider** : `context.read<CashProvider>().loadSessions(pharmacyId: ..., fromDate: ..., toDate: ...)` (`loadSessions` déjà écrit dans `cash_provider.dart`) — pour `pharmacyId`, suivre le motif déjà en usage dans `cash_dashboard_screen.dart` (`'default_pharmacy'` en dur, limitation préexistante, ne pas la corriger ici, hors périmètre). Filtres de date : au choix, un sélecteur simple (7/30/90 derniers jours) suffit pour ce lot — ne pas sur-construire.
**Affichage** : liste des `CashDrawerSession` (`provider.sessions`) — champs utiles : `openedAt`, `closedAt`, `cashierName`, `openingBalance`, `closingBalance`, `difference`, `status` (`CashSessionStatus`, vérifier le libellé/couleur déjà défini sur ce enum si une extension existe, même motif que `ReturnStatusExtension`).
**Écran de référence pour le style de liste** : `lib/modules/returns/screens/customer_returns_list_screen.dart` (liste avec état de chargement/erreur/vide déjà bien géré, à imiter).

## 3. `CashReportScreen` (cash)

Route déjà écrite, commentée (~ligne 1544) :
```dart
GoRoute(
  path: '/cash/report',
  name: 'cash-report',
  builder: (context, state) => const CashReportScreen(),
),
```
**Fichier à créer :** `lib/modules/cash/screens/cash_report_screen.dart`
**Appel provider** : `context.read<CashProvider>().loadReport(pharmacyId: ..., fromDate: ..., toDate: ...)` (déjà écrit) — sélecteur de plage de dates requis cette fois (paramètres `fromDate`/`toDate` obligatoires côté provider).
**Affichage** : `provider.report` est un `Map<String, dynamic>?` avec les clés exactes (vérifiées dans `cash_service.dart::getCashReport()`) : `total_sessions`, `total_opening`, `total_sales`, `total_refunds`, `total_withdrawals`, `total_deposits`, `total_closing`, `net_cash` — tous des `int` (montants en unité monétaire entière, comme le reste du module cash). Simple grille de tuiles chiffrées suffit pour ce lot.

## 4. `CustomerReturnCreateScreen` (returns)

Route déjà écrite, commentée (~ligne 1571) :
```dart
GoRoute(
  path: '/returns/customer/new',
  name: 'returns-customer-new',
  builder: (context, state) => const CustomerReturnCreateScreen(),
),
```
**Fichier à créer :** `lib/modules/returns/screens/customer_return_create_screen.dart`
**Champs**, tirés de `lib/modules/returns/models/customer_return.dart` : `customerId`, `saleId`, `reasonId` (menu déroulant, charger via `context.read<ReturnsProvider>().loadReasons()` puis `provider.reasons`, disponible après le correctif §0), `reasonText` (optionnel, complément libre), `notes` (optionnel). `returnNumber`/`returnDate`/`status`/`totalAmount`/`refundAmount` : laisser le service les gérer (mêmes valeurs par défaut que pour `business`/`cash` — vérifier `createCustomerReturn()` dans `returns_service.dart` si un doute).
**Point non tranché à signaler, pas à deviner** : ce formulaire suppose la saisie des articles retournés (`items`, `List<CustomerReturnItem>`) pour que le retour ait un sens métier réel (quantités, produits). Aucun écran de sélection de produits n'existe dans ce lot ni dans le périmètre D53. Si un écran minimal (même juste un champ produit + quantité répétable, sans recherche catalogue avancée) est attendu pour ce ticket, le signaler en section 6 avant de improviser une UX de sélection produit non spécifiée — ne pas inventer un flux de recherche catalogue de toutes pièces.
**Appel provider** : `context.read<ReturnsProvider>().createCustomerReturn(returnData)`.

## 5. `CustomerReturnDetailScreen` (returns)

Route déjà écrite, commentée (~ligne 1577) :
```dart
GoRoute(
  path: '/returns/customer/:id',
  name: 'returns-customer-detail',
  builder: (context, state) {
    final id = state.pathParameters['id']!;
    return CustomerReturnDetailScreen(returnId: id);
  },
),
```
**Fichier à créer :** `lib/modules/returns/screens/customer_return_detail_screen.dart`
**Appel provider** : `context.read<ReturnsProvider>().loadCustomerReturn(widget.returnId)` dans `initState`, affichage via `provider.selectedCustomerReturn` (disponible après le correctif §0).
**Action métier disponible** : changement de statut via `context.read<ReturnsProvider>().updateCustomerReturnStatus(id, newStatus, refundAmount: ..., notes: ...)` — `ReturnStatus` : `pending`/`approved`/`rejected`/`completed`/`cancelled` (enum déjà en place, `ReturnStatusExtension` fournit déjà labels/couleurs pour l'affichage). Proposer les transitions de statut comme des boutons, sur le même principe que ce qui existe déjà ailleurs dans l'app pour un cycle de statut (chercher un écran comparable si besoin, ex. commandes/RES).
**Écran de référence** : `lib/modules/business/screens/company_detail_screen.dart` (structure générale détail + actions).

## 6. Décisions de règle métier remontées (à remplir par Claude Code en cours de route)

*(Le point de §4 — flux de sélection produit pour la création d'un retour — est probablement à remonter ici sauf si un motif déjà en usage ailleurs dans l'app permet de le résoudre sans inventer une UX. Ajouter tout autre point rencontré, ne rien trancher seul.)*

## 7. Vérification et commit

1. `flutter analyze lib/modules/business/ lib/modules/cash/ lib/modules/returns/ lib/routes/app_router.dart`
2. `flutter analyze lib/` complet — comparer au dernier total connu (164, après C151, avant C161).
3. `flutter test` — comparer à 72/28 (dernier connu, après C151).
4. Test manuel de navigation minimal si possible dans l'environnement local : `/business/company/new`, `/business/company/edit/:id`, `/cash/history`, `/cash/report`, `/returns/customer/new`, `/returns/customer/:id` — au moins vérifier qu'aucune ne crash à l'ouverture.
5. Commits séparés par écran ou par module (pas un seul gros commit), fichiers listés explicitement (pas de `git add -A`), format `feat(business): add CompanyCreateScreen (D53 niveau 1)` etc. Le correctif §0 (`returns_provider.dart`) peut être son propre commit `fix(returns): add missing public getters (C161)`.

---

**Rapport attendu en retour :** par écran — fichier créé, route décommentée, résultat `flutter analyze`/`flutter test` avant/après, et tout point de la section 6 rencontré. Une fois vérifié, je clôture C161 et la partie niveau 1 de D53 au registre, et je prépare les consignes niveau 2 (clients/fournisseurs, sales).
