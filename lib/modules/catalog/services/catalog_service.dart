import '../../../shared/models/product.dart';
import '../models/category.dart';
import '../models/manufacturer.dart';

class CatalogService {
  // ==================== DONNÉES MOCKÉES ====================

  static final List<Category> _categories = [
    const Category(id: 'cat_analgesic', name: 'Antalgiques', icon: '💊'),
    const Category(id: 'cat_antibiotic', name: 'Antibiotiques', icon: '🦠'),
    const Category(
      id: 'cat_antiinflammatory',
      name: 'Anti-inflammatoires',
      icon: '🔥',
    ),
    const Category(id: 'cat_cardio', name: 'Cardiologie', icon: '❤️'),
    const Category(id: 'cat_diabetes', name: 'Diabète', icon: '🩸'),
    const Category(id: 'cat_respiratory', name: 'Respiratoire', icon: '🫁'),
    const Category(id: 'cat_digestive', name: 'Digestif', icon: '🍽️'),
    const Category(id: 'cat_dermatology', name: 'Dermatologie', icon: '🧴'),
  ];

  static final List<Manufacturer> _manufacturers = [
    const Manufacturer(id: 'man_sanofi', name: 'Sanofi'),
    const Manufacturer(id: 'man_biogaran', name: 'Biogaran'),
    const Manufacturer(id: 'man_upsa', name: 'UPSA'),
    const Manufacturer(id: 'man_pfizer', name: 'Pfizer'),
    const Manufacturer(id: 'man_gsk', name: 'GSK'),
    const Manufacturer(id: 'man_teva', name: 'Teva'),
    const Manufacturer(id: 'man_astrazeneca', name: 'AstraZeneca'),
    const Manufacturer(id: 'man_merck', name: 'Merck'),
  ];

  // Produits mockés (similaires à ceux de SearchService mais plus complets)
  static final List<Product> _products = [
    Product(
      id: 'p1',
      name: 'Doliprane 1000mg',
      genericName: 'Paracétamol',
      dosage: '1000 mg',
      form: 'Comprimé',
      category: 'Antalgique',
      imageUrl: '',
      isGeneric: false,
      manufacturer: 'Sanofi',
      isPrescriptionRequired: false,
      description:
          'Antalgique et antipyrétique. Indiqué dans le traitement des douleurs et de la fièvre.',
    ),
    Product(
      id: 'p2',
      name: 'Amoxicilline 500mg',
      genericName: 'Amoxicilline',
      dosage: '500 mg',
      form: 'Gélule',
      category: 'Antibiotique',
      imageUrl: '',
      isGeneric: true,
      manufacturer: 'Biogaran',
      isPrescriptionRequired: true,
      description: 'Antibiotique de la famille des pénicillines.',
    ),
    Product(
      id: 'p3',
      name: 'Efferalgan 500mg',
      genericName: 'Paracétamol',
      dosage: '500 mg',
      form: 'Comprimé effervescent',
      category: 'Antalgique',
      imageUrl: '',
      isGeneric: false,
      manufacturer: 'UPSA',
      isPrescriptionRequired: false,
      description:
          'Antalgique et antipyrétique. Effervescent pour une meilleure absorption.',
    ),
    Product(
      id: 'p4',
      name: 'Ibuprofène 400mg',
      genericName: 'Ibuprofène',
      dosage: '400 mg',
      form: 'Comprimé',
      category: 'Anti-inflammatoire',
      imageUrl: '',
      isGeneric: false,
      manufacturer: 'Pfizer',
      isPrescriptionRequired: false,
      description: 'Anti-inflammatoire non stéroïdien.',
    ),
    Product(
      id: 'p5',
      name: 'Ventoline 100µg',
      genericName: 'Salbutamol',
      dosage: '100 µg',
      form: 'Aérosol',
      category: 'Respiratoire',
      imageUrl: '',
      isGeneric: false,
      manufacturer: 'GSK',
      isPrescriptionRequired: true,
      description: 'Bronchodilatateur indiqué dans l\'asthme.',
    ),
    Product(
      id: 'p6',
      name: 'Doliprane 500mg',
      genericName: 'Paracétamol',
      dosage: '500 mg',
      form: 'Comprimé',
      category: 'Antalgique',
      imageUrl: '',
      isGeneric: false,
      manufacturer: 'Sanofi',
      isPrescriptionRequired: false,
    ),
    Product(
      id: 'p7',
      name: 'Augmentin 1g',
      genericName: 'Amoxicilline + Acide clavulanique',
      dosage: '1 g',
      form: 'Comprimé',
      category: 'Antibiotique',
      imageUrl: '',
      isGeneric: false,
      manufacturer: 'GSK',
      isPrescriptionRequired: true,
    ),
    Product(
      id: 'p8',
      name: 'Spasfon 80mg',
      genericName: 'Phloroglucinol',
      dosage: '80 mg',
      form: 'Comprimé',
      category: 'Digestif',
      imageUrl: '',
      isGeneric: false,
      manufacturer: 'Teva',
      isPrescriptionRequired: false,
    ),
    Product(
      id: 'p9',
      name: 'Crestor 10mg',
      genericName: 'Rosuvastatine',
      dosage: '10 mg',
      form: 'Comprimé',
      category: 'Cardiologie',
      imageUrl: '',
      isGeneric: true,
      manufacturer: 'AstraZeneca',
      isPrescriptionRequired: true,
    ),
    Product(
      id: 'p10',
      name: 'Diabètes 850mg',
      genericName: 'Metformine',
      dosage: '850 mg',
      form: 'Comprimé',
      category: 'Diabète',
      imageUrl: '',
      isGeneric: true,
      manufacturer: 'Merck',
      isPrescriptionRequired: true,
    ),
  ];

  // ==================== MÉTHODES ====================

  Future<List<Product>> getProducts({
    String? categoryId,
    String? searchQuery,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    var list = _products;

    // Filtrer par catégorie (nom de la catégorie, pas ID)
    if (categoryId != null) {
      final category = _categories.firstWhere(
        (c) => c.id == categoryId,
        orElse: () => _categories.first,
      );
      list = list.where((p) => p.category == category.name).toList();
    }

    // Filtrer par recherche
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final lower = searchQuery.toLowerCase();
      list = list
          .where(
            (p) =>
                p.name.toLowerCase().contains(lower) ||
                p.genericName.toLowerCase().contains(lower) ||
                p.manufacturer.toLowerCase().contains(lower),
          )
          .toList();
    }

    return list;
  }

  Future<Product> getProduct(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _products.firstWhere((p) => p.id == id);
  }

  Future<List<Category>> getCategories() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _categories;
  }

  Future<List<Manufacturer>> getManufacturers() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _manufacturers;
  }
}
