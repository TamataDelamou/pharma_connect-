import 'package:flutter/material.dart';
import '../../../shared/models/product.dart';
import '../models/search_filters.dart';
import '../models/search_suggestion.dart';
import '../models/search_result.dart';
import '../models/availability_result.dart';
import '../services/search_service.dart';

enum SearchStatus { idle, searching, loaded, error }

class SearchProvider extends ChangeNotifier {
  final SearchService _service = SearchService();

  // État
  String _query = '';
  SearchStatus _status = SearchStatus.idle;
  String? _error;
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
  List<SearchResult> get results => _results;
  List<SearchSuggestion> get suggestions => _suggestions;
  List<String> get searchHistory => _searchHistory;
  bool get showSuggestions => _showSuggestions;
  SearchFilters get filters => _filters;
  Product? get scannedProduct => _scannedProduct;
  AvailabilityResult? get selectedProductAvailability =>
      _selectedProductAvailability;

  bool get hasResults => _results.isNotEmpty;
  bool get hasFilters => _filters.hasFilters;
  int get filterCount => _filters.filterCount;

  bool get showOnlyAvailable => _filters.onlyAvailable ?? false;
  bool get showOnlyGeneric => _filters.onlyGeneric ?? false;
  bool get showOnlyNearby => _filters.onlyNearby ?? false;

  // ==================== RECHERCHE ====================

  Future<void> search({
    String? query,
    SearchFilters? filters,
    double? userLat,
    double? userLon,
  }) async {
    final searchQuery = query ?? _query;
    if (searchQuery.isEmpty) {
      _results = [];
      _status = SearchStatus.idle;
      notifyListeners();
      return;
    }

    _query = searchQuery;
    _status = SearchStatus.searching;
    _error = null;
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
      _results = results;
      _status = SearchStatus.loaded;
      await _service.addToHistory(searchQuery);
    } catch (e) {
      _error = e.toString();
      _status = SearchStatus.error;
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

  Future<void> loadHistory() async {
    try {
      _searchHistory = await _service.getSearchHistory();
    } catch (e) {
      _searchHistory = [];
    }
    notifyListeners();
  }

  Future<void> clearHistory() async {
    try {
      await _service.clearHistory();
      _searchHistory = [];
      notifyListeners();
    } catch (e) {
      // ignore
    }
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
      await search(query: suggestion.query!);
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
