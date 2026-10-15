import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/kernel/kernel_badge.dart';
import '../../../core/widgets/layout/responsive.dart';
import '../../../core/widgets/inputs/glass_input.dart';
import '../providers/catalog_provider.dart';
import '../widgets/category_filter.dart';
import '../widgets/product_grid_item.dart';
import '../../../core/theme/palette.dart';

class CatalogListScreen extends StatefulWidget {
  const CatalogListScreen({super.key});

  @override
  State<CatalogListScreen> createState() => _CatalogListScreenState();
}

class _CatalogListScreenState extends State<CatalogListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CatalogProvider>();
      provider.loadCatalog();
      provider.loadCategories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CatalogProvider>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Catalogue', style: context.text.heading1),
                      SizedBox(height: 4),
                      Text(
                        'Parcourez tous les médicaments disponibles',
                        style: context.text.body2,
                      ),
                    ],
                  ),
                ),
                KernelBadge(),
              ],
            ),
            const SizedBox(height: 16),

            // Barre de recherche
            GlassInput(
              label: '',
              // C265 : texte d'aide qui tient sur une ligne à 360 px.
              hint: 'Médicament, DCI, fabricant',
              controller: _searchController,
              prefixIcon: Icons.search,
              suffixIcon: _searchController.text.isNotEmpty
                  ? Icons.clear
                  : null,
              onSuffixPressed: () {
                _searchController.clear();
                provider.searchProducts('');
              },
              onChanged: (value) {
                setState(() {});
                provider.searchProducts(value);
              },
            ),
            const SizedBox(height: 12),

            // Filtres par catégorie
            if (provider.categories.isNotEmpty)
              CategoryFilter(
                categories: provider.categories,
                selectedCategoryId: provider.selectedCategoryId,
                onCategorySelected: (id) => provider.filterByCategory(id),
                onClear: provider.clearFilters,
              ),
            const SizedBox(height: 16),

            // Contenu principal
            Expanded(child: _buildContent(provider)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(CatalogProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Erreur : ${provider.error}',
              style: context.text.body2.copyWith(color: context.palette.danger),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.loadCatalog(),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (provider.products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: context.palette.veil(0.24),
            ),
            SizedBox(height: 16),
            Text('Aucun produit trouvé', style: context.text.heading2),
            SizedBox(height: 8),
            Text('Essayez de modifier vos filtres', style: context.text.body2),
          ],
        ),
      );
    }

    // C266 : en largeur téléphone, deux colonnes de hauteur fixe. Trois
    // colonnes ne laissaient à 360 px qu'une centaine de pixels par carte :
    // le nom du produit, à la même taille que dans « Stock & Lots », était
    // coupé lettre par lettre et le contenu dépassait la carte.
    // C268 : avec une police agrandie, une seule colonne, plus haute : sur
    // deux colonnes, le nom d'un produit ne tenait plus et était coupé au
    // milieu d'un mot.
    final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
    return GridView.builder(
      gridDelegate: isCompactWidth(context)
          ? SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: textScale > 1.15 ? 1 : 2,
              mainAxisExtent: 290 * textScale,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            )
          : const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.9,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
      itemCount: provider.products.length,
      itemBuilder: (context, index) {
        final product = provider.products[index];
        return ProductGridItem(
          product: product,
          onTap: () {
            context.push('/catalog/${product.id}');
          },
        );
      },
    );
  }
}
