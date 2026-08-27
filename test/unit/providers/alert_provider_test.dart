import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pharma_connect/modules/alerts/providers/alert_provider.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-anon-key',
    );
  });

  group('AlertProvider', () {
    test('loadAlerts() (nominal) charge la liste mockée sans erreur', () async {
      final provider = AlertProvider();

      await provider.loadAlerts();

      expect(provider.error, isNull);
      expect(provider.isLoading, isFalse);
      expect(provider.alerts, isNotEmpty);
    });

    test('loadAlert() (erreur) avec un id inexistant renseigne error', () async {
      final provider = AlertProvider();

      await provider.loadAlert('id-inexistant');

      expect(provider.error, isNotNull);
      expect(provider.isLoading, isFalse);
      expect(provider.selectedAlert, isNull);
    });
  });
}
