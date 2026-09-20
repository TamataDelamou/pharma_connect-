import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../providers/network_admin_provider.dart';
import '../widgets/network_alert_card.dart';

class NetworkDashboardScreen extends StatefulWidget {
  final String? groupId;

  const NetworkDashboardScreen({super.key, this.groupId});

  @override
  State<NetworkDashboardScreen> createState() => _NetworkDashboardScreenState();
}

class _NetworkDashboardScreenState extends State<NetworkDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    if (widget.groupId != null) {
      context.read<NetworkAdminProvider>().loadDashboard(widget.groupId!);
    } else {
      context.read<NetworkAdminProvider>().loadAllDashboards();
    }
    context.read<NetworkAdminProvider>().loadAlerts(
      groupId: widget.groupId,
      unreadOnly: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NetworkAdminProvider>();
    final dashboard = provider.selectedDashboard;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🌐 Administration réseau',
                        style: PharmaConnectTypography.heading1,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Supervision centralisée du réseau d\'officines',
                        style: PharmaConnectTypography.body2,
                      ),
                    ],
                  ),
                ),
                const KernelBadge(),
                const SizedBox(width: 16),
                if (provider.unreadAlertCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: PharmaConnectColors.accentRed.withValues(
                        alpha: 0.15,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${provider.unreadAlertCount} alertes',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: PharmaConnectColors.accentRed,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: PharmaConnectColors.accentRed,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            provider.error!,
                            style: PharmaConnectTypography.body2.copyWith(
                              color: PharmaConnectColors.accentRed,
                            ),
                          ),
                          const SizedBox(height: 16),
                          PrimaryButton(
                            label: 'Réessayer',
                            onPressed: _loadData,
                            width: 200,
                          ),
                        ],
                      ),
                    )
                  : widget.groupId != null && dashboard != null
                  ? _buildSingleDashboard(provider)
                  : _buildAllDashboards(provider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleDashboard(NetworkAdminProvider provider) {
    final dashboard = provider.selectedDashboard!;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI cards
          Row(
            children: [
              Expanded(
                child: _buildKPICard(
                  '🏥 Officines',
                  '${dashboard.pharmacyCount}',
                  PharmaConnectColors.accentCyan,
                ),
              ),
              Expanded(
                child: _buildKPICard(
                  '💰 CA total',
                  dashboard.formattedRevenue,
                  PharmaConnectColors.accentGreen,
                ),
              ),
              Expanded(
                child: _buildKPICard(
                  '📦 Stock',
                  '${dashboard.totalStockItems} articles',
                  PharmaConnectColors.accentPurple,
                ),
              ),
              Expanded(
                child: _buildKPICard(
                  '📋 Ventes',
                  '${dashboard.totalSales}',
                  PharmaConnectColors.accentOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Alerts
          if (provider.alerts.isNotEmpty) ...[
            const Text(
              '🚨 Alertes réseau',
              style: PharmaConnectTypography.heading3,
            ),
            const SizedBox(height: 8),
            ...provider.alerts.take(3).map((alert) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: NetworkAlertCard(
                  alert: alert,
                  onRead: () => provider.markAlertRead(alert.id),
                  onTap: () {
                    // Navigate to alert detail
                  },
                ),
              );
            }),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildAllDashboards(NetworkAdminProvider provider) {
    if (provider.dashboards.isEmpty) {
      return const Center(
        child: Text(
          'Aucun groupe configuré',
          style: PharmaConnectTypography.body2,
        ),
      );
    }

    return ListView.builder(
      itemCount: provider.dashboards.length,
      itemBuilder: (context, index) {
        final d = provider.dashboards[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            onTap: () => context.push('/network/group/${d.groupId}'),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.groupName,
                        style: PharmaConnectTypography.heading3,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${d.pharmacyCount} officines • ${d.totalSales} ventes',
                        style: PharmaConnectTypography.body2,
                      ),
                    ],
                  ),
                ),
                Text(
                  d.formattedRevenue,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: PharmaConnectColors.accentCyan,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: Colors.white24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildKPICard(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: PharmaConnectTypography.micro),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
