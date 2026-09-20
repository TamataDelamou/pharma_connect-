import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pharma_connect/modules/healthrecord/providers/health_record_provider.dart';
import 'package:pharma_connect/modules/healthrecord/models/health_record.dart';

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

  group('HealthRecordProvider', () {
    late HealthRecordProvider provider;

    setUp(() {
      provider = HealthRecordProvider();
    });

    test('initial state is correct', () {
      expect(provider.records, isEmpty);
      expect(provider.selectedRecord, isNull);
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
    });

    test('loadRecords handles error gracefully', () async {
      // Simulate a failure by passing an invalid patientId
      await provider.loadRecords('invalid-id');
      expect(provider.error, isNotNull);
      expect(provider.isLoading, isFalse);
      expect(provider.records, isEmpty);
    });

    test('clearError resets error state', () {
      provider.errorForTest = 'Some error';
      provider.clearError();
      expect(provider.error, isNull);
    });

    test('clearSelected resets selected record', () {
      final record = HealthRecord(
        id: '1',
        patientId: 'p1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      provider.selectedRecordForTest = record;
      provider.clearSelected();
      expect(provider.selectedRecord, isNull);
    });
  });
}
