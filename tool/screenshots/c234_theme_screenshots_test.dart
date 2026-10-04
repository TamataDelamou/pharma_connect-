// C234 : captures d'écran à 360 px de large, en thème clair et en thème
// sombre, pour relire le rendu sans appareil.
//
//   flutter test tool/screenshots/c234_theme_screenshots_test.dart
//
// Les images sont écrites dans build/c234_screenshots/ (non versionné). Ce
// fichier est hors de test/ : il ne tourne pas avec `flutter test`. Les
// écrans sont montés hors ligne, avec les routes réelles : les données sont
// vides ou en erreur réseau, seul le rendu des couleurs est contrôlé.
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
import 'package:pharma_connect/modules/auth/models/account_status.dart';
import 'package:pharma_connect/modules/auth/models/user_role.dart';
import 'package:pharma_connect/modules/auth/providers/auth_provider.dart';
import 'package:pharma_connect/routes/app_router.dart';

const _outputDir = 'build/c234_screenshots';
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
  final bool dark;
  final void Function(AuthProvider auth)? prepare;

  const _Shot(
    this.name,
    this.route, {
    this.extra,
    this.dark = false,
    this.prepare,
  });
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
    const _Shot('01_connexion', '/login'),
    const _Shot(
      '02_code_email',
      '/otp',
      extra: {'identifier': 'patient@exemple.com', 'method': 'email'},
    ),
    const _Shot('03_inscription', '/register'),
    _Shot(
      '04_compte_en_attente',
      '/dashboard',
      prepare: (auth) {
        auth.setRole(UserRole.pharmacien);
        auth.accountStatusForTesting = const AccountStatus(
          role: 'pharmacien',
          state: AccountState.pharmacyApplicationPending,
          roleActive: false,
          applicationName: 'Pharmacie de Kaloum',
          applicationStatus: 'pending',
        );
      },
    ),
    _Shot(
      '05_accueil_patient',
      '/dashboard',
      prepare: (auth) => auth.setRole(UserRole.patient),
    ),
    const _Shot('06_recherche', '/search'),
    _Shot(
      '07_tableau_de_bord_officine',
      '/dashboard',
      prepare: (auth) => auth.setRole(UserRole.pharmacien),
    ),
    _Shot(
      '08_comptoir_pos',
      '/pos',
      prepare: (auth) {
        auth.setRole(UserRole.pharmacien);
        auth.pharmacyIdForTesting = '00000000-0000-0000-0000-000000000001';
      },
    ),
    _Shot(
      '09_accueil_patient_sombre',
      '/dashboard',
      dark: true,
      prepare: (auth) => auth.setRole(UserRole.patient),
    ),
    const _Shot('10_connexion_sombre', '/login', dark: true),
    const _Shot('11_recherche_sombre', '/search', dark: true),
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
              themeMode: shot.dark ? ThemeMode.dark : ThemeMode.light,
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
      // L'indicateur Kernel est animé en boucle : pas de pumpAndSettle.
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 150));
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
      // Le compte à rebours de l'écran de code (180 s) continue après le
      // démontage : on le laisse s'écouler.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(minutes: 5));
    });
  }
}
