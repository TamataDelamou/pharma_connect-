import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../../auth/models/user_role.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/stock_provider.dart';
import '../widgets/stock_status_chip.dart';
import '../../../core/theme/palette.dart';

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
      final pharmacyId = context.read<AuthProvider>().pharmacyId;
      context.read<StockProvider>().loadAlerts(pharmacyId: pharmacyId);
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
                  icon: Icon(
                    Icons.arrow_back,
                    color: context.palette.textPrimary,
                  ),
                  onPressed: () => context.pop(),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Alertes de stock', style: context.text.heading2),
                ),
                // Audit Module 11 (29/08/2026) : /stock/forecast et le
                // nouvel écran /stock/forecast/orders (arbitrage D17)
                // étaient routés et leur provider déclaré dans app.dart,
                // mais n'avaient aucun point d'entrée de navigation nulle
                // part dans l'app — même défaut que /alerts/thresholds et
                // /alerts/preferences avant leur correction au Module 10.
                if (context.watch<AuthProvider>().effectiveRole ==
                    UserRole.pharmacien)
                  IconButton(
                    icon: Icon(
                      Icons.insights_outlined,
                      color: context.palette.textPrimary,
                    ),
                    tooltip: 'Prévision de la demande',
                    onPressed: () => context.push('/stock/forecast'),
                  ),
                const KernelBadge(),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Produits nécessitant une attention immédiate',
              style: context.text.body2,
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
                            color: context.palette.danger,
                            emptyMessage: 'Aucune rupture de stock',
                          ),
                          const SizedBox(height: 16),

                          // Stock critique
                          _buildAlertSection(
                            title: '🟠 Stock critique',
                            items: provider.criticalStockItems,
                            color: context.palette.warningStrong,
                            emptyMessage: 'Aucun stock critique',
                          ),
                          const SizedBox(height: 16),

                          // Stock faible
                          _buildAlertSection(
                            title: '🟡 Stock faible',
                            items: provider.lowStockItems,
                            color: context.palette.warning,
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
            Icon(Icons.check_circle, color: context.palette.success),
            const SizedBox(width: 12),
            Expanded(child: Text(emptyMessage, style: context.text.body2)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title (${items.length})',
          style: context.text.heading3.copyWith(color: color),
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
                          style: context.text.body1.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Stock : ${item.availableQuantity}',
                          style: context.text.body2,
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
