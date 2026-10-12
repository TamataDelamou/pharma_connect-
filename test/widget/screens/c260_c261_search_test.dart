import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pharma_connect/core/theme/app_theme.dart';
import 'package:pharma_connect/modules/search/models/search_filters.dart';
import 'package:pharma_connect/modules/search/models/search_result.dart';
import 'package:pharma_connect/modules/search/providers/search_provider.dart';
import 'package:pharma_connect/modules/search/screens/search_screen.dart';
import 'package:pharma_connect/modules/search/services/search_service.dart';
import 'package:pharma_connect/modules/search/widgets/search_result_card.dart';
import 'package:pharma_connect/shared/models/product.dart';

// C260 : l'historique des recherches ne garde que les recherches voulues,
// pas chaque lettre tapée (« p », « pa », « par »…).
// C261 : tirer la liste vers le bas montre une roue d'actualisation.

SearchResult _result(String name) => SearchResult(
  product: Product(
    id: name,
    name: name,
    genericName: name,
    dosage: '500mg',
    form: 'Comprimé',
    category: 'Antalgiques',
    imageUrl: '',
    isGeneric: false,
    manufacturer: 'Laboratoire',
    isPrescriptionRequired: false,
  ),
);

/// Recherche et historique en mémoire : pas de lecture du serveur.
class _FakeSearchService extends SearchService {
  final List<String> searched = [];
  final List<String> remembered = [];

  /// Réponses retenues par le test, par requête.
  final Map<String, Completer<void>> gates = {};

  @override
  Future<List<SearchResult>> search({
    required String query,
    SearchFilters? filters,
    double? userLat,
    double? userLon,
  }) async {
    searched.add(query);
    await gates[query]?.future;
    return [_result('Résultat pour $query')];
  }

  @override
  Future<void> addToHistory(String query) async => remembered.add(query);

  @override
  Future<List<String>> getSearchHistory() async => remembered.reversed.toList();

  @override
  Future<void> clearHistory() async => remembered.clear();
}

Future<void> _pumpScreen(WidgetTester tester, SearchProvider provider) async {
  tester.view.physicalSize = const Size(800, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ChangeNotifierProvider<SearchProvider>.value(
      value: provider,
      child: MaterialApp(
        theme: PharmaConnectAppTheme.light(),
        home: const SearchScreen(),
      ),
    ),
  );
  await tester.pump();
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

  group('C260, fournisseur', () {
    test(
      'une recherche pendant la frappe ne va pas dans l\'historique',
      () async {
        final service = _FakeSearchService();
        final provider = SearchProvider(service: service);
        for (final typed in ['p', 'pa', 'par', 'para']) {
          await provider.search(query: typed);
        }
        expect(provider.results, isNotEmpty);
        expect(service.remembered, isEmpty);
        expect(provider.searchHistory, isEmpty);
      },
    );

    test(
      'une recherche voulue y va, une seule fois, la plus récente en tête',
      () async {
        final service = _FakeSearchService();
        final provider = SearchProvider(service: service);
        await provider.search(query: 'paracetamol', recordHistory: true);
        await provider.search(query: 'ibuprofene', recordHistory: true);
        await provider.search(query: 'paracetamol', recordHistory: true);
        await Future<void>.delayed(Duration.zero);
        expect(provider.searchHistory, ['paracetamol', 'ibuprofene']);
        expect(service.remembered.last, 'paracetamol');
      },
    );

    test('une seule lettre n\'est jamais gardée', () async {
      final service = _FakeSearchService();
      final provider = SearchProvider(service: service);
      await provider.search(query: 'p', recordHistory: true);
      await Future<void>.delayed(Duration.zero);
      expect(provider.searchHistory, isEmpty);
      expect(service.remembered, isEmpty);
    });

    test('ouvrir un résultat inscrit la recherche en cours', () async {
      final service = _FakeSearchService();
      final provider = SearchProvider(service: service);
      await provider.search(query: 'para');
      await provider.rememberCurrentQuery();
      expect(provider.searchHistory, ['para']);
      expect(service.remembered, ['para']);
    });

    test('la réponse d\'une recherche dépassée est ignorée', () async {
      final service = _FakeSearchService();
      final provider = SearchProvider(service: service);
      final slow = service.gates['p'] = Completer<void>();
      final first = provider.search(query: 'p');
      await provider.search(query: 'pa');
      expect(provider.results.single.product.name, 'Résultat pour pa');
      slow.complete();
      await first;
      expect(provider.results.single.product.name, 'Résultat pour pa');
      expect(provider.query, 'pa');
    });

    test('C261 : une actualisation garde la liste affichée', () async {
      final service = _FakeSearchService();
      final provider = SearchProvider(service: service);
      await provider.search(query: 'para');
      final gate = service.gates['para'] = Completer<void>();
      final refresh = provider.search(keepResults: true);
      expect(provider.status, SearchStatus.loaded);
      expect(provider.results, isNotEmpty);
      gate.complete();
      await refresh;
      expect(provider.status, SearchStatus.loaded);
      expect(service.searched, ['para', 'para']);
    });
  });

  group('écran de recherche', () {
    testWidgets(
      'C260 : taper « para » lettre par lettre lance une seule recherche et '
      'n\'écrit rien dans l\'historique ; valider au clavier l\'y inscrit',
      (tester) async {
        final service = _FakeSearchService();
        final provider = SearchProvider(service: service);
        await _pumpScreen(tester, provider);

        for (final typed in ['p', 'pa', 'par', 'para']) {
          await tester.enterText(find.byType(TextFormField), typed);
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(service.searched, isEmpty);
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump();
        expect(service.searched, ['para']);
        expect(service.remembered, isEmpty);
        expect(provider.searchHistory, isEmpty);

        await tester.testTextInput.receiveAction(TextInputAction.search);
        await tester.pump();
        await tester.pump();
        expect(provider.searchHistory, ['para']);
        expect(service.remembered, ['para']);
      },
    );

    testWidgets('C260 : ouvrir un résultat inscrit la recherche', (
      tester,
    ) async {
      final service = _FakeSearchService();
      final provider = SearchProvider(service: service);
      await provider.search(query: 'para');
      await _pumpScreen(tester, provider);

      // La navigation échoue sans routeur dans cet essai ; seul
      // l'enregistrement compte.
      final card = tester.widget<SearchResultCard>(
        find.byType(SearchResultCard),
      );
      try {
        card.onTap();
      } catch (_) {}
      await tester.pump();
      expect(provider.searchHistory, ['para']);
    });

    testWidgets(
      'C261 : tirer la liste vers le bas montre la roue d\'actualisation et '
      'relance la recherche, liste toujours affichée',
      (tester) async {
        final service = _FakeSearchService();
        final provider = SearchProvider(service: service);
        await provider.search(query: 'para');
        await _pumpScreen(tester, provider);
        expect(find.byType(RefreshProgressIndicator), findsNothing);

        final gate = service.gates['para'] = Completer<void>();
        await tester.fling(
          find.byType(SearchResultCard),
          const Offset(0, 400),
          1000,
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(find.byType(RefreshProgressIndicator), findsOneWidget);
        expect(find.byType(SearchResultCard), findsOneWidget);
        expect(service.searched, ['para', 'para']);

        gate.complete();
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(RefreshProgressIndicator), findsNothing);
        expect(find.byType(SearchResultCard), findsOneWidget);
      },
    );
  });
}
