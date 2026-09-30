import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../providers/admin_provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AdminProvider>();
      provider.loadStatistics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();

    return Scaffold(
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
                        'Administration',
                        style: PharmaConnectTypography.heading1,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Gérez les utilisateurs, les pharmacies et la configuration du système',
                        style: PharmaConnectTypography.body2,
                      ),
                    ],
                  ),
                ),
                const KernelBadge(),
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
                    label: 'Utilisateurs',
                    value: provider.statistics['totalUsers']?.toString() ?? '0',
                    subValue:
                        '${provider.statistics['activeUsers'] ?? 0} actifs',
                    color: PharmaConnectColors.accentCyan,
                    icon: Icons.people,
                    onTap: () => context.push('/admin/users'),
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    label: 'Pharmacies',
                    value:
                        provider.statistics['totalPharmacies']?.toString() ??
                        '0',
                    subValue:
                        '${provider.statistics['activePharmacies'] ?? 0} actives',
                    color: PharmaConnectColors.accentGreen,
                    icon: Icons.local_pharmacy,
                    onTap: () => context.push('/admin/pharmacies'),
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    label: 'En attente',
                    value:
                        provider.statistics['pendingPharmacies']?.toString() ??
                        '0',
                    subValue: 'Pharmacies à vérifier',
                    color: PharmaConnectColors.accentOrange,
                    icon: Icons.pending_actions,
                    onTap: () =>
                        context.push('/admin/pharmacies?status=pending'),
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    label: 'Audit',
                    value:
                        provider.statistics['totalAuditLogs']?.toString() ??
                        '0',
                    subValue:
                        '${provider.statistics['recentLogs'] ?? 0} récents',
                    color: PharmaConnectColors.accentPurple,
                    icon: Icons.history,
                    onTap: () => context.push('/admin/audit'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Accès rapides
              const Text(
                'Accès rapides',
                style: PharmaConnectTypography.heading3,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildQuickAction(
                    icon: Icons.people,
                    label: 'Utilisateurs',
                    color: PharmaConnectColors.accentCyan,
                    onTap: () => context.push('/admin/users'),
                  ),
                  const SizedBox(width: 12),
                  _buildQuickAction(
                    icon: Icons.local_pharmacy,
                    label: 'Pharmacies',
                    color: PharmaConnectColors.accentGreen,
                    onTap: () => context.push('/admin/pharmacies'),
                  ),
                  const SizedBox(width: 12),
                  _buildQuickAction(
                    icon: Icons.verified_user,
                    label: 'Vérifications',
                    color: PharmaConnectColors.accentAmber,
                    onTap: () => context.push('/admin/verifications'),
                  ),
                  const SizedBox(width: 12),
                  _buildQuickAction(
                    icon: Icons.history,
                    label: 'Audit',
                    color: PharmaConnectColors.accentPurple,
                    onTap: () => context.push('/admin/audit'),
                  ),
                  const SizedBox(width: 12),
                  _buildQuickAction(
                    icon: Icons.settings,
                    label: 'Configuration',
                    color: PharmaConnectColors.accentOrange,
                    onTap: () => context.push('/admin/config'),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Dernières actions audit
              const Text(
                'Dernières actions administrateurs',
                style: PharmaConnectTypography.heading3,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: provider.auditLogs.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucune activité récente',
                          style: PharmaConnectTypography.body2,
                        ),
                      )
                    : ListView.builder(
                        itemCount: provider.auditLogs.take(10).length,
                        itemBuilder: (context, index) {
                          final log = provider.auditLogs[index];
                          return Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  log.isSuccess
                                      ? Icons.check_circle
                                      : Icons.error_outline,
                                  color: log.isSuccess
                                      ? PharmaConnectColors.accentGreen
                                      : PharmaConnectColors.accentRed,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${log.userName} - ${log.action}',
                                        style: PharmaConnectTypography.body1,
                                      ),
                                      Text(
                                        '${log.resource}: ${log.resourceId}',
                                        style: PharmaConnectTypography.micro,
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _formatDateTime(log.timestamp),
                                  style: PharmaConnectTypography.micro,
                                ),
                              ],
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
    required String subValue,
    required Color color,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 8),
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
                fontSize: 20,
              ),
            ),
            Text(subValue, style: PharmaConnectTypography.micro),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: PharmaConnectTypography.body2,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
