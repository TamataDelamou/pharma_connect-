import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pharma_connect/modules/iot/providers/iot_provider.dart';
import 'package:pharma_connect/modules/iot/models/iot_device.dart';

// Meme motif que auth_provider_test.dart : le service sous-jacent (via
// SupabaseService().client) exige que Supabase.initialize() ait ete
// appele au moins une fois dans l'isolat, y compris pour le seul
// constructeur du provider.
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-anon-key',
    );
  });

  group('IotProvider', () {
    late IotProvider provider;

    setUp(() {
      provider = IotProvider();
    });

    test('initial state', () {
      expect(provider.devices, isEmpty);
      expect(provider.selectedDevice, isNull);
      expect(provider.readings, isEmpty);
      expect(provider.alerts, isEmpty);
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
    });

    test('clearError', () {
      provider.errorForTest = 'error';
      provider.clearError();
      expect(provider.error, isNull);
    });

    test('clearSelected', () {
      provider.selectedDeviceForTest = IotDevice(
        id: '1',
        deviceId: 'DEV001',
        name: 'Test',
        type: 'temperature_sensor',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      provider.clearSelected();
      expect(provider.selectedDevice, isNull);
    });
  });
}
