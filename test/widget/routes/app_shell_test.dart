import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pharma_connect/core/widgets/navigation/sidebar_navigation.dart';
import 'package:pharma_connect/modules/auth/providers/auth_provider.dart';
import 'package:pharma_connect/routes/app_shell.dart';

// C226 : cadre de navigation commun (AppShell), sur un routeur de test qui
// reproduit la structure de app_router.dart (ShellRoute autour des routes
// connectées, /login hors du cadre).
class _FakeAuthProvider extends AuthProvider {
  int logoutCalls = 0;

  @override
  Future<void> logout() async {
    logoutCalls++;
  }
}

Widget _page(String label) => Scaffold(body: Center(child: Text(label)));

GoRouter _router(String initialLocation) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(path: '/login', builder: (_, _) => _page('ECRAN CONNEXION')),
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/dashboard', builder: (_, _) => _page('ECRAN ACCUEIL')),
        GoRoute(path: '/zone', builder: (_, _) => _page('ECRAN ZONE')),
        GoRoute(path: '/zone/detail', builder: (_, _) => _page('ECRAN DETAIL')),
        GoRoute(path: '/family/:id', builder: (_, _) => _page('ECRAN FAMILLE')),
        GoRoute(
          path: '/family/challenges/:id',
          builder: (_, _) => _page('ECRAN DEFI'),
        ),
      ],
    ),
  ],
);

Future<_FakeAuthProvider> _pump(
  WidgetTester tester, {
  required String location,
  required double width,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final auth = _FakeAuthProvider();
  await tester.pumpWidget(
    ChangeNotifierProvider<AuthProvider>.value(
      value: auth,
      child: MaterialApp.router(routerConfig: _router(location)),
    ),
  );
  await _settle(tester);
  return auth;
}

// L'indicateur Kernel de la barre latérale est animé en boucle :
// pumpAndSettle n'aboutirait jamais, on avance le temps par paliers.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
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

  testWidgets('étroit : barre du haut, flèche retour et tiroir avec le menu', (
    tester,
  ) async {
    await _pump(tester, location: '/zone', width: 400);

    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byTooltip('Retour'), findsOneWidget);
    // Pas de barre latérale permanente en largeur téléphone.
    expect(find.byType(SidebarNavigation), findsNothing);

    await tester.tap(find.byTooltip('Menu'));
    await _settle(tester);

    expect(find.byType(Drawer), findsOneWidget);
    expect(find.text('Tableau de bord'), findsOneWidget);
    expect(find.text('Se déconnecter'), findsOneWidget);

    // Une entrée du menu navigue et referme le tiroir.
    await tester.tap(find.text('Tableau de bord'));
    await _settle(tester);
    expect(find.text('ECRAN ACCUEIL'), findsOneWidget);
    expect(find.byType(Drawer), findsNothing);
  });

  testWidgets('pas de flèche retour sur /dashboard', (tester) async {
    await _pump(tester, location: '/dashboard', width: 400);

    expect(find.text('ECRAN ACCUEIL'), findsOneWidget);
    expect(find.byTooltip('Retour'), findsNothing);
    expect(find.byTooltip('Menu'), findsOneWidget);
  });

  testWidgets('large : barre latérale toujours visible, pas de barre du haut', (
    tester,
  ) async {
    await _pump(tester, location: '/zone', width: 1400);

    expect(find.byType(SidebarNavigation), findsOneWidget);
    expect(find.byType(AppBar), findsNothing);
    expect(find.text('Se déconnecter'), findsOneWidget);
    expect(find.text('ECRAN ZONE'), findsOneWidget);
  });

  testWidgets(
    'retour depuis une adresse ouverte directement : parent puis tableau de bord',
    (tester) async {
      await _pump(tester, location: '/zone/detail', width: 400);
      expect(find.text('ECRAN DETAIL'), findsOneWidget);

      await tester.tap(find.byTooltip('Retour'));
      await _settle(tester);
      expect(find.text('ECRAN ZONE'), findsOneWidget);

      await tester.tap(find.byTooltip('Retour'));
      await _settle(tester);
      expect(find.text('ECRAN ACCUEIL'), findsOneWidget);
      expect(find.byTooltip('Retour'), findsNothing);
    },
  );

  testWidgets(
    'parente absente du routeur : /family/challenges/:id revient au tableau '
    'de bord, pas au détail de la famille « challenges »',
    (tester) async {
      await _pump(tester, location: '/family/challenges/d1', width: 400);
      expect(find.text('ECRAN DEFI'), findsOneWidget);

      await tester.tap(find.byTooltip('Retour'));
      await _settle(tester);
      expect(find.text('ECRAN ACCUEIL'), findsOneWidget);
      expect(find.text('ECRAN FAMILLE'), findsNothing);
    },
  );

  testWidgets('bouton retour du système : même logique que la flèche', (
    tester,
  ) async {
    await _pump(tester, location: '/zone/detail', width: 400);

    // Simule le bouton retour d'Android.
    await tester.binding.handlePopRoute();
    await _settle(tester);
    expect(find.text('ECRAN ZONE'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await _settle(tester);
    expect(find.text('ECRAN ACCUEIL'), findsOneWidget);
  });

  testWidgets('Se déconnecter (tiroir), confirmé : logout() puis /login', (
    tester,
  ) async {
    final auth = await _pump(tester, location: '/zone', width: 400);

    await tester.tap(find.byTooltip('Menu'));
    await _settle(tester);
    await tester.tap(find.text('Se déconnecter'));
    await _settle(tester);
    expect(find.text('Voulez-vous vous déconnecter ?'), findsOneWidget);

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
    final auth = await _pump(tester, location: '/zone', width: 1400);

    await tester.tap(find.text('Se déconnecter'));
    await _settle(tester);
    await tester.tap(find.text('Annuler'));
    await _settle(tester);

    expect(auth.logoutCalls, 0);
    expect(find.text('ECRAN ZONE'), findsOneWidget);
  });
}
