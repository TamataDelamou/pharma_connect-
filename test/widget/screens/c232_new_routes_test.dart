import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pharma_connect/modules/auth/providers/auth_provider.dart';
import 'package:pharma_connect/modules/family/providers/family_challenge_provider.dart';
import 'package:pharma_connect/modules/family/screens/family_challenge_detail_screen.dart';
import 'package:pharma_connect/modules/solidarity/providers/solidarity_provider.dart';
import 'package:pharma_connect/modules/solidarity/screens/solidarity_dashboard_screen.dart';

// C232 : routes ajoutées vers des écrans déjà construits.
// - /family/challenges/:id ouvre le détail du défi avec l'identifiant reçu ;
// - « Nouveau programme » (/solidarity/program/new) n'est montré qu'à
//   l'administration GSG (RLS « Staff manage solidarity programs » :
//   is_gsg_admin()).
GoRouter _router(String initialLocation) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(
      path: '/family/challenges/:id',
      builder: (context, state) =>
          FamilyChallengeDetailScreen(challengeId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/solidarity/staff',
      builder: (context, state) =>
          const SolidarityDashboardScreen(isStaff: true),
    ),
  ],
);

Widget _app(String initialLocation) => MultiProvider(
  providers: [
    // Compte non connecté : isGsgAdmin == false.
    ChangeNotifierProvider(create: (_) => AuthProvider()),
    ChangeNotifierProvider(create: (_) => FamilyChallengeProvider()),
    ChangeNotifierProvider(create: (_) => SolidarityProvider()),
  ],
  child: MaterialApp.router(routerConfig: _router(initialLocation)),
);

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-anon-key',
    );
  });

  testWidgets('/family/challenges/:id ouvre le détail du défi', (tester) async {
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app('/family/challenges/defi-42'));
    await tester.pump();

    final screen = tester.widget<FamilyChallengeDetailScreen>(
      find.byType(FamilyChallengeDetailScreen),
    );
    expect(screen.challengeId, 'defi-42');
  });

  testWidgets(
    '/solidarity/staff sans être administrateur GSG : pas de « Nouveau programme »',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app('/solidarity/staff'));
      await tester.pump();

      expect(find.byType(SolidarityDashboardScreen), findsOneWidget);
      expect(find.text('Nouveau programme'), findsNothing);
    },
  );
}
