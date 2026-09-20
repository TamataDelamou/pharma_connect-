import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pharma_connect/modules/teleconsult/providers/teleconsult_provider.dart';
import 'package:pharma_connect/modules/teleconsult/models/consultation.dart';
import 'package:pharma_connect/modules/teleconsult/models/consultation_status.dart';

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

  group('TeleconsultProvider', () {
    late TeleconsultProvider provider;

    setUp(() {
      provider = TeleconsultProvider();
    });

    test('initial state', () {
      expect(provider.consultations, isEmpty);
      expect(provider.selectedConsultation, isNull);
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
    });
    test('clearError works', () {
      provider.errorForTest = 'error';
      provider.clearError();
      expect(provider.error, isNull);
    });

    test('clearSelected works', () {
      provider.selectedConsultationForTest = Consultation(
        id: '1',
        patientId: 'p1',
        professionalId: 'pro1',
        scheduledAt: DateTime.now(),
        status: ConsultationStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      provider.clearSelected();
      expect(provider.selectedConsultation, isNull);
    });
  });
}
