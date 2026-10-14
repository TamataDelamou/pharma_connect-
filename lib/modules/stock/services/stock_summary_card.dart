import 'package:flutter/material.dart';
import '../../../core/widgets/cards/stat_tile_grid.dart';
import '../../../core/theme/palette.dart';

/// Chiffres du stock de l'officine, en tête de « Stock & Lots ».
/// C265 : tuiles communes (`StatTileGrid`) : grille 2 × 2 en largeur
/// téléphone, titres entiers, une seule icône par tuile.
class StockSummaryCard extends StatelessWidget {
  final int totalProducts;
  final int totalStock;
  final int lowStockCount;
  final int outOfStockCount;

  const StockSummaryCard({
    super.key,
    required this.totalProducts,
    required this.totalStock,
    required this.lowStockCount,
    required this.outOfStockCount,
  });

  @override
  Widget build(BuildContext context) {
    return StatTileGrid(
      tiles: [
        StatTileData(
          label: 'Produits',
          value: totalProducts.toString(),
          icon: Icons.inventory_2,
          color: context.palette.primary,
        ),
        StatTileData(
          label: 'Unités',
          value: totalStock.toString(),
          icon: Icons.numbers,
          color: context.palette.secondary,
        ),
        StatTileData(
          label: 'Stock faible',
          value: lowStockCount.toString(),
          icon: Icons.warning_amber,
          color: context.palette.warning,
        ),
        StatTileData(
          label: 'Ruptures',
          value: outOfStockCount.toString(),
          icon: Icons.error_outline,
          color: context.palette.danger,
        ),
      ],
    );
  }
}
