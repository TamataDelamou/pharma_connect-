import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:pharma_connect/modules/catalog/providers/catalog_provider.dart';
import 'package:pharma_connect/modules/catalog/screens/catalog_list_screen.dart';
import 'package:pharma_connect/modules/catalog/widgets/product_grid_item.dart';
import 'package:pharma_connect/shared/models/product.dart';

import '../../helpers/phone_layout.dart';

// C276 : le catalogue passe à une colonne dès que la carte n'a plus la
// largeur nécessaire (écran étroit, police agrandie, zoom de l'écran) ; en
// une colonne, chaque carte prend la hauteur de son contenu (C275).

Product _product(String name) => Product(
  id: name,
  name: name,
  genericName: name,
  dosage: '500mg',
  form: 'Comprimé',
  category: 'Antalgiques',
  imageUrl: '',
  isGeneric: true,
  manufacturer: 'Laboratoire',
  isPrescriptionRequired: false,
);

class _CatalogProvider extends CatalogProvider {
  _CatalogProvider(this._products);

  final List<Product> _products;

  @override
  List<Product> get products => _products;

  @override
  bool get isLoading => false;

  @override
  String? get error => null;

  @override
  Future<void> loadCatalog({String? categoryId, String? searchQuery}) async {}

  @override
  Future<void> loadCategories() async {}
}

/// Nombre de cartes sur la première rangée.
Future<int> _columns(
  WidgetTester tester,
  List<Product> products, {
  required double width,
  required double scale,
}) async {
  phoneWidth = width;
  phoneTextScale = scale;
  addTearDown(() {
    phoneWidth = 360;
    phoneTextScale = 1.0;
  });
  final overflows = await pumpAtPhoneWidth(
    tester,
    const CatalogListScreen(),
    wrap: (app) => ChangeNotifierProvider<CatalogProvider>.value(
      value: _CatalogProvider(products),
      child: app,
    ),
  );
  expect(overflows, isEmpty);
  final cards = find.byType(ProductGridItem);
  final top = tester.getTopLeft(cards.first).dy;
  return cards
      .evaluate()
      .where((e) => tester.getTopLeft(find.byWidget(e.widget)).dy == top)
      .length;
}

void main() {
  setUpAll(loadAppFonts);

  final short = [
    for (final n in ['Doliprane', 'Efferalgan', 'Dafalgan']) _product(n),
  ];

  testWidgets('noms courts, 360 points, police normale : deux colonnes', (
    tester,
  ) async {
    expect(await _columns(tester, short, width: 360, scale: 1.0), 2);
  });

  testWidgets('noms courts, 320 points, police 1,15 : la largeur suffit, '
      'deux colonnes', (tester) async {
    expect(await _columns(tester, short, width: 320, scale: 1.15), 2);
  });

  testWidgets('un nom trop long pour une demi-largeur : une colonne', (
    tester,
  ) async {
    final products = [...short, _product('Métronidazole')];
    expect(await _columns(tester, products, width: 360, scale: 1.15), 1);
  });

  testWidgets('une colonne : la carte a la hauteur de son contenu', (
    tester,
  ) async {
    final products = [...short, _product('Métronidazole')];
    expect(await _columns(tester, products, width: 320, scale: 1.3), 1);
    final card = tester.getSize(find.byType(ProductGridItem).first);
    // Avant C276 : hauteur fixe de 290 × 1,3 = 377 points.
    expect(card.height, lessThan(290 * 1.3 - 40));
  });
}
