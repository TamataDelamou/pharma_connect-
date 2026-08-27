import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pharma_connect/modules/coldchain/providers/coldchain_provider.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-anon-key',
    );
  });

  group('ColdChainProvider', () {
    test(
      'loadEquipments() (nominal) charge la liste mockée sans erreur',
      () async {
        final provider = ColdChainProvider();

        await provider.loadEquipments();

        expect(provider.error, isNull);
        expect(provider.isLoading, isFalse);
        expect(provider.equipments, isNotEmpty);
      },
    );

    test(
      'loadEquipment() (erreur) avec un id inexistant renseigne error',
      () async {
        final provider = ColdChainProvider();

        await provider.loadEquipment('id-inexistant');

        expect(provider.error, isNotNull);
        expect(provider.isLoading, isFalse);
        expect(provider.selectedEquipment, isNull);
      },
    );
  });
}
