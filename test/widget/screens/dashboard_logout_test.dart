import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pharma_connect/modules/auth/providers/auth_provider.dart';
import 'package:pharma_connect/modules/dashboard/dashboard_screen.dart';
import 'package:pharma_connect/modules/dashboard/providers/dashboard_provider.dart';

// C231 : « Se déconnecter » (barre latérale du tableau de bord) demande une
// confirmation, puis appelle AuthProvider.logout() et revient à /login.
class _FakeAuthProvider extends AuthProvider {
  int logoutCalls = 0;

  @override
  Future<void> logout() async {
    logoutCalls++;
  }
}

Future<_FakeAuthProvider> _pumpDashboard(WidgetTester tester) async {
  // Fenêtre de bureau : la barre latérale et le tableau de bord tiennent.
  tester.view.physicalSize = const Size(1600, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final auth = _FakeAuthProvider();
  final router = GoRouter(
    initialLocation: '/dashboard',
    routes: [
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const Text('ECRAN CONNEXION'),
      ),
    ],
  );
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
  return auth;
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-anon-key',
    );
  });

  testWidgets('Se déconnecter, confirmé : logout() appelé, retour à /login', (
    tester,
  ) async {
    final auth = await _pumpDashboard(tester);

    await tester.tap(find.text('Se déconnecter'));
    await _settle(tester);
    expect(find.text('Voulez-vous vous déconnecter ?'), findsOneWidget);

    // Bouton de confirmation de la boîte de dialogue.
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Se déconnecter'),
      ),
    );
    await _settle(tester);

    expect(auth.logoutCalls, 1);
    expect(find.text('ECRAN CONNEXION'), findsOneWidget);
  });

  testWidgets('Se déconnecter, annulé : logout() non appelé', (tester) async {
    final auth = await _pumpDashboard(tester);

    await tester.tap(find.text('Se déconnecter'));
    await _settle(tester);
    await tester.tap(find.text('Annuler'));
    await _settle(tester);

    expect(auth.logoutCalls, 0);
    expect(find.byType(DashboardScreen), findsOneWidget);
  });
}

// L'indicateur Kernel de la barre latérale est animé en boucle :
// pumpAndSettle n'aboutirait jamais, on avance le temps par paliers.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
