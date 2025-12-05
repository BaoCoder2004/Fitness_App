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
    final range = maxY - minY;
    
    // Điều chỉnh min/max với padding hợp lý để biểu đồ bắt đầu từ dưới
    // Padding dưới lớn hơn một chút để biểu đồ không bắt đầu quá cao
    final bottomPadding = range > 0 ? (range * 0.2).clamp(1.0, 5.0) : 2.0;
    final topPadding = range > 0 ? (range * 0.1).clamp(0.5, 3.0) : 1.0;
    final adjustedMaxY = maxY + topPadding;
    final adjustedMinY = (minY - bottomPadding).clamp(0, double.infinity);
    
    // Tính interval động dựa trên range để có khoảng 5-8 labels, tránh quá nhiều labels
    double yInterval;
    if (range <= 0) {
      yInterval = 1.0;
    } else if (range < 10) {
      // Range nhỏ: hiển thị đầy đủ (interval = 1)
      yInterval = 1.0;
    } else if (range < 30) {
      // Range vừa: interval = 5
      yInterval = 5.0;
    } else if (range < 60) {
      // Range lớn: interval = 10
      yInterval = 10.0;
    } else if (range < 100) {
      // Range rất lớn: interval = 20
      yInterval = 20.0;
    } else {
      // Range cực lớn: interval = 50
      yInterval = 50.0;
    }
    
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
                reservedSize: 35, // Tăng reservedSize để tránh bị đè
                interval: dataPoints.length > 7 ? (dataPoints.length / 7).ceil().toDouble() : 1,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= dataPoints.length) return const SizedBox.shrink();
                  final date = dataPoints[value.toInt()].key;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      getXAxisLabel(date),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                interval: yInterval,
                getTitlesWidget: (value, meta) {
                  // Chỉ hiển thị label tại đúng các bội số của interval để tránh trùng
                  if (yInterval <= 0) return const SizedBox.shrink();
                  final ratio = value / yInterval;
                  final isOnTick = (ratio - ratio.round()).abs() < 1e-3;
                  if (!isOnTick) return const SizedBox.shrink();

                  // Định dạng số nguyên (không hiển thị .0)
                  final formattedValue = value.round().toString();
                  
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      formattedValue,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.right,
                    ),
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

