import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/product.dart';
import '../models/search_filters.dart';
import '../models/search_suggestion.dart';
import '../models/search_result.dart';
import '../models/availability_result.dart';
import '../models/pharmacy.dart';
import '../../../core/services/supabase_service.dart';

// SearchResult/AvailabilityResult/SearchSuggestion n'ont pas de table dédiée
// (voir supabase/migrations/20260827001500_search.sql) : ils sont calculés
// à la volée depuis products/stock_items/pharmacies. Seul search_history est
// réellement persisté.
class SearchService {
  SupabaseClient get _client => SupabaseService().client;

  static const _productSelect =
      '*, category:categories(name), manufacturer:manufacturers(name)';

  Future<List<Product>> _fetchAllProducts() async {
    final rows = await _client.from('products').select(_productSelect);
    return rows.map((row) => Product.fromJson(row)).toList();
  }

  Future<Map<String, List<PharmacyStock>>> _fetchStocksFor(
    List<String> productIds,
  ) async {
    if (productIds.isEmpty) return {};
    // RG-AUT-04 (audit Module 2, 29/08/2026) : « un compte pharmacie
    // suspendu... est immédiatement retiré des résultats de recherche
    // patients ». Cette jointure n'appliquait jusqu'ici aucun filtre sur
    // pharmacies.status : une officine 'suspended', 'rejected',
    // 'underReview', ou même 'pending' (candidature en auto-inscription pas
    // encore revue — voir Module 1, PharmacyService) apparaissait au même
    // titre qu'une officine 'active' dans la recherche publique. `!inner`
    // est nécessaire pour que le filtre sur la ressource imbriquée soit
    // réellement appliqué par PostgREST (un simple `pharmacies(*)` avec
    // `.eq('pharmacy.status', ...)` ne filtre pas, il ne fait que passer
    // silencieusement l'objet à null).
    final rows = await _client
        .from('stock_items')
        .select('*, pharmacy:pharmacies!inner(*)')
        .inFilter('product_id', productIds)
        .eq('pharmacy.status', 'active');

    final byProduct = <String, List<PharmacyStock>>{};
    for (final row in rows) {
      final productId = row['product_id'] as String;
      final pharmacyJson = row['pharmacy'] as Map<String, dynamic>?;
      if (pharmacyJson == null) continue;

      final available =
          (row['total_quantity'] as int? ?? 0) -
          (row['reserved_quantity'] as int? ?? 0);
      byProduct
          .putIfAbsent(productId, () => [])
          .add(
            PharmacyStock(
              pharmacy: Pharmacy.fromJson(pharmacyJson),
              stock: available < 0 ? 0 : available,
              price: row['unit_price'] as int? ?? 0,
              isAvailable: available > 0,
              lastUpdated: DateTime.parse(row['updated_at'] as String),
            ),
          );
    }
    return byProduct;
  }

  // ==================== RECHERCHE AVANCÉE ====================

  Future<List<SearchResult>> search({
    required String query,
    SearchFilters? filters,
    double? userLat,
    double? userLon,
  }) async {
    if (query.isEmpty) return [];

    final products = await _fetchAllProducts();
    final lowerQuery = query.toLowerCase();

    final matched = <Product>[];
    final relevanceByProduct = <String, double>{};
    final matchedTermsByProduct = <String, List<String>>{};

    for (final product in products) {
      double relevance = 0;
      final matchedTerms = <String>[];

      if (product.name.toLowerCase().contains(lowerQuery)) {
        relevance += 1.0;
        matchedTerms.add(product.name);
      }
      if (product.genericName.toLowerCase().contains(lowerQuery)) {
        relevance += 0.9;
        matchedTerms.add(product.genericName);
      }
      if (product.manufacturer.toLowerCase().contains(lowerQuery)) {
        relevance += 0.5;
        matchedTerms.add(product.manufacturer);
      }
      if (product.category.toLowerCase().contains(lowerQuery)) {
        relevance += 0.4;
        matchedTerms.add(product.category);
      }
      if (product.dosage.toLowerCase().contains(lowerQuery)) {
        relevance += 0.3;
        matchedTerms.add(product.dosage);
      }

      if (relevance > 0) {
        matched.add(product);
        relevanceByProduct[product.id] = relevance;
        matchedTermsByProduct[product.id] = matchedTerms;
      }
    }

    if (matched.isEmpty) return [];

    final stocksByProduct = await _fetchStocksFor(
      matched.map((p) => p.id).toList(),
    );

    var results = matched.map((product) {
      final availability = AvailabilityResult(
        product: product,
        pharmacyStocks: stocksByProduct[product.id] ?? [],
      );
      return SearchResult(
        product: product,
        availability: availability,
        relevanceScore: relevanceByProduct[product.id]!,
        matchedTerms: matchedTermsByProduct[product.id]!,
      );
    }).toList();

    if (filters != null) {
      if (filters.category != null) {
        results = results
            .where((r) => r.product.category == filters.category)
            .toList();
      }
      if (filters.manufacturer != null) {
        results = results
            .where((r) => r.product.manufacturer == filters.manufacturer)
            .toList();
      }
      if (filters.onlyAvailable == true) {
        results = results.where((r) => r.isAvailable).toList();
      }
      if (filters.onlyGeneric == true) {
        results = results.where((r) => r.product.isGeneric).toList();
      }
      if (filters.onlyPrescriptionRequired == true) {
        results = results
            .where((r) => r.product.isPrescriptionRequired)
            .toList();
      }
      if (filters.maxPrice != null) {
        results = results
            .where((r) => r.bestPrice != null && r.bestPrice! <= filters.maxPrice!)
            .toList();
      }
      if (filters.minPrice != null) {
        results = results
            .where((r) => r.bestPrice != null && r.bestPrice! >= filters.minPrice!)
            .toList();
      }
    }

    switch (filters?.sortBy) {
      case SortOption.relevance:
      case null:
        results.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
        break;
      case SortOption.priceAsc:
        results.sort((a, b) {
          final num pa = a.bestPrice ?? double.infinity;
          final num pb = b.bestPrice ?? double.infinity;
          return pa.compareTo(pb);
        });
        break;
      case SortOption.priceDesc:
        results.sort((a, b) {
          final num pa = a.bestPrice ?? double.infinity;
          final num pb = b.bestPrice ?? double.infinity;
          return pb.compareTo(pa);
        });
        break;
      case SortOption.nameAsc:
        results.sort((a, b) => a.product.name.compareTo(b.product.name));
        break;
      case SortOption.nameDesc:
        results.sort((a, b) => b.product.name.compareTo(a.product.name));
        break;
      case SortOption.distance:
        results.sort((a, b) {
          final da =
              a.availability?.nearest?.pharmacy.distance ?? double.infinity;
          final db =
              b.availability?.nearest?.pharmacy.distance ?? double.infinity;
          return da.compareTo(db);
        });
        break;
    }

    return results;
  }

  // ==================== SUGGESTIONS ====================

  Future<List<SearchSuggestion>> getSuggestions(String query) async {
    if (query.isEmpty) return [];

    final products = await _fetchAllProducts();
    final lower = query.toLowerCase();
    final suggestions = <SearchSuggestion>[];

    final matchingProducts = products
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

    final matchingDcis = products
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

    final matchingCategories = products
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
    // Aucune colonne barcode/GTIN sur public.products aujourd'hui : même
    // heuristique qu'avant (comparaison à l'id), pas une vraie recherche
    // code-barres. À revoir quand le référentiel médicament aura un GTIN.
    final products = await _fetchAllProducts();
    final matches = products
        .where((p) => p.id == barcode || p.id == 'p$barcode')
        .toList();
    return matches.isNotEmpty ? matches.first : null;
  }

  // ==================== HISTORIQUE ====================

  Future<List<String>> getSearchHistory() async {
    final userId = SupabaseService().currentUser?.id;
    if (userId == null) return [];

    final rows = await _client
        .from('search_history')
        .select('query')
        .eq('user_id', userId)
        .order('searched_at', ascending: false)
        .limit(10);
    return rows.map((row) => row['query'] as String).toList();
  }

  Future<void> addToHistory(String query) async {
    if (query.trim().isEmpty) return;
    final userId = SupabaseService().currentUser?.id;
    if (userId == null) return;

    // Dédoublonne comme le faisait la liste en mémoire : retire les entrées
    // précédentes de la même requête avant d'insérer la plus récente.
    await _client
        .from('search_history')
        .delete()
        .eq('user_id', userId)
        .eq('query', query);
    await _client.from('search_history').insert({
      'user_id': userId,
      'query': query,
    });
  }

  Future<void> clearHistory() async {
    final userId = SupabaseService().currentUser?.id;
    if (userId == null) return;
    await _client.from('search_history').delete().eq('user_id', userId);
  }

  // ==================== DISPONIBILITÉ PRODUIT ====================

  Future<AvailabilityResult?> getProductAvailability(String productId) async {
    final row = await _client
        .from('products')
        .select(_productSelect)
        .eq('id', productId)
        .maybeSingle();
    if (row == null) return null;

    final product = Product.fromJson(row);
    final stocksByProduct = await _fetchStocksFor([productId]);
    return AvailabilityResult(
      product: product,
      pharmacyStocks: stocksByProduct[productId] ?? [],
    );
  }

  // ==================== GÉNÉRIQUES ====================

  Future<List<Product>> getGenericAlternatives(String productId) async {
    final row = await _client
        .from('products')
        .select()
        .eq('id', productId)
        .single();
    final genericName = row['generic_name'] as String;

    final rows = await _client
        .from('products')
        .select(_productSelect)
        .eq('generic_name', genericName)
        .eq('is_generic', true)
        .neq('id', productId);
    return rows.map((r) => Product.fromJson(r)).toList();
  }
}
