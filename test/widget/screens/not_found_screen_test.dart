import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:pharma_connect/core/widgets/screens/not_found_screen.dart';

// C231 : la page « Page introuvable » propose un retour qui fonctionne
// (tableau de bord si connecté, connexion sinon).
GoRouter _router({required bool isAuthenticated}) => GoRouter(
  initialLocation: '/route-inexistante',
  errorBuilder: (context, state) =>
      NotFoundScreen(isAuthenticated: isAuthenticated),
  routes: [
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const Text('ECRAN TABLEAU DE BORD'),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const Text('ECRAN CONNEXION'),
    ),
  ],
);

void main() {
  testWidgets(
    'route inconnue, connecté : Page introuvable puis retour au tableau de bord',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(routerConfig: _router(isAuthenticated: true)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Page introuvable'), findsOneWidget);
      expect(find.text('Retour au tableau de bord'), findsOneWidget);

      await tester.tap(find.text('Retour au tableau de bord'));
      await tester.pumpAndSettle();

      expect(find.text('ECRAN TABLEAU DE BORD'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('route inconnue, non connecté : retour à la connexion', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp.router(routerConfig: _router(isAuthenticated: false)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Page introuvable'), findsOneWidget);
    await tester.tap(find.text('Retour à la connexion'));
    await tester.pumpAndSettle();

    expect(find.text('ECRAN CONNEXION'), findsOneWidget);
  });
}
