import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pharma_connect/modules/solidarity/providers/solidarity_provider.dart';
import 'package:pharma_connect/modules/solidarity/models/solidarity_program.dart';

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

  group('SolidarityProvider', () {
    late SolidarityProvider provider;

    setUp(() {
      provider = SolidarityProvider();
    });

    test('initial state', () {
      expect(provider.programs, isEmpty);
      expect(provider.selectedProgram, isNull);
      expect(provider.beneficiaries, isEmpty);
      expect(provider.selectedBeneficiary, isNull);
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
    });

    test('clearError', () {
      provider.errorForTest = 'error';
      provider.clearError();
      expect(provider.error, isNull);
    });

    test('clearSelected', () {
      provider.selectedProgramForTest = SolidarityProgram(
        id: '1',
        name: 'Test',
        type: 'free_medication',
        startDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      provider.clearSelected();
      expect(provider.selectedProgram, isNull);
    });
  });
}
