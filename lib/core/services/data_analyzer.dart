import '../../domain/entities/goal.dart';
import '../../domain/repositories/activity_repository.dart';
import '../../domain/repositories/goal_repository.dart';
import '../../domain/repositories/gps_route_repository.dart';
import '../../domain/repositories/weight_history_repository.dart';

/// Kết quả phân tích xu hướng cân nặng
class WeightTrendAnalysis {
  const WeightTrendAnalysis({
    required this.trend,
    required this.currentWeight,
    this.previousWeight,
    this.weightChange,
    this.weightChangePerWeek,
    this.targetWeight,
    this.isOnTrack,
    this.daysAnalyzed,
  });

  final String trend; // 'increasing' | 'decreasing' | 'stable'
  final double currentWeight;
  final double? previousWeight;
  final double? weightChange; // kg
  final double? weightChangePerWeek; // kg/tuần
  final double? targetWeight;
  final bool? isOnTrack; // Có đang đúng hướng với mục tiêu không
  final int? daysAnalyzed;
}

/// Kết quả phân tích mức độ hoạt động
class ActivityLevelAnalysis {
  const ActivityLevelAnalysis({
    required this.totalSessions,
    required this.totalCalories,
    required this.totalDistanceKm,
    required this.totalDurationSeconds,
    required this.sessionsPerWeek,
    this.previousWeekSessions,
    this.previousWeekCalories,
    this.activityChange,
    this.daysAnalyzed,
  });

  final int totalSessions;
  final double totalCalories;
  final double totalDistanceKm;
  final int totalDurationSeconds;
  final double sessionsPerWeek;
  final int? previousWeekSessions;
  final double? previousWeekCalories;
  final double? activityChange; // % thay đổi so với tuần trước
  final int? daysAnalyzed;
}

/// Kết quả phân tích thói quen tập luyện
class WorkoutHabitsAnalysis {
  const WorkoutHabitsAnalysis({
    required this.favoriteActivityType,
    required this.mostActiveDayOfWeek,
    required this.mostActiveTimeOfDay,
    required this.activityTypeDistribution,
    required this.dayOfWeekDistribution,
    required this.timeOfDayDistribution,
    this.daysAnalyzed,
  });

  final String favoriteActivityType;
  final int mostActiveDayOfWeek; // 0 = Monday, 6 = Sunday
  final String mostActiveTimeOfDay; // 'morning' | 'afternoon' | 'evening'
  final Map<String, int> activityTypeDistribution; // {activityType: count}
  final Map<int, int> dayOfWeekDistribution; // {dayOfWeek: count}
  final Map<String, int> timeOfDayDistribution; // {timeOfDay: count}
  final int? daysAnalyzed;
}

/// Kết quả phân tích dữ liệu GPS
class GPSDataAnalysis {
  const GPSDataAnalysis({
    required this.totalRoutes,
    required this.averageDistanceKm,
    required this.averageSpeedKmh,
    required this.averageDurationSeconds,
    this.speedImprovement,
    this.distanceImprovement,
    this.daysAnalyzed,
  });

  final int totalRoutes;
  final double averageDistanceKm;
  final double averageSpeedKmh;
  final int averageDurationSeconds;
  final double? speedImprovement; // % cải thiện tốc độ
  final double? distanceImprovement; // % cải thiện quãng đường
  final int? daysAnalyzed;
}

/// Service phân tích dữ liệu người dùng
class DataAnalyzer {
  DataAnalyzer({
    required WeightHistoryRepository weightHistoryRepository,
    required ActivityRepository activityRepository,
    required GpsRouteRepository gpsRouteRepository,
    required GoalRepository goalRepository,
  })  : _weightHistoryRepository = weightHistoryRepository,
        _activityRepository = activityRepository,
        _gpsRouteRepository = gpsRouteRepository,
        _goalRepository = goalRepository;

  final WeightHistoryRepository _weightHistoryRepository;
  final ActivityRepository _activityRepository;
  final GpsRouteRepository _gpsRouteRepository;
  final GoalRepository _goalRepository;

  /// Phân tích xu hướng cân nặng
  Future<WeightTrendAnalysis> analyzeWeightTrend(
    String userId,
    int days,
  ) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));

    // Lấy tất cả weight records
    final recordsStream = _weightHistoryRepository.watchRecords(userId);
    final allRecords = await recordsStream.first;
    final recordsInRange = allRecords
        .where((record) =>
            record.recordedAt.isAfter(startDate) &&
            record.recordedAt.isBefore(endDate.add(const Duration(days: 1))))
        .toList()
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

    if (recordsInRange.isEmpty) {
      // Nếu không có dữ liệu, lấy record gần nhất
      if (allRecords.isNotEmpty) {
        final latestRecord = allRecords.first;
        return WeightTrendAnalysis(
          trend: 'stable',
          currentWeight: latestRecord.weightKg,
          daysAnalyzed: 0,
        );
      }
      throw Exception('Không có dữ liệu cân nặng');
    }

    final currentWeight = recordsInRange.last.weightKg;
    final firstWeight = recordsInRange.first.weightKg;
    final weightChange = currentWeight - firstWeight;
    final daysBetween = recordsInRange.last.recordedAt
        .difference(recordsInRange.first.recordedAt)
        .inDays;
    final weightChangePerWeek = daysBetween > 0
        ? (weightChange / daysBetween) * 7
        : 0.0;

    String trend;
    if (weightChange.abs() < 0.5) {
      trend = 'stable';
    } else if (weightChange > 0) {
      trend = 'increasing';
    } else {
      trend = 'decreasing';
    }

    // Lấy mục tiêu cân nặng (nếu có)
    double? targetWeight;
    bool? isOnTrack;
    try {
      final goals = await _goalRepository.fetchGoals(
        userId: userId,
        status: GoalStatus.active,
      );
      final weightGoals = goals.where(
        (goal) => goal.goalType == GoalType.weight,
      ).toList();
      final weightGoal = weightGoals.isNotEmpty ? weightGoals.first : null;
      if (weightGoal != null) {
        targetWeight = weightGoal.targetValue;
        if (weightGoal.direction == 'decrease') {
          isOnTrack = trend == 'decreasing' ||
              (trend == 'stable' && currentWeight <= targetWeight);
        } else if (weightGoal.direction == 'increase') {
          isOnTrack = trend == 'increasing' ||
              (trend == 'stable' && currentWeight >= targetWeight);
        }
      }
    } catch (e) {
      // Không có mục tiêu hoặc lỗi khi lấy mục tiêu
    }

    return WeightTrendAnalysis(
      trend: trend,
      currentWeight: currentWeight,
      previousWeight: recordsInRange.length > 1 ? firstWeight : null,
      weightChange: weightChange,
      weightChangePerWeek: weightChangePerWeek,
      targetWeight: targetWeight,
      isOnTrack: isOnTrack,
      daysAnalyzed: daysBetween + 1,
    );
  }

  /// Phân tích mức độ hoạt động
  Future<ActivityLevelAnalysis> analyzeActivityLevel(
    String userId,
    int days,
  ) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));

    final activities = await _activityRepository.getActivitiesInRange(
      userId: userId,
      start: startDate,
      end: endDate,
    );

    if (activities.isEmpty) {
      return const ActivityLevelAnalysis(
        totalSessions: 0,
        totalCalories: 0,
        totalDistanceKm: 0,
        totalDurationSeconds: 0,
        sessionsPerWeek: 0,
        daysAnalyzed: 0,
      );
    }

    final totalSessions = activities.length;
    final totalCalories = activities.fold<double>(
      0,
      (sum, activity) => sum + activity.calories,
    );
    final totalDistanceKm = activities.fold<double>(
      0,
      (sum, activity) => sum + (activity.distanceKm ?? 0),
    );
    final totalDurationSeconds = activities.fold<int>(
      0,
      (sum, activity) => sum + activity.durationSeconds,
    );
    final sessionsPerWeek = (totalSessions / days) * 7;

    // So sánh với tuần trước
    final previousWeekStart = startDate.subtract(Duration(days: 7));
    final previousWeekActivities = await _activityRepository.getActivitiesInRange(
      userId: userId,
      start: previousWeekStart,
      end: startDate,
    );

    int? previousWeekSessions;
    double? previousWeekCalories;
    double? activityChange;

    if (previousWeekActivities.isNotEmpty) {
      previousWeekSessions = previousWeekActivities.length;
      previousWeekCalories = previousWeekActivities.fold<double>(
        0,
        (sum, activity) => sum + activity.calories,
      );
      if (previousWeekCalories > 0) {
        activityChange =
            ((totalCalories - previousWeekCalories) / previousWeekCalories) * 100;
      }
    }

    return ActivityLevelAnalysis(
      totalSessions: totalSessions,
      totalCalories: totalCalories,
      totalDistanceKm: totalDistanceKm,
      totalDurationSeconds: totalDurationSeconds,
      sessionsPerWeek: sessionsPerWeek,
      previousWeekSessions: previousWeekSessions,
      previousWeekCalories: previousWeekCalories,
      activityChange: activityChange,
      daysAnalyzed: days,
    );
  }

  /// Phân tích thói quen tập luyện
  Future<WorkoutHabitsAnalysis> analyzeWorkoutHabits(
    String userId,
    int days,
  ) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));

    final activities = await _activityRepository.getActivitiesInRange(
      userId: userId,
      start: startDate,
      end: endDate,
    );

    if (activities.isEmpty) {
      return const WorkoutHabitsAnalysis(
        favoriteActivityType: '',
        mostActiveDayOfWeek: 0,
        mostActiveTimeOfDay: 'morning',
        activityTypeDistribution: {},
        dayOfWeekDistribution: {},
        timeOfDayDistribution: {},
        daysAnalyzed: 0,
      );
    }

    // Phân tích loại hoạt động
    final activityTypeCount = <String, int>{};
    for (final activity in activities) {
      activityTypeCount[activity.activityType] =
          (activityTypeCount[activity.activityType] ?? 0) + 1;
    }
    final favoriteActivityType = activityTypeCount.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    // Phân tích ngày trong tuần (0 = Monday, 6 = Sunday)
    final dayOfWeekCount = <int, int>{};
    for (final activity in activities) {
      final dayOfWeek = (activity.date.weekday - 1) % 7; // Convert to 0-6
      dayOfWeekCount[dayOfWeek] = (dayOfWeekCount[dayOfWeek] ?? 0) + 1;
    }
    final mostActiveDayOfWeek = dayOfWeekCount.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    // Phân tích thời gian trong ngày
    final timeOfDayCount = <String, int>{};
    for (final activity in activities) {
      final hour = activity.date.hour;
      String timeOfDay;
      if (hour >= 5 && hour < 12) {
        timeOfDay = 'morning';
      } else if (hour >= 12 && hour < 17) {
        timeOfDay = 'afternoon';
      } else {
        timeOfDay = 'evening';
      }
      timeOfDayCount[timeOfDay] = (timeOfDayCount[timeOfDay] ?? 0) + 1;
    }
    final mostActiveTimeOfDay = timeOfDayCount.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    return WorkoutHabitsAnalysis(
      favoriteActivityType: favoriteActivityType,
      mostActiveDayOfWeek: mostActiveDayOfWeek,
      mostActiveTimeOfDay: mostActiveTimeOfDay,
      activityTypeDistribution: activityTypeCount,
      dayOfWeekDistribution: dayOfWeekCount,
      timeOfDayDistribution: timeOfDayCount,
      daysAnalyzed: days,
    );
  }

  /// Phân tích dữ liệu GPS
  Future<GPSDataAnalysis> analyzeGPSData(
    String userId,
    int days,
  ) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));

    // Lấy tất cả routes
    final routesStream = _gpsRouteRepository.watchRoutes(userId: userId);
    final allRoutes = await routesStream.first;
    final routesInRange = allRoutes
        .where((route) =>
            route.createdAt.isAfter(startDate) &&
            route.createdAt.isBefore(endDate.add(const Duration(days: 1))))
        .toList();

    if (routesInRange.isEmpty) {
      return const GPSDataAnalysis(
        totalRoutes: 0,
        averageDistanceKm: 0,
        averageSpeedKmh: 0,
        averageDurationSeconds: 0,
        daysAnalyzed: 0,
      );
    }

    final totalRoutes = routesInRange.length;
    final totalDistance = routesInRange.fold<double>(
      0,
      (sum, route) => sum + route.totalDistanceKm,
    );
    final totalDuration = routesInRange.fold<int>(
      0,
      (sum, route) => sum + route.totalDurationSeconds,
    );

    final averageDistanceKm = totalDistance / totalRoutes;
    final averageDurationSeconds = totalDuration ~/ totalRoutes;
    final averageSpeedKmh = averageDurationSeconds > 0
        ? (averageDistanceKm / averageDurationSeconds) * 3600
        : 0.0;

    // Tính cải thiện tốc độ và quãng đường (so sánh nửa đầu vs nửa sau)
    double? speedImprovement;
    double? distanceImprovement;

    if (routesInRange.length >= 4) {
      final halfPoint = routesInRange.length ~/ 2;
      final firstHalf = routesInRange.sublist(0, halfPoint);
      final secondHalf = routesInRange.sublist(halfPoint);

      // Tính tốc độ trung bình nửa đầu
      double firstHalfAvgSpeed = 0;
      int firstHalfCount = 0;
      for (final route in firstHalf) {
        if (route.totalDurationSeconds > 0) {
          final speed = (route.totalDistanceKm / route.totalDurationSeconds) * 3600;
          firstHalfAvgSpeed += speed;
          firstHalfCount++;
        }
      }
      if (firstHalfCount > 0) {
        firstHalfAvgSpeed /= firstHalfCount;
      }

      // Tính tốc độ trung bình nửa sau
      double secondHalfAvgSpeed = 0;
      int secondHalfCount = 0;
      for (final route in secondHalf) {
        if (route.totalDurationSeconds > 0) {
          final speed = (route.totalDistanceKm / route.totalDurationSeconds) * 3600;
          secondHalfAvgSpeed += speed;
          secondHalfCount++;
        }
      }
      if (secondHalfCount > 0) {
        secondHalfAvgSpeed /= secondHalfCount;
      }

      if (firstHalfAvgSpeed > 0) {
        speedImprovement =
            ((secondHalfAvgSpeed - firstHalfAvgSpeed) / firstHalfAvgSpeed) * 100;
      }

      // Tính quãng đường trung bình
      final firstHalfAvgDistance = firstHalf.fold<double>(
            0,
            (sum, route) => sum + route.totalDistanceKm,
          ) /
          firstHalf.length;
      final secondHalfAvgDistance = secondHalf.fold<double>(
            0,
            (sum, route) => sum + route.totalDistanceKm,
          ) /
          secondHalf.length;

      if (firstHalfAvgDistance > 0) {
        distanceImprovement =
            ((secondHalfAvgDistance - firstHalfAvgDistance) / firstHalfAvgDistance) * 100;
      }
    }

    return GPSDataAnalysis(
      totalRoutes: totalRoutes,
      averageDistanceKm: averageDistanceKm,
      averageSpeedKmh: averageSpeedKmh,
      averageDurationSeconds: averageDurationSeconds,
      speedImprovement: speedImprovement,
      distanceImprovement: distanceImprovement,
      daysAnalyzed: days,
    );
  }
}

