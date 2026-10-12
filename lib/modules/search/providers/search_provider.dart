import 'dart:async';

import 'package:flutter/material.dart';
import '../../../shared/models/product.dart';
import '../models/search_filters.dart';
import '../models/search_suggestion.dart';
import '../models/search_result.dart';
import '../models/availability_result.dart';
import '../services/search_service.dart';

enum SearchStatus { idle, searching, loaded, error }

class SearchProvider extends ChangeNotifier {
  final SearchService _service;

  /// [service] : remplaçable dans les tests.
  SearchProvider({SearchService? service})
    : _service = service ?? SearchService();

  // C260 : numéro de la dernière recherche lancée. La réponse d'une
  // recherche dépassée (frappe plus récente) est ignorée.
  int _searchSeq = 0;

  // État
  String _query = '';
  SearchStatus _status = SearchStatus.idle;
  String? _error;
  bool _isOffline = false;
  List<SearchResult> _results = [];
  List<SearchSuggestion> _suggestions = [];
  List<String> _searchHistory = [];
  bool _showSuggestions = false;
  SearchFilters _filters = const SearchFilters();
  Product? _scannedProduct;
  AvailabilityResult? _selectedProductAvailability;

  // Getters
  String get query => _query;
  SearchStatus get status => _status;
  String? get error => _error;
  bool get isOffline => _isOffline;
  List<SearchResult> get results => _results;
  List<SearchSuggestion> get suggestions => _suggestions;
  List<String> get searchHistory => _searchHistory;
  bool get showSuggestions => _showSuggestions;
  SearchFilters get filters => _filters;
  Product? get scannedProduct => _scannedProduct;
  AvailabilityResult? get selectedProductAvailability =>
      _selectedProductAvailability;

  /// Pose une disponibilité sans appel au serveur (tests et captures
  /// d'écran).
  @visibleForTesting
  set selectedProductAvailabilityForTesting(AvailabilityResult? value) {
    _selectedProductAvailability = value;
    notifyListeners();
  }

  bool get hasResults => _results.isNotEmpty;
  bool get hasFilters => _filters.hasFilters;
  int get filterCount => _filters.filterCount;

  bool get showOnlyAvailable => _filters.onlyAvailable ?? false;
  bool get showOnlyGeneric => _filters.onlyGeneric ?? false;
  bool get showOnlyNearby => _filters.onlyNearby ?? false;

  // ==================== RECHERCHE ====================

  /// Lance une recherche.
  ///
  /// C260 : [recordHistory] n'est vrai que pour une recherche voulue (touche
  /// « Rechercher » du clavier, suggestion ou ancienne recherche choisie).
  /// La recherche lancée pendant la frappe ne s'inscrit pas dans
  /// l'historique : il gardait « p », « pa », « par »…
  ///
  /// C261 : [keepResults] laisse la liste affichée pendant une
  /// actualisation (tirer pour actualiser).
  Future<void> search({
    String? query,
    SearchFilters? filters,
    double? userLat,
    double? userLon,
    bool recordHistory = false,
    bool keepResults = false,
  }) async {
    final searchQuery = query ?? _query;
    if (searchQuery.isEmpty) {
      _searchSeq++;
      _results = [];
      _status = SearchStatus.idle;
      notifyListeners();
      return;
    }

    final seq = ++_searchSeq;
    _query = searchQuery;
    if (!(keepResults && _status == SearchStatus.loaded)) {
      _status = SearchStatus.searching;
    }
    _error = null;
    _isOffline = false;
    _showSuggestions = false;
    notifyListeners();

    try {
      final filtersToUse = filters ?? _filters;
      final results = await _service.search(
        query: searchQuery,
        filters: filtersToUse,
        userLat: userLat,
        userLon: userLon,
      );
      if (seq != _searchSeq) return;
      _results = results;
      _status = SearchStatus.loaded;
      _isOffline = false;
      if (recordHistory) unawaited(_remember(searchQuery));
    } catch (e) {
      if (seq != _searchSeq) return;
      // Directive utilisateur (29/08/2026) : « privilégier le mode
      // hors-ligne tant que cela est possible ». Avant ce correctif, toute
      // erreur réseau effaçait `_results` déjà affichés et basculait sur un
      // écran d'erreur vide — y compris quand une recherche précédente avait
      // déjà rempli l'écran avec des résultats valides. On préserve
      // désormais ces résultats (marqués `_isOffline`) plutôt que de les
      // remplacer par un état d'erreur dur ; l'écran d'erreur reste réservé
      // au cas où il n'y avait rien à montrer avant l'échec.
      if (_results.isNotEmpty) {
        _isOffline = true;
        _error =
            'Connexion indisponible — résultats précédents affichés, '
            'possiblement pas à jour.';
        _status = SearchStatus.loaded;
      } else {
        _error = e.toString();
        _status = SearchStatus.error;
      }
    }

    notifyListeners();
  }

  // ==================== SUGGESTIONS ====================

  Future<void> loadSuggestions(String query) async {
    if (query.isEmpty) {
      _suggestions = [];
      _showSuggestions = false;
      notifyListeners();
      return;
    }

    try {
      final suggestions = await _service.getSuggestions(query);
      _suggestions = suggestions;
      _showSuggestions = true;
    } catch (e) {
      _suggestions = [];
      _showSuggestions = false;
      _error = e.toString();
    }
    notifyListeners();
  }

  void hideSuggestions() {
    _showSuggestions = false;
    notifyListeners();
  }

  // ==================== FILTRES ====================

  void updateFilters(SearchFilters newFilters) {
    _filters = newFilters;
    notifyListeners();
    // Relancer la recherche avec les nouveaux filtres
    if (_query.isNotEmpty) {
      search(query: _query);
    }
  }

  void clearFilters() {
    _filters = const SearchFilters();
    notifyListeners();
    if (_query.isNotEmpty) {
      search(query: _query);
    }
  }

  void toggleFilterAvailable() {
    updateFilters(_filters.copyWith(onlyAvailable: !showOnlyAvailable));
  }

  void toggleFilterGeneric() {
    updateFilters(_filters.copyWith(onlyGeneric: !showOnlyGeneric));
  }

  void toggleFilterNearby() {
    updateFilters(_filters.copyWith(onlyNearby: !showOnlyNearby));
  }

  // ==================== HISTORIQUE ====================

  /// C260 : inscrit la recherche en cours dans l'historique, quand le patient
  /// ouvre un résultat : c'est le signe qu'il a trouvé ce qu'il cherchait.
  Future<void> rememberCurrentQuery() => _remember(_query);

  // Une recherche d'une seule lettre n'est jamais gardée. Un échec
  // d'enregistrement ne touche pas aux résultats affichés.
  Future<void> _remember(String query) async {
    final term = query.trim();
    if (term.length < 2) return;
    _searchHistory = [
      term,
      ..._searchHistory.where((q) => q != term),
    ].take(10).toList();
    notifyListeners();
    try {
      await _service.addToHistory(term);
    } catch (_) {}
  }

  Future<void> loadHistory() async {
    try {
      _searchHistory = await _service.getSearchHistory();
    } catch (e) {
      _searchHistory = [];
      _error = e.toString();
    }
    notifyListeners();
  }

  Future<void> clearHistory() async {
    try {
      await _service.clearHistory();
      _searchHistory = [];
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  // ==================== CODE-BARRES ====================

  Future<void> scanBarcode(String barcode) async {
    _status = SearchStatus.searching;
    _error = null;
    notifyListeners();

    try {
      final product = await _service.searchByBarcode(barcode);
      if (product != null) {
        _scannedProduct = product;
        // Rechercher la disponibilité du produit scanné
        await search(query: product.name);
      } else {
        _error = 'Aucun produit trouvé pour ce code-barres';
        _status = SearchStatus.error;
      }
    } catch (e) {
      _error = e.toString();
      _status = SearchStatus.error;
    }

    notifyListeners();
  }

  void clearScannedProduct() {
    _scannedProduct = null;
    notifyListeners();
  }

  // ==================== NAVIGATION ====================

  Future<void> selectSuggestion(SearchSuggestion suggestion) async {
    if (suggestion.query != null) {
      await search(query: suggestion.query!, recordHistory: true);
    }
  }

  // ==================== DISPONIBILITÉ PRODUIT ====================

  Future<void> loadProductAvailability(String productId) async {
    try {
      _selectedProductAvailability = await _service.getProductAvailability(
        productId,
      );
    } catch (e) {
      _selectedProductAvailability = null;
      _error = e.toString();
    }
    notifyListeners();
  }

  void clearSelectedProductAvailability() {
    _selectedProductAvailability = null;
    notifyListeners();
  }

  // ==================== UTILITAIRES ====================

  void clearSearch() {
    _query = '';
    _results = [];
    _status = SearchStatus.idle;
    _error = null;
    _showSuggestions = false;
    _scannedProduct = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clear() {
    clearSearch();
    clearFilters();
    _searchHistory = [];
    notifyListeners();
  }
}
