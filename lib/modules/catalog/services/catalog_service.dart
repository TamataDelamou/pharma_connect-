import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../../../shared/models/product.dart';
import '../models/category.dart';
import '../models/manufacturer.dart';

class CatalogService {
  SupabaseClient get _client => SupabaseService().client;

  static const _productSelect =
      '*, category:categories(name), manufacturer:manufacturers(name)';

  Future<List<Product>> getProducts({
    String? categoryId,
    String? searchQuery,
  }) async {
    var query = _client.from('products').select(_productSelect);

    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }
    // La recherche texte ne porte que sur products.name/generic_name : filtrer
    // aussi sur le nom du fabricant nécessiterait un embed en inner join côté
    // PostgREST, non couvert ici faute de base réelle pour le vérifier.
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.or('name.ilike.%$searchQuery%,generic_name.ilike.%$searchQuery%');
    }

    final rows = await query;
    return rows.map((row) => Product.fromJson(row)).toList();
  }

  Future<Product> getProduct(String id) async {
    final row = await _client
        .from('products')
        .select(_productSelect)
        .eq('id', id)
        .single();
    return Product.fromJson(row);
  }

  Future<List<Category>> getCategories() async {
    final rows = await _client.from('categories').select();
    return rows.map((row) => Category.fromJson(row)).toList();
  }

  Future<List<Manufacturer>> getManufacturers() async {
    final rows = await _client.from('manufacturers').select();
    return rows.map((row) => Manufacturer.fromJson(row)).toList();
  }
}
