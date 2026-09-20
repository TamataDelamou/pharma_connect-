import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pharma_connect/modules/insurance/providers/insurance_provider.dart';
import 'package:pharma_connect/modules/insurance/models/insurance_enrollment.dart';

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

  group('InsuranceProvider', () {
    late InsuranceProvider provider;

    setUp(() {
      provider = InsuranceProvider();
    });

    test('initial state', () {
      expect(provider.companies, isEmpty);
      expect(provider.enrollments, isEmpty);
      expect(provider.selectedEnrollment, isNull);
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
    });

    test('clearError', () {
      provider.errorForTest = 'error';
      provider.clearError();
      expect(provider.error, isNull);
    });

    test('clearSelected', () {
      provider.selectedEnrollmentForTest = InsuranceEnrollment(
        id: '1',
        patientId: 'p1',
        planId: 'plan1',
        policyNumber: 'POL123',
        startDate: DateTime.now(),
        status: 'active',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      provider.clearSelected();
      expect(provider.selectedEnrollment, isNull);
    });
  });
}
