import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pharma_connect/core/theme/app_theme.dart';
import 'package:pharma_connect/core/utils/currency_formatter.dart';
import 'package:pharma_connect/modules/auth/models/user_role.dart';
import 'package:pharma_connect/modules/auth/providers/auth_provider.dart';
import 'package:pharma_connect/modules/cash/models/cash_drawer_session.dart';
import 'package:pharma_connect/modules/cash/models/cash_movement.dart';
import 'package:pharma_connect/modules/cash/providers/cash_provider.dart';
import 'package:pharma_connect/modules/cash/screens/cash_dashboard_screen.dart';
import 'package:pharma_connect/modules/cash/services/cash_service.dart';
import 'package:pharma_connect/routes/app_menu.dart';

// C274 : le menu dit « Ouverture de caisse » ou « Fermeture de caisse » selon
// l'état de la caisse, « Caisse » tant qu'il n'est pas connu.
// C273 (a) : le fonds de caisse et le solde compté sont confirmés avant d'être
// enregistrés ; « Corriger » ou « Recompter » ramène à la saisie.

CashDrawerSession _session({required bool open}) => CashDrawerSession(
  id: 's1',
  pharmacyId: 'ph1',
  cashierId: 'u1',
  openingBalance: 10000,
  expectedBalance: 10000,
  openedAt: DateTime(2026, 10, 16, 8),
  status: open ? CashSessionStatus.open : CashSessionStatus.closed,
  createdAt: DateTime(2026, 10, 16, 8),
  updatedAt: DateTime(2026, 10, 16, 8),
);

/// Caisse en mémoire : pas de lecture du serveur.
class _FakeCashService extends CashService {
  bool open = false;
  bool fails = false;
  int reads = 0;
  int? openedWith;
  int? closedWith;

  @override
  Future<CashDrawerSession?> getCurrentOpenSession(String pharmacyId) async {
    reads++;
    if (fails) throw Exception('SocketException: hors connexion');
    return open ? _session(open: true) : null;
  }

  @override
  Future<CashDrawerSession> openSession({
    required String pharmacyId,
    required String cashierId,
    required int openingBalance,
    String? notes,
  }) async {
    openedWith = openingBalance;
    open = true;
    return _session(open: true);
  }

  @override
  Future<CashDrawerSession> closeSession({
    required String sessionId,
    required int closingBalance,
    String? notes,
  }) async {
    closedWith = closingBalance;
    open = false;
    return _session(open: false);
  }

  @override
  Future<List<CashMovement>> getMovements(String sessionId) async => [];

  @override
  Future<Map<String, dynamic>> getSessionSummary(String sessionId) async => {
    'session_id': 's1',
    'total_sales': 1500,
    'total_refunds': 0,
    'total_deposits': 0,
    'total_withdrawals': 0,
    'current_expected_cash': 11500,
  };
}

String? _cashLabel(bool? drawerOpen) => appMenuFor(
  UserRole.pharmacien,
  cashDrawerOpen: drawerOpen,
).firstWhere((i) => i.route == '/cash').label;

Future<void> _pump(WidgetTester tester, CashProvider provider) async {
  tester.view.physicalSize = const Size(900, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final auth = AuthProvider()
    // ignore: invalid_use_of_visible_for_testing_member
    ..pharmacyIdForTesting = 'ph1'
    // ignore: invalid_use_of_visible_for_testing_member
    ..userIdForTesting = 'u1';
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProvider<CashProvider>.value(value: provider),
      ],
      child: MaterialApp(
        theme: PharmaConnectAppTheme.light(),
        home: const CashDashboardScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
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

  group('C274, libellé du menu', () {
    test('selon l\'état de la caisse, « Caisse » s\'il n\'est pas connu', () {
      expect(_cashLabel(false), 'Ouverture de caisse');
      expect(_cashLabel(true), 'Fermeture de caisse');
      expect(_cashLabel(null), 'Caisse');
    });

    test('pas d\'entrée de caisse pour un patient', () {
      expect(
        appMenuFor(UserRole.patient, cashDrawerOpen: true).map((i) => i.route),
        isNot(contains('/cash')),
      );
    });

    test('état lu une fois par compte et par officine', () async {
      final service = _FakeCashService();
      final provider = CashProvider(service: service);
      expect(provider.drawerOpen, isNull);

      await provider.ensureDrawerState(userId: 'u1', pharmacyId: 'ph1');
      expect(provider.drawerOpen, isFalse);
      await provider.ensureDrawerState(userId: 'u1', pharmacyId: 'ph1');
      expect(service.reads, 1);

      // Autre compte sur le même téléphone : relu.
      service.open = true;
      await provider.ensureDrawerState(userId: 'u2', pharmacyId: 'ph1');
      expect(service.reads, 2);
      expect(provider.drawerOpen, isTrue);
    });

    test('lecture en échec (hors connexion) : état inconnu', () async {
      final service = _FakeCashService()..fails = true;
      final provider = CashProvider(service: service);
      await provider.ensureDrawerState(userId: 'u1', pharmacyId: 'ph1');
      expect(provider.drawerOpen, isNull);
    });

    test('ouvrir puis fermer la caisse met l\'état à jour', () async {
      final provider = CashProvider(service: _FakeCashService());
      await provider.openSession(
        pharmacyId: 'ph1',
        cashierId: 'u1',
        openingBalance: 10000,
      );
      expect(provider.drawerOpen, isTrue);
      await provider.closeSession(sessionId: 's1', closingBalance: 11500);
      expect(provider.drawerOpen, isFalse);
    });
  });

  group('C273 (a), confirmation', () {
    Future<void> typeOpening(WidgetTester tester, String amount) async {
      await tester.tap(find.text('🟢 Ouvrir la caisse'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Fonds de caisse (GNF)'),
        amount,
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Ouvrir'));
      await tester.pumpAndSettle();
    }

    testWidgets('ouverture : rien n\'est enregistré avant « Confirmer »', (
      tester,
    ) async {
      final service = _FakeCashService();
      await _pump(tester, CashProvider(service: service));

      await typeOpening(tester, '100 000');
      expect(
        find.text(
          'Fonds de caisse : ${CurrencyFormatter.format(100000)}\n\n'
          'Vérifiez le montant avant de confirmer.',
        ),
        findsOneWidget,
      );
      expect(service.openedWith, isNull);

      // « Corriger » : retour à la saisie, montant gardé.
      await tester.tap(find.text('Corriger'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, '100 000'), findsOneWidget);
      expect(service.openedWith, isNull);

      await tester.enterText(
        find.widgetWithText(TextField, 'Fonds de caisse (GNF)'),
        '10 000',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Ouvrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Confirmer'));
      await tester.pumpAndSettle();
      expect(service.openedWith, 10000);
    });

    Future<void> typeClosing(WidgetTester tester, String amount) async {
      await tester.tap(find.text('🔒 Fermer la caisse'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Solde réel (GNF)'),
        amount,
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Fermer'));
      await tester.pumpAndSettle();
    }

    testWidgets(
      'fermeture avec écart : attendu, compté, écart, « Recompter »',
      (tester) async {
        final service = _FakeCashService()..open = true;
        final provider = CashProvider(service: service);
        await provider.loadCurrentSession('ph1');
        await _pump(tester, provider);

        await typeClosing(tester, '1 150');
        expect(
          find.text('Solde attendu : ${CurrencyFormatter.format(11500)}'),
          findsWidgets,
        );
        expect(
          find.text('Solde compté : ${CurrencyFormatter.format(1150)}'),
          findsOneWidget,
        );
        expect(
          find.text('Écart : ${CurrencyFormatter.format(-10350)}'),
          findsOneWidget,
        );
        expect(find.textContaining('Recomptez le tiroir'), findsOneWidget);
        expect(service.closedWith, isNull);

        await tester.tap(find.text('Recompter'));
        await tester.pumpAndSettle();
        expect(find.widgetWithText(TextField, '1 150'), findsOneWidget);

        await tester.enterText(
          find.widgetWithText(TextField, 'Solde réel (GNF)'),
          '11 500',
        );
        await tester.tap(find.widgetWithText(ElevatedButton, 'Fermer'));
        await tester.pumpAndSettle();
        expect(
          find.text('Écart : ${CurrencyFormatter.format(0)}'),
          findsOneWidget,
        );
        expect(find.textContaining('Recomptez'), findsNothing);
        await tester.tap(find.widgetWithText(ElevatedButton, 'Confirmer'));
        await tester.pumpAndSettle();
        expect(service.closedWith, 11500);
      },
    );
  });
}
