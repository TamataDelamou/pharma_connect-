import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import '../models/demand_forecast.dart';

class ForecastChart extends StatelessWidget {
  final List<DemandForecast> forecasts;

  const ForecastChart({super.key, required this.forecasts});

  @override
  Widget build(BuildContext context) {
    if (forecasts.isEmpty) {
      return const Center(child: Text('Aucune donnée de prévision'));
    }

    final spots = <FlSpot>[];
    final lowerSpots = <FlSpot>[];
    final upperSpots = <FlSpot>[];

    for (int i = 0; i < forecasts.length; i++) {
      final f = forecasts[i];
      spots.add(FlSpot(i.toDouble(), f.predictedDemand.toDouble()));
      if (f.lowerBound != null) {
        lowerSpots.add(FlSpot(i.toDouble(), f.lowerBound!.toDouble()));
        upperSpots.add(FlSpot(i.toDouble(), f.upperBound!.toDouble()));
      }
    }

    return SizedBox(
      height: 200,
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
                reservedSize: 20,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= forecasts.length) return const SizedBox.shrink();
                  final date = forecasts[index].forecastDate;
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${date.day}/${date.month}',
                      style: const TextStyle(
                        fontSize: 9,
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
          maxY: spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.3,
          lineBarsData: [
            // Confidence band
            if (lowerSpots.isNotEmpty && upperSpots.isNotEmpty)
              LineChartBarData(
                spots: [...lowerSpots, ...upperSpots.reversed],
                isCurved: true,
                color: Colors.white12,
                barWidth: 0,
                belowBarData: BarAreaData(
                  show: true,
                  color: PharmaConnectColors.accentCyan.withValues(alpha: 0.08),
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
                color: PharmaConnectColors.accentCyan.withValues(alpha: 0.1),
              ),
              dotData: const FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }
}
