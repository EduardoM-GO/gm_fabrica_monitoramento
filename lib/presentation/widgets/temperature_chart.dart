import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/freezer_view_data.dart';

class TemperatureChart extends StatelessWidget {
  final List<TemperaturePoint> history;
  final bool isCoolingChamber;

  const TemperatureChart({
    super.key,
    required this.history,
    this.isCoolingChamber = false,
  });

  @override
  Widget build(BuildContext context) {
    if (history.length < 2) {
      return Container(
        height: 72,
        alignment: Alignment.center,
        child: const Text(
          'Coletando leituras para o gráfico...',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    final lineSpots = <FlSpot>[];
    double minY = history.first.temperature;
    double maxY = history.first.temperature;

    for (int i = 0; i < history.length; i++) {
      final temp = history[i].temperature;
      lineSpots.add(FlSpot(i.toDouble(), temp));
      if (temp < minY) minY = temp;
      if (temp > maxY) maxY = temp;
    }

    // Give some breathing room on Y axis
    final padding = (maxY - minY).abs() * 0.2 + 0.5;
    final chartMinY = (minY - padding).floorToDouble();
    final chartMaxY = (maxY + padding).ceilToDouble();

    final lineColor = isCoolingChamber ? AppTheme.primaryBlue : const Color(0xFF67E8F9);

    return SizedBox(
      height: 72,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (history.length - 1).toDouble(),
          minY: chartMinY,
          maxY: chartMaxY,
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    '${spot.y.toStringAsFixed(1)} °C',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: lineSpots,
              isCurved: true,
              curveSmoothness: 0.25,
              color: lineColor,
              barWidth: 2.2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    lineColor.withValues(alpha: 0.28),
                    lineColor.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

