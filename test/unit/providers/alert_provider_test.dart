import 'package:flutter_test/flutter_test.dart';
import 'package:pharma_connect/modules/alerts/providers/alert_provider.dart';

void main() {
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
