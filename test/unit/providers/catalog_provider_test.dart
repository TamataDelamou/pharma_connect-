import 'package:flutter_test/flutter_test.dart';
import 'package:pharma_connect/modules/catalog/providers/catalog_provider.dart';

void main() {
  group('CatalogProvider', () {
    test('loadCatalog() (nominal) charge la liste mockée sans erreur', () async {
      final provider = CatalogProvider();

      await provider.loadCatalog();

      expect(provider.error, isNull);
      expect(provider.isLoading, isFalse);
      expect(provider.products, isNotEmpty);
    });

    test(
      'loadProductDetail() (erreur) avec un id inexistant renseigne error',
      () async {
        final provider = CatalogProvider();

        await provider.loadProductDetail('id-inexistant');

        expect(provider.error, isNotNull);
        expect(provider.isLoading, isFalse);
        expect(provider.selectedProduct, isNull);
      },
    );
  });
}
