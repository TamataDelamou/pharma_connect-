import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
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
import 'package:pharma_connect/modules/reservations/services/reservation_service.dart';
import 'package:pharma_connect/modules/reservations/widgets/pickup_qr_code.dart';
import 'package:pharma_connect/modules/reservations/widgets/reservation_status_card.dart';

// C255 : le QR code s'ouvre depuis « Réservations », un toucher à la fois.
// C263 : aucun message technique n'est affiché au patient, même après une
// ouverture hors connexion.
// C264 : hors connexion, le QR code s'affiche tout de suite, sans attendre
// l'échec du réseau.

/// Erreur réelle relevée à l'essai « release » du 13/10/2026.
final _offlineError = Exception(
  'ClientException with SocketException: Failed host lookup: '
  'xyzabc.supabase.co (OS Error: No address associated with hostname, '
  'errno = 7), uri=https://xyzabc.supabase.co/rest/v1/reservations'
  '?select=*&id=eq.71996b45-0c1e-4a2b-9d3f-000000000001',
);

/// Mots qui ne doivent jamais apparaître à l'écran.
const _technical = [
  'Exception',
  'Socket',
  'supabase',
  'uri=',
  '71996b45',
  'errno',
];

Reservation _reservation(
  String id,
  String? code, {
  ReservationStatus status = ReservationStatus.pending,
}) {
  final now = DateTime.now();
  return Reservation(
    id: id,
    patientId: 'patient-1',
    patientName: 'Mariama Diallo',
    patientPhone: '',
    pharmacyId: 'pharmacy-1',
    pharmacyName: 'TEST Officine Lot 3',
    pharmacyAddress: 'Kaloum',
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
    status: status,
    totalPrice: 1500,
    qrCodeToken: code,
  );
}

/// Serveur simulé : en ligne ou hors connexion, réponses retenues au besoin.
class _FakeReservationService extends ReservationService {
  bool online = true;
  int reads = 0;
  final Map<String, Reservation> server = {};

  /// Réponse retenue jusqu'à ce que le test la libère.
  Completer<void>? gate;

  @override
  Future<Reservation> getReservation(String id) async {
    reads++;
    await gate?.future;
    if (!online) throw _offlineError;
    return server[id]!;
  }
}

class _Harness {
  _Harness(this.service, this.provider, this.router);
  final _FakeReservationService service;
  final ReservationProvider provider;
  final GoRouter router;
}

Future<_Harness> _pump(
  WidgetTester tester, {
  required List<Reservation> list,
  bool offlineList = false,
}) async {
  tester.view.physicalSize = const Size(400, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final service = _FakeReservationService()
    ..server.addAll({
      for (final r in list)
        r.id: _reservation(
          r.id,
          r.qrCodeToken,
          status: ReservationStatus.ready,
        ),
    });
  final provider = ReservationProvider(service: service)
    // ignore: invalid_use_of_visible_for_testing_member
    ..setStateForTesting(reservations: list, offline: offlineList);
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
  return _Harness(service, provider, router);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void _expectNothingTechnical(WidgetTester tester) {
  final shown = tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '')
      .join('\n');
  for (final word in _technical) {
    expect(shown.contains(word), isFalse, reason: '« $word » affiché');
  }
}

Future<void> _back(WidgetTester tester, _Harness h) async {
  h.router.pop();
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
  });

  testWidgets(
    'C263, constat de l\'essai : réservation ouverte avec réseau, puis '
    'rouverte en mode avion : QR code tout de suite, mention « Hors '
    'connexion », aucun message technique au retour sur la liste',
    (tester) async {
      final h = await _pump(tester, list: [_reservation('r1', 'K7M4QX')]);

      // Avec réseau : le QR code s'ouvre, la réservation est relue.
      await tester.tap(find.byType(ReservationStatusCard));
      await _settle(tester);
      expect(find.byType(ReservationQRScreen), findsOneWidget);
      expect(h.service.reads, 1);
      expect(find.textContaining('Hors connexion'), findsNothing);
      await _back(tester, h);

      // Mode avion, même réservation : elle était déjà sélectionnée.
      h.service.online = false;
      await tester.tap(find.byType(ReservationStatusCard));
      await _settle(tester);
      expect(find.byType(ReservationQRScreen), findsOneWidget);
      expect(find.text('K7M4QX'), findsOneWidget);
      expect(
        find.textContaining('Hors connexion — dernières données enregistrées'),
        findsOneWidget,
      );
      _expectNothingTechnical(tester);

      await _back(tester, h);
      expect(find.byType(ReservationHistoryScreen), findsOneWidget);
      expect(h.provider.error, isNull);
      _expectNothingTechnical(tester);
    },
  );

  testWidgets('C264 : le QR code s\'affiche avant la réponse du serveur, et la '
      'mention apparaît quand le serveur ne répond pas', (tester) async {
    final h = await _pump(tester, list: [_reservation('r1', 'K7M4QX')]);
    h.service
      ..online = false
      ..gate = Completer<void>();

    await tester.tap(find.byType(ReservationStatusCard));
    await _settle(tester);
    // Le serveur n'a pas encore répondu : le QR code est déjà là.
    expect(find.byType(ReservationQRScreen), findsOneWidget);
    expect(
      tester.widget<PickupQrCode>(find.byType(PickupQrCode)).data,
      'K7M4QX',
    );
    expect(find.byType(LinearProgressIndicator), findsNothing);

    h.service.gate!.complete();
    await _settle(tester);
    expect(
      find.textContaining('Hors connexion — dernières données enregistrées'),
      findsOneWidget,
    );
    _expectNothingTechnical(tester);
  });

  testWidgets(
    'C263 : liste hors connexion : bandeau au texte fixe, qui disparaît '
    'dès que le serveur répond',
    (tester) async {
      final h = await _pump(
        tester,
        list: [_reservation('r1', 'K7M4QX')],
        offlineList: true,
      );
      expect(
        find.text('Hors connexion — dernières données enregistrées'),
        findsOneWidget,
      );

      // Le réseau revient : ouvrir une réservation la relit.
      await tester.tap(find.byType(ReservationStatusCard));
      await _settle(tester);
      // Liste venue du cache : la mention s'affiche jusqu'à la réponse.
      expect(find.textContaining('Hors connexion'), findsNothing);
      await _back(tester, h);

      expect(h.provider.isOffline, isFalse);
      expect(find.textContaining('Hors connexion'), findsNothing);
    },
  );

  testWidgets(
    'C255 : réservation sans code de retrait, hors connexion : message '
    'lisible, pas de QR code',
    (tester) async {
      final h = await _pump(tester, list: [_reservation('r1', null)]);
      h.service.online = false;

      await tester.tap(find.byType(ReservationStatusCard));
      await _settle(tester);

      expect(find.byType(ReservationQRScreen), findsNothing);
      expect(find.textContaining('Impossible d\'ouvrir'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      _expectNothingTechnical(tester);
    },
  );

  testWidgets('C255 : réservation sans code de retrait, avec réseau : barre de '
      'progression pendant la lecture, puis le QR code relu', (tester) async {
    final h = await _pump(tester, list: [_reservation('r1', null)]);
    h.service.server['r1'] = _reservation('r1', 'B2N8ZP');
    h.service.gate = Completer<void>();

    await tester.tap(find.byType(ReservationStatusCard));
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.byType(ReservationStatusCard), findsOneWidget);

    h.service.gate!.complete();
    await _settle(tester);
    expect(find.byType(ReservationQRScreen), findsOneWidget);
    expect(find.text('B2N8ZP'), findsOneWidget);
  });

  testWidgets('C255 : double toucher : un seul écran, un seul retour', (
    tester,
  ) async {
    final h = await _pump(
      tester,
      list: [_reservation('r1', 'K7M4QX'), _reservation('r2', 'B2N8ZP')],
    );
    await tester.tap(find.byType(ReservationStatusCard).first);
    await tester.tap(find.byType(ReservationStatusCard).first);
    await tester.tap(find.byType(ReservationStatusCard).last);
    await _settle(tester);
    expect(find.byType(ReservationQRScreen), findsOneWidget);
    expect(find.text('K7M4QX'), findsOneWidget);

    await _back(tester, h);
    expect(find.byType(ReservationQRScreen), findsNothing);
    expect(find.byType(ReservationHistoryScreen), findsOneWidget);

    // Le toucher suivant est de nouveau pris en compte.
    await tester.tap(find.byType(ReservationStatusCard).last);
    await _settle(tester);
    expect(find.text('B2N8ZP'), findsOneWidget);
  });
}
