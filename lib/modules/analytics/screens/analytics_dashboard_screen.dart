import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import 'package:pharma_connect/core/utils/currency_formatter.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/analytics_provider.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = SupabaseService().currentUser?.id;
      if (userId != null) {
        context.read<AnalyticsProvider>().loadDashboards(userId);
        context.read<AnalyticsProvider>().loadAllData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnalyticsProvider>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // C233 : en-tête adaptable (actions sous le titre sur téléphone).
            HeaderRow(
              leading: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Analytics',
                    style: PharmaConnectTypography.heading1,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Indicateurs clés et performances du réseau',
                    style: PharmaConnectTypography.body2,
                  ),
                ],
              ),
              trailing: [
                const KernelBadge(),
                DropdownButton<String>(
                  value: provider.selectedDashboard?.id,
                  hint: const Text('Tableau de bord'),
                  dropdownColor: PharmaConnectColors.primaryDeep,
                  style: const TextStyle(
                    color: PharmaConnectColors.textPrimary,
                  ),
                  items: provider.dashboards.map((d) {
                    return DropdownMenuItem<String>(
                      value: d.id,
                      child: Text(d.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      provider.selectDashboard(value);
                    }
                  },
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(
                    Icons.refresh,
                    color: PharmaConnectColors.textSecondary,
                  ),
                  onPressed: () {
                    provider.loadAllData();
                  },
                ),
                // Audit Module 28 (BI), Étape 3 (05/09/2026), BI-6/BI-8 :
                // seules entrées d'accès à DashboardEditorScreen (BI-7),
                // ForecastScreen et au nouvel écran d'export (BI-8) — les
                // trois étaient soit construites et inatteignables (BI-6),
                // soit absentes (BI-8). Exposées sans filtrage par rôle,
                // comme la quasi-totalité des menus de ce projet : c'est la
                // RLS/les vues scopées (BI-1/BI-2/BI-7) qui gouvernent
                // réellement ce que chaque compte y voit.
                IconButton(
                  tooltip: 'Personnaliser',
                  icon: const Icon(
                    Icons.dashboard_customize,
                    color: PharmaConnectColors.textSecondary,
                  ),
                  onPressed: () => context.push('/analytics/dashboard-editor'),
                ),
                // C232 : écran absent — « Prévisions IA »
                // (/analytics/forecast, route désactivée par C188) masqué.
                IconButton(
                  tooltip: 'Exporter des rapports',
                  icon: const Icon(
                    Icons.ios_share,
                    color: PharmaConnectColors.textSecondary,
                  ),
                  onPressed: () => context.push('/analytics/export'),
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
                            onPressed: () {
                              provider.clearError();
                              provider.loadAllData();
                            },
                            width: 200,
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // KPI Cards
                          _buildKpiRow(provider),
                          const SizedBox(height: 24),

                          // Charts
                          _buildCharts(provider),
                          const SizedBox(height: 24),

                          // Top products and pharmacies
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: _buildTopProducts(provider),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 1,
                                child: _buildTopPharmacies(provider),
                              ),
                            ],
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

  Widget _buildKpiRow(AnalyticsProvider provider) {
    final summary = provider.summary;
    if (summary == null) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Consultations',
                  style: PharmaConnectTypography.label,
                ),
                const SizedBox(height: 4),
                Text(
                  summary.totalConsultations.toString(),
                  style: PharmaConnectTypography.kpiMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Prescriptions',
                  style: PharmaConnectTypography.label,
                ),
                const SizedBox(height: 4),
                Text(
                  summary.totalPrescriptions.toString(),
                  style: PharmaConnectTypography.kpiMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Réservations',
                  style: PharmaConnectTypography.label,
                ),
                const SizedBox(height: 4),
                Text(
                  summary.totalReservations.toString(),
                  style: PharmaConnectTypography.kpiMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chiffre d\'affaires',
                  style: PharmaConnectTypography.label,
                ),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.format(summary.totalRevenue),
                  style: PharmaConnectTypography.kpiMedium.copyWith(
                    color: PharmaConnectColors.accentCyan,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCharts(AnalyticsProvider provider) {
    if (provider.dailyStats.isEmpty) {
      return const SizedBox.shrink();
    }

    final stats = provider.dailyStats.reversed.toList();
    final spots = stats.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        entry.value.consultationsCount.toDouble(),
      );
    }).toList();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Activité quotidienne (30 derniers jours)',
            style: PharmaConnectTypography.heading3,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: _bottomTitleWidgets,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: spots.length.toDouble(),
                minY: 0,
                maxY:
                    spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.2,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: PharmaConnectColors.accentCyan,
                    barWidth: 2,
                    belowBarData: BarAreaData(
                      show: true,
                      color: PharmaConnectColors.accentCyan.withValues(
                        alpha: 0.2,
                      ),
                    ),
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomTitleWidgets(double value, TitleMeta meta) {
    final stats = context
        .watch<AnalyticsProvider>()
        .dailyStats
        .reversed
        .toList();
    if (value.toInt() >= stats.length) return const SizedBox.shrink();
    final date = stats[value.toInt()].date;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        '${date.day}/${date.month}',
        style: const TextStyle(fontSize: 10, color: Colors.white54),
      ),
    );
  }

  Widget _buildTopProducts(AnalyticsProvider provider) {
    if (provider.topProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Top produits', style: PharmaConnectTypography.heading3),
          const SizedBox(height: 8),
          ...provider.topProducts.take(5).map((product) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      product.name,
                      style: PharmaConnectTypography.body2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    product.totalQuantitySold.toString(),
                    style: PharmaConnectTypography.body1.copyWith(
                      fontWeight: FontWeight.w600,
                      color: PharmaConnectColors.accentCyan,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTopPharmacies(AnalyticsProvider provider) {
    if (provider.pharmacyPerformance.isEmpty) {
      return const SizedBox.shrink();
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Top pharmacies', style: PharmaConnectTypography.heading3),
          const SizedBox(height: 8),
          ...provider.pharmacyPerformance.take(5).map((pharmacy) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pharmacy.name,
                    style: PharmaConnectTypography.body2.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    CurrencyFormatter.format(pharmacy.totalRevenue),
                    style: PharmaConnectTypography.micro.copyWith(
                      color: PharmaConnectColors.accentCyan,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
