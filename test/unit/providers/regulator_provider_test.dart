import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pharma_connect/modules/regulator/providers/regulator_provider.dart';
import 'package:pharma_connect/modules/regulator/models/adverse_reaction.dart';

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

  group('RegulatorProvider', () {
    late RegulatorProvider provider;

    setUp(() {
      provider = RegulatorProvider();
    });

    test('initial state', () {
      expect(provider.reactions, isEmpty);
      expect(provider.selectedReaction, isNull);
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
    });

    test('clearError', () {
      provider.errorForTest = 'error';
      provider.clearError();
      expect(provider.error, isNull);
    });

    test('clearSelected', () {
      provider.selectedReactionForTest = AdverseReaction(
        id: '1',
        reporterId: 'reporter_1',
        reporterType: 'patient',
        medicationName: 'Test',
        reactionDate: DateTime.now(),
        reportedAt: DateTime.now(),
        symptoms: 'test',
        severity: 'mild',
        status: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      provider.clearSelected();
      expect(provider.selectedReaction, isNull);
    });
  });
}
