import 'package:flutter/material.dart';
import 'package:pharma_connect/core/widgets/layout/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/kernel/kernel_badge.dart';
import '../../../core/widgets/cards/glass_card.dart';
import '../models/recall_status.dart';
import '../providers/recall_provider.dart';
import '../widgets/recall_card.dart';
import '../widgets/recall_filter_chips.dart';
import '../../../core/theme/palette.dart';

class RecallDashboardScreen extends StatefulWidget {
  const RecallDashboardScreen({super.key});

  @override
  State<RecallDashboardScreen> createState() => _RecallDashboardScreenState();
}

class _RecallDashboardScreenState extends State<RecallDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<RecallProvider>();
      provider.loadRecalls();
      provider.loadStatistics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecallProvider>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              // C233 : en-tête adaptable (actions sous le titre sur téléphone).
              HeaderRow(
                leading: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rappels de lots',
                      style: context.text.heading1,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Gérez les rappels de produits et suivez leur exécution',
                      style: context.text.body2,
                    ),
                  ],
                ),
                trailing: [
                  const KernelBadge(),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/recall/create'),
                    icon: const Icon(Icons.add),
                    label: const Text('Nouveau rappel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.palette.primary,
                      foregroundColor: context.palette.onPrimary,
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
                      label: 'Total',
                      value:
                          provider.statistics['totalRecalls']?.toString() ??
                          '0',
                      color: context.palette.primary,
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      label: 'Actifs',
                      value:
                          provider.statistics['activeRecalls']?.toString() ??
                          '0',
                      color: context.palette.warning,
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      label: 'Classe I',
                      value:
                          provider.statistics['bySeverity']?['classI']
                              ?.toString() ??
                          '0',
                      color: context.palette.danger,
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      label: 'Taux de rappel',
                      value:
                          '${((provider.statistics['averageCompletionRate'] ?? 0) * 100).toStringAsFixed(0)}%',
                      color: context.palette.success,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Graphiques
                _buildCharts(provider),
                const SizedBox(height: 16),
              ],

              // Filtres
              const RecallFilterChips(),
              const SizedBox(height: 16),

              // Liste
              provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.recalls.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.warning_amber_outlined,
                            size: 64,
                            color: context.palette.veil(0.24),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Aucun rappel en cours',
                            style: context.text.heading2,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Créez un nouveau rappel pour gérer un lot défectueux',
                            style: context.text.body2,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: provider.recalls.length,
                      itemBuilder: (context, index) {
                        final recall = provider.recalls[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: RecallCard(
                            recall: recall,
                            onTap: () {
                              context.push('/recall/${recall.id}');
                            },
                          ),
                        );
                      },
                    ),
            ],
          ),
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
              style: context.text.kpiMedium.copyWith(
                color: color,
                fontSize: 20,
              ),
            ),
            Text(
              label,
              style: context.text.micro,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharts(RecallProvider provider) {
    final activeRecalls = provider.recalls.where((r) => r.isActive).length;
    final completedRecalls = provider.recalls
        .where((r) => r.isCompleted)
        .length;
    final draftRecalls = provider.recalls
        .where((r) => r.status == RecallStatus.draft)
        .length;

    return Row(
      children: [
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Statut des rappels', style: context.text.heading3),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          value: activeRecalls.toDouble(),
                          color: context.palette.warning,
                          title: 'Actifs',
                          radius: 30,
                          titleStyle: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: context.palette.onPrimary,
                          ),
                        ),
                        PieChartSectionData(
                          value: completedRecalls.toDouble(),
                          color: context.palette.success,
                          title: 'Terminés',
                          radius: 30,
                          titleStyle: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: context.palette.onPrimary,
                          ),
                        ),
                        PieChartSectionData(
                          value: draftRecalls.toDouble(),
                          color: context.palette.secondary,
                          title: 'Brouillons',
                          radius: 30,
                          titleStyle: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: context.palette.onPrimary,
                          ),
                        ),
                      ],
                      sectionsSpace: 2,
                      centerSpaceRadius: 30,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Taux de récupération', style: context.text.heading3),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: BarChart(
                    BarChartData(
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              return const Text('Taux');
                            },
                          ),
                        ),
                      ),
                      gridData: FlGridData(show: false),
                      barGroups: [
                        BarChartGroupData(
                          x: 1,
                          barRods: [
                            BarChartRodData(
                              toY:
                                  (((provider.statistics['averageCompletionRate']
                                                  as num?) ??
                                              0) *
                                          100)
                                      .toDouble(),
                              color: context.palette.primary,
                              width: 20,
                              borderRadius: BorderRadius.circular(4),
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
        ),
      ],
    );
  }
}
