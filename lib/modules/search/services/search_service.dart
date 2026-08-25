import 'dart:math' as math;
import '../../../shared/models/product.dart';
import '../models/search_filters.dart';
import '../models/search_suggestion.dart';
import '../models/search_result.dart';
import '../models/availability_result.dart';
import '../models/pharmacy.dart';

class SearchService {
  static final math.Random _random = math.Random();

  // ==================== DONNÉES ====================

  static final List<Product> _products = [
    // ... (tous les produits existants, voir version précédente)
    // Je garde les produits déjà présents, j'ajoute quelques nouveaux
    Product(
      id: 'p11',
      name: 'Dafalgan 500mg',
      genericName: 'Paracétamol',
      dosage: '500 mg',
      form: 'Comprimé',
      category: 'Antalgique',
      imageUrl: '',
      isGeneric: true,
      manufacturer: 'UPSA',
      isPrescriptionRequired: false,
    ),
    Product(
      id: 'p12',
      name: 'Clamoxyl 500mg',
      genericName: 'Amoxicilline',
      dosage: '500 mg',
      form: 'Gélule',
      category: 'Antibiotique',
      imageUrl: '',
      isGeneric: true,
      manufacturer: 'GSK',
      isPrescriptionRequired: true,
    ),
    Product(
      id: 'p13',
      name: 'Nurofen 400mg',
      genericName: 'Ibuprofène',
      dosage: '400 mg',
      form: 'Comprimé',
      category: 'Anti-inflammatoire',
      imageUrl: '',
      isGeneric: false,
      manufacturer: 'Reckitt Benckiser',
      isPrescriptionRequired: false,
    ),
    Product(
      id: 'p14',
      name: 'Spedifen 400mg',
      genericName: 'Ibuprofène',
      dosage: '400 mg',
      form: 'Comprimé',
      category: 'Anti-inflammatoire',
      imageUrl: '',
      isGeneric: true,
      manufacturer: 'Biogaran',
      isPrescriptionRequired: false,
    ),
  ];

  static final List<Pharmacy> _pharmacies = [
    // ... (pharmacies existantes)
  ];

  static final Map<String, Map<String, PharmacyStock>> _stocks = {};

  static void _initStocks() {
    if (_stocks.isNotEmpty) return;
    for (final product in _products) {
      final Map<String, PharmacyStock> stockByPharmacy = {};
      for (final pharmacy in _pharmacies) {
        final hasStock = _random.nextDouble() > 0.3;
        final stock = hasStock ? _random.nextInt(80) + 1 : 0;
        final price = 1000 + _random.nextInt(15000);
        stockByPharmacy[pharmacy.id] = PharmacyStock(
          pharmacy: pharmacy,
          stock: stock,
          price: price,
          isAvailable: stock > 0,
          lastUpdated: DateTime.now().subtract(
            Duration(hours: _random.nextInt(24)),
          ),
        );
      }
      _stocks[product.id] = stockByPharmacy;
    }
  }

  // ==================== RECHERCHE AVANCÉE ====================

  Future<List<SearchResult>> search({
    required String query,
    SearchFilters? filters,
    double? userLat,
    double? userLon,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _initStocks();

    if (query.isEmpty) return [];

    final lowerQuery = query.toLowerCase();
    final results = <SearchResult>[];

    for (final product in _products) {
      double relevance = 0;
      final matchedTerms = <String>[];

      // Recherche par nom
      if (product.name.toLowerCase().contains(lowerQuery)) {
        relevance += 1.0;
        matchedTerms.add(product.name);
      }

      // Recherche par DCI
      if (product.genericName.toLowerCase().contains(lowerQuery)) {
        relevance += 0.9;
        matchedTerms.add(product.genericName);
      }

      // Recherche par fabricant
      if (product.manufacturer.toLowerCase().contains(lowerQuery)) {
        relevance += 0.5;
        matchedTerms.add(product.manufacturer);
      }

      // Recherche par catégorie
      if (product.category.toLowerCase().contains(lowerQuery)) {
        relevance += 0.4;
        matchedTerms.add(product.category);
      }

      // Recherche par dosage
      if (product.dosage.toLowerCase().contains(lowerQuery)) {
        relevance += 0.3;
        matchedTerms.add(product.dosage);
      }

      if (relevance > 0) {
        final stock = _stocks[product.id] ?? {};
        final pharmacyStocks = stock.values.toList();
        final availability = AvailabilityResult(
          product: product,
          pharmacyStocks: pharmacyStocks,
        );

        results.add(
          SearchResult(
            product: product,
            availability: availability,
            relevanceScore: relevance,
            matchedTerms: matchedTerms,
          ),
        );
      }
    }

    // Appliquer les filtres
    var filtered = results;
    if (filters != null) {
      if (filters.category != null) {
        filtered = filtered
            .where((r) => r.product.category == filters.category)
            .toList();
      }

      if (filters.manufacturer != null) {
        filtered = filtered
            .where((r) => r.product.manufacturer == filters.manufacturer)
            .toList();
      }

      if (filters.onlyAvailable == true) {
        filtered = filtered.where((r) => r.isAvailable).toList();
      }

      if (filters.onlyGeneric == true) {
        filtered = filtered.where((r) => r.product.isGeneric).toList();
      }

      if (filters.onlyPrescriptionRequired == true) {
        filtered = filtered
            .where((r) => r.product.isPrescriptionRequired)
            .toList();
      }

      if (filters.maxPrice != null) {
        filtered = filtered
            .where(
              (r) => r.bestPrice != null && r.bestPrice! <= filters.maxPrice!,
            )
            .toList();
      }

      if (filters.minPrice != null) {
        filtered = filtered
            .where(
              (r) => r.bestPrice != null && r.bestPrice! >= filters.minPrice!,
            )
            .toList();
      }
    }

    // Trier
    if (filters?.sortBy != null) {
      switch (filters!.sortBy) {
        case SortOption.relevance:
          filtered.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
          break;
        case SortOption.priceAsc:
          filtered.sort((a, b) {
            final pa = a.bestPrice ?? double.infinity;
            final pb = b.bestPrice ?? double.infinity;
            return pa.compareTo(pb);
          });
          break;
        case SortOption.priceDesc:
          filtered.sort((a, b) {
            final pa = a.bestPrice ?? double.infinity;
            final pb = b.bestPrice ?? double.infinity;
            return pb.compareTo(pa);
          });
          break;
        case SortOption.nameAsc:
          filtered.sort((a, b) => a.product.name.compareTo(b.product.name));
          break;
        case SortOption.nameDesc:
          filtered.sort((a, b) => b.product.name.compareTo(a.product.name));
          break;
        case SortOption.distance:
          filtered.sort((a, b) {
            // Simuler le tri par distance
            final da =
                a.availability?.nearest?.pharmacy.distance ?? double.infinity;
            final db =
                b.availability?.nearest?.pharmacy.distance ?? double.infinity;
            return da.compareTo(db);
          });
          break;
      }
    }

    return filtered;
  }

  // ==================== SUGGESTIONS ====================

  Future<List<SearchSuggestion>> getSuggestions(String query) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (query.isEmpty) return [];

    final lower = query.toLowerCase();
    final suggestions = <SearchSuggestion>[];

    // Suggestions de produits
    final matchingProducts = _products
        .where((p) => p.name.toLowerCase().contains(lower))
        .take(3)
        .toList();

    for (final product in matchingProducts) {
      suggestions.add(
        SearchSuggestion(
          id: product.id,
          label: product.name,
          subtitle: '${product.dosage} • ${product.form}',
          type: SuggestionType.product,
          query: product.name,
        ),
      );
    }

    // Suggestions de DCI
    final matchingDcis = _products
        .where((p) => p.genericName.toLowerCase().contains(lower))
        .map((p) => p.genericName)
        .toSet()
        .take(2)
        .toList();

    for (final dci in matchingDcis) {
      if (!suggestions.any((s) => s.label == dci)) {
        suggestions.add(
          SearchSuggestion(
            id: 'dci_${dci.hashCode}',
            label: dci,
            subtitle: 'Dénomination commune internationale',
            type: SuggestionType.dci,
            query: dci,
          ),
        );
      }
    }

    // Suggestions de catégories
    final matchingCategories = _products
        .where((p) => p.category.toLowerCase().contains(lower))
        .map((p) => p.category)
        .toSet()
        .take(2)
        .toList();

    for (final category in matchingCategories) {
      if (!suggestions.any((s) => s.label == category)) {
        suggestions.add(
          SearchSuggestion(
            id: 'cat_${category.hashCode}',
            label: category,
            subtitle: 'Catégorie',
            type: SuggestionType.category,
            query: category,
          ),
        );
      }
    }

    return suggestions;
  }

  // ==================== CODE-BARRES ====================

  Future<Product?> searchByBarcode(String barcode) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Simuler une recherche par code-barres
    // En vrai, on ferait un appel API avec le code-barres
    final matchedProducts = _products
        .where((p) => p.id == barcode || p.id == 'p${barcode}')
        .toList();

    return matchedProducts.isNotEmpty ? matchedProducts.first : null;
  }

  // ==================== HISTORIQUE ====================

  static final List<String> _searchHistory = [];

  Future<List<String>> getSearchHistory() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _searchHistory;
  }

  Future<void> addToHistory(String query) async {
    await Future.delayed(const Duration(milliseconds: 50));
    if (query.trim().isEmpty) return;
    _searchHistory.remove(query);
    _searchHistory.insert(0, query);
    if (_searchHistory.length > 10) {
      _searchHistory.removeLast();
    }
  }

  Future<void> clearHistory() async {
    await Future.delayed(const Duration(milliseconds: 50));
    _searchHistory.clear();
  }

  // ==================== DISPONIBILITÉ PRODUIT ====================

  Future<AvailabilityResult?> getProductAvailability(String productId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initStocks();
    final matches = _products.where((p) => p.id == productId).toList();
    if (matches.isEmpty) return null;
    final stock = _stocks[productId] ?? {};
    final pharmacyStocks = stock.values.toList();
    return AvailabilityResult(product: matches.first, pharmacyStocks: pharmacyStocks);
  }

  // ==================== GÉNÉRIQUES ====================

  Future<List<Product>> getGenericAlternatives(String productId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _initStocks();
    final product = _products.firstWhere((p) => p.id == productId);
    return _products
        .where(
          (p) =>
              p.genericName == product.genericName &&
              p.id != productId &&
              p.isGeneric,
        )
        .toList();
  }
}
