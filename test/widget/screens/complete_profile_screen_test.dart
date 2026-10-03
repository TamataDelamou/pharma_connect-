import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pharma_connect/modules/auth/providers/auth_provider.dart';
import 'package:pharma_connect/modules/auth/screens/complete_profile_screen.dart';

// C228 : écran « Complétez votre profil », affiché à l'arrivée sur le
// tableau de bord tant que le nom du profil est vide.
class _FakeAuthProvider extends AuthProvider {
  _FakeAuthProvider({required this.nameMissing});

  bool nameMissing;
  bool skipped = false;
  String? savedName;
  String? savedPhone;

  @override
  bool get needsProfileCompletion => nameMissing && !skipped;

  @override
  void skipProfileCompletion() {
    skipped = true;
    notifyListeners();
  }

  @override
  Future<bool> completeProfile({
    required String fullName,
    String? phone,
  }) async {
    savedName = fullName;
    savedPhone = phone;
    nameMissing = false;
    return true;
  }
}

// Même montage que app_router.dart : redirection posée sur /dashboard.
GoRouter _router() => GoRouter(
  initialLocation: '/dashboard',
  routes: [
    GoRoute(
      path: '/dashboard',
      redirect: (context, state) => completeProfileRedirect(context),
      builder: (context, state) =>
          const Scaffold(body: Text('ECRAN TABLEAU DE BORD')),
    ),
    GoRoute(
      path: '/complete-profile',
      builder: (context, state) => const CompleteProfileScreen(),
    ),
  ],
);

Future<_FakeAuthProvider> _pump(
  WidgetTester tester, {
  required bool nameMissing,
}) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final auth = _FakeAuthProvider(nameMissing: nameMissing);
  await tester.pumpWidget(
    ChangeNotifierProvider<AuthProvider>.value(
      value: auth,
      child: MaterialApp.router(routerConfig: _router()),
    ),
  );
  await tester.pumpAndSettle();
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

  testWidgets('nom vide : l\'écran s\'affiche à la place du tableau de bord', (
    tester,
  ) async {
    await _pump(tester, nameMissing: true);

    expect(find.text('Complétez votre profil'), findsOneWidget);
    expect(find.text('ECRAN TABLEAU DE BORD'), findsNothing);
  });

  testWidgets('nom renseigné : l\'écran ne s\'affiche pas', (tester) async {
    await _pump(tester, nameMissing: false);

    expect(find.text('ECRAN TABLEAU DE BORD'), findsOneWidget);
    expect(find.text('Complétez votre profil'), findsNothing);
  });

  testWidgets('nom obligatoire : rien n\'est enregistré sans nom', (
    tester,
  ) async {
    final auth = await _pump(tester, nameMissing: true);

    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(find.text('Le nom est obligatoire'), findsOneWidget);
    expect(auth.savedName, isNull);
    expect(find.text('ECRAN TABLEAU DE BORD'), findsNothing);
  });

  testWidgets('nom saisi : enregistré, puis tableau de bord', (tester) async {
    final auth = await _pump(tester, nameMissing: true);

    await tester.enterText(find.byType(TextField).first, '  Achille Test  ');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(auth.savedName, 'Achille Test');
    expect(auth.savedPhone, isNull);
    expect(find.text('ECRAN TABLEAU DE BORD'), findsOneWidget);
  });

  testWidgets('« Plus tard » mène au tableau de bord sans rien enregistrer', (
    tester,
  ) async {
    final auth = await _pump(tester, nameMissing: true);

    await tester.tap(find.text('Plus tard'));
    await tester.pumpAndSettle();

    expect(auth.skipped, isTrue);
    expect(auth.savedName, isNull);
    expect(find.text('ECRAN TABLEAU DE BORD'), findsOneWidget);
  });
}
