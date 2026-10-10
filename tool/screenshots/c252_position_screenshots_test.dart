// C252 (officine sans position) : captures d'écran à 360 px de large des écrans de la réservation
// faite par le serveur (patient, file de l'officine, retrait). Données
// d'exemple injectées dans ReservationProvider : les écrans sont montés
// hors ligne.
//
// Les images sont écrites dans build/c252_screenshots/ (non versionné). Ce
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
import 'package:pharma_connect/modules/admin/models/admin_pharmacy.dart';
import 'package:pharma_connect/modules/admin/models/pharmacy_status.dart';
import 'package:pharma_connect/modules/admin/providers/admin_provider.dart';
import 'package:pharma_connect/modules/auth/models/user_role.dart';
import 'package:pharma_connect/modules/auth/providers/auth_provider.dart';
import 'package:pharma_connect/modules/search/models/availability_result.dart';
import 'package:pharma_connect/modules/search/models/pharmacy.dart';
import 'package:pharma_connect/modules/search/providers/search_provider.dart';
import 'package:pharma_connect/shared/models/product.dart';
import 'package:pharma_connect/routes/app_router.dart';

const _outputDir = 'build/c252_screenshots';
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

AdminPharmacy _adminPharmacy(
  String id,
  String name,
  PharmacyStatus status, {
  double? latitude,
  double? longitude,
}) => AdminPharmacy(
  id: id,
  name: name,
  address: 'Quartier Almamya, Kaloum, Conakry',
  phone: '+224620000000',
  email: '',
  licenseNumber: 'DNPM-GN-2026-0001',
  status: status,
  managerName: 'Dr. Mariama Barry',
  latitude: latitude,
  longitude: longitude,
  isActive: true,
  createdAt: DateTime(2026, 10, 9),
);

// Une officine inscrite par l'application, sans position, à côté d'une
// officine qui en a une.
final _adminPharmacies = [
  _adminPharmacy('a1', 'Pharmacie Nouvelle', PharmacyStatus.verified),
  _adminPharmacy(
    'a2',
    'Pharmacie Kaloum Centrale',
    PharmacyStatus.active,
    latitude: 9.5092,
    longitude: -13.7122,
  ),
];

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

// Fiche produit : la première officine vient de la base sans latitude ni
// longitude (même lecture que l'application).
final _availability = AvailabilityResult(
  product: _paracetamol,
  pharmacyStocks: [
    PharmacyStock(
      pharmacy: Pharmacy.fromJson({
        'id': 'a1',
        'name': 'Pharmacie Nouvelle',
        'address': 'Quartier Almamya, Kaloum, Conakry',
        'phone': '+224620000000',
        'latitude': null,
        'longitude': null,
      }),
      stock: 10,
      price: 1500,
      isAvailable: true,
      lastUpdated: DateTime.now(),
    ),
    PharmacyStock(
      pharmacy: Pharmacy.fromJson({
        'id': _kaloum,
        'name': 'Pharmacie Kaloum Centrale',
        'address': 'Avenue de la République, Kaloum',
        'phone': '+224620000001',
        'latitude': 9.5092,
        'longitude': -13.7122,
      }),
      stock: 4,
      price: 1600,
      isAvailable: true,
      lastUpdated: DateTime.now(),
    ),
  ],
);

T _read<T>(WidgetTester tester) =>
    tester.element(find.byType(AdaptiveTextScale)).read<T>();

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

  void asAdmin(AuthProvider auth) {
    auth.setRole(UserRole.patient);
    auth.isGsgAdminForTesting = true;
  }

  Future<void> showPharmacies(WidgetTester tester) async {
    _read<AdminProvider>(tester).pharmaciesForTesting = _adminPharmacies;
    await _settle(tester);
  }

  final shots = <_Shot>[
    // Candidature : bouton facultatif de position.
    _Shot(
      '01_candidature_position',
      '/license-verification',
      prepare: (auth) => auth.setRole(UserRole.pharmacien),
      act: (tester) async {
        await tester.ensureVisible(
          find.textContaining('Utiliser ma position actuelle'),
        );
        await _settle(tester);
      },
    ),
    // Candidature : bouton touché, recherche de la position en cours (hors
    // appareil, la localisation ne répond pas : le refus n'est pas capturé).
    _Shot(
      '02_candidature_position_recherche',
      '/license-verification',
      prepare: (auth) => auth.setRole(UserRole.pharmacien),
      act: (tester) async {
        final button = find.textContaining('Utiliser ma position actuelle');
        await tester.ensureVisible(button);
        await tester.tap(button);
        await _settle(tester);
      },
    ),
    // Administration : la liste s'affiche avec une officine sans position.
    _Shot(
      '03_admin_officine_sans_position',
      '/admin/pharmacies',
      prepare: asAdmin,
      act: showPharmacies,
    ),
    _Shot(
      '04_admin_saisie_position',
      '/admin/pharmacies',
      prepare: asAdmin,
      act: (tester) async {
        await showPharmacies(tester);
        await tester.tap(find.text('Saisir la position'));
        await _settle(tester);
      },
    ),
    _Shot(
      '05_admin_approuver_sans_position',
      '/admin/pharmacies',
      prepare: asAdmin,
      act: (tester) async {
        await showPharmacies(tester);
        await tester.tap(find.text('Approuver'));
        await _settle(tester);
      },
    ),
    // Patient : fiche produit avec une officine sans position.
    _Shot(
      '06_fiche_produit_officine_sans_position',
      '/product/p1',
      prepare: (auth) => auth.setRole(UserRole.patient),
      act: (tester) async {
        _read<SearchProvider>(tester).selectedProductAvailabilityForTesting =
            _availability;
        await _settle(tester);
      },
    ),
    // Administration : latitude et longitude inversées, avertissement sans
    // blocage.
    _Shot(
      '07_admin_position_hors_guinee',
      '/admin/pharmacies',
      prepare: asAdmin,
      act: (tester) async {
        await showPharmacies(tester);
        await tester.tap(find.text('Saisir la position'));
        await _settle(tester);
        await tester.enterText(find.byType(TextField).at(0), '-13.6785');
        await tester.enterText(find.byType(TextField).at(1), '9.5370');
        await tester.tap(find.text('Enregistrer'));
        await _settle(tester);
      },
    ),
    // Administration : latitude impossible, refus.
    _Shot(
      '08_admin_position_invalide',
      '/admin/pharmacies',
      prepare: asAdmin,
      act: (tester) async {
        await showPharmacies(tester);
        await tester.tap(find.text('Saisir la position'));
        await _settle(tester);
        await tester.enterText(find.byType(TextField).at(0), '95');
        await tester.enterText(find.byType(TextField).at(1), '-13.6785');
        await tester.tap(find.text('Enregistrer'));
        await _settle(tester);
      },
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
      FlutterError.onError = (d) {
        final m = d.exceptionAsString();
        if (!m.contains("Socket") && !m.contains("ClientException")) {
          debugPrint(
            "ERR[${shot.name}] ${m.length > 300 ? m.substring(0, 300) : m}",
          );
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
