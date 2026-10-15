import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pharma_connect/modules/stock/providers/stock_provider.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-anon-key',
    );
  });

  group('StockProvider', () {
    test('loadStock() (nominal) charge la liste mockée sans erreur', () async {
      final provider = StockProvider();

      await provider.loadStock();

      expect(provider.error, isNull);
      expect(provider.isLoading, isFalse);
      expect(provider.stockItems, isNotEmpty);
    });

    // Contrairement aux 13 autres providers, StockService.getStockItem()
    // avale sa propre exception firstWhere (try/catch -> retourne null) au
    // lieu de la laisser remonter — le chemin `provider.error` de
    // loadStockItem() est donc aujourd'hui inatteignable. Documenté comme
    // trouvaille dans PharmaConnect_CLAUDE.md plutôt que masqué par un test
    // qui prétendrait le contraire.
    test(
      'loadStockItem() avec un id inexistant résout à null sans erreur (incohérence connue)',
      () async {
        final provider = StockProvider();

        await provider.loadStockItem('id-inexistant');

        expect(provider.selectedStockItem, isNull);
        expect(provider.itemError, isNull);
        expect(provider.error, isNull);
        expect(provider.isItemLoading, isFalse);
        expect(provider.isLoading, isFalse);
      },
    );
  });
}
