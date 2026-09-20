import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pharma_connect/modules/analytics/providers/analytics_provider.dart';
import 'package:pharma_connect/modules/analytics/models/analytics_dashboard.dart';

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

  group('AnalyticsProvider', () {
    late AnalyticsProvider provider;

    setUp(() {
      provider = AnalyticsProvider();
    });

    test('initial state', () {
      expect(provider.dailyStats, isEmpty);
      expect(provider.pharmacyPerformance, isEmpty);
      expect(provider.topProducts, isEmpty);
      expect(provider.summary, isNull);
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
    });

    test('clearError', () {
      provider.errorForTest = 'error';
      provider.clearError();
      expect(provider.error, isNull);
    });

    test('clearSelected', () {
      provider.selectedDashboardForTest = AnalyticsDashboard(
        id: '1',
        userId: 'u1',
        name: 'Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      provider.clearSelected();
      expect(provider.selectedDashboard, isNull);
    });
  });
}
