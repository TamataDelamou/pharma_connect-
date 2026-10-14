import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pharma_connect/core/utils/currency_formatter.dart';
import 'package:pharma_connect/modules/auth/providers/auth_provider.dart';
import 'package:pharma_connect/modules/pos/models/pos_receipt.dart';
import 'package:pharma_connect/modules/pos/models/pos_sale.dart';
import 'package:pharma_connect/modules/pos/models/pos_sale_item.dart';
import 'package:pharma_connect/modules/pos/models/stock_product.dart';
import 'package:pharma_connect/modules/pos/providers/pos_provider.dart';
import 'package:pharma_connect/modules/pos/screens/pos_checkout_screen.dart';
import 'package:pharma_connect/modules/pos/services/pos_service.dart';

import '../../helpers/phone_layout.dart';

// C262 : plus de remise au comptoir. L'écran ne la propose plus, le montant
// à payer ne dépend plus d'un geste sur l'écran, et la vente envoyée au
// serveur porte une remise nulle.

/// Stock et enregistrement de la vente en mémoire.
class _FakePOSService extends POSService {
  POSSale? sent;

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
      unitPrice: 1500,
      availableQuantity: 10,
      prescriptionRequired: false,
    ),
  ];

  @override
  Future<POSSale> createSale(POSSale sale) async {
    sent = sale;
    return sale.copyWith(id: 'sale-1');
  }

  @override
  Future<POSReceipt?> getReceipt(String saleId) async => null;
}

POSSaleItem _box() => POSSaleItem(
  id: 'p1',
  saleId: '',
  productId: 'p1',
  productName: 'Paracétamol 500mg',
  quantity: 1,
  unitPrice: 1500,
  totalPrice: 1500,
  createdAt: DateTime(2026, 10, 13),
);

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

  test(
    'fournisseur : à payer = total + TVA, vente envoyée sans remise',
    () async {
      final service = _FakePOSService();
      final pos = POSProvider(service: service)..addToCart(_box());
      expect(pos.total, 1500);
      expect(pos.finalTotal, 1575);

      final ok = await pos.checkout(pharmacyId: 'ph1', cashierId: 'u1');
      expect(ok, isTrue);
      expect(service.sent!.discountAmount, 0);
      expect(service.sent!.totalAmount, 1500);
      expect(service.sent!.taxAmount, 75);
      expect(service.sent!.finalAmount, 1575);
      expect(
        service.sent!.items!.every((i) => i.discountPercentage == 0),
        isTrue,
      );
    },
  );

  for (final size in [phoneSize, const Size(1200, 800)]) {
    testWidgets(
      'écran de ${size.width.toInt()} px : aucune réglette ni ligne de remise ; '
      'faire défiler ne change pas le montant',
      (tester) async {
        final service = _FakePOSService();
        final pos = POSProvider(service: service)..addToCart(_box());
        final auth = AuthProvider()
          // ignore: invalid_use_of_visible_for_testing_member
          ..pharmacyIdForTesting = 'ph1';
        final overflows = await pumpAtPhoneWidth(
          tester,
          POSCheckoutScreen(posService: service),
          size: size,
          wrap: (app) => MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: auth),
              ChangeNotifierProvider<POSProvider>.value(value: pos),
            ],
            child: app,
          ),
        );
        expect(overflows, isEmpty);

        expect(find.byType(Slider), findsNothing);
        expect(find.textContaining('Remise'), findsNothing);
        expect(find.text('0%'), findsNothing);
        expect(find.text(CurrencyFormatter.format(1575)), findsOneWidget);

        // Gestes de défilement partis du champ de quantité, là où était la
        // réglette : le montant ne bouge pas.
        final start = tester.getCenter(find.widgetWithText(TextField, 'Qté'));
        for (final delta in const [
          Offset(0, -300),
          Offset(200, 0),
          Offset(0, 300),
        ]) {
          await tester.dragFrom(start + const Offset(120, 0), delta);
          await pumpFrames(tester);
        }
        expect(pos.finalTotal, 1575);
        expect(find.text(CurrencyFormatter.format(1575)), findsOneWidget);
      },
    );
  }

  test('le code de la vente au comptoir ne règle plus de remise', () {
    final screen = File(
      'lib/modules/pos/screens/pos_checkout_screen.dart',
    ).readAsStringSync();
    final provider = File(
      'lib/modules/pos/providers/pos_provider.dart',
    ).readAsStringSync();
    expect(screen.contains('Slider('), isFalse);
    expect(provider.contains('setDiscount'), isFalse);
    expect(provider.contains('discountAmount: 0'), isTrue);
  });
}
