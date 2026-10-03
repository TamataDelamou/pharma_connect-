import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../../auth/models/user_role.dart';
import '../../auth/providers/auth_provider.dart';
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
      // Correctif audit Module 12 : la liste complète des lots (avec ses
      // mouvements/certificats imbriqués) n'est plus affichée qu'au staff
      // (voir build() ci-dessous) — inutile de la charger pour un patient,
      // qui ne voit que _buildPatientView().
      final role = context.read<AuthProvider>().effectiveRole;
      final isStaff =
          role == UserRole.pharmacien ||
          role == UserRole.grossiste ||
          role == UserRole.regulateur;
      if (!isStaff) return;
      final provider = context.read<TraceabilityProvider>();
      provider.loadBatches();
      provider.loadStatistics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TraceabilityProvider>();
    final role = context.watch<AuthProvider>().effectiveRole;
    // Audit Module 12 (29/08/2026) : ce dashboard exposait la liste complète
    // des lots (mouvements, fabricant, grossiste) à tout compte authentifié,
    // patient compris — c'est une vue d'exploitation de la chaîne
    // d'approvisionnement, pas un service patient. Restreinte aux mêmes
    // rôles que la policy RLS d'écriture (`traceable_batches_write_staff`) ;
    // un patient garde l'essentiel (vérifier / signaler).
    final isStaff =
        role == UserRole.pharmacien ||
        role == UserRole.grossiste ||
        role == UserRole.regulateur;

    return Scaffold(
      floatingActionButton: const ScanFloatingButton(),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            // C233 : en-tête adaptable (actions sous le titre sur téléphone).
            HeaderRow(
              leading: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Traçabilité',
                    style: PharmaConnectTypography.heading1,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Suivez et vérifiez l\'authenticité des produits',
                    style: PharmaConnectTypography.body2,
                  ),
                ],
              ),
              trailing: [
                const KernelBadge(),
                OutlinedButton.icon(
                  onPressed: () => context.push('/traceability/report'),
                  icon: const Icon(Icons.report_outlined),
                  label: const Text('Signaler'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: PharmaConnectColors.accentRed,
                    side: const BorderSide(
                      color: PharmaConnectColors.accentRed,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (isStaff) ...[
                  OutlinedButton.icon(
                    onPressed: () => context.push('/traceability/receive'),
                    icon: const Icon(Icons.move_to_inbox_outlined),
                    label: const Text('Réceptionner'),
                  ),
                  const SizedBox(width: 8),
                ],
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

            if (!isStaff) ...[
              Expanded(child: _buildPatientView(context)),
            ] else if (provider.isLoading) ...[
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

  Widget _buildPatientView(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.verified_outlined,
              size: 72,
              color: PharmaConnectColors.accentCyan,
            ),
            const SizedBox(height: 16),
            const Text(
              'Vérifiez l\'authenticité d\'un produit en scannant son '
              'code-barres, ou signalez un produit qui vous semble suspect.',
              style: PharmaConnectTypography.body2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GlassCard(
              onTap: () => context.push('/traceability/verify'),
              padding: const EdgeInsets.all(16),
              child: const Row(
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    color: PharmaConnectColors.accentCyan,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Vérifier un produit',
                      style: PharmaConnectTypography.body1,
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.white38),
                ],
              ),
            ),
            const SizedBox(height: 8),
            GlassCard(
              onTap: () => context.push('/traceability/report'),
              padding: const EdgeInsets.all(16),
              child: const Row(
                children: [
                  Icon(
                    Icons.report_outlined,
                    color: PharmaConnectColors.accentRed,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Signaler un produit suspect',
                      style: PharmaConnectTypography.body1,
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.white38),
                ],
              ),
            ),
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
