import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pharma_connect/core/theme/app_theme.dart';
import 'package:pharma_connect/modules/auth/providers/auth_provider.dart';
import 'package:pharma_connect/modules/dashboard/dashboard_screen.dart';
import 'package:pharma_connect/modules/dashboard/providers/dashboard_provider.dart';

// C261 : tirer le tableau de bord vers le bas montre la roue d'actualisation
// et relit l'état du compte.

/// Relecture de l'état du compte retenue par le test.
class _FakeAuthProvider extends AuthProvider {
  int refreshCalls = 0;
  Completer<void>? pending;
  bool fails = false;

  @override
  Future<void> refreshAccountStatus() async {
    refreshCalls++;
    pending = Completer<void>();
    await pending!.future;
    if (fails) throw Exception('hors connexion');
  }
}

Future<_FakeAuthProvider> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final auth = _FakeAuthProvider();
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
      ],
      child: MaterialApp(
        theme: PharmaConnectAppTheme.light(),
        home: const DashboardScreen(),
      ),
    ),
  );
  // Chargement simulé du tableau de bord (500 ms).
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
  return auth;
}

Future<void> _pullDown(WidgetTester tester) async {
  await tester.fling(find.text('Tableau de bord'), const Offset(0, 400), 1000);
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
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

  testWidgets('tirer vers le bas : roue visible, état du compte relu', (
    tester,
  ) async {
    final auth = await _pump(tester);
    expect(find.byType(RefreshProgressIndicator), findsNothing);

    await _pullDown(tester);
    expect(find.byType(RefreshProgressIndicator), findsOneWidget);
    expect(find.text('Tableau de bord'), findsOneWidget);
    expect(auth.refreshCalls, 1);

    auth.pending!.complete();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(RefreshProgressIndicator), findsNothing);
  });

  testWidgets('actualisation échouée : message, pas d\'erreur', (tester) async {
    final auth = await _pump(tester)
      ..fails = true;
    await _pullDown(tester);
    auth.pending!.complete();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.textContaining('Actualisation impossible'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
