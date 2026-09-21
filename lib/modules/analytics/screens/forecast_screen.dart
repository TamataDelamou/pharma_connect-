import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pharma_connect/core/kernel/kernel_badge.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import 'package:pharma_connect/core/theme/typography.dart';
import 'package:pharma_connect/core/widgets/buttons/primary_button.dart';
import 'package:pharma_connect/core/widgets/cards/glass_card.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/forecast_provider.dart';

class ForecastScreen extends StatefulWidget {
  const ForecastScreen({super.key});

  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen> {
  String _selectedMetric = 'consultations';
  int _forecastDays = 7;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateForecast();
      context.read<ForecastProvider>().loadAlerts();
    });
  }

  void _generateForecast() {
    context.read<ForecastProvider>().generateForecast(
      metricType: _selectedMetric,
      days: _forecastDays,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ForecastProvider>();

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
                        '🔮 Prévisions IA',
                        style: PharmaConnectTypography.heading1,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Anticipez l\'activité à venir',
                        style: PharmaConnectTypography.body2,
                      ),
                    ],
                  ),
                ),
                const KernelBadge(),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: provider.isGenerating ? null : _generateForecast,
                  icon: provider.isGenerating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              PharmaConnectColors.textOnAccent,
                            ),
                          ),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(
                    provider.isGenerating ? 'Génération...' : 'Rafraîchir',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PharmaConnectColors.accentCyan,
                    foregroundColor: PharmaConnectColors.textOnAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Controls
            _buildControls(),
            const SizedBox(height: 16),

            // Chart
            Expanded(
              child: provider.isGenerating || provider.isLoading
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
                              _generateForecast();
                            },
                            width: 200,
                          ),
                        ],
                      ),
                    )
                  : provider.predictions.isEmpty
                  ? const Center(
                      child: Text(
                        'Aucune prévision disponible',
                        style: PharmaConnectTypography.body2,
                      ),
                    )
                  : _buildChart(provider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Metric selector
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              value: _selectedMetric,
              decoration: const InputDecoration(
                labelText: 'Métrique',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'consultations',
                  child: Text('Consultations'),
                ),
                DropdownMenuItem(
                  value: 'prescriptions',
                  child: Text('Prescriptions'),
                ),
                DropdownMenuItem(
                  value: 'reservations',
                  child: Text('Réservations'),
                ),
                DropdownMenuItem(
                  value: 'deliveries',
                  child: Text('Livraisons'),
                ),
                DropdownMenuItem(value: 'revenue', child: Text('CA')),
                DropdownMenuItem(value: 'stock', child: Text('Stock')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedMetric = value);
                  _generateForecast();
                }
              },
            ),
          ),
          const SizedBox(width: 12),

          // Days selector
          Expanded(
            child: DropdownButtonFormField<int>(
              value: _forecastDays,
              decoration: const InputDecoration(
                labelText: 'Jours',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
              ),
              items: const [
                DropdownMenuItem(value: 7, child: Text('7j')),
                DropdownMenuItem(value: 14, child: Text('14j')),
                DropdownMenuItem(value: 30, child: Text('30j')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _forecastDays = value);
                  _generateForecast();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(ForecastProvider provider) {
    final predictions = provider.predictions;
    final spots = <FlSpot>[];
    final lowerSpots = <FlSpot>[];
    final upperSpots = <FlSpot>[];

    for (int i = 0; i < predictions.length; i++) {
      final p = predictions[i];
      spots.add(FlSpot(i.toDouble(), p.predictedValue));
      if (p.lowerBound != null) {
        lowerSpots.add(FlSpot(i.toDouble(), p.lowerBound!));
        upperSpots.add(FlSpot(i.toDouble(), p.upperBound!));
      }
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Prévisions ${_getMetricLabel(_selectedMetric)}',
                style: PharmaConnectTypography.heading3,
              ),
              Row(
                children: [
                  _buildLegend('Prévision', PharmaConnectColors.accentCyan),
                  const SizedBox(width: 12),
                  _buildLegend('Intervalle de confiance', Colors.white24),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= predictions.length)
                          return const SizedBox.shrink();
                        final date = predictions[index].targetDate;
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${date.day}/${date.month}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white54,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: spots.length.toDouble() - 1,
                minY: 0,
                lineBarsData: [
                  // Confidence interval band
                  if (lowerSpots.isNotEmpty && upperSpots.isNotEmpty)
                    LineChartBarData(
                      spots: [...lowerSpots, ...upperSpots.reversed],
                      isCurved: true,
                      color: Colors.white12,
                      barWidth: 0,
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                      dotData: const FlDotData(show: false),
                    ),
                  // Prediction line
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: PharmaConnectColors.accentCyan,
                    barWidth: 2,
                    belowBarData: BarAreaData(
                      show: true,
                      color: PharmaConnectColors.accentCyan.withValues(
                        alpha: 0.1,
                      ),
                    ),
                    dotData: const FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Dernière valeur : ${predictions.isNotEmpty ? predictions.first.predictedValue.toStringAsFixed(1) : 'N/A'}',
                style: PharmaConnectTypography.micro,
              ),
              Text(
                'Confiance : ${(predictions.isNotEmpty ? predictions.first.confidenceLevel * 100 : 0).toStringAsFixed(0)}%',
                style: PharmaConnectTypography.micro,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 2, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.white54),
        ),
      ],
    );
  }

  String _getMetricLabel(String metric) {
    switch (metric) {
      case 'consultations':
        return 'des consultations';
      case 'prescriptions':
        return 'des prescriptions';
      case 'reservations':
        return 'des réservations';
      case 'deliveries':
        return 'des livraisons';
      case 'revenue':
        return 'du chiffre d\'affaires';
      case 'stock':
        return 'du stock';
      default:
        return metric;
    }
  }
}
