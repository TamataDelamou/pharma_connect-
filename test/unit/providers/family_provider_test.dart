import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pharma_connect/modules/family/providers/family_provider.dart';
import 'package:pharma_connect/modules/family/models/family_link.dart';
import 'package:pharma_connect/modules/family/models/family_link_status.dart';

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

  group('FamilyProvider', () {
    late FamilyProvider provider;

    setUp(() {
      provider = FamilyProvider();
    });

    test('initial state', () {
      expect(provider.links, isEmpty);
      expect(provider.incomingRequests, isEmpty);
      expect(provider.selectedLink, isNull);
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
      expect(provider.unreadAlertCount, 0);
    });

    test('clearError', () {
      provider.errorForTest = 'error';
      provider.clearError();
      expect(provider.error, isNull);
    });

    test('clearSelected', () {
      provider.selectedLinkForTest = FamilyLink(
        id: '1',
        patientId: 'p1',
        familyMemberId: 'f1',
        relationship: 'parent',
        status: FamilyLinkStatus.active,
        invitedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      provider.clearSelected();
      expect(provider.selectedLink, isNull);
    });
  });
}
