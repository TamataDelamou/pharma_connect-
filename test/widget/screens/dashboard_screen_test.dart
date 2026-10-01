import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pharma_connect/modules/auth/providers/auth_provider.dart';
import 'package:pharma_connect/modules/dashboard/providers/dashboard_provider.dart';
import 'package:pharma_connect/modules/dashboard/dashboard_screen.dart';

// C213 : DashboardScreen lit AuthProvider (rôle effectif, bandeau d'état du
// compte), fourni au-dessus de tous les écrans dans app.dart. Le test le
// fournit aussi ; comme dans login_screen_test.dart, le constructeur
// d'AuthProvider exige que Supabase.initialize() ait été appelé.
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-anon-key',
    );
  });

  testWidgets(
    'DashboardScreen se construit avec DashboardProvider sans exception',
    (tester) async {
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
    },
  );
}
