import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pharma_connect/modules/recall/providers/recall_provider.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-anon-key',
    );
  });

  group('RecallProvider', () {
    test('loadRecalls() (nominal) charge la liste mockée sans erreur', () async {
      final provider = RecallProvider();

      await provider.loadRecalls();

      expect(provider.error, isNull);
      expect(provider.isLoading, isFalse);
      expect(provider.recalls, isNotEmpty);
    });

    test('loadRecall() (erreur) avec un id inexistant renseigne error', () async {
      final provider = RecallProvider();

      await provider.loadRecall('id-inexistant');

      expect(provider.error, isNotNull);
      expect(provider.isLoading, isFalse);
      expect(provider.selectedRecall, isNull);
    });
  });
}
