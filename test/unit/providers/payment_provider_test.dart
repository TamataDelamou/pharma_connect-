import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pharma_connect/modules/payments/providers/payment_provider.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-anon-key',
    );
  });

  group('PaymentProvider', () {
    test(
      'loadTransactions() (nominal) charge la liste mockée sans erreur',
      () async {
        final provider = PaymentProvider();

        await provider.loadTransactions();

        expect(provider.error, isNull);
        expect(provider.isLoading, isFalse);
        expect(provider.transactions, isNotEmpty);
      },
    );

    test(
      'loadTransaction() (erreur) avec un id inexistant renseigne error',
      () async {
        final provider = PaymentProvider();

        await provider.loadTransaction('id-inexistant');

        expect(provider.error, isNotNull);
        expect(provider.isLoading, isFalse);
        expect(provider.selectedTransaction, isNull);
      },
    );
  });
}
