import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/cards/glass_card.dart';

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
    return Row(
      children: [
        _buildStatCard(
          label: 'Produits',
          value: totalProducts.toString(),
          icon: Icons.inventory_2,
          color: PharmaConnectColors.accentCyan,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          label: 'Unités',
          value: totalStock.toString(),
          icon: Icons.numbers,
          color: PharmaConnectColors.accentPurple,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          label: '⚠️ Faible',
          value: lowStockCount.toString(),
          icon: Icons.warning_amber,
          color: PharmaConnectColors.accentOrange,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          label: '🔴 Rupture',
          value: outOfStockCount.toString(),
          icon: Icons.error_outline,
          color: PharmaConnectColors.accentRed,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    style: PharmaConnectTypography.micro,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: PharmaConnectTypography.kpiMedium.copyWith(
                color: color,
                fontSize: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
