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

  /// C273 (b) : mouvements de la session et réponse « titulaire ».
  final movements = <CashMovement>[];
  bool manager = false;
  bool movementsFail = false;

  void addSale(int amount) =>
      movements.add(_movement(CashMovementType.sale, amount));

  @override
  Future<List<CashMovement>> getMovements(String sessionId) async {
    if (movementsFail) throw Exception('SocketException: hors connexion');
    return List.of(movements);
  }

  @override
  Future<bool> isPharmacyManager(String pharmacyId) async => manager;

  @override
  Future<CashMovement> addMovement({
    required String sessionId,
    required CashMovementType type,
    required int amount,
    String? referenceId,
    String? referenceType,
    String? notes,
  }) async {
    final m = _movement(type, amount, notes: notes);
    movements.add(m);
    return m;
  }

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

CashMovement _movement(CashMovementType type, int amount, {String? notes}) =>
    CashMovement(
      id: 'm${type.name}$amount',
      cashDrawerSessionId: 's1',
      type: type,
      amount: amount,
      notes: notes,
      createdAt: DateTime(2026, 10, 16, 9),
    );

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

  group('C273 (b), corrections', () {
    Future<(CashProvider, _FakeCashService)> openWith({
      bool manager = false,
      int sales = 0,
      bool movementsFail = false,
    }) async {
      final service = _FakeCashService()
        ..open = true
        ..manager = manager
        ..movementsFail = movementsFail;
      for (var i = 0; i < sales; i++) {
        service.addSale(1500);
      }
      final provider = CashProvider(service: service);
      await provider.loadCurrentSession('ph1');
      return (provider, service);
    }

    test('avant la première vente : le caissier corrige le fonds', () async {
      final (provider, service) = await openWith();
      expect(provider.canCorrectOpening, isTrue);
      expect(provider.canAddCashMovement, isFalse);

      // Fonds saisi 10 000 à l'ouverture, 12 000 en réalité : dépôt de 2 000.
      expect(await provider.correctOpening(12000), isTrue);
      expect(service.movements.last.type, CashMovementType.deposit);
      expect(service.movements.last.amount, 2000);
      expect(service.movements.last.notes, CashProvider.openingCorrectionNote);

      // Deuxième correction, à 9 000 : retrait de 3 000 (depuis 12 000).
      expect(await provider.correctOpening(9000), isTrue);
      expect(service.movements.last.type, CashMovementType.withdrawal);
      expect(service.movements.last.amount, 3000);

      // Même montant : rien à enregistrer.
      final count = service.movements.length;
      expect(await provider.correctOpening(9000), isTrue);
      expect(service.movements.length, count);
    });

    test('après une vente : plus de correction du fonds', () async {
      final (provider, service) = await openWith(sales: 1);
      expect(provider.canCorrectOpening, isFalse);
      expect(await provider.correctOpening(12000), isFalse);
      expect(service.movements.length, 1);
    });

    test('après une vente : dépôt ou retrait par le titulaire seul', () async {
      final (cashier, _) = await openWith(sales: 1);
      expect(cashier.canAddCashMovement, isFalse);
      expect(
        await cashier.addCashMovement(
          type: CashMovementType.deposit,
          amount: 500,
          reason: 'Monnaie',
        ),
        isFalse,
      );

      final (owner, service) = await openWith(sales: 1, manager: true);
      expect(owner.canAddCashMovement, isTrue);
      // Motif obligatoire.
      expect(
        await owner.addCashMovement(
          type: CashMovementType.withdrawal,
          amount: 500,
          reason: '  ',
        ),
        isFalse,
      );
      expect(
        await owner.addCashMovement(
          type: CashMovementType.withdrawal,
          amount: 500,
          reason: 'Erreur de saisie du caissier',
        ),
        isTrue,
      );
      expect(service.movements.last.notes, 'Erreur de saisie du caissier');
    });

    test('mouvements non chargés : aucune correction proposée', () async {
      final (provider, _) = await openWith(manager: true, movementsFail: true);
      expect(provider.canCorrectOpening, isFalse);
      expect(provider.canAddCashMovement, isFalse);
    });

    testWidgets(
      'écran : « Corriger le fonds », confirmation, puis enregistré',
      (tester) async {
        final (provider, service) = await openWith();
        await _pump(tester, provider);
        expect(find.text('💵 Dépôt ou retrait'), findsNothing);

        await tester.tap(find.text('✏️ Corriger le fonds'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextField, 'Fonds correct (GNF)'),
          '12 000',
        );
        await tester.tap(find.widgetWithText(ElevatedButton, 'Corriger'));
        await tester.pumpAndSettle();
        expect(
          find.text('Fonds correct : ${CurrencyFormatter.format(12000)}'),
          findsOneWidget,
        );
        expect(service.movements, isEmpty);

        await tester.tap(find.widgetWithText(ElevatedButton, 'Confirmer'));
        await tester.pumpAndSettle();
        expect(service.movements.single.amount, 2000);
        expect(find.text('Fonds corrigé'), findsOneWidget);
      },
    );

    testWidgets('écran : après une vente, « Dépôt ou retrait » pour le '
        'titulaire seulement', (tester) async {
      final (cashier, _) = await openWith(sales: 1);
      await _pump(tester, cashier);
      expect(find.text('✏️ Corriger le fonds'), findsNothing);
      expect(find.text('💵 Dépôt ou retrait'), findsNothing);

      final (owner, _) = await openWith(sales: 1, manager: true);
      await _pump(tester, owner);
      expect(find.text('✏️ Corriger le fonds'), findsNothing);
      expect(find.text('💵 Dépôt ou retrait'), findsOneWidget);
    });
  });
}
