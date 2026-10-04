// C245 (chemins du pilote : menus par role, reservation depuis la fiche produit) : captures d'écran à 360 px de large des écrans de la réservation
// faite par le serveur (patient, file de l'officine, retrait). Données
// d'exemple injectées dans ReservationProvider : les écrans sont montés
// hors ligne.
//
// Les images sont écrites dans build/c245_screenshots/ (non versionné). Ce
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
import 'package:pharma_connect/modules/reservations/models/reservation_item.dart';
import 'package:pharma_connect/modules/search/models/availability_result.dart';
import 'package:pharma_connect/modules/search/models/pharmacy.dart';
import 'package:pharma_connect/modules/search/providers/search_provider.dart';
import 'package:pharma_connect/shared/models/product.dart';
import 'package:pharma_connect/modules/reservations/providers/reservation_provider.dart';
import 'package:pharma_connect/routes/app_router.dart';

const _outputDir = 'build/c245_screenshots';
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
  final void Function(AuthProvider auth)? prepare;

  /// Gestes à jouer avant la capture (avancer dans un parcours).
  final Future<void> Function(WidgetTester tester)? act;

  const _Shot(this.name, this.route, {this.prepare, this.act});
}

Future<void> _settle(WidgetTester tester) async {
  // L'indicateur Kernel est animé en boucle : pas de pumpAndSettle.
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}

const _kaloum = '00000000-0000-0000-0000-000000000001';

Pharmacy _pharmacy(String id, String name, String address) => Pharmacy(
  id: id,
  name: name,
  address: address,
  phone: '+224620000000',
  latitude: 9.51,
  longitude: -13.71,
  isOpenNow: true,
);

final _paracetamol = Product(
  id: 'p1',
  name: 'Paracétamol',
  genericName: 'Paracétamol',
  dosage: '500mg',
  form: 'Comprimé',
  category: 'Antalgiques',
  imageUrl: '',
  isGeneric: true,
  manufacturer: 'Laboratoire',
  isPrescriptionRequired: false,
);

final _availability = AvailabilityResult(
  product: _paracetamol,
  pharmacyStocks: [
    PharmacyStock(
      pharmacy: _pharmacy(
        _kaloum,
        'Pharmacie Kaloum Centrale',
        'Avenue de la République, Kaloum',
      ),
      stock: 10,
      price: 1500,
      isAvailable: true,
      lastUpdated: DateTime.now(),
    ),
    PharmacyStock(
      pharmacy: _pharmacy('ph2', 'Pharmacie de Dixinn', 'Route de Donka'),
      stock: 0,
      price: 1500,
      isAvailable: false,
      lastUpdated: DateTime.now(),
    ),
  ],
);

T _read<T>(WidgetTester tester) =>
    tester.element(find.byType(AdaptiveTextScale)).read<T>();

Future<void> _openMenu(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.menu));
  await _settle(tester);
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

  void asPharmacist(AuthProvider auth) {
    auth.setRole(UserRole.pharmacien);
    auth.pharmacyIdForTesting = _kaloum;
  }

  void asAdmin(AuthProvider auth) {
    auth.setRole(UserRole.patient);
    auth.isGsgAdminForTesting = true;
  }

  Future<void> showAvailability(WidgetTester tester) async {
    _read<SearchProvider>(tester).selectedProductAvailabilityForTesting =
        _availability;
    await _settle(tester);
  }

  final shots = <_Shot>[
    // Menus par rôle (tiroir du téléphone).
    _Shot(
      '01_menu_patient',
      '/dashboard',
      prepare: (auth) => auth.setRole(UserRole.patient),
      act: _openMenu,
    ),
    _Shot(
      '02_menu_pharmacien',
      '/dashboard',
      prepare: asPharmacist,
      act: (tester) async {
        await _openMenu(tester);
        await tester.ensureVisible(find.text('Historique des ventes'));
        await _settle(tester);
      },
    ),
    _Shot(
      '03_menu_administrateur',
      '/dashboard',
      prepare: asAdmin,
      act: (tester) async {
        await _openMenu(tester);
        await tester.ensureVisible(find.text('Administration'));
        await _settle(tester);
      },
    ),
    // Patient : fiche produit, officines à toucher pour réserver.
    _Shot(
      '04_fiche_produit_reserver',
      '/product/p1',
      prepare: (auth) => auth.setRole(UserRole.patient),
      act: showAvailability,
    ),
    // Patient : panier ouvert après avoir touché une officine.
    _Shot(
      '05_panier_apres_reserver',
      '/product/p1',
      prepare: (auth) => auth.setRole(UserRole.patient),
      act: (tester) async {
        await showAvailability(tester);
        await tester.ensureVisible(find.text('Pharmacie Kaloum Centrale'));
        await tester.tap(find.text('Pharmacie Kaloum Centrale'));
        await _settle(tester);
      },
    ),
    // Patient : changement d'officine avec un panier déjà rempli.
    _Shot(
      '06_changer_officine',
      '/product/p1',
      prepare: (auth) => auth.setRole(UserRole.patient),
      act: (tester) async {
        _read<ReservationProvider>(tester)
          ..setPharmacyInfo(
            id: 'ph3',
            name: 'Pharmacie Matam Providence',
            address: 'Matam',
          )
          ..addToCart(
            ReservationItem(
              productId: 'p9',
              productName: 'Vitamine C',
              genericName: 'Vitamine C',
              dosage: '1000mg',
              pricePerUnit: 4000,
              quantity: 1,
            ),
          );
        await showAvailability(tester);
        await tester.ensureVisible(find.text('Pharmacie Kaloum Centrale'));
        await tester.tap(find.text('Pharmacie Kaloum Centrale'));
        await _settle(tester);
      },
    ),
    // Écrans désormais atteignables depuis le menu.
    _Shot('07_officine_caisse', '/cash', prepare: asPharmacist),
    _Shot(
      '08_officine_historique_ventes',
      '/pos/history',
      prepare: asPharmacist,
    ),
    _Shot('09_administration', '/admin', prepare: asAdmin),
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
      FlutterError.onError = (d) {
        final m = d.exceptionAsString();
        if (!m.contains("Socket") && !m.contains("ClientException")) {
          debugPrint("ERR[${shot.name}] ${m.length > 300 ? m.substring(0, 300) : m}");
        }
      };

      final router = GoRouter(
        initialLocation: shot.route,
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
