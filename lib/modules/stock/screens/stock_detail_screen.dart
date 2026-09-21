import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../providers/stock_provider.dart';
import '../widgets/stock_batch_tile.dart';
import '../widgets/stock_status_chip.dart';

class StockDetailScreen extends StatefulWidget {
  final String stockId;

  const StockDetailScreen({super.key, required this.stockId});

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StockProvider>().loadStockItem(widget.stockId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StockProvider>();
    final item = provider.selectedStockItem;

    if (provider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (provider.error != null || item == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                provider.error ?? 'Produit introuvable',
                style: PharmaConnectTypography.body2.copyWith(
                  color: PharmaConnectColors.accentRed,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Retour'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
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
                Expanded(
                  child: Text(
                    'Détail du stock',
                    style: PharmaConnectTypography.heading2,
                  ),
                ),
                const KernelBadge(),
              ],
            ),
            const SizedBox(height: 24),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Informations produit
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: PharmaConnectColors.accentCyan
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.medication,
                                  color: PharmaConnectColors.accentCyan,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.product.name,
                                      style: PharmaConnectTypography.heading3,
                                    ),
                                    Text(
                                      item.product.genericName,
                                      style: PharmaConnectTypography.body2,
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          '${item.product.dosage} • ${item.product.form}',
                                          style: PharmaConnectTypography.micro,
                                        ),
                                        const SizedBox(width: 12),
                                        StockStatusChip(
                                          status: item.status,
                                          showLabel: true,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(color: Colors.white12),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Disponible',
                                      style: PharmaConnectTypography.label,
                                    ),
                                    Text(
                                      '${item.availableQuantity}',
                                      style: PharmaConnectTypography.kpiSmall,
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Réservé',
                                      style: PharmaConnectTypography.label,
                                    ),
                                    Text(
                                      '${item.reservedQuantity}',
                                      style: PharmaConnectTypography.kpiSmall
                                          .copyWith(
                                            color:
                                                PharmaConnectColors.accentCyan,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Total',
                                      style: PharmaConnectTypography.label,
                                    ),
                                    Text(
                                      '${item.totalQuantity}',
                                      style: PharmaConnectTypography.kpiSmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text(
                                'Seuil bas : ',
                                style: PharmaConnectTypography.label,
                              ),
                              Text('${item.thresholdLow}'),
                              const SizedBox(width: 16),
                              const Text(
                                'Seuil critique : ',
                                style: PharmaConnectTypography.label,
                              ),
                              Text('${item.thresholdCritical}'),
                            ],
                          ),
                          if (item.defaultLocation != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Emplacement : ${item.defaultLocation}',
                              style: PharmaConnectTypography.micro,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Lots
                    const Text('Lots', style: PharmaConnectTypography.heading3),
                    const SizedBox(height: 8),
                    if (item.batches.isEmpty) ...[
                      const Text(
                        'Aucun lot enregistré',
                        style: PharmaConnectTypography.body2,
                      ),
                    ] else ...[
                      ...item.batches.map(
                        (batch) => StockBatchTile(
                          batch: batch,
                          onTap: () {
                            // Navigation vers le détail du lot
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Historique des mouvements
                    const Text(
                      'Derniers mouvements',
                      style: PharmaConnectTypography.heading3,
                    ),
                    const SizedBox(height: 8),
                    if (provider.movements.isEmpty) ...[
                      const Text(
                        'Aucun mouvement',
                        style: PharmaConnectTypography.body2,
                      ),
                    ] else ...[
                      ...provider.movements
                          .take(5)
                          .map(
                            (movement) => Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 12,
                              ),
                              margin: const EdgeInsets.only(bottom: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.03),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  // Audit Module 4 (29/08/2026) : icônes
                                  // inversées par rapport au signe/couleur
                                  // affichés juste à côté (texte "+X" vert
                                  // avec une flèche vers le bas, "-X" rouge
                                  // avec une flèche vers le haut).
                                  Icon(
                                    movement.quantity > 0
                                        ? Icons.arrow_upward
                                        : Icons.arrow_downward,
                                    color: movement.typeColor,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      movement.typeLabel,
                                      style: PharmaConnectTypography.body2,
                                    ),
                                  ),
                                  Text(
                                    '${movement.quantity > 0 ? "+" : ""}${movement.quantity}',
                                    style: PharmaConnectTypography.body2
                                        .copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: movement.quantity > 0
                                              ? PharmaConnectColors.accentGreen
                                              : PharmaConnectColors.accentRed,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      if (provider.movements.length > 5) ...[
                        TextButton(
                          onPressed: () {
                            context.push('/stock/movements?item=${item.id}');
                          },
                          child: const Text('Voir tout l\'historique'),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
