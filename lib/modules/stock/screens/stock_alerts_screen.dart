import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../providers/stock_provider.dart';
import '../widgets/stock_status_chip.dart';

class StockAlertsScreen extends StatefulWidget {
  const StockAlertsScreen({super.key});

  @override
  State<StockAlertsScreen> createState() => _StockAlertsScreenState();
}

class _StockAlertsScreenState extends State<StockAlertsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StockProvider>().loadAlerts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StockProvider>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: PharmaConnectColors.textPrimary,
                  ),
                  onPressed: () => context.pop(),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Alertes de stock',
                    style: PharmaConnectTypography.heading2,
                  ),
                ),
                const KernelBadge(),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Produits nécessitant une attention immédiate',
              style: PharmaConnectTypography.body2,
            ),
            const SizedBox(height: 24),

            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          // Ruptures de stock
                          _buildAlertSection(
                            title: '🔴 Ruptures de stock',
                            items: provider.outOfStockItems,
                            color: PharmaConnectColors.accentRed,
                            emptyMessage: 'Aucune rupture de stock',
                          ),
                          const SizedBox(height: 16),

                          // Stock critique
                          _buildAlertSection(
                            title: '🟠 Stock critique',
                            items: provider.criticalStockItems,
                            color: PharmaConnectColors.accentAmber,
                            emptyMessage: 'Aucun stock critique',
                          ),
                          const SizedBox(height: 16),

                          // Stock faible
                          _buildAlertSection(
                            title: '🟡 Stock faible',
                            items: provider.lowStockItems,
                            color: PharmaConnectColors.accentOrange,
                            emptyMessage: 'Aucun stock faible',
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertSection({
    required String title,
    required List items,
    required Color color,
    required String emptyMessage,
  }) {
    if (items.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: PharmaConnectColors.accentGreen),
            const SizedBox(width: 12),
            Expanded(
              child: Text(emptyMessage, style: PharmaConnectTypography.body2),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title (${items.length})',
          style: PharmaConnectTypography.heading3.copyWith(color: color),
        ),
        const SizedBox(height: 8),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GlassCard(
              onTap: () => context.push('/stock/${item.id}'),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.product.name,
                          style: PharmaConnectTypography.body1.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Stock : ${item.availableQuantity}',
                          style: PharmaConnectTypography.body2,
                        ),
                      ],
                    ),
                  ),
                  StockStatusChip(status: item.status),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
