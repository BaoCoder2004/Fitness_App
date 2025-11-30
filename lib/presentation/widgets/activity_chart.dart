import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ActivityChart extends StatelessWidget {
  const ActivityChart({
    super.key,
    required this.dataPoints,
    required this.getXAxisLabel,
    required this.metricLabel,
    required this.color,
  });

  final List<MapEntry<DateTime, double>> dataPoints;
  final String Function(DateTime) getXAxisLabel;
  final String metricLabel;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (dataPoints.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text('Chưa có dữ liệu'),
        ),
      );
    }

    final spots = dataPoints.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();

    final maxY = dataPoints.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final minY = dataPoints.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    final yInterval = (maxY - minY) / 5;
    final adjustedMaxY = maxY + yInterval;
    final adjustedMinY = (minY - yInterval).clamp(0, double.infinity);

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: yInterval > 0 ? yInterval : null,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Theme.of(context).colorScheme.outline.withAlpha(30),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: dataPoints.length > 7 ? (dataPoints.length / 7).ceil().toDouble() : 1,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= dataPoints.length) return const Text('');
                  final date = dataPoints[value.toInt()].key;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      getXAxisLabel(date),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                interval: yInterval > 0 ? yInterval : null,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toDouble().toStringAsFixed(value < 10 ? 1 : 0),
                    style: Theme.of(context).textTheme.bodySmall,
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withAlpha(51),
            ),
          ),
          minX: 0,
          maxX: (dataPoints.length - 1).toDouble(),
          minY: adjustedMinY.toDouble(),
          maxY: adjustedMaxY.toDouble(),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: color,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: color.withAlpha(30),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (List<LineBarSpot> touchedSpots) {
                return touchedSpots.map((LineBarSpot touchedSpot) {
                  final index = touchedSpot.x.toInt();
                  if (index >= dataPoints.length) return null;
                  final date = dataPoints[index].key;
                  return LineTooltipItem(
                    '${touchedSpot.y.toStringAsFixed(1)} $metricLabel\n${getXAxisLabel(date)}',
                    TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }
}

