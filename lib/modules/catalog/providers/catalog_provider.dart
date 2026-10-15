import 'package:pharma_connect/core/utils/user_message.dart';
import 'package:flutter/material.dart';
import '../../../shared/models/product.dart';
import '../models/category.dart';
import '../models/manufacturer.dart';
import '../services/catalog_service.dart';

class CatalogProvider extends ChangeNotifier {
  final CatalogService _service;

  /// [service] : remplaçable dans les tests.
  CatalogProvider({CatalogService? service})
    : _service = service ?? CatalogService();

  List<Product> _products = [];
  List<Category> _categories = [];
  List<Manufacturer> _manufacturers = [];
  Product? _selectedProduct;
  bool _isLoading = false;
  String? _error;
  String? _selectedCategoryId;
  String? _searchQuery;
  bool _isDetailLoading = false;
  String? _detailError;

  // Getters
  List<Product> get products => _products;
  List<Category> get categories => _categories;
  List<Manufacturer> get manufacturers => _manufacturers;
  Product? get selectedProduct => _selectedProduct;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedCategoryId => _selectedCategoryId;
  String? get searchQuery => _searchQuery;
  bool get isDetailLoading => _isDetailLoading;
  String? get detailError => _detailError;

  // ==================== CHARGEMENT ====================

  Future<void> loadCatalog({String? categoryId, String? searchQuery}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final products = await _service.getProducts(
        categoryId: categoryId,
        searchQuery: searchQuery,
      );
      _products = products;
      _selectedCategoryId = categoryId;
      _searchQuery = searchQuery;
    } catch (e) {
      _error = userMessage(e);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadCategories() async {
    try {
      _categories = await _service.getCategories();
      notifyListeners();
    } catch (e) {
      _error = userMessage(e);
      notifyListeners();
    }
  }

  Future<void> loadManufacturers() async {
    try {
      _manufacturers = await _service.getManufacturers();
      notifyListeners();
    } catch (e) {
      _error = userMessage(e);
      notifyListeners();
    }
  }

  /// C271 : la fiche produit a son propre état de chargement et d'erreur.
  /// Elle levait `isLoading`, celui de la liste : la liste, restée ouverte
  /// sous la fiche, était remplacée par la roue de chargement et revenait en
  /// haut au retour.
  Future<void> loadProductDetail(String id) async {
    _isDetailLoading = true;
    _detailError = null;
    notifyListeners();

    try {
      _selectedProduct = await _service.getProduct(id);
    } catch (e) {
      _detailError = userMessage(e);
    }

    _isDetailLoading = false;
    notifyListeners();
  }

  // ==================== FILTRES ====================

  void filterByCategory(String? categoryId) {
    _selectedCategoryId = categoryId;
    loadCatalog(categoryId: categoryId, searchQuery: _searchQuery);
  }

  void searchProducts(String query) {
    _searchQuery = query;
    loadCatalog(categoryId: _selectedCategoryId, searchQuery: query);
  }

  void clearFilters() {
    _selectedCategoryId = null;
    _searchQuery = null;
    loadCatalog();
  }

  // ==================== UTILITAIRES ====================

  void clearSelected() {
    _selectedProduct = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearDetailError() {
    _detailError = null;
    notifyListeners();
  }
}
