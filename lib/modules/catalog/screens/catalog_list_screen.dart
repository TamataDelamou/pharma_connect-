import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/kernel/kernel_badge.dart';
import '../../../core/widgets/layout/responsive.dart';
import '../../../core/widgets/inputs/glass_input.dart';
import '../providers/catalog_provider.dart';
import '../widgets/category_filter.dart';
import '../widgets/product_grid_item.dart';
import '../../../core/widgets/text/whole_words_text.dart';
import '../../../shared/models/product.dart';
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
              provider.error!,
              textAlign: TextAlign.center,
              style: context.text.body2.copyWith(color: context.palette.danger),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              // C271 : réessayer garde la catégorie et la recherche en cours.
              onPressed: () => provider.loadCatalog(
                categoryId: provider.selectedCategoryId,
                searchQuery: provider.searchQuery,
              ),
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

    // C266 : en largeur, trois colonnes (inchangé).
    if (!isCompactWidth(context)) {
      return GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.9,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: provider.products.length,
        itemBuilder: (context, index) => _item(provider.products[index]),
      );
    }

    // C276 (règle d'Achille du 16/10/2026) : en largeur téléphone, deux
    // colonnes seulement si chaque mot des cartes tient dans la largeur réelle
    // d'une carte, quelle que soit la raison du manque de place (écran
    // étroit, police agrandie, zoom de l'écran) ; sinon une colonne. Plus de
    // hauteur fixe : en deux colonnes, une rangée prend la hauteur de sa plus
    // haute carte ; en une colonne, chaque carte la hauteur de son contenu
    // (C275). Avant : deux colonnes jusqu'à l'échelle 1,15, hauteur fixe
    // (C266, C268), d'où des noms coupés au milieu et des cartes rognées.
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final cardWidth = (constraints.maxWidth - spacing) / 2;
        final columns = _wordsFit(context, provider, cardWidth) ? 2 : 1;
        final rows = (provider.products.length / columns).ceil();
        return ListView.builder(
          itemCount: rows,
          itemBuilder: (context, row) {
            final start = row * columns;
            final Widget content;
            if (columns == 1) {
              content = _item(provider.products[start]);
            } else {
              content = IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _item(provider.products[start])),
                    const SizedBox(width: spacing),
                    Expanded(
                      child: start + 1 < provider.products.length
                          ? _item(provider.products[start + 1])
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              );
            }
            return Padding(
              padding: EdgeInsets.only(bottom: row < rows - 1 ? spacing : 0),
              child: content,
            );
          },
        );
      },
    );
  }

  Widget _item(Product product) => ProductGridItem(
    product: product,
    onTap: () => context.push('/catalog/${product.id}'),
  );

  /// C276 : chaque mot du nom, de la DCI et de la ligne « dosage • forme »
  /// de chaque produit tient-il dans une carte de [cardWidth] ?
  bool _wordsFit(
    BuildContext context,
    CatalogProvider provider,
    double cardWidth,
  ) {
    final inner = cardWidth - 2 * ProductGridItem.padding - 2;
    if (inner <= 0) return false;
    final textScaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    final base = DefaultTextStyle.of(context).style;
    final styles = ProductGridItem.textStyles(context);
    for (final product in provider.products) {
      final texts = ProductGridItem.texts(product);
      for (var i = 0; i < texts.length; i++) {
        final style = base.merge(styles[i]);
        if (WholeWordsText.longestWordScale(
              texts[i],
              style,
              maxWidth: inner,
              textScaler: textScaler,
              textDirection: direction,
            ) <
            1) {
          return false;
        }
      }
    }
    return true;
  }
}
