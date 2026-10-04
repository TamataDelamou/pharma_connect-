import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import '../providers/network_admin_provider.dart';
import '../widgets/network_alert_card.dart';
import 'package:pharma_connect/core/theme/palette.dart';

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
            // C233 : en-tête adaptable (actions sous le titre sur téléphone).
            HeaderRow(
              leading: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🌐 Administration réseau',
                    style: context.text.heading1,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Supervision centralisée du réseau d\'officines',
                    style: context.text.body2,
                  ),
                ],
              ),
              trailing: [
                const KernelBadge(),
                if (provider.unreadAlertCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: context.palette.danger.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${provider.unreadAlertCount} alertes',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.palette.danger,
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
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: context.palette.danger,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            provider.error!,
                            style: context.text.body2.copyWith(
                              color: context.palette.danger,
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
                  context.palette.primary,
                ),
              ),
              Expanded(
                child: _buildKPICard(
                  '💰 CA total',
                  dashboard.formattedRevenue,
                  context.palette.success,
                ),
              ),
              Expanded(
                child: _buildKPICard(
                  '📦 Stock',
                  '${dashboard.totalStockItems} articles',
                  context.palette.secondary,
                ),
              ),
              Expanded(
                child: _buildKPICard(
                  '📋 Ventes',
                  '${dashboard.totalSales}',
                  context.palette.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Alerts
          if (provider.alerts.isNotEmpty) ...[
            Text('🚨 Alertes réseau', style: context.text.heading3),
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
      return Center(
        child: Text('Aucun groupe configuré', style: context.text.body2),
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
                      Text(d.groupName, style: context.text.heading3),
                      const SizedBox(height: 4),
                      Text(
                        '${d.pharmacyCount} officines • ${d.totalSales} ventes',
                        style: context.text.body2,
                      ),
                    ],
                  ),
                ),
                Text(
                  d.formattedRevenue,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: context.palette.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: context.palette.veil(0.24)),
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
            Text(label, style: context.text.micro),
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
