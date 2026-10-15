import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../providers/stock_provider.dart';
import '../widgets/stock_batch_tile.dart';
import '../widgets/stock_status_chip.dart';
import '../../../core/theme/palette.dart';

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

    if (provider.isItemLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (provider.itemError != null || item == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                provider.itemError ?? 'Produit introuvable',
                style: context.text.body2.copyWith(
                  color: context.palette.danger,
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
                  icon: Icon(
                    Icons.arrow_back,
                    color: context.palette.textPrimary,
                  ),
                  onPressed: () => context.pop(),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Détail du stock', style: context.text.heading2),
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
                                  color: context.palette.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.medication,
                                  color: context.palette.primary,
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
                                      style: context.text.heading3,
                                    ),
                                    Text(
                                      item.product.genericName,
                                      style: context.text.body2,
                                    ),
                                    // C272 : l'état passe sous le dosage et
                                    // la forme quand la place manque.
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 4,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        Text(
                                          '${item.product.dosage} • ${item.product.form}',
                                          style: context.text.micro,
                                        ),
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
                          Divider(color: context.palette.veil(0.12)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Disponible',
                                      style: context.text.label,
                                    ),
                                    Text(
                                      '${item.availableQuantity}',
                                      style: context.text.kpiSmall,
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Réservé', style: context.text.label),
                                    Text(
                                      '${item.reservedQuantity}',
                                      style: context.text.kpiSmall.copyWith(
                                        color: context.palette.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Total', style: context.text.label),
                                    Text(
                                      '${item.totalQuantity}',
                                      style: context.text.kpiSmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // C272 : seuils l'un sous l'autre (côte à côte,
                          // débordement avec une police agrandie).
                          Row(
                            children: [
                              Text('Seuil bas : ', style: context.text.label),
                              Text('${item.thresholdLow}'),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                'Seuil critique : ',
                                style: context.text.label,
                              ),
                              Text('${item.thresholdCritical}'),
                            ],
                          ),
                          if (item.defaultLocation != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Emplacement : ${item.defaultLocation}',
                              style: context.text.micro,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Lots
                    Text('Lots', style: context.text.heading3),
                    const SizedBox(height: 8),
                    if (item.batches.isEmpty) ...[
                      Text('Aucun lot enregistré', style: context.text.body2),
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
                    Text('Derniers mouvements', style: context.text.heading3),
                    const SizedBox(height: 8),
                    if (provider.movements.isEmpty) ...[
                      Text('Aucun mouvement', style: context.text.body2),
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
                                color: context.palette.surfaceDisabled,
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
                                    color: movement.typeColor.of(
                                      context.palette,
                                    ),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      movement.typeLabel,
                                      style: context.text.body2,
                                    ),
                                  ),
                                  Text(
                                    '${movement.quantity > 0 ? "+" : ""}${movement.quantity}',
                                    style: context.text.body2.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: movement.quantity > 0
                                          ? context.palette.success
                                          : context.palette.danger,
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
