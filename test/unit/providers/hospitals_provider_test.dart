import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pharma_connect/modules/hospitals/providers/hospitals_provider.dart';
import 'package:pharma_connect/modules/hospitals/models/hospital.dart';

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

  group('HospitalsProvider', () {
    late HospitalsProvider provider;

    setUp(() {
      provider = HospitalsProvider();
    });

    test('initial state', () {
      expect(provider.hospitals, isEmpty);
      expect(provider.selectedHospital, isNull);
      expect(provider.hospitalTypes, isEmpty);
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
    });

    test('clearError', () {
      provider.errorForTest = 'error';
      provider.clearError();
      expect(provider.error, isNull);
    });

    test('clearSelected', () {
      provider.selectedHospitalForTest = Hospital(
        id: '1',
        name: 'Test Hospital',
        address: '123 Test St',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      provider.clearSelected();
      expect(provider.selectedHospital, isNull);
    });
  });
}
