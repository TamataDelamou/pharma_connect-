import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../providers/coldchain_provider.dart';
import '../widgets/equipment_card.dart';

class ColdChainDashboardScreen extends StatefulWidget {
  const ColdChainDashboardScreen({super.key});

  @override
  State<ColdChainDashboardScreen> createState() =>
      _ColdChainDashboardScreenState();
}

class _ColdChainDashboardScreenState extends State<ColdChainDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ColdChainProvider>();
      provider.loadEquipments();
      provider.loadStatistics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ColdChainProvider>();

    return Scaffold(
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
                    'Chaîne du froid',
                    style: PharmaConnectTypography.heading1,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Surveillez la température des équipements et des produits',
                    style: PharmaConnectTypography.body2,
                  ),
                ],
              ),
              trailing: [
                const KernelBadge(),
                ElevatedButton.icon(
                  onPressed: () => context.push('/coldchain/add'),
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PharmaConnectColors.accentCyan,
                    foregroundColor: PharmaConnectColors.textOnAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Statistiques
            if (!provider.isLoading) ...[
              Row(
                children: [
                  _buildStatCard(
                    label: 'Équipements',
                    value:
                        provider.statistics['totalEquipments']?.toString() ??
                        '0',
                    color: PharmaConnectColors.accentCyan,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    label: 'Opérationnels',
                    value:
                        provider.statistics['operational']?.toString() ?? '0',
                    color: PharmaConnectColors.accentGreen,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    label: 'Alertes',
                    value: provider.statistics['alarms']?.toString() ?? '0',
                    color: PharmaConnectColors.accentRed,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    label: 'Incidents',
                    value:
                        provider.statistics['activeIncidents']?.toString() ??
                        '0',
                    color: PharmaConnectColors.accentOrange,
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Liste des équipements
            const Text(
              'Équipements de froid',
              style: PharmaConnectTypography.heading3,
            ),
            const SizedBox(height: 8),

            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.equipments.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.ac_unit_outlined,
                            size: 64,
                            color: Colors.white24,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Aucun équipement enregistré',
                            style: PharmaConnectTypography.body2,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: provider.equipments.length,
                      itemBuilder: (context, index) {
                        final equipment = provider.equipments[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: EquipmentCard(
                            equipment: equipment,
                            onTap: () {
                              context.push('/coldchain/${equipment.id}');
                            },
                          ),
                        );
                      },
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
  }) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.all(12),
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
    );
  }
}
