import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pharma_connect/modules/chains/providers/chain_provider.dart';
import 'package:pharma_connect/modules/chains/models/pharmacy_group.dart';

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

  group('ChainProvider', () {
    late ChainProvider provider;

    setUp(() {
      provider = ChainProvider();
    });

    test('initial state', () {
      expect(provider.groups, isEmpty);
      expect(provider.selectedGroup, isNull);
      expect(provider.members, isEmpty);
      expect(provider.transfers, isEmpty);
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
    });

    test('clearError', () {
      provider.errorForTest = 'error';
      provider.clearError();
      expect(provider.error, isNull);
    });

    test('clearSelected', () {
      provider.selectedGroupForTest = PharmacyGroup(
        id: '1',
        name: 'Test Group',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      provider.clearSelected();
      expect(provider.selectedGroup, isNull);
    });
  });
}
