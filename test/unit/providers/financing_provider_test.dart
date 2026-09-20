import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pharma_connect/modules/financing/providers/financing_provider.dart';
import 'package:pharma_connect/modules/financing/models/financing_request.dart';

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

  group('FinancingProvider', () {
    late FinancingProvider provider;

    setUp(() {
      provider = FinancingProvider();
    });

    test('initial state', () {
      expect(provider.requests, isEmpty);
      expect(provider.selectedRequest, isNull);
      expect(provider.repayments, isEmpty);
      expect(provider.creditScore, isNull);
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
    });

    test('clearError', () {
      provider.errorForTest = 'error';
      provider.clearError();
      expect(provider.error, isNull);
    });

    test('clearSelected', () {
      provider.selectedRequestForTest = FinancingRequest(
        id: '1',
        pharmacyId: 'p1',
        amount: 100000,
        status: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      provider.clearSelected();
      expect(provider.selectedRequest, isNull);
    });
  });
}
