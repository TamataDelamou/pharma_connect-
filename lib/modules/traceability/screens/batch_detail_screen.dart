import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../providers/traceability_provider.dart';
import '../widgets/batch_status_chip.dart';
import '../widgets/movement_timeline.dart';

class BatchDetailScreen extends StatefulWidget {
  final String batchId;

  const BatchDetailScreen({super.key, required this.batchId});

  @override
  State<BatchDetailScreen> createState() => _BatchDetailScreenState();
}

class _BatchDetailScreenState extends State<BatchDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TraceabilityProvider>().loadBatch(widget.batchId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TraceabilityProvider>();
    final batch = provider.selectedBatch;

    if (provider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (batch == null) {
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
                      'Détail du lot',
                      style: PharmaConnectTypography.heading2,
                    ),
                  ),
                  const KernelBadge(),
                ],
              ),
              const SizedBox(height: 24),
              const Expanded(
                child: Center(
                  child: Text(
                    'Lot introuvable',
                    style: PharmaConnectTypography.body2,
                  ),
                ),
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
                    'Détail du lot',
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
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      batch.productName,
                                      style: PharmaConnectTypography.heading3,
                                    ),
                                    Text(
                                      'Lot: ${batch.batchNumber}',
                                      style: PharmaConnectTypography.body2,
                                    ),
                                    Text(
                                      'SN: ${batch.serialNumber}',
                                      style: PharmaConnectTypography.micro,
                                    ),
                                  ],
                                ),
                              ),
                              BatchStatusChip(status: batch.status),
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
                                      'Fabricant',
                                      style: PharmaConnectTypography.label,
                                    ),
                                    Text(batch.manufacturer),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'GTIN',
                                      style: PharmaConnectTypography.label,
                                    ),
                                    Text(batch.gtin),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Fabrication',
                                      style: PharmaConnectTypography.label,
                                    ),
                                    Text(_formatDate(batch.manufacturingDate)),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Péremption',
                                      style: PharmaConnectTypography.label,
                                    ),
                                    Text(
                                      _formatDate(batch.expiryDate),
                                      style: TextStyle(
                                        color:
                                            batch.expiryDate.isBefore(
                                              DateTime.now(),
                                            )
                                            ? PharmaConnectColors.accentRed
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (batch.isRecalled) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: PharmaConnectColors.accentRed.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: PharmaConnectColors.accentRed
                                      .withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.warning,
                                    color: PharmaConnectColors.accentRed,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'RAPPEL: ${batch.recallReason}',
                                      style: PharmaConnectTypography.body2
                                          .copyWith(
                                            color:
                                                PharmaConnectColors.accentRed,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Mouvements
                    const Text(
                      'Historique des mouvements',
                      style: PharmaConnectTypography.heading3,
                    ),
                    const SizedBox(height: 8),
                    if (provider.movements.isEmpty) ...[
                      const Text(
                        'Aucun mouvement',
                        style: PharmaConnectTypography.body2,
                      ),
                    ] else ...[
                      MovementTimeline(movements: provider.movements),
                    ],

                    const SizedBox(height: 16),

                    // Chaîne du froid
                    if (provider.coldChainRecords.isNotEmpty) ...[
                      const Text(
                        'Chaîne du froid',
                        style: PharmaConnectTypography.heading3,
                      ),
                      const SizedBox(height: 8),
                      ...provider.coldChainRecords.map(
                        (record) => Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: record.isBreach
                                  ? PharmaConnectColors.accentRed.withValues(
                                      alpha: 0.2,
                                    )
                                  : Colors.white.withValues(alpha: 0.06),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                record.isBreach
                                    ? Icons.error_outline
                                    : Icons.check_circle,
                                color: record.isBreach
                                    ? PharmaConnectColors.accentRed
                                    : PharmaConnectColors.accentGreen,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${record.temperature}°C',
                                      style: PharmaConnectTypography.body1,
                                    ),
                                    Text(
                                      _formatDateTime(record.timestamp),
                                      style: PharmaConnectTypography.micro,
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                record.status,
                                style: TextStyle(
                                  color: record.isBreach
                                      ? PharmaConnectColors.accentRed
                                      : PharmaConnectColors.accentGreen,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
