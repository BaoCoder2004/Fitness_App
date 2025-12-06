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
    DateTime? referenceDate, // Ngày tham chiếu (mặc định là hôm nay)
  }) async {
    final now = referenceDate ?? DateTime.now();
    DateTime start;
    DateTime end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (range) {
      case TimeRange.day:
        // Cho "Ngày": Chỉ lấy hôm nay và hôm qua để so sánh
        final yesterday = now.subtract(const Duration(days: 1));
        start = DateTime(yesterday.year, yesterday.month, yesterday.day);
        break;
      case TimeRange.week:
        // referenceDate đã là thứ 2 của tuần được chọn
        // Tính từ thứ 2 đến chủ nhật của tuần đó
        final weekday = now.weekday;
        final daysToSubtract = weekday == 1 ? 0 : weekday - 1;
        final monday = now.subtract(Duration(days: daysToSubtract));
        start = DateTime(monday.year, monday.month, monday.day);
        // Tính cuối tuần (chủ nhật)
        final sunday = monday.add(const Duration(days: 6));
        end = DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59);
        break;
      case TimeRange.month:
        // referenceDate đã là ngày đầu tháng được chọn
        start = DateTime(now.year, now.month, 1);
        final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
        end = DateTime(now.year, now.month, lastDayOfMonth.day, 23, 59, 59);
        break;
      case TimeRange.year:
        // referenceDate đã là ngày đầu năm được chọn
        start = DateTime(now.year, 1, 1);
        end = DateTime(now.year, 12, 31, 23, 59, 59);
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
    
    // Normalize start và end về đầu ngày và cuối ngày
    final startDate = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);
    
    return allRecords.where((record) {
      // Normalize record date về đầu ngày để so sánh
      final recordDate = DateTime(
        record.recordedAt.year,
        record.recordedAt.month,
        record.recordedAt.day,
      );
      
      // Chỉ lấy dữ liệu trong khoảng từ startDate đến endDate (bao gồm cả 2 ngày)
      final isInRange = recordDate.isAtSameMomentAs(startDate) || 
                       recordDate.isAtSameMomentAs(endDate) ||
                       (recordDate.isAfter(startDate) && recordDate.isBefore(endDate));
      
      return isInRange;
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

  /// Lấy danh sách các tuần có dữ liệu
  Future<List<DateTime>> getAvailableWeeks(String userId) async {
    final activities = await getAllActivities(userId);
    final weightRecords =
        await _weightHistoryRepository.watchRecords(userId).first;
    if (activities.isEmpty && weightRecords.isEmpty) return [];

    final weekSet = <String>{};
    final weeks = <DateTime>[];

    // Weeks từ activity sessions
    for (final activity in activities) {
      final weekday = activity.date.weekday;
      final daysToSubtract = weekday == 1 ? 0 : weekday - 1;
      final monday = activity.date.subtract(Duration(days: daysToSubtract));
      final weekKey = '${monday.year}-${monday.month}-${monday.day}';

      if (!weekSet.contains(weekKey)) {
        weekSet.add(weekKey);
        weeks.add(DateTime(monday.year, monday.month, monday.day));
      }
    }

    // Weeks từ weight records (để thống kê cân nặng vẫn có dữ liệu
    // ngay cả khi không có buổi tập)
    for (final record in weightRecords) {
      final date = record.recordedAt;
      final weekday = date.weekday;
      final daysToSubtract = weekday == 1 ? 0 : weekday - 1;
      final monday = date.subtract(Duration(days: daysToSubtract));
      final weekKey = '${monday.year}-${monday.month}-${monday.day}';

      if (!weekSet.contains(weekKey)) {
        weekSet.add(weekKey);
        weeks.add(DateTime(monday.year, monday.month, monday.day));
      }
    }

    // Sắp xếp từ mới nhất đến cũ nhất
    weeks.sort((a, b) => b.compareTo(a));
    return weeks;
  }

  /// Lấy danh sách các tháng có dữ liệu
  Future<List<DateTime>> getAvailableMonths(String userId) async {
    final activities = await getAllActivities(userId);
    final weightRecords =
        await _weightHistoryRepository.watchRecords(userId).first;
    if (activities.isEmpty && weightRecords.isEmpty) return [];

    final monthSet = <String>{};
    final months = <DateTime>[];

    // Months từ activity sessions
    for (final activity in activities) {
      final monthKey = '${activity.date.year}-${activity.date.month}';

      if (!monthSet.contains(monthKey)) {
        monthSet.add(monthKey);
        months.add(DateTime(activity.date.year, activity.date.month, 1));
      }
    }

    // Months từ weight records
    for (final record in weightRecords) {
      final date = record.recordedAt;
      final monthKey = '${date.year}-${date.month}';

      if (!monthSet.contains(monthKey)) {
        monthSet.add(monthKey);
        months.add(DateTime(date.year, date.month, 1));
      }
    }

    // Sắp xếp từ mới nhất đến cũ nhất
    months.sort((a, b) => b.compareTo(a));
    return months;
  }

  /// Lấy danh sách các năm có dữ liệu
  Future<List<DateTime>> getAvailableYears(String userId) async {
    final activities = await getAllActivities(userId);
    final weightRecords =
        await _weightHistoryRepository.watchRecords(userId).first;
    if (activities.isEmpty && weightRecords.isEmpty) return [];

    final yearSet = <int>{};
    final years = <DateTime>[];

    // Years từ activity sessions
    for (final activity in activities) {
      if (!yearSet.contains(activity.date.year)) {
        yearSet.add(activity.date.year);
        years.add(DateTime(activity.date.year, 1, 1));
      }
    }

    // Years từ weight records
    for (final record in weightRecords) {
      final year = record.recordedAt.year;
      if (!yearSet.contains(year)) {
        yearSet.add(year);
        years.add(DateTime(year, 1, 1));
      }
    }

    // Sắp xếp từ mới nhất đến cũ nhất
    years.sort((a, b) => b.compareTo(a));
    return years;
  }
}

