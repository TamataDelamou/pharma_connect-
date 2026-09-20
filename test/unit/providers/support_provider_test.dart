import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pharma_connect/modules/support/providers/support_provider.dart';
import 'package:pharma_connect/modules/support/models/ticket.dart';

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

  group('SupportProvider', () {
    late SupportProvider provider;

    setUp(() {
      provider = SupportProvider();
    });

    test('initial state', () {
      expect(provider.tickets, isEmpty);
      expect(provider.openTickets, isEmpty);
      expect(provider.selectedTicket, isNull);
      expect(provider.responses, isEmpty);
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
    });

    test('clearError', () {
      provider.errorForTest = 'error';
      provider.clearError();
      expect(provider.error, isNull);
    });

    test('clearSelected', () {
      provider.selectedTicketForTest = SupportTicket(
        id: '1',
        ticketNumber: 'T001',
        patientId: 'p1',
        subject: 'test',
        description: 'test',
        status: 'new',
        priority: 'medium',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      provider.clearSelected();
      expect(provider.selectedTicket, isNull);
    });
  });
}
