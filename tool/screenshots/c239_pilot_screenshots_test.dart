// C239 : captures d'écran à 360 px de large des écrans touchés par les
// masquages du pilote (`PilotConfig`).
//
//   flutter test tool/screenshots/c239_pilot_screenshots_test.dart
//
// Les images sont écrites dans build/c239_screenshots/ (non versionné). Ce
// fichier est hors de test/ : il ne tourne pas avec `flutter test`. Même
// montage que c234_theme_screenshots_test.dart : écrans hors ligne, routes
// réelles, données vides ou en erreur réseau.
// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pharma_connect/app.dart';
import 'package:pharma_connect/core/theme/adaptive_text_scale.dart';
import 'package:pharma_connect/core/theme/app_theme.dart';
import 'package:pharma_connect/modules/auth/models/user_role.dart';
import 'package:pharma_connect/modules/auth/providers/auth_provider.dart';
import 'package:pharma_connect/routes/app_router.dart';

const _outputDir = 'build/c239_screenshots';
const _size = Size(360, 780);

Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final path in paths) {
    final bytes = File(path).readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

class _Shot {
  final String name;
  final String route;
  final Object? extra;
  final void Function(AuthProvider auth)? prepare;

  /// Gestes à jouer avant la capture (avancer dans un parcours).
  final Future<void> Function(WidgetTester tester)? act;

  const _Shot(this.name, this.route, {this.extra, this.prepare, this.act});
}

Future<void> _settle(WidgetTester tester) async {
  // L'indicateur Kernel est animé en boucle : pas de pumpAndSettle.
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 150));
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
    const inter = 'assets/fonts/Inter';
    await _loadFont('Inter', [
      '$inter/Inter-Regular.ttf',
      '$inter/Inter-Medium.ttf',
      '$inter/Inter-SemiBold.ttf',
      '$inter/Inter-Bold.ttf',
    ]);
    await _loadFont('JetBrainsMono', [
      'assets/fonts/JetBrainsMono/JetBrainsMono-Light.ttf',
    ]);
    final flutterRoot = Platform.environment['FLUTTER_ROOT'];
    if (flutterRoot != null) {
      await _loadFont('MaterialIcons', [
        '$flutterRoot/bin/cache/artifacts/material_fonts/'
            'MaterialIcons-Regular.otf',
      ]);
    }
    Directory(_outputDir).createSync(recursive: true);
  });

  final shots = <_Shot>[
    const _Shot('01_login', '/login'),
    const _Shot('02_register', '/register'),
    // Étapes affichées pendant le pilote : récapitulatif, paiement,
    // confirmation. La confirmation demande une réservation créée sur le
    // serveur : elle n'est pas capturable hors ligne.
    _Shot(
      '03a_reservations_checkout_recapitulatif',
      '/reservations/checkout',
      prepare: (auth) => auth.setRole(UserRole.patient),
    ),
    _Shot(
      '03b_reservations_checkout_paiement',
      '/reservations/checkout',
      prepare: (auth) => auth.setRole(UserRole.patient),
      act: (tester) async {
        await tester.tap(find.text('Continuer'));
        await _settle(tester);
      },
    ),
    _Shot(
      '04_payments',
      '/payments',
      // Montant d'exemple, pour afficher le résumé.
      extra: 25000,
      prepare: (auth) => auth.setRole(UserRole.patient),
    ),
    _Shot(
      '05_dashboard_patient',
      '/dashboard',
      prepare: (auth) => auth.setRole(UserRole.patient),
    ),
    // Écran « IA » masqué : l'adresse de l'assistant renvoie à /support, où
    // le bouton « Chat support » n'apparaît plus.
    _Shot(
      '06_support_chat_masque',
      '/support/chat',
      prepare: (auth) => auth.setRole(UserRole.patient),
    ),
    // Dépôt d'ordonnance sans lecture automatique.
    _Shot(
      '07_prescriptions_upload',
      '/prescriptions/upload',
      prepare: (auth) => auth.setRole(UserRole.patient),
    ),
  ];

  for (final shot in shots) {
    testWidgets('capture ${shot.name}', (tester) async {
      tester.view.physicalSize = _size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // Les ombres sont remplacées par un trait noir en test : rétablies
      // pour la capture.
      debugDisableShadows = false;

      // Hors ligne, les écrans signalent des erreurs réseau : ignorées ici.
      final previousOnError = FlutterError.onError;
      FlutterError.onError = (_) {};

      final router = GoRouter(
        initialLocation: shot.route,
        initialExtra: shot.extra,
        routes: AppRouter.router.configuration.routes,
      );
      final boundaryKey = GlobalKey();

      await tester.pumpWidget(
        RepaintBoundary(
          key: boundaryKey,
          child: MultiProvider(
            providers: appProviders(restoreSession: false),
            child: MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: PharmaConnectAppTheme.light(),
              darkTheme: PharmaConnectAppTheme.dark(),
              themeMode: ThemeMode.light,
              routerConfig: router,
              builder: (context, child) => AdaptiveTextScale(child: child!),
            ),
          ),
        ),
      );
      if (shot.prepare != null) {
        final context = tester.element(find.byType(AdaptiveTextScale));
        shot.prepare!(context.read<AuthProvider>());
      }
      await _settle(tester);
      if (shot.act != null) {
        await shot.act!(tester);
      }

      final boundary =
          boundaryKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        File(
          '$_outputDir/${shot.name}.png',
        ).writeAsBytesSync(data!.buffer.asUint8List());
      });

      FlutterError.onError = previousOnError;
      debugDisableShadows = true;
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(minutes: 5));
    });
  }
}
