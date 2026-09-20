import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pharma_connect/modules/triage/providers/triage_provider.dart';
import 'package:pharma_connect/modules/triage/models/triage_patient.dart';
import 'package:pharma_connect/modules/triage/models/triage_status.dart';

// Meme motif que auth_provider_test.dart : TriageService (via
// SupabaseService().client) exige que Supabase.initialize() ait ete
// appele au moins une fois dans l'isolat, y compris pour le seul
// constructeur du provider - sans quoi meme les tests d'etat pur (aucun
// appel reseau) plantent a la construction.
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-anon-key',
    );
  });

  group('TriageProvider', () {
    late TriageProvider provider;

    setUp(() {
      provider = TriageProvider();
    });

    test('initial state', () {
      expect(provider.patients, isEmpty);
      expect(provider.selectedPatient, isNull);
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
    });

    test('clearError', () {
      provider.errorForTest = 'error';
      provider.clearError();
      expect(provider.error, isNull);
    });

    test('clearSelected', () {
      provider.selectedPatientForTest = TriagePatient(
        id: '1',
        patientId: 'p1',
        arrivalTime: DateTime.now(),
        status: TriageStatus.waiting,
        priorityLevel: 3,
        chiefComplaint: 'fever',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      provider.clearSelected();
      expect(provider.selectedPatient, isNull);
    });
  });
}
