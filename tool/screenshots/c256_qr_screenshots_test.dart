// C256 (QR code de retrait lisible) : captures d'écran à 360 px de large des
// écrans du patient qui montrent le QR code, en thème clair et en thème
// sombre. Données d'exemple injectées dans ReservationProvider : les écrans
// sont montés hors ligne.
//
// Les images sont écrites dans build/c256_screenshots/ (non versionné). Ce
// fichier est hors de test/ : il ne tourne pas avec `flutter test`. Même
// montage que c243_reservation_screenshots_test.dart. L'écran de validation
// de commande n'affiche son QR code qu'après une réservation acceptée par le
// serveur : il n'est pas capturé ici, il utilise le même composant.
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
import 'package:pharma_connect/modules/reservations/models/reservation.dart';
import 'package:pharma_connect/modules/reservations/models/reservation_item.dart';
import 'package:pharma_connect/modules/reservations/models/reservation_status.dart';
import 'package:pharma_connect/modules/reservations/providers/reservation_provider.dart';
import 'package:pharma_connect/routes/app_router.dart';

const _outputDir = 'build/c256_screenshots';
const _size = Size(360, 780);

Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final path in paths) {
    final bytes = File(path).readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

Future<void> _settle(WidgetTester tester) async {
  // L'indicateur Kernel est animé en boucle : pas de pumpAndSettle.
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}

Reservation _reservation() {
  final now = DateTime.now();
  return Reservation(
    id: 'r1',
    patientId: 'patient-1',
    patientName: 'Mariama Diallo',
    patientPhone: '',
    pharmacyId: '00000000-0000-0000-0000-000000000001',
    pharmacyName: 'Pharmacie Kaloum Centrale',
    pharmacyAddress: 'Avenue de la République, Kaloum',
    items: [
      ReservationItem(
        id: 'p1',
        productId: 'p1',
        productName: 'Paracétamol',
        genericName: 'Paracétamol',
        dosage: '500mg',
        pricePerUnit: 1500,
        quantity: 2,
        prescriptionRequired: false,
      ),
    ],
    reservedAt: now.subtract(const Duration(hours: 2)),
    pickupDeadline: now.add(const Duration(hours: 22)),
    status: ReservationStatus.pending,
    totalPrice: 3000,
    qrCodeToken: 'K7M4QX',
    queuePosition: 1,
    estimatedWaitMinutes: 10,
  );
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

  final shots = <(String, String, ThemeMode)>[
    ('01_qr_clair', '/reservations/qr', ThemeMode.light),
    ('02_qr_sombre', '/reservations/qr', ThemeMode.dark),
    ('03_confirmation_clair', '/reservations/confirmation', ThemeMode.light),
    ('04_confirmation_sombre', '/reservations/confirmation', ThemeMode.dark),
  ];

  for (final (name, route, mode) in shots) {
    testWidgets('capture $name', (tester) async {
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
        initialLocation: route,
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
              themeMode: mode,
              routerConfig: router,
              builder: (context, child) => AdaptiveTextScale(child: child!),
            ),
          ),
        ),
      );
      final context = tester.element(find.byType(AdaptiveTextScale));
      context.read<AuthProvider>().setRole(UserRole.patient);
      context.read<ReservationProvider>().setStateForTesting(
        selected: _reservation(),
      );
      await _settle(tester);
      // Le fournisseur ne prévient pas après une injection de test : l'écran
      // est reconstruit en rouvrant la route.
      router.go(route);
      await _settle(tester);

      final boundary =
          boundaryKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        File(
          '$_outputDir/$name.png',
        ).writeAsBytesSync(data!.buffer.asUint8List());
      });

      FlutterError.onError = previousOnError;
      debugDisableShadows = true;
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(minutes: 5));
    });
  }
}
