import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pharma_connect/modules/auth/providers/auth_provider.dart';
import 'package:pharma_connect/modules/pos/models/pos_sale_item.dart';
import 'package:pharma_connect/modules/pos/models/stock_product.dart';
import 'package:pharma_connect/modules/pos/providers/pos_provider.dart';
import 'package:pharma_connect/modules/pos/screens/pos_checkout_screen.dart';
import 'package:pharma_connect/modules/pos/services/pos_service.dart';

import '../../helpers/phone_layout.dart';

// C257 : « Vente au comptoir » en largeur téléphone : une colonne, « À
// payer » et le bouton de paiement fixés en bas, aucun débordement.

/// Stock posé par le test : pas de lecture du serveur.
class _FakePOSService extends POSService {
  @override
  Future<List<StockProduct>> searchStockProducts(
    String pharmacyId, {
    String? query,
    int limit = 30,
  }) async => const [
    StockProduct(
      productId: 'p1',
      name: 'Paracétamol',
      dosage: '500mg',
      form: 'Comprimé',
      unitPrice: 1500,
      availableQuantity: 10,
      prescriptionRequired: false,
    ),
    StockProduct(
      productId: 'p2',
      name: 'Amoxicilline acide clavulanique',
      genericName: 'Amoxicilline + acide clavulanique',
      dosage: '1g/125mg',
      form: 'Comprimé pelliculé',
      unitPrice: 125000,
      availableQuantity: 3,
      prescriptionRequired: true,
    ),
    StockProduct(
      productId: 'p3',
      name: 'Ibuprofène',
      dosage: '400mg',
      unitPrice: 0,
      availableQuantity: 0,
      prescriptionRequired: false,
    ),
  ];
}

POSSaleItem _item(
  String id,
  String name,
  int quantity,
  int unitPrice, {
  bool prescription = false,
}) => POSSaleItem(
  id: id,
  saleId: '',
  productId: id,
  productName: name,
  quantity: quantity,
  unitPrice: unitPrice,
  totalPrice: quantity * unitPrice,
  createdAt: DateTime(2026, 10, 12),
  prescriptionRequired: prescription,
);

Future<List<String>> _pump(
  WidgetTester tester,
  POSProvider pos, {
  Size size = phoneSize,
}) {
  final auth = AuthProvider()
    // ignore: invalid_use_of_visible_for_testing_member
    ..pharmacyIdForTesting = 'ph1';
  return pumpAtPhoneWidth(
    tester,
    POSCheckoutScreen(posService: _FakePOSService()),
    size: size,
    wrap: (app) => MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProvider<POSProvider>.value(value: pos),
      ],
      child: app,
    ),
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-anon-key',
    );
    await loadAppFonts();
  });

  testWidgets('360 px, panier vide : aucun débordement', (tester) async {
    final overflows = await _pump(tester, POSProvider());
    expect(overflows, isEmpty);
    expect(find.text('Paracétamol 500mg'), findsOneWidget);
  });

  testWidgets(
    '360 px, panier rempli, remise, gros montants : aucun débordement, « À '
    'payer » et le paiement visibles sans défiler',
    (tester) async {
      final pos = POSProvider()
        ..addToCart(_item('p1', 'Paracétamol 500mg', 4, 1500))
        ..addToCart(
          _item(
            'p2',
            'Amoxicilline acide clavulanique 1g/125mg',
            12,
            125000,
            prescription: true,
          ),
        );
      final overflows = await _pump(tester, pos);
      expect(overflows, isEmpty);

      // Panneau fixe : entièrement dans l'écran, sur toute la largeur.
      final pay = find.text('💳 Finaliser la vente');
      final total = find.text('À payer');
      expect(pay, findsOneWidget);
      expect(total, findsOneWidget);
      final screen = Offset.zero & phoneSize;
      expect(screen.contains(tester.getBottomRight(pay)), isTrue);
      expect(screen.contains(tester.getTopLeft(total)), isTrue);
      expect(
        tester
            .getSize(
              find.widgetWithText(ElevatedButton, '💳 Finaliser la vente'),
            )
            .width,
        greaterThan(300),
      );

      // Le reste défile jusqu'au bouton « Vider le panier », lisible en
      // entier.
      // Geste parti du titre du panier : la liste des produits trouvés
      // défile pour elle-même.
      final afterScroll = await collectOverflows(() async {
        await tester.drag(find.text('🛒 Panier'), const Offset(0, -3000));
        await pumpFrames(tester);
      });
      expect(find.text('🔄 Vider le panier'), findsOneWidget);
      expect(afterScroll, isEmpty);
      expect(total, findsOneWidget);
    },
  );

  testWidgets('écran large : deux colonnes, aucun débordement', (tester) async {
    final pos = POSProvider()
      ..addToCart(_item('p1', 'Paracétamol 500mg', 4, 1500));
    final overflows = await _pump(tester, pos, size: const Size(1200, 800));
    expect(overflows, isEmpty);
    expect(find.text('🛒 Panier'), findsNothing);
  });
}
