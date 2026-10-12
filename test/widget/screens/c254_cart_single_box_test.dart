import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pharma_connect/core/theme/app_theme.dart';
import 'package:pharma_connect/modules/reservations/models/reservation_item.dart';
import 'package:pharma_connect/modules/reservations/providers/reservation_provider.dart';
import 'package:pharma_connect/modules/search/models/availability_result.dart';
import 'package:pharma_connect/modules/search/models/pharmacy.dart';
import 'package:pharma_connect/modules/search/providers/search_provider.dart';
import 'package:pharma_connect/modules/search/screens/product_detail_screen.dart';
import 'package:pharma_connect/modules/search/widgets/pharmacy_list_tile.dart';
import 'package:pharma_connect/shared/models/product.dart';

// C254 : toucher une officine sur la fiche produit n'ajoute qu'une boîte,
// même après plusieurs retours sur la fiche.

/// Disponibilité posée par le test : pas de lecture du serveur.
class _FakeSearchProvider extends SearchProvider {
  @override
  Future<void> loadProductAvailability(String productId) async {}
}

final _availability = AvailabilityResult(
  product: Product(
    id: 'p1',
    name: 'Paracétamol',
    genericName: 'Paracétamol',
    dosage: '500mg',
    form: 'Comprimé',
    category: 'Antalgiques',
    imageUrl: '',
    isGeneric: true,
    manufacturer: 'Laboratoire',
    isPrescriptionRequired: false,
  ),
  pharmacyStocks: [
    PharmacyStock(
      pharmacy: Pharmacy(
        id: 'ph1',
        name: 'Pharmacie Kaloum Centrale',
        address: 'Avenue de la République, Kaloum',
        phone: '+224620000000',
        latitude: 9.51,
        longitude: -13.71,
        isOpenNow: true,
      ),
      stock: 10,
      price: 1500,
      isAvailable: true,
      lastUpdated: DateTime.now(),
    ),
  ],
);

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-anon-key',
    );
  });

  test('isInCart : vrai seulement pour un produit du panier', () {
    final provider = ReservationProvider();
    expect(provider.isInCart('p1'), isFalse);
    provider.addToCart(
      ReservationItem(
        productId: 'p1',
        productName: 'Paracétamol',
        genericName: 'Paracétamol',
        dosage: '500mg',
        pricePerUnit: 1500,
        quantity: 1,
        prescriptionRequired: false,
      ),
    );
    expect(provider.isInCart('p1'), isTrue);
    expect(provider.isInCart('p2'), isFalse);
    provider.removeFromCart('p1');
    expect(provider.isInCart('p1'), isFalse);
  });

  testWidgets(
    'toucher une officine, revenir, toucher de nouveau : une seule boîte',
    (tester) async {
      // Écran large : les débordements à 360 px sont l'objet de C253.
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final reservations = ReservationProvider();
      final search = _FakeSearchProvider()
        // ignore: invalid_use_of_visible_for_testing_member
        ..selectedProductAvailabilityForTesting = _availability;
      final router = GoRouter(
        initialLocation: '/product/p1',
        routes: [
          GoRoute(
            path: '/product/:id',
            builder: (_, state) =>
                ProductDetailScreen(productId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/cart',
            builder: (_, _) => const Scaffold(body: Text('PANIER')),
          ),
        ],
      );
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SearchProvider>.value(value: search),
            ChangeNotifierProvider<ReservationProvider>.value(
              value: reservations,
            ),
          ],
          child: MaterialApp.router(
            theme: PharmaConnectAppTheme.light(),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (var visit = 1; visit <= 3; visit++) {
        await tester.tap(find.byType(PharmacyListTile));
        await tester.pumpAndSettle();
        expect(find.text('PANIER'), findsOneWidget, reason: 'visite $visit');
        expect(reservations.cartItems, hasLength(1));
        expect(reservations.cartItems.single.quantity, 1);
        expect(reservations.cartItemCount, 1);

        // Le patient sort du panier sans commander.
        router.pop();
        await tester.pumpAndSettle();
        expect(find.byType(ProductDetailScreen), findsOneWidget);
      }

      // La quantité ne change que dans le panier.
      reservations.updateCartItemQuantity('p1', 3);
      await tester.tap(find.byType(PharmacyListTile));
      await tester.pumpAndSettle();
      expect(reservations.cartItems.single.quantity, 3);
    },
  );
}
