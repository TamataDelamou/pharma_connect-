import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

import 'package:pharma_connect/modules/payments/providers/payment_provider.dart';
import 'package:pharma_connect/modules/payments/screens/wallet_screen.dart';
import 'package:pharma_connect/modules/auth/providers/auth_provider.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-anon-key',
    );
  });

  testWidgets('WalletScreen se construit avec PaymentProvider sans exception', (
    tester,
  ) async {
    // WalletScreen lit aussi AuthProvider (userId courant) - absent du
    // wrapper d'origine, ProviderNotFoundException a la construction.
    await tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => PaymentProvider()),
          ],
          child: const WalletScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(tester.takeException(), isNull);
    expect(find.byType(WalletScreen), findsOneWidget);
  });
}
