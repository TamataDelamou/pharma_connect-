import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pharma_connect/app.dart';
import 'package:pharma_connect/core/theme/adaptive_text_scale.dart';
import 'package:pharma_connect/core/theme/app_theme.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/routes/app_router.dart';

// C233 : textes et mise en page sur un petit téléphone (360 px de large).
// Les écrans réels sont montés avec les routes de app_router.dart (sans la
// redirection de connexion), dans AppShell, avec l'échelle de texte
// adaptative posée comme dans app.dart.

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-anon-key',
    );
  });

  group('échelle de texte adaptative (tokens)', () {
    test('en largeur téléphone, les titres perdent 20 à 30 %', () {
      double reduction(double size) =>
          1 - PharmaConnectTypography.compactFontSize(size) / size;
      for (final style in [
        PharmaConnectTypography.heading1,
        PharmaConnectTypography.heading2,
        PharmaConnectTypography.kpiLarge,
        PharmaConnectTypography.kpiMedium,
      ]) {
        expect(reduction(style.fontSize!), inInclusiveRange(0.20, 0.30));
      }
      // heading3 (22 px) : 18 px, soit 18 %, pour rester au-dessus du texte
      // courant.
      expect(PharmaConnectTypography.compactFontSize(22), 18);
    });

    test('le texte courant ne change pas (16 et 14 px)', () {
      expect(PharmaConnectTypography.compactFontSize(16), 16);
      expect(PharmaConnectTypography.compactFontSize(14), 14);
      expect(PharmaConnectTypography.compactFontSize(12), 12);
    });

    test('réglage du téléphone respecté, plafonné à 1,3', () {
      final big = PharmaConnectTypography.textScalerFor(
        width: 360,
        system: const TextScaler.linear(2.0),
      );
      expect(big.scale(14), closeTo(14 * 1.3, 0.001));

      final medium = PharmaConnectTypography.textScalerFor(
        width: 360,
        system: const TextScaler.linear(1.15),
      );
      expect(medium.scale(14), closeTo(14 * 1.15, 0.001));
    });

    test('en largeur ≥ 600 px, aucune réduction', () {
      final wide = PharmaConnectTypography.textScalerFor(
        width: 1200,
        system: TextScaler.noScaling,
      );
      expect(wide.scale(36), 36);
      expect(wide.scale(28), 28);
    });
  });

  testWidgets('à 360 px : tableau de bord, recherche et objectifs santé sans '
      'débordement, titre de la barre sur une ligne', (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: '/dashboard',
      routes: AppRouter.router.configuration.routes,
    );

    // Seuls les débordements sont contrôlés : hors ligne, les écrans
    // signalent aussi des erreurs réseau, attendues ici.
    final overflows = <String>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      final message = details.exceptionAsString();
      if (message.contains('overflowed')) overflows.add(message);
    };
    addTearDown(() => FlutterError.onError = previousOnError);

    await tester.pumpWidget(
      MultiProvider(
        providers: appProviders(restoreSession: false),
        child: MaterialApp.router(
          theme: PharmaConnectAppTheme.dark(),
          routerConfig: router,
          builder: (context, child) => AdaptiveTextScale(child: child!),
        ),
      ),
    );

    const screens = {
      '/dashboard': 'Tableau de bord',
      '/search': 'Recherche',
      '/healthrecord/goals': 'Objectifs santé',
    };
    for (final entry in screens.entries) {
      overflows.clear();
      router.go(entry.key);
      // L'indicateur Kernel est animé en boucle : pas de pumpAndSettle.
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 150));
      }

      expect(overflows, isEmpty, reason: 'débordement sur ${entry.key}');

      // Titre de la barre du haut : le bon libellé, sur une seule ligne.
      final title = find.descendant(
        of: find.byType(AppBar),
        matching: find.text(entry.value),
      );
      expect(title, findsOneWidget, reason: 'titre de ${entry.key}');
      final paragraph = tester.renderObject<RenderParagraph>(
        find.descendant(of: title, matching: find.byType(RichText)),
      );
      final style = paragraph.text.style!;
      final lineHeight =
          paragraph.textScaler.scale(style.fontSize!) * (style.height ?? 1.2);
      expect(
        paragraph.size.height,
        lessThan(lineHeight * 1.5),
        reason: 'titre de ${entry.key} sur plus d\'une ligne',
      );
    }
    tester.takeException();
  });
}
