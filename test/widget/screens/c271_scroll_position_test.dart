import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pharma_connect/core/theme/app_theme.dart';
import 'package:pharma_connect/modules/auth/providers/auth_provider.dart';
import 'package:pharma_connect/modules/catalog/models/category.dart';
import 'package:pharma_connect/modules/catalog/providers/catalog_provider.dart';
import 'package:pharma_connect/modules/catalog/screens/catalog_detail_screen.dart';
import 'package:pharma_connect/modules/catalog/screens/catalog_list_screen.dart';
import 'package:pharma_connect/modules/catalog/services/catalog_service.dart';
import 'package:pharma_connect/modules/reservations/providers/reservation_provider.dart';
import 'package:pharma_connect/modules/search/models/availability_result.dart';
import 'package:pharma_connect/modules/search/models/search_filters.dart';
import 'package:pharma_connect/modules/search/models/search_result.dart';
import 'package:pharma_connect/modules/search/providers/search_provider.dart';
import 'package:pharma_connect/modules/search/screens/product_detail_screen.dart';
import 'package:pharma_connect/modules/search/screens/search_screen.dart';
import 'package:pharma_connect/modules/search/services/search_service.dart';
import 'package:pharma_connect/modules/stock/models/stock_item.dart';
import 'package:pharma_connect/modules/stock/models/stock_movement.dart';
import 'package:pharma_connect/modules/stock/providers/stock_provider.dart';
import 'package:pharma_connect/modules/stock/screens/stock_detail_screen.dart';
import 'package:pharma_connect/modules/stock/screens/stock_list_screen.dart';
import 'package:pharma_connect/modules/stock/services/stock_service.dart';
import 'package:pharma_connect/shared/models/product.dart';

// C271 : après avoir consulté une fiche, le retour à la liste garde la
// position de défilement, la catégorie et la recherche en cours, sans
// recharger la liste. Catalogue, « Stock & Lots » et résultats de recherche.
//
// Les fiches chargent par le vrai fournisseur ; le service retient la
// réponse le temps que le test le décide, comme un réseau lent. C'est ce
// chargement qui remettait la liste en haut.

Product _product(int i) => Product(
  id: 'p$i',
  name: 'Produit $i',
  genericName: 'Produit $i',
  dosage: '500mg',
  form: 'Comprimé',
  category: 'Antalgiques',
  imageUrl: '',
  isGeneric: true,
  manufacturer: 'Laboratoire',
  isPrescriptionRequired: false,
);

final _products = [for (var i = 0; i < 40; i++) _product(i)];

StockItem _stockItem(Product p) => StockItem(
  id: p.id,
  pharmacyId: 'ph1',
  product: p,
  batches: const [],
  totalQuantity: 10,
);

/// Réponse de la fiche retenue jusqu'à [release].
class _Gate {
  final _completer = Completer<void>();

  Future<void> get wait => _completer.future;

  void release() => _completer.complete();
}

class _CatalogService extends CatalogService {
  final _Gate gate;
  _CatalogService(this.gate);

  @override
  Future<Product> getProduct(String id) async {
    await gate.wait;
    return _products.firstWhere((p) => p.id == id);
  }
}

/// Liste posée par le test ; les fiches gardent le chargement réel.
class _CatalogProvider extends CatalogProvider {
  _CatalogProvider(_Gate gate) : super(service: _CatalogService(gate));

  final loads = <(String?, String?)>[];

  @override
  List<Product> get products => _products;

  @override
  List<Category> get categories => [
    Category(id: 'c1', name: 'Antalgiques', icon: '💊'),
    Category(id: 'c2', name: 'Antibiotiques', icon: '💊'),
  ];

  @override
  Future<void> loadCatalog({String? categoryId, String? searchQuery}) async {
    loads.add((categoryId, searchQuery));
  }

  @override
  Future<void> loadCategories() async {}
}

class _StockService extends StockService {
  final _Gate gate;
  _StockService(this.gate);

  @override
  Future<StockItem?> getStockItem(String id) async {
    await gate.wait;
    return _stockItem(_products.firstWhere((p) => p.id == id));
  }

  @override
  Future<List<StockMovement>> getMovements({
    String? stockItemId,
    String? batchId,
    int limit = 50,
  }) async => [];
}

class _StockProvider extends StockProvider {
  _StockProvider(_Gate gate) : super(service: _StockService(gate));

  int loads = 0;

  @override
  List<StockItem> get stockItems => [for (final p in _products) _stockItem(p)];

  @override
  Future<void> loadStock({
    String? pharmacyId,
    String? productId,
    String? searchQuery,
  }) async {
    loads++;
  }
}

class _SearchService extends SearchService {
  final _Gate gate;
  _SearchService(this.gate);

  int searches = 0;

  @override
  Future<List<SearchResult>> search({
    required String query,
    SearchFilters? filters,
    double? userLat,
    double? userLon,
  }) async {
    searches++;
    return [for (final p in _products) SearchResult(product: p)];
  }

  @override
  Future<AvailabilityResult?> getProductAvailability(String productId) async {
    await gate.wait;
    return null;
  }

  @override
  Future<void> addToHistory(String query) async {}

  @override
  Future<List<String>> getSearchHistory() async => [];
}

Future<GoRouter> _pump(
  WidgetTester tester, {
  required String list,
  required Widget listScreen,
  required String detail,
  required Widget Function(String id) detailScreen,
  required List<ChangeNotifierProvider> providers,
}) async {
  // Largeur tablette : les fiches chargées débordent en largeur téléphone
  // (registre, C272), défaut sans lien avec la position de défilement.
  tester.view.physicalSize = const Size(800, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: list,
    routes: [
      GoRoute(path: list, builder: (context, state) => listScreen),
      GoRoute(
        path: detail,
        builder: (context, state) => detailScreen(state.pathParameters['id']!),
      ),
    ],
  );
  await tester.pumpWidget(
    MultiProvider(
      providers: providers,
      child: MaterialApp.router(
        theme: PharmaConnectAppTheme.light(),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

/// Liste défilante de l'écran [screen].
Finder _list(Type screen) => find
    .descendant(of: find.byType(screen), matching: find.byType(Scrollable))
    .last;

double _offset(WidgetTester tester, Type screen) =>
    tester.state<ScrollableState>(_list(screen)).position.pixels;

/// La fiche peut garder une roue de chargement (disponibilité absente) :
/// pas d'attente de fin d'animation, mais le temps d'une transition.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Défile, ouvre la fiche d'un produit visible, la laisse charger, revient ;
/// rend la position avant l'ouverture et la position au retour.
Future<(double, double)> _scrollOpenBack(
  WidgetTester tester,
  GoRouter router,
  Type screen,
  _Gate gate,
) async {
  await tester.drag(_list(screen), const Offset(0, -1500));
  await tester.pumpAndSettle();
  final before = _offset(tester, screen);
  expect(before, greaterThan(500));

  final visible = [
    for (final p in _products) find.text(p.name).hitTestable(),
  ].firstWhere((f) => f.evaluate().isNotEmpty);
  await tester.tap(visible.first);
  // Fiche ouverte, chargement en cours (réseau lent).
  await _settle(tester);
  expect(find.byType(screen), findsNothing, reason: 'fiche ouverte');
  gate.release();
  await _settle(tester);

  router.pop();
  await _settle(tester);
  return (before, _offset(tester, screen));
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-anon-key',
    );
  });

  testWidgets(
    'catalogue : même position, même catégorie, même recherche, sans recharger',
    (tester) async {
      final gate = _Gate();
      final catalog = _CatalogProvider(gate);
      final router = await _pump(
        tester,
        list: '/catalog',
        listScreen: const CatalogListScreen(),
        detail: '/catalog/:id',
        detailScreen: (id) => CatalogDetailScreen(productId: id),
        providers: [
          ChangeNotifierProvider<CatalogProvider>.value(value: catalog),
          ChangeNotifierProvider<AuthProvider>.value(value: AuthProvider()),
        ],
      );

      await tester.ensureVisible(find.textContaining('Antibiotiques'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Antibiotiques'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Produit');
      await tester.pumpAndSettle();
      final loads = catalog.loads.length;

      final (before, after) = await _scrollOpenBack(
        tester,
        router,
        CatalogListScreen,
        gate,
      );

      expect(after, before);
      expect(catalog.selectedCategoryId, 'c2');
      expect(catalog.searchQuery, 'Produit');
      expect(find.widgetWithText(TextField, 'Produit'), findsOneWidget);
      expect(catalog.loads.length, loads, reason: 'liste rechargée');
    },
  );

  testWidgets('stock et lots : même position, sans recharger', (tester) async {
    final gate = _Gate();
    final stock = _StockProvider(gate);
    final router = await _pump(
      tester,
      list: '/stock',
      listScreen: const StockListScreen(),
      detail: '/stock/:id',
      detailScreen: (id) => StockDetailScreen(stockId: id),
      providers: [
        ChangeNotifierProvider<StockProvider>.value(value: stock),
        ChangeNotifierProvider<AuthProvider>.value(
          value: AuthProvider()
            // ignore: invalid_use_of_visible_for_testing_member
            ..pharmacyIdForTesting = 'ph1',
        ),
      ],
    );
    final loads = stock.loads;

    final (before, after) = await _scrollOpenBack(
      tester,
      router,
      StockListScreen,
      gate,
    );

    expect(after, before);
    expect(stock.loads, loads, reason: 'liste rechargée');
  });

  testWidgets('résultats de recherche : même position, sans relancer', (
    tester,
  ) async {
    final gate = _Gate();
    final service = _SearchService(gate);
    final search = SearchProvider(service: service);
    await search.search(query: 'Produit');
    final router = await _pump(
      tester,
      list: '/search',
      listScreen: const SearchScreen(),
      detail: '/product/:id',
      detailScreen: (id) => ProductDetailScreen(productId: id),
      providers: [
        ChangeNotifierProvider<SearchProvider>.value(value: search),
        ChangeNotifierProvider<ReservationProvider>.value(
          value: ReservationProvider(),
        ),
      ],
    );
    final searches = service.searches;

    final (before, after) = await _scrollOpenBack(
      tester,
      router,
      SearchScreen,
      gate,
    );

    expect(after, before);
    expect(search.query, 'Produit');
    expect(service.searches, searches, reason: 'recherche relancée');
  });
}
