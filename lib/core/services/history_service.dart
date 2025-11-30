import '../../../domain/entities/activity_session.dart';
import '../../../domain/entities/weight_record.dart';
import '../../../domain/repositories/activity_repository.dart';
import '../../../domain/repositories/weight_history_repository.dart';

enum TimeRange {
  day,
  week,
  month,
  year,
  custom,
}

class HistoryService {
  HistoryService({
    required ActivityRepository activityRepository,
    required WeightHistoryRepository weightHistoryRepository,
  })  : _activityRepository = activityRepository,
        _weightHistoryRepository = weightHistoryRepository;

  final ActivityRepository _activityRepository;
  final WeightHistoryRepository _weightHistoryRepository;

  /// Lấy danh sách activities theo time range
  Future<List<ActivitySession>> getActivitiesInRange({
    required String userId,
    required TimeRange range,
    DateTime? customStart,
    DateTime? customEnd,
  }) async {
    final now = DateTime.now();
    DateTime start;
    DateTime end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (range) {
      case TimeRange.day:
        start = DateTime(now.year, now.month, now.day);
        break;
      case TimeRange.week:
        final weekday = now.weekday;
        start = now.subtract(Duration(days: weekday - 1));
        start = DateTime(start.year, start.month, start.day);
        break;
      case TimeRange.month:
        start = DateTime(now.year, now.month, 1);
        break;
      case TimeRange.year:
        start = DateTime(now.year, 1, 1);
        break;
      case TimeRange.custom:
        if (customStart == null || customEnd == null) {
          throw ArgumentError('customStart and customEnd are required for custom range');
        }
        start = DateTime(customStart.year, customStart.month, customStart.day);
        end = DateTime(customEnd.year, customEnd.month, customEnd.day, 23, 59, 59);
        break;
    }

    return _activityRepository.getActivitiesInRange(
      userId: userId,
      start: start,
      end: end,
    );
  }

  /// Lấy tất cả activities của user (không filter)
  Future<List<ActivitySession>> getAllActivities(String userId) async {
    // Lấy 1 năm gần nhất
    final now = DateTime.now();
    final start = DateTime(now.year - 1, 1, 1);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return _activityRepository.getActivitiesInRange(
      userId: userId,
      start: start,
      end: end,
    );
  }

  /// Filter activities theo loại hoạt động
  List<ActivitySession> filterByActivityType({
    required List<ActivitySession> activities,
    String? activityType,
  }) {
    if (activityType == null || activityType.isEmpty) {
      return activities;
    }
    return activities.where((a) => a.activityType == activityType).toList();
  }

  /// Search activities theo ghi chú
  List<ActivitySession> searchInNotes({
    required List<ActivitySession> activities,
    required String query,
  }) {
    if (query.isEmpty) return activities;
    final lowerQuery = query.toLowerCase();
    return activities
        .where((a) =>
            a.notes?.toLowerCase().contains(lowerQuery) ?? false)
        .toList();
  }

  /// Sắp xếp activities
  List<ActivitySession> sortActivities({
    required List<ActivitySession> activities,
    bool ascending = false,
  }) {
    final sorted = List<ActivitySession>.from(activities);
    sorted.sort((a, b) {
      if (ascending) {
        return a.date.compareTo(b.date);
      } else {
        return b.date.compareTo(a.date);
      }
    });
    return sorted;
  }

  /// Lấy weight history trong khoảng thời gian
  Future<List<WeightRecord>> getWeightHistoryInRange({
    required String userId,
    required DateTime start,
    required DateTime end,
  }) async {
    final allRecords = await _weightHistoryRepository
        .watchRecords(userId)
        .first;
    return allRecords.where((record) {
      return record.recordedAt.isAfter(start.subtract(const Duration(days: 1))) &&
          record.recordedAt.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  /// Aggregate dữ liệu cho biểu đồ
  Map<DateTime, double> aggregateActivitiesByDate({
    required List<ActivitySession> activities,
    required String metric, // 'calories', 'distance', 'duration'
  }) {
    final Map<DateTime, double> result = {};
    
    for (final activity in activities) {
      final date = DateTime(
        activity.date.year,
        activity.date.month,
        activity.date.day,
      );
      
      double value = 0;
      switch (metric) {
        case 'calories':
          value = activity.calories;
          break;
        case 'distance':
          value = activity.distanceKm ?? 0;
          break;
        case 'duration':
          value = activity.durationSeconds / 60.0; // phút
          break;
      }
      
      result[date] = (result[date] ?? 0) + value;
    }
    
    return result;
  }

  /// Aggregate weight history theo ngày
  Map<DateTime, double> aggregateWeightByDate({
    required List<WeightRecord> records,
  }) {
    final Map<DateTime, double> result = {};
    
    for (final record in records) {
      final date = DateTime(
        record.recordedAt.year,
        record.recordedAt.month,
        record.recordedAt.day,
      );
      result[date] = record.weightKg;
    }
    
    return result;
  }
}

