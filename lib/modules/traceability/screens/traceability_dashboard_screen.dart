import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../providers/traceability_provider.dart';
import '../widgets/batch_status_chip.dart';
import '../widgets/scan_fab.dart';

class TraceabilityDashboardScreen extends StatefulWidget {
  const TraceabilityDashboardScreen({super.key});

  @override
  State<TraceabilityDashboardScreen> createState() =>
      _TraceabilityDashboardScreenState();
}

class _TraceabilityDashboardScreenState
    extends State<TraceabilityDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<TraceabilityProvider>();
      provider.loadBatches();
      provider.loadStatistics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TraceabilityProvider>();

    return Scaffold(
      floatingActionButton: const ScanFloatingButton(),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Traçabilité',
                        style: PharmaConnectTypography.heading1,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Suivez et vérifiez l\'authenticité des produits',
                        style: PharmaConnectTypography.body2,
                      ),
                    ],
                  ),
                ),
                const KernelBadge(),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => context.push('/traceability/verify'),
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Vérifier un produit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PharmaConnectColors.accentCyan,
                    foregroundColor: PharmaConnectColors.textOnAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (provider.isLoading) ...[
              const Expanded(child: Center(child: CircularProgressIndicator())),
            ] else ...[
              // Statistiques
              Row(
                children: [
                  _buildStatCard(
                    label: 'Total lots',
                    value:
                        provider.statistics['totalBatches']?.toString() ?? '0',
                    color: PharmaConnectColors.accentCyan,
                    icon: Icons.inventory_2,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    label: 'Actifs',
                    value:
                        provider.statistics['activeBatches']?.toString() ?? '0',
                    color: PharmaConnectColors.accentGreen,
                    icon: Icons.check_circle,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    label: 'Rappels',
                    value:
                        provider.statistics['recalledBatches']?.toString() ??
                        '0',
                    color: PharmaConnectColors.accentRed,
                    icon: Icons.warning,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    label: 'Authentifiés',
                    value:
                        provider.statistics['authenticated']?.toString() ?? '0',
                    color: PharmaConnectColors.accentPurple,
                    icon: Icons.verified,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Liste des lots
              const Text(
                'Lots tracés',
                style: PharmaConnectTypography.heading3,
              ),
              const SizedBox(height: 8),

              Expanded(
                child: provider.batches.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 64,
                              color: Colors.white24,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Aucun lot enregistré',
                              style: PharmaConnectTypography.body2,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: provider.batches.length,
                        itemBuilder: (context, index) {
                          final batch = provider.batches[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: GlassCard(
                              onTap: () {
                                context.push('/traceability/${batch.id}');
                              },
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: batch.statusColor,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          batch.productName,
                                          style: PharmaConnectTypography.body1
                                              .copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        Text(
                                          'Lot: ${batch.batchNumber} • SN: ${batch.serialNumber}',
                                          style: PharmaConnectTypography.body2,
                                        ),
                                        if (batch.isRecalled) ...[
                                          const Text(
                                            '⚠️ RAPPEL',
                                            style: TextStyle(
                                              color:
                                                  PharmaConnectColors.accentRed,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  BatchStatusChip(status: batch.status),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: PharmaConnectTypography.kpiMedium.copyWith(
                      color: color,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    label,
                    style: PharmaConnectTypography.micro,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
