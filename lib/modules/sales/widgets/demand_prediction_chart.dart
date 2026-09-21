import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pharma_connect/core/theme/colors.dart';
import '../models/demand_prediction.dart';

class DemandPredictionChart extends StatelessWidget {
  final List<DemandPrediction> predictions;

  const DemandPredictionChart({super.key, required this.predictions});

  @override
  Widget build(BuildContext context) {
    if (predictions.isEmpty) {
      return const Center(child: Text('Aucune prévision'));
    }

    final spots = <FlSpot>[];
    final lowerSpots = <FlSpot>[];
    final upperSpots = <FlSpot>[];

    for (int i = 0; i < predictions.length; i++) {
      final p = predictions[i];
      spots.add(FlSpot(i.toDouble(), p.predictedQuantity.toDouble()));
      if (p.lowerBound != null) {
        lowerSpots.add(FlSpot(i.toDouble(), p.lowerBound!.toDouble()));
        upperSpots.add(FlSpot(i.toDouble(), p.upperBound!.toDouble()));
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
                reservedSize: 24,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= predictions.length)
                    return const SizedBox.shrink();
                  final date = predictions[index].predictionDate;
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
          lineBarsData: [
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
