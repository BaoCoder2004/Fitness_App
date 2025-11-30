import '../../../domain/entities/activity_session.dart';
import '../../../domain/entities/weight_record.dart';
import 'history_service.dart';

enum ChartMetric {
  calories,
  distance,
  duration,
  weight,
}

class ChartService {
  /// Aggregate dữ liệu activities theo ngày/tuần/tháng/năm
  Map<DateTime, double> aggregateActivities({
    required List<ActivitySession> activities,
    required ChartMetric metric,
    required TimeRange range,
  }) {
    final Map<DateTime, double> result = {};

    for (final activity in activities) {
      DateTime key;
      switch (range) {
        case TimeRange.day:
          key = DateTime(
            activity.date.year,
            activity.date.month,
            activity.date.day,
          );
          break;
        case TimeRange.week:
          final weekday = activity.date.weekday;
          final weekStart = activity.date.subtract(Duration(days: weekday - 1));
          key = DateTime(weekStart.year, weekStart.month, weekStart.day);
          break;
        case TimeRange.month:
          key = DateTime(activity.date.year, activity.date.month, 1);
          break;
        case TimeRange.year:
          key = DateTime(activity.date.year, 1, 1);
          break;
        case TimeRange.custom:
          key = DateTime(
            activity.date.year,
            activity.date.month,
            activity.date.day,
          );
          break;
      }

      double value = 0;
      switch (metric) {
        case ChartMetric.calories:
          value = activity.calories;
          break;
        case ChartMetric.distance:
          value = activity.distanceKm ?? 0;
          break;
        case ChartMetric.duration:
          value = activity.durationSeconds / 60.0; // phút
          break;
        case ChartMetric.weight:
          value = 0; // Không áp dụng cho activities
          break;
      }

      result[key] = (result[key] ?? 0) + value;
    }

    return result;
  }

  /// Aggregate weight records theo ngày/tuần/tháng/năm
  Map<DateTime, double> aggregateWeights({
    required List<WeightRecord> records,
    required TimeRange range,
  }) {
    final Map<DateTime, double> result = {};

    for (final record in records) {
      DateTime key;
      switch (range) {
        case TimeRange.day:
          key = DateTime(
            record.recordedAt.year,
            record.recordedAt.month,
            record.recordedAt.day,
          );
          break;
        case TimeRange.week:
          final weekday = record.recordedAt.weekday;
          final weekStart = record.recordedAt.subtract(Duration(days: weekday - 1));
          key = DateTime(weekStart.year, weekStart.month, weekStart.day);
          break;
        case TimeRange.month:
          key = DateTime(record.recordedAt.year, record.recordedAt.month, 1);
          break;
        case TimeRange.year:
          key = DateTime(record.recordedAt.year, 1, 1);
          break;
        case TimeRange.custom:
          key = DateTime(
            record.recordedAt.year,
            record.recordedAt.month,
            record.recordedAt.day,
          );
          break;
      }

      // Lấy giá trị mới nhất trong khoảng thời gian đó
      if (!result.containsKey(key) || 
          record.recordedAt.isAfter(
            result.keys.firstWhere((k) => k == key, orElse: () => DateTime(1970)),
          )) {
        result[key] = record.weightKg;
      }
    }

    return result;
  }

  /// Tạo danh sách điểm dữ liệu cho biểu đồ (sắp xếp theo thời gian)
  List<MapEntry<DateTime, double>> getSortedDataPoints(
    Map<DateTime, double> aggregated,
  ) {
    final entries = aggregated.entries.toList();
    entries.sort((a, b) => a.key.compareTo(b.key));
    return entries;
  }

  /// Lấy label cho trục X dựa trên range
  String getXAxisLabel(DateTime date, TimeRange range) {
    switch (range) {
      case TimeRange.day:
        return '${date.day}/${date.month}';
      case TimeRange.week:
        return '${date.day}/${date.month}';
      case TimeRange.month:
        return 'Tuần ${((date.day - 1) / 7).floor() + 1}';
      case TimeRange.year:
        return 'T${date.month}';
      case TimeRange.custom:
        return '${date.day}/${date.month}';
    }
  }

  /// Lấy label cho metric
  String getMetricLabel(ChartMetric metric) {
    switch (metric) {
      case ChartMetric.calories:
        return 'Kcal';
      case ChartMetric.distance:
        return 'Km';
      case ChartMetric.duration:
        return 'Phút';
      case ChartMetric.weight:
        return 'Kg';
    }
  }
}

