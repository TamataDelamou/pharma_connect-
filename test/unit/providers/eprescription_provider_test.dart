import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pharma_connect/modules/eprescription/providers/eprescription_provider.dart';
import 'package:pharma_connect/modules/eprescription/models/eprescription.dart';

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

  group('EPrescriptionProvider', () {
    late EPrescriptionProvider provider;

    setUp(() {
      provider = EPrescriptionProvider();
    });

    test('initial state', () {
      expect(provider.prescriptions, isEmpty);
      expect(provider.selectedPrescription, isNull);
      expect(provider.items, isEmpty);
      expect(provider.history, isEmpty);
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
    });

    test('clearError', () {
      provider.errorForTest = 'error';
      provider.clearError();
      expect(provider.error, isNull);
    });

    test('clearSelected', () {
      provider.selectedPrescriptionForTest = EPrescription(
        id: '1',
        prescriptionNumber: 'RX001',
        patientId: 'p1',
        doctorId: 'd1',
        prescribedAt: DateTime.now(),
        validUntil: DateTime.now().add(const Duration(days: 30)),
        status: 'draft',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      provider.clearSelected();
      expect(provider.selectedPrescription, isNull);
    });
  });
}
