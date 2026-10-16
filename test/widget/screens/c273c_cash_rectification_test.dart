import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pharma_connect/core/theme/app_theme.dart';
import 'package:pharma_connect/core/utils/currency_formatter.dart';
import 'package:pharma_connect/modules/auth/providers/auth_provider.dart';
import 'package:pharma_connect/modules/cash/models/cash_drawer_session.dart';
import 'package:pharma_connect/modules/cash/providers/cash_provider.dart';
import 'package:pharma_connect/modules/cash/screens/cash_history_screen.dart';
import 'package:pharma_connect/modules/cash/services/cash_service.dart';

// C273 (c) : une caisse fermée n'est jamais modifiée ; le titulaire y
// rattache une rectification (montant compté, motif). La fermeture d'origine
// reste visible ; la dernière rectification fait foi.

Map<String, dynamic> _sessionJson({List<Map<String, dynamic>>? rects}) => {
  'id': 's1',
  'pharmacy_id': 'ph1',
  'cashier_id': 'u1',
  'opening_balance': 10000,
  'closing_balance': 11000,
  'expected_balance': 14000,
  'difference': -3000,
  'opened_at': '2026-10-16T08:00:00Z',
  'closed_at': '2026-10-16T18:00:00Z',
  'status': 'closed',
  'created_at': '2026-10-16T08:00:00Z',
  'updated_at': '2026-10-16T18:00:00Z',
  'cashiers': {'full_name': 'Caissier Kaloum'},
  'rectifications': ?rects,
};

Map<String, dynamic> _rect(int seq, int counted, String reason) => {
  'id': 'r$seq',
  'seq': seq,
  'cash_drawer_session_id': 's1',
  'previous_counted_balance': 11000,
  'counted_balance': counted,
  'expected_balance': 14000,
  'difference': counted - 14000,
  'reason': reason,
  'created_by': 't1',
  'created_at': '2026-10-16T19:00:00Z',
};

class _FakeCashService extends CashService {
  _FakeCashService({this.manager = false});

  bool manager;
  List<Map<String, dynamic>> rects = [];
  (String, int, String)? rectified;

  @override
  Future<List<CashDrawerSession>> getSessions({
    String? pharmacyId,
    String? cashierId,
    CashSessionStatus? status,
    DateTime? fromDate,
    DateTime? toDate,
  }) async => [CashDrawerSession.fromJson(_sessionJson(rects: rects))];

  @override
  Future<bool> isPharmacyManager(String pharmacyId) async => manager;

  @override
  Future<void> rectifyClosing({
    required String sessionId,
    required int countedBalance,
    required String reason,
  }) async {
    rectified = (sessionId, countedBalance, reason);
    rects = [...rects, _rect(rects.length + 1, countedBalance, reason)];
  }
}

Future<void> _pump(WidgetTester tester, CashProvider provider) async {
  tester.view.physicalSize = const Size(900, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final auth = AuthProvider()
    // ignore: invalid_use_of_visible_for_testing_member
    ..pharmacyIdForTesting = 'ph1'
    // ignore: invalid_use_of_visible_for_testing_member
    ..userIdForTesting = 't1';
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProvider<CashProvider>.value(value: provider),
      ],
      child: MaterialApp(
        theme: PharmaConnectAppTheme.light(),
        home: const CashHistoryScreen(),
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

  group('modèle', () {
    test('sans rectification : rien de rectifié', () {
      final s = CashDrawerSession.fromJson(_sessionJson());
      expect(s.rectifications, isEmpty);
      expect(s.latestRectification, isNull);
    });

    test('la dernière rectification (ordre d\'enregistrement) fait foi', () {
      final s = CashDrawerSession.fromJson(
        _sessionJson(
          rects: [_rect(2, 13900, 'Recompte'), _rect(1, 14000, 'Erreur')],
        ),
      );
      expect(s.rectifications.map((r) => r.seq), [1, 2]);
      expect(s.latestRectification!.countedBalance, 13900);
      expect(s.latestRectification!.difference, -100);
      // La fermeture d'origine n'est pas touchée.
      expect(s.closingBalance, 11000);
      expect(s.difference, -3000);
    });
  });

  group('fournisseur', () {
    test('le titulaire seul peut rectifier une caisse fermée', () async {
      final session = CashDrawerSession.fromJson(_sessionJson());
      final cashier = CashProvider(service: _FakeCashService());
      await cashier.ensureManager(userId: 'u1', pharmacyId: 'ph1');
      expect(cashier.canRectify(session), isFalse);
      expect(
        await cashier.rectifyClosing(
          session: session,
          countedBalance: 14000,
          reason: 'Erreur',
        ),
        isFalse,
      );

      final service = _FakeCashService(manager: true);
      final owner = CashProvider(service: service);
      await owner.ensureManager(userId: 't1', pharmacyId: 'ph1');
      expect(owner.canRectify(session), isTrue);
      // Motif obligatoire.
      expect(
        await owner.rectifyClosing(
          session: session,
          countedBalance: 14000,
          reason: ' ',
        ),
        isFalse,
      );
      expect(service.rectified, isNull);
    });

    test('caisse ouverte : pas de rectification', () async {
      final open = CashDrawerSession.fromJson(
        _sessionJson()
          ..['status'] = 'open'
          ..['closing_balance'] = null,
      );
      final owner = CashProvider(service: _FakeCashService(manager: true));
      await owner.ensureManager(userId: 't1', pharmacyId: 'ph1');
      expect(owner.canRectify(open), isFalse);
    });
  });

  group('historique', () {
    testWidgets('caissier : fermeture affichée, pas de bouton', (tester) async {
      await _pump(tester, CashProvider(service: _FakeCashService()));
      expect(find.textContaining('Clôture'), findsOneWidget);
      expect(find.text('Rectifier la fermeture'), findsNothing);
    });

    testWidgets(
      'titulaire : rectifie, confirme ; la fermeture d\'origine reste',
      (tester) async {
        final service = _FakeCashService(manager: true);
        await _pump(tester, CashProvider(service: service));

        await tester.tap(find.text('Rectifier la fermeture'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextField, 'Montant compté (GNF)'),
          '14 000',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Motif (obligatoire)'),
          'Erreur de saisie a la fermeture',
        );
        await tester.tap(find.widgetWithText(ElevatedButton, 'Rectifier'));
        await tester.pumpAndSettle();

        // Confirmation : rien n'est enregistré avant.
        expect(
          find.text('Écart : ${CurrencyFormatter.format(0)}'),
          findsOneWidget,
        );
        expect(service.rectified, isNull);
        await tester.tap(find.widgetWithText(ElevatedButton, 'Confirmer'));
        await tester.pumpAndSettle();

        expect(service.rectified, (
          's1',
          14000,
          'Erreur de saisie a la fermeture',
        ));
        // Fermeture d'origine et rectification, l'une sous l'autre.
        expect(
          find.textContaining(
            'Clôture ${CurrencyFormatter.format(11000)}',
          ),
          findsOneWidget,
        );
        expect(
          find.text(
            'Rectifiée : ${CurrencyFormatter.format(14000)} • écart '
            '${CurrencyFormatter.format(0)}',
          ),
          findsOneWidget,
        );
      },
    );
  });
}
