import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pharma_connect/modules/search/providers/search_provider.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-anon-key',
    );
  });

  group('SearchProvider', () {
    test('search() (nominal) trouve des résultats sans erreur', () async {
      final provider = SearchProvider();

      await provider.search(query: 'Dafalgan');

      expect(provider.error, isNull);
      expect(provider.status, SearchStatus.loaded);
      expect(provider.results, isNotEmpty);
    });

    test(
      'scanBarcode() (erreur) avec un code-barres inconnu renseigne error',
      () async {
        final provider = SearchProvider();

        await provider.scanBarcode('code-barres-inconnu');

        expect(provider.error, isNotNull);
        expect(provider.status, SearchStatus.error);
        expect(provider.scannedProduct, isNull);
      },
    );
  });
}
