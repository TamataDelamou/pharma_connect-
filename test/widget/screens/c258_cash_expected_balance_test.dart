import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pharma_connect/core/utils/currency_formatter.dart';
import 'package:pharma_connect/core/theme/app_theme.dart';
import 'package:pharma_connect/modules/auth/providers/auth_provider.dart';
import 'package:pharma_connect/modules/cash/models/cash_drawer_session.dart';
import 'package:pharma_connect/modules/cash/models/cash_movement.dart';
import 'package:pharma_connect/modules/cash/providers/cash_provider.dart';
import 'package:pharma_connect/modules/cash/screens/cash_dashboard_screen.dart';

// C258 : pendant une session ouverte, le « Solde attendu » est celui que le
// serveur calcule à partir des mouvements, pas le fonds de caisse figé à
// l'ouverture.

/// Session ouverte et résumé posés par le test : pas de lecture du serveur.
class _FakeCashProvider extends CashProvider {
  _FakeCashProvider(this._fakeSummary);

  Map<String, dynamic>? _fakeSummary;

  /// Résumé que rendra la relecture faite avant la fermeture.
  Map<String, dynamic>? summaryAfterRefresh;
  bool refreshFails = false;
  int refreshCalls = 0;

  @override
  CashDrawerSession? get currentSession => CashDrawerSession(
    id: 's1',
    pharmacyId: 'ph1',
    cashierId: 'u1',
    openingBalance: 0,
    // Valeur figée à l'ouverture : ne doit jamais être affichée.
    expectedBalance: 0,
    openedAt: DateTime(2026, 10, 10, 18),
    status: CashSessionStatus.open,
    createdAt: DateTime(2026, 10, 10, 18),
    updatedAt: DateTime(2026, 10, 10, 18),
  );

  @override
  bool get hasOpenSession => true;

  @override
  Map<String, dynamic>? get summary => _fakeSummary;

  @override
  List<CashMovement> get movements => const [];

  @override
  bool get isLoading => false;

  @override
  String? get error => null;

  @override
  Future<void> loadCurrentSession(String pharmacyId) async {}

  @override
  Future<void> refreshSummary(String sessionId) async {
    refreshCalls++;
    _fakeSummary = refreshFails ? null : (summaryAfterRefresh ?? _fakeSummary);
    notifyListeners();
  }

  /// C267 : solde compté reçu par la fermeture.
  int? closedWith;

  @override
  Future<bool> closeSession({
    required String sessionId,
    required int closingBalance,
    String? notes,
  }) async {
    closedWith = closingBalance;
    return true;
  }
}

Map<String, dynamic> _summary({required int sales, required int expected}) => {
  'session_id': 's1',
  'total_sales': sales,
  'total_refunds': 0,
  'total_deposits': 0,
  'total_withdrawals': 0,
  'current_expected_cash': expected,
};

Future<void> _pump(WidgetTester tester, _FakeCashProvider provider) async {
  // Écran large : les débordements de la rangée de boutons à 360 px sont
  // l'objet de C253.
  tester.view.physicalSize = const Size(900, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final auth = AuthProvider()
    // ignore: invalid_use_of_visible_for_testing_member
    ..pharmacyIdForTesting = 'ph1';
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
  await tester.pump();
}

/// Montant affiché sur la ligne du résumé qui porte [label].
String _amountOf(WidgetTester tester, String label) {
  final row = find.ancestor(of: find.text(label), matching: find.byType(Row));
  final texts = tester
      .widgetList<Text>(
        find.descendant(of: row.first, matching: find.byType(Text)),
      )
      .toList();
  return texts.last.data!;
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

  group('CashProvider.currentExpectedCash', () {
    test('lit current_expected_cash du résumé de la session ouverte', () {
      final provider = _FakeCashProvider(_summary(sales: 5400, expected: 5400));
      expect(provider.currentExpectedCash, 5400);
    });

    test('null sans résumé, ou avec le résumé d\'une autre session', () {
      expect(_FakeCashProvider(null).currentExpectedCash, isNull);
      expect(_FakeCashProvider({}).currentExpectedCash, isNull);
      final other = _summary(sales: 900, expected: 900)..['session_id'] = 's0';
      expect(_FakeCashProvider(other).currentExpectedCash, isNull);
    });
  });

  testWidgets(
    'fonds 0, ventes 5 400 : solde attendu 5 400 à l\'écran et dans le '
    'message de fermeture',
    (tester) async {
      final provider = _FakeCashProvider(_summary(sales: 5400, expected: 5400));
      await _pump(tester, provider);

      expect(_amountOf(tester, 'Ventes'), CurrencyFormatter.format(5400));
      expect(
        _amountOf(tester, 'Solde attendu'),
        CurrencyFormatter.format(5400),
      );

      // Une vente de plus avant la fermeture : le message relit le serveur.
      provider.summaryAfterRefresh = _summary(sales: 6900, expected: 6900);
      await tester.tap(find.text('🔒 Fermer la caisse'));
      await tester.pumpAndSettle();

      expect(provider.refreshCalls, 1);
      expect(
        find.text('Solde attendu : ${CurrencyFormatter.format(6900)}'),
        findsOneWidget,
      );
    },
  );

  testWidgets('résumé non chargé : « — », jamais l\'ancienne valeur', (
    tester,
  ) async {
    final provider = _FakeCashProvider(null);
    await _pump(tester, provider);

    expect(_amountOf(tester, 'Solde attendu'), '—');
    expect(_amountOf(tester, 'Ventes'), '—');
  });

  testWidgets('relecture échouée à la fermeture : « — » dans le message', (
    tester,
  ) async {
    final provider = _FakeCashProvider(_summary(sales: 5400, expected: 5400))
      ..refreshFails = true;
    await _pump(tester, provider);

    await tester.tap(find.text('🔒 Fermer la caisse'));
    await tester.pumpAndSettle();

    expect(find.text('Solde attendu : —'), findsOneWidget);
    expect(_amountOf(tester, 'Solde attendu'), '—');
  });

  testWidgets(
    'C267 : solde compté saisi « 16 075 » (avec séparateur) : lu 16 075 à la '
    'fermeture',
    (tester) async {
      final provider = _FakeCashProvider(
        _summary(sales: 6075, expected: 16075),
      );
      await _pump(tester, provider);

      await tester.tap(find.text('🔒 Fermer la caisse'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Solde réel (GNF)'),
        '16 075',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Fermer'));
      await tester.pumpAndSettle();
      // C273 (a) : étape de confirmation avant la fermeture.
      await tester.tap(find.widgetWithText(ElevatedButton, 'Confirmer'));
      await tester.pumpAndSettle();

      expect(provider.closedWith, 16075);
    },
  );
}
