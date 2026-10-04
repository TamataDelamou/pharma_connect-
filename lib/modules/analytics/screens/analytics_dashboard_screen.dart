import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import 'package:pharma_connect/core/utils/currency_formatter.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/analytics_provider.dart';
import 'package:pharma_connect/core/theme/palette.dart';

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
              leading: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Analytics',
                    style: context.text.heading1,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Indicateurs clés et performances du réseau',
                    style: context.text.body2,
                  ),
                ],
              ),
              trailing: [
                const KernelBadge(),
                DropdownButton<String>(
                  value: provider.selectedDashboard?.id,
                  hint: const Text('Tableau de bord'),
                  dropdownColor: context.palette.background,
                  style: TextStyle(color: context.palette.textPrimary),
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
                  icon: Icon(
                    Icons.refresh,
                    color: context.palette.textSecondary,
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
                  icon: Icon(
                    Icons.dashboard_customize,
                    color: context.palette.textSecondary,
                  ),
                  onPressed: () => context.push('/analytics/dashboard-editor'),
                ),
                // C232 : écran absent — « Prévisions IA »
                // (/analytics/forecast, route désactivée par C188) masqué.
                IconButton(
                  tooltip: 'Exporter des rapports',
                  icon: Icon(
                    Icons.ios_share,
                    color: context.palette.textSecondary,
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
                Text('Consultations', style: context.text.label),
                const SizedBox(height: 4),
                Text(
                  summary.totalConsultations.toString(),
                  style: context.text.kpiMedium,
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
                Text('Prescriptions', style: context.text.label),
                const SizedBox(height: 4),
                Text(
                  summary.totalPrescriptions.toString(),
                  style: context.text.kpiMedium,
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
                Text('Réservations', style: context.text.label),
                const SizedBox(height: 4),
                Text(
                  summary.totalReservations.toString(),
                  style: context.text.kpiMedium,
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
                Text('Chiffre d\'affaires', style: context.text.label),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.format(summary.totalRevenue),
                  style: context.text.kpiMedium.copyWith(
                    color: context.palette.primary,
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
          Text(
            'Activité quotidienne (30 derniers jours)',
            style: context.text.heading3,
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
                    color: context.palette.primary,
                    barWidth: 2,
                    belowBarData: BarAreaData(
                      show: true,
                      color: context.palette.primary.withValues(alpha: 0.2),
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
        style: TextStyle(fontSize: 10, color: context.palette.textSecondary),
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
          Text('Top produits', style: context.text.heading3),
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
                      style: context.text.body2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    product.totalQuantitySold.toString(),
                    style: context.text.body1.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.palette.primary,
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
          Text('Top pharmacies', style: context.text.heading3),
          const SizedBox(height: 8),
          ...provider.pharmacyPerformance.take(5).map((pharmacy) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pharmacy.name,
                    style: context.text.body2.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    CurrencyFormatter.format(pharmacy.totalRevenue),
                    style: context.text.micro.copyWith(
                      color: context.palette.primary,
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
