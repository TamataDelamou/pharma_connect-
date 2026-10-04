// C243 : captures d'écran à 360 px de large des écrans de la réservation
// faite par le serveur (patient, file de l'officine, retrait). Données
// d'exemple injectées dans ReservationProvider : les écrans sont montés
// hors ligne.
//
// Les images sont écrites dans build/c243_screenshots/ (non versionné). Ce
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
import 'package:pharma_connect/modules/reservations/models/pickup_line.dart';
import 'package:pharma_connect/modules/reservations/models/reservation.dart';
import 'package:pharma_connect/modules/reservations/models/reservation_item.dart';
import 'package:pharma_connect/modules/reservations/models/reservation_status.dart';
import 'package:pharma_connect/modules/reservations/providers/reservation_provider.dart';
import 'package:pharma_connect/routes/app_router.dart';

const _outputDir = 'build/c243_screenshots';
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

ReservationItem _item(
  String id,
  String name,
  String dosage,
  int price,
  int quantity, {
  bool prescription = false,
}) => ReservationItem(
  id: id,
  productId: id,
  productName: name,
  genericName: name,
  dosage: dosage,
  pricePerUnit: price,
  quantity: quantity,
  prescriptionRequired: prescription,
);

Reservation _reservation(
  String id,
  String patient,
  ReservationStatus status,
  List<ReservationItem> items, {
  required Duration deadlineIn,
  String? cancelledBy,
  String? cancelReason,
}) {
  final now = DateTime.now();
  return Reservation(
    id: id,
    patientId: 'patient-1',
    patientName: patient,
    patientPhone: '',
    pharmacyId: _kaloum,
    pharmacyName: 'Pharmacie Kaloum Centrale',
    pharmacyAddress: 'Avenue de la République, Kaloum',
    items: items,
    reservedAt: now.subtract(const Duration(hours: 2)),
    pickupDeadline: now.add(deadlineIn),
    pickedUpAt: status == ReservationStatus.pickedUp ? now : null,
    status: status,
    totalPrice: items.fold(0, (sum, i) => sum + i.totalPrice),
    qrCodeToken: 'K7M4QX',
    cancelledBy: cancelledBy,
    cancelReason: cancelReason,
  );
}

final _para = _item('p1', 'Paracétamol', '500mg', 1500, 4);
final _ibu = _item('p2', 'Ibuprofène', '400mg', 2000, 1, prescription: true);
final _doli = _item('p3', 'Doliprane', '1000mg', 1200, 2);

final _r1 = _reservation(
  'r1',
  'Mariama Diallo',
  ReservationStatus.pending,
  [_para, _ibu],
  deadlineIn: const Duration(hours: 22),
);
final _r2 = _reservation('r2', 'Ibrahima Sow', ReservationStatus.ready, [
  _doli,
], deadlineIn: const Duration(hours: 9));
final _r3 = _reservation(
  'r3',
  'Mariama Diallo',
  ReservationStatus.cancelled,
  [_doli],
  deadlineIn: const Duration(hours: 5),
  cancelledBy: 'staff',
  cancelReason: 'Produit abîmé',
);
final _r4 = _reservation(
  'r4',
  'Mariama Diallo',
  ReservationStatus.expired,
  [_para],
  deadlineIn: const Duration(hours: -3),
);

ReservationProvider _provider(WidgetTester tester) =>
    tester.element(find.byType(AdaptiveTextScale)).read<ReservationProvider>();

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

  final shots = <_Shot>[
    // Patient : récapitulatif (prix indicatif).
    _Shot(
      '01_patient_reservation_recapitulatif',
      '/reservations/checkout',
      prepare: (auth) => auth.setRole(UserRole.patient),
      act: (tester) async {
        _provider(tester)
          ..setStateForTesting(cartItems: [_para, _ibu])
          ..setPharmacyInfo(
            id: _kaloum,
            name: 'Pharmacie Kaloum Centrale',
            address: 'Avenue de la République, Kaloum',
          );
        await _settle(tester);
      },
    ),
    // Patient : mes réservations (réservée avec ordonnance, prête avec un
    // produit devenu indisponible).
    _Shot(
      '02_patient_mes_reservations',
      '/reservations/history',
      prepare: (auth) => auth.setRole(UserRole.patient),
      act: (tester) async {
        _provider(tester).setStateForTesting(
          reservations: [_r1, _r2, _r3, _r4],
          unavailableItems: {
            'r2': ['Doliprane'],
          },
        );
        await _settle(tester);
      },
    ),
    _Shot(
      '03_patient_reservations_terminees',
      '/reservations/history',
      prepare: (auth) => auth.setRole(UserRole.patient),
      act: (tester) async {
        _provider(
          tester,
        ).setStateForTesting(reservations: [_r1, _r2, _r3, _r4]);
        await _settle(tester);
        await tester.tap(find.text('Terminées'));
        await _settle(tester);
      },
    ),
    // Officine : file des réservations à retirer.
    _Shot(
      '04_officine_file',
      '/pharmacy/queue',
      prepare: asPharmacist,
      act: (tester) async {
        _provider(tester).setStateForTesting(
          reservations: [_r1, _r2],
          unavailableItems: {
            'r2': ['Doliprane'],
          },
        );
        await _settle(tester);
      },
    ),
    // Officine : écran de retrait (prix du jour, écart, ordonnance).
    _Shot(
      '05_officine_retrait',
      '/pharmacy/queue/pickup/r1',
      prepare: asPharmacist,
      act: (tester) async {
        _provider(tester).setStateForTesting(
          selected: _r1,
          pickupLines: const [
            PickupLine(
              reservationItemId: 'p1',
              productName: 'Paracétamol',
              dosage: '500mg',
              quantity: 4,
              reservedUnitPrice: 1500,
              currentUnitPrice: 1600,
              prescriptionRequired: false,
              unavailableQuantity: 0,
            ),
            PickupLine(
              reservationItemId: 'p2',
              productName: 'Ibuprofène',
              dosage: '400mg',
              quantity: 1,
              reservedUnitPrice: 2000,
              currentUnitPrice: 2000,
              prescriptionRequired: true,
              unavailableQuantity: 0,
            ),
          ],
        );
        await _settle(tester);
        await tester.enterText(find.byType(TextField).first, 'K7M4QX');
        await _settle(tester);
      },
    ),
    // Officine : retrait avec un lot rappelé sans remplaçant.
    _Shot(
      '06_officine_retrait_lot_rappele',
      '/pharmacy/queue/pickup/r1',
      prepare: asPharmacist,
      act: (tester) async {
        _provider(tester).setStateForTesting(
          selected: _r1,
          pickupLines: const [
            PickupLine(
              reservationItemId: 'p1',
              productName: 'Paracétamol',
              dosage: '500mg',
              quantity: 4,
              reservedUnitPrice: 1500,
              currentUnitPrice: 1500,
              prescriptionRequired: false,
              unavailableQuantity: 4,
            ),
            PickupLine(
              reservationItemId: 'p2',
              productName: 'Ibuprofène',
              dosage: '400mg',
              quantity: 1,
              reservedUnitPrice: 2000,
              currentUnitPrice: 2000,
              prescriptionRequired: true,
              unavailableQuantity: 0,
            ),
          ],
        );
        await _settle(tester);
        // Retrait partiel choisi et motivé : le montant exclut le produit
        // non remis.
        await tester.enterText(find.byType(TextField).first, 'K7M4QX');
        await tester.ensureVisible(find.byType(SwitchListTile));
        await tester.tap(find.byType(SwitchListTile));
        await _settle(tester);
        await tester.enterText(
          find.byType(TextField).last,
          'Lot rappelé, patient informé',
        );
        await _settle(tester);
        await tester.ensureVisible(find.text('À encaisser en espèces'));
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
      FlutterError.onError = (_) {};

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
