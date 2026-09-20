import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pharma_connect/modules/dashboard/providers/dashboard_provider.dart';
import 'package:pharma_connect/modules/dashboard/dashboard_screen.dart';
import 'package:pharma_connect/modules/auth/providers/auth_provider.dart';

void main() {
  setUpAll(() async {
    // AuthProvider -> AuthService construit SupabaseService().auth des le
    // constructeur (meme motif que les autres tests de ce depot) : Supabase
    // doit etre initialise avant meme d'instancier AuthProvider.
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-anon-key',
    );
  });

  testWidgets('DashboardScreen se construit avec DashboardProvider sans exception', (
    tester,
  ) async {
    // DashboardScreen lit aussi AuthProvider (role affiche dans l'entete) -
    // absent du wrapper d'origine, ProviderNotFoundException a la construction.
    await tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => DashboardProvider()),
          ],
          child: const DashboardScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(tester.takeException(), isNull);
    expect(find.byType(DashboardScreen), findsOneWidget);
  });
}
