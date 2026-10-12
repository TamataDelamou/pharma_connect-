import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pharma_connect/core/theme/app_theme.dart';
import 'package:pharma_connect/modules/auth/providers/auth_provider.dart';
import 'package:pharma_connect/modules/reservations/models/reservation.dart';
import 'package:pharma_connect/modules/reservations/models/reservation_item.dart';
import 'package:pharma_connect/modules/reservations/models/reservation_status.dart';
import 'package:pharma_connect/modules/reservations/providers/reservation_provider.dart';
import 'package:pharma_connect/modules/reservations/screens/reservation_history_screen.dart';
import 'package:pharma_connect/modules/reservations/screens/reservation_qr_screen.dart';
import 'package:pharma_connect/modules/reservations/widgets/pickup_qr_code.dart';
import 'package:pharma_connect/modules/reservations/widgets/reservation_status_card.dart';

// C255 : le QR code s'ouvre depuis la liste des réservations.
// C256 : le QR code est lisible dans les deux thèmes.

Reservation _reservation(String id, String? code) {
  final now = DateTime.now();
  return Reservation(
    id: id,
    patientId: 'patient-1',
    patientName: 'Mariama Diallo',
    patientPhone: '',
    pharmacyId: 'pharmacy-1',
    pharmacyName: 'Pharmacie Kaloum Centrale',
    pharmacyAddress: 'Avenue de la République, Kaloum',
    items: [
      ReservationItem(
        id: 'i-$id',
        productId: 'p-$id',
        productName: 'Paracétamol',
        genericName: 'Paracétamol',
        dosage: '500mg',
        pricePerUnit: 1500,
        quantity: 1,
        prescriptionRequired: false,
      ),
    ],
    reservedAt: now.subtract(const Duration(hours: 1)),
    pickupDeadline: now.add(const Duration(hours: 23)),
    status: ReservationStatus.pending,
    totalPrice: 1500,
    qrCodeToken: code,
  );
}

/// Chargement d'une réservation simulé : `isLoading` passe à vrai, comme
/// dans le vrai fournisseur, puis le test décide de la suite.
class _FakeReservationProvider extends ReservationProvider {
  bool _loading = false;
  Completer<bool>? _pending;
  int loadCalls = 0;

  @override
  bool get isLoading => _loading;

  @override
  Future<void> loadReservation(String id) async {
    loadCalls++;
    _loading = true;
    notifyListeners();
    _pending = Completer<bool>();
    final found = await _pending!.future;
    _loading = false;
    if (found) {
      // ignore: invalid_use_of_visible_for_testing_member
      setStateForTesting(selected: reservations.firstWhere((r) => r.id == id));
    } else {
      notifyListeners();
    }
  }

  /// [found] faux : le serveur n'a pas répondu, la sélection ne change pas.
  void finishLoading({required bool found}) => _pending!.complete(found);
}

Future<_FakeReservationProvider> _pumpHistory(WidgetTester tester) async {
  // Assez haut pour que les trois cartes de la liste soient construites.
  tester.view.physicalSize = const Size(360, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final provider = _FakeReservationProvider()
    // ignore: invalid_use_of_visible_for_testing_member
    ..setStateForTesting(
      reservations: [
        _reservation('r1', 'K7M4QX'),
        _reservation('r2', 'B2N8ZP'),
        _reservation('r3', null),
      ],
    );
  final router = GoRouter(
    initialLocation: '/reservations/history',
    routes: [
      GoRoute(
        path: '/reservations/history',
        builder: (_, _) => const ReservationHistoryScreen(),
      ),
      GoRoute(
        path: '/reservations/qr',
        builder: (_, _) => const ReservationQRScreen(),
      ),
    ],
  );
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider<ReservationProvider>.value(value: provider),
      ],
      child: MaterialApp.router(
        theme: PharmaConnectAppTheme.light(),
        routerConfig: router,
      ),
    ),
  );
  await tester.pump();
  return provider;
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

  group('C255 : ouverture du QR code depuis « Réservations »', () {
    testWidgets('toucher une carte ouvre le QR code de cette réservation', (
      tester,
    ) async {
      final provider = await _pumpHistory(tester);
      expect(find.byType(ReservationStatusCard), findsNWidgets(3));
      expect(find.byType(LinearProgressIndicator), findsNothing);

      await tester.tap(find.byType(ReservationStatusCard).at(1));
      await tester.pump();

      // Pendant le chargement, la liste reste affichée et le toucher est
      // signalé.
      expect(provider.isLoading, isTrue);
      expect(find.byType(ReservationStatusCard), findsNWidgets(3));
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      provider.finishLoading(found: true);
      await tester.pumpAndSettle();

      expect(find.byType(ReservationQRScreen), findsOneWidget);
      expect(find.text('B2N8ZP'), findsOneWidget);
      expect(
        tester.widget<PickupQrCode>(find.byType(PickupQrCode)).data,
        'B2N8ZP',
      );
      expect(find.textContaining('Hors connexion'), findsNothing);
    });

    testWidgets(
      'chargement échoué, réservation en cache : QR code ouvert, mention '
      '« Hors connexion »',
      (tester) async {
        final provider = await _pumpHistory(tester);
        await tester.tap(find.byType(ReservationStatusCard).first);
        await tester.pump();
        provider.finishLoading(found: false);
        await tester.pumpAndSettle();

        expect(find.byType(ReservationQRScreen), findsOneWidget);
        expect(
          tester.widget<PickupQrCode>(find.byType(PickupQrCode)).data,
          'K7M4QX',
        );
        expect(provider.selectedReservationFromCache, isTrue);
        expect(
          find.textContaining(
            'Hors connexion — dernières données enregistrées',
          ),
          findsOneWidget,
        );
        // État et échéance connus affichés.
        expect(find.textContaining('À retirer avant le'), findsOneWidget);
        expect(find.textContaining('Impossible d\'ouvrir'), findsNothing);
      },
    );

    testWidgets(
      'chargement échoué, réservation sans code : pas de QR code, message',
      (tester) async {
        final provider = await _pumpHistory(tester);
        await tester.ensureVisible(find.byType(ReservationStatusCard).at(2));
        await tester.pump();
        await tester.tap(find.byType(ReservationStatusCard).at(2));
        await tester.pump();
        provider.finishLoading(found: false);
        await tester.pumpAndSettle();

        expect(find.byType(ReservationQRScreen), findsNothing);
        expect(find.textContaining('Impossible d\'ouvrir'), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsNothing);
      },
    );

    testWidgets('double toucher : un seul chargement, un seul écran ouvert', (
      tester,
    ) async {
      final provider = await _pumpHistory(tester);
      await tester.tap(find.byType(ReservationStatusCard).first);
      await tester.pump();
      await tester.tap(find.byType(ReservationStatusCard).first);
      await tester.pump();
      await tester.tap(find.byType(ReservationStatusCard).at(1));
      await tester.pump();
      expect(provider.loadCalls, 1);

      provider.finishLoading(found: true);
      await tester.pumpAndSettle();
      expect(find.byType(ReservationQRScreen), findsOneWidget);
      expect(find.text('K7M4QX'), findsOneWidget);

      // Un seul écran empilé : un retour ramène à la liste.
      await tester.tap(find.byIcon(Icons.arrow_back).last);
      await tester.pumpAndSettle();
      expect(find.byType(ReservationQRScreen), findsNothing);
      expect(find.byType(ReservationHistoryScreen), findsOneWidget);

      // Le toucher suivant est de nouveau pris en compte.
      await tester.tap(find.byType(ReservationStatusCard).at(1));
      await tester.pump();
      expect(provider.loadCalls, 2);
      provider.finishLoading(found: true);
      await tester.pumpAndSettle();
      expect(find.text('B2N8ZP'), findsOneWidget);
    });
  });

  group('C256 : QR code lisible dans les deux thèmes', () {
    for (final (name, theme) in [
      ('clair', PharmaConnectAppTheme.light()),
      ('sombre', PharmaConnectAppTheme.dark()),
    ]) {
      testWidgets('thème $name : modules noirs, fond blanc, marge blanche', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: const Scaffold(
              body: Center(child: PickupQrCode(data: 'K7M4QX', extent: 232)),
            ),
          ),
        );

        const white = Color(0xFFFFFFFF);
        const black = Color(0xFF000000);
        final qr = tester.widget<QrImageView>(find.byType(QrImageView));
        expect(qr.backgroundColor, white);
        expect(qr.eyeStyle.color, black);
        expect(qr.dataModuleStyle.color, black);
        expect(qr.padding, EdgeInsets.zero);

        final box = tester.widget<Container>(
          find
              .descendant(
                of: find.byType(PickupQrCode),
                matching: find.byType(Container),
              )
              .first,
        );
        expect((box.decoration! as BoxDecoration).color, white);

        // Marge blanche d'au moins 4 modules pour un QR code de 21 modules.
        final outer = tester.getSize(find.byType(PickupQrCode));
        final inner = tester.getSize(find.byType(QrImageView));
        expect(outer, const Size(232, 232));
        final margin = (outer.width - inner.width) / 2;
        expect(margin, greaterThanOrEqualTo(4 * inner.width / 21 - 0.01));
      });
    }

    test('aucun QR code hors de PickupQrCode', () {
      final offenders = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) => !f.path.endsWith('pickup_qr_code.dart'))
          .where((f) => f.readAsStringSync().contains('QrImageView('))
          .map((f) => f.path)
          .toList();
      expect(offenders, isEmpty);
    });
  });
}
