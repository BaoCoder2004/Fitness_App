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
    DateTime? start,
    DateTime? end,
  }) {
    final Map<DateTime, double> result = {};

    for (final activity in activities) {
      // Filter theo range nếu có start và end
      if (start != null && end != null) {
        final activityDate = DateTime(
          activity.date.year,
          activity.date.month,
          activity.date.day,
        );
        final startDate = DateTime(start.year, start.month, start.day);
        final endDate = DateTime(end.year, end.month, end.day);
        
        // Chỉ lấy dữ liệu trong range (bao gồm cả start và end)
        if (activityDate.isBefore(startDate) || activityDate.isAfter(endDate)) {
          continue; // Bỏ qua dữ liệu ngoài range
        }
      }
      
      DateTime key;
      switch (range) {
        case TimeRange.day:
          // Cho "Ngày": Chỉ hiển thị hôm qua và hôm nay
          final activityDate = DateTime(
            activity.date.year,
            activity.date.month,
            activity.date.day,
          );
          final today = DateTime.now();
          final todayDate = DateTime(today.year, today.month, today.day);
          final yesterday = todayDate.subtract(const Duration(days: 1));
          
          // Chỉ lấy dữ liệu của hôm qua và hôm nay
          if (activityDate.isAtSameMomentAs(yesterday) || activityDate.isAtSameMomentAs(todayDate)) {
            key = activityDate;
          } else {
            continue; // Bỏ qua các ngày khác
          }
          break;
        case TimeRange.week:
          // Cho "Tuần": Hiển thị theo từng ngày trong tuần (không nhóm)
          key = DateTime(
            activity.date.year,
            activity.date.month,
            activity.date.day,
          );
          break;
        case TimeRange.month:
          // Cho "Tháng": Nhóm theo tuần
          final weekday = activity.date.weekday;
          final weekStart = activity.date.subtract(Duration(days: weekday - 1));
          key = DateTime(weekStart.year, weekStart.month, weekStart.day);
          break;
        case TimeRange.year:
          // Cho "Năm": Nhóm theo tháng
          key = DateTime(activity.date.year, activity.date.month, 1);
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

      // Cộng dồn giá trị (vì trong 1 ngày có thể có nhiều buổi tập)
      result[key] = (result[key] ?? 0) + value;
    }

    return result;
  }

  /// Aggregate weight records theo ngày/tuần/tháng/năm
  Map<DateTime, double> aggregateWeights({
    required List<WeightRecord> records,
    required TimeRange range,
    DateTime? start,
    DateTime? end,
  }) {
    final Map<DateTime, double> result = {};
    final Map<DateTime, DateTime> keyToLatestRecord = {}; // Lưu thời gian ghi nhận mới nhất cho mỗi key

    // Sắp xếp records theo thời gian giảm dần (mới nhất trước) để đảm bảo lấy giá trị mới nhất
    final sortedRecords = List<WeightRecord>.from(records)
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

    for (final record in sortedRecords) {
      // Filter theo range nếu có start và end
      if (start != null && end != null) {
        final recordDate = DateTime(
          record.recordedAt.year,
          record.recordedAt.month,
          record.recordedAt.day,
        );
        final startDate = DateTime(start.year, start.month, start.day);
        final endDate = DateTime(end.year, end.month, end.day);
        
        // Chỉ lấy dữ liệu trong range (bao gồm cả start và end)
        if (recordDate.isBefore(startDate) || recordDate.isAfter(endDate)) {
          continue; // Bỏ qua dữ liệu ngoài range
        }
      }
      
      DateTime key;
      switch (range) {
        case TimeRange.day:
          // Cho "Ngày": Chỉ hiển thị hôm qua và hôm nay
          final recordDate = DateTime(
            record.recordedAt.year,
            record.recordedAt.month,
            record.recordedAt.day,
          );
          final today = DateTime.now();
          final todayDate = DateTime(today.year, today.month, today.day);
          final yesterday = todayDate.subtract(const Duration(days: 1));
          
          // Chỉ lấy dữ liệu của hôm qua và hôm nay
          if (recordDate.isAtSameMomentAs(yesterday) || recordDate.isAtSameMomentAs(todayDate)) {
            key = recordDate;
          } else {
            continue; // Bỏ qua các ngày khác
          }
          break;
        case TimeRange.week:
          // Cho "Tuần": Hiển thị theo từng ngày trong tuần (không nhóm)
          key = DateTime(
            record.recordedAt.year,
            record.recordedAt.month,
            record.recordedAt.day,
          );
          break;
        case TimeRange.month:
          // Cho "Tháng": Nhóm theo tuần
          final weekday = record.recordedAt.weekday;
          final weekStart = record.recordedAt.subtract(Duration(days: weekday - 1));
          key = DateTime(weekStart.year, weekStart.month, weekStart.day);
          break;
        case TimeRange.year:
          // Cho "Năm": Nhóm theo tháng
          key = DateTime(record.recordedAt.year, record.recordedAt.month, 1);
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
      // Nếu key chưa tồn tại hoặc record này mới hơn record đã lưu, cập nhật
      if (!keyToLatestRecord.containsKey(key) || 
          record.recordedAt.isAfter(keyToLatestRecord[key]!)) {
        result[key] = record.weightKg;
        keyToLatestRecord[key] = record.recordedAt;
      }
    }

    // Không điền các ngày không có dữ liệu - chỉ hiển thị các ngày có dữ liệu

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

