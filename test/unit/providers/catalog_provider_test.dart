import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pharma_connect/modules/catalog/providers/catalog_provider.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-anon-key',
    );
  });

  group('CatalogProvider', () {
    test('loadCatalog() (nominal) charge la liste mockée sans erreur', () async {
      final provider = CatalogProvider();

      await provider.loadCatalog();

      expect(provider.error, isNull);
      expect(provider.isLoading, isFalse);
      expect(provider.products, isNotEmpty);
    });

    test(
      'loadProductDetail() (erreur) avec un id inexistant renseigne detailError sans toucher à la liste (C271)',
      () async {
        final provider = CatalogProvider();

        await provider.loadProductDetail('id-inexistant');

        expect(provider.detailError, isNotNull);
        expect(provider.error, isNull);
        expect(provider.isDetailLoading, isFalse);
        expect(provider.isLoading, isFalse);
        expect(provider.selectedProduct, isNull);
      },
    );
  });
}
