import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pharma_connect/modules/delivery/providers/delivery_provider.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-anon-key',
    );
  });

  group('DeliveryProvider', () {
    test(
      'loadDeliveries() (nominal) charge la liste mockée sans erreur',
      () async {
        final provider = DeliveryProvider();

        await provider.loadDeliveries();

        expect(provider.error, isNull);
        expect(provider.isLoading, isFalse);
        expect(provider.deliveries, isNotEmpty);
      },
    );

    test(
      'loadDelivery() (erreur) avec un id inexistant renseigne error',
      () async {
        final provider = DeliveryProvider();

        await provider.loadDelivery('id-inexistant');

        expect(provider.error, isNotNull);
        expect(provider.isLoading, isFalse);
        expect(provider.selectedDelivery, isNull);
      },
    );
  });
}
