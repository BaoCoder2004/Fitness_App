import '../../domain/entities/activity_session.dart';
import '../../domain/repositories/activity_repository.dart';
import 'history_service.dart';

class PeriodStats {
  const PeriodStats({
    required this.totalCalories,
    required this.totalDistanceKm,
    required this.totalDurationSeconds,
    required this.sessionCount,
    required this.dayCount,
  });

  final double totalCalories;
  final double totalDistanceKm;
  final int totalDurationSeconds;
  final int sessionCount;
  final int dayCount;

  double get averageCaloriesPerDay =>
      dayCount == 0 ? 0 : totalCalories / dayCount;

  double get averageDistancePerDay =>
      dayCount == 0 ? 0 : totalDistanceKm / dayCount;

  double get averageDurationMinutesPerDay =>
      dayCount == 0 ? 0 : (totalDurationSeconds / 60.0) / dayCount;

  double get totalDurationHours => totalDurationSeconds / 3600.0;
}

class StatsComparison {
  const StatsComparison({
    required this.caloriesPercent,
    required this.distancePercent,
    required this.durationPercent,
  });

  final double caloriesPercent;
  final double distancePercent;
  final double durationPercent;

  factory StatsComparison.fromPeriods(
    PeriodStats current,
    PeriodStats previous,
  ) {
    return StatsComparison(
      caloriesPercent:
          _calcPercent(current.totalCalories, previous.totalCalories),
      distancePercent:
          _calcPercent(current.totalDistanceKm, previous.totalDistanceKm),
      durationPercent: _calcPercent(
        current.totalDurationSeconds.toDouble(),
        previous.totalDurationSeconds.toDouble(),
      ),
    );
  }

  static double _calcPercent(double current, double previous) {
    if (previous == 0) {
      return current > 0 ? 100 : 0;
    }
    return ((current - previous) / previous) * 100;
  }
}

class DetailedStatsResult {
  const DetailedStatsResult({
    required this.current,
    required this.previous,
    required this.comparison,
  });

  final PeriodStats current;
  final PeriodStats previous;
  final StatsComparison comparison;
}

class MilestoneProgress {
  const MilestoneProgress({
    required this.id,
    required this.title,
    required this.description,
    required this.target,
    required this.current,
    required this.unit,
  });

  final String id;
  final String title;
  final String description;
  final double target;
  final double current;
  final String unit;

  double get progress => target == 0 ? 0 : (current / target).clamp(0, 1);
  bool get achieved => current >= target;
}

class PeriodRange {
  const PeriodRange({
    required this.start,
    required this.end,
    required this.dayCount,
  });

  final DateTime start;
  final DateTime end;
  final int dayCount;
}

class StatisticsService {
  StatisticsService({
    required ActivityRepository activityRepository,
  }) : _activityRepository = activityRepository;

  final ActivityRepository _activityRepository;

  Future<DetailedStatsResult> getStats({
    required String userId,
    required TimeRange range,
    DateTime? reference,
  }) async {
    final ref = reference ?? DateTime.now();
    final currentRange = _buildRange(range, ref);
    final previousRange = _buildPreviousRange(range, currentRange);

    final currentActivities = await _activityRepository.getActivitiesInRange(
      userId: userId,
      start: currentRange.start,
      end: currentRange.end,
    );
    final previousActivities = await _activityRepository.getActivitiesInRange(
      userId: userId,
      start: previousRange.start,
      end: previousRange.end,
    );

    final currentStats =
        _calculateStats(currentActivities, currentRange.dayCount);
    final previousStats =
        _calculateStats(previousActivities, previousRange.dayCount);

    return DetailedStatsResult(
      current: currentStats,
      previous: previousStats,
      comparison: StatsComparison.fromPeriods(currentStats, previousStats),
    );
  }

  Future<List<MilestoneProgress>> getMilestones({
    required String userId,
  }) async {
    final activities = await _activityRepository.getActivitiesInRange(
      userId: userId,
      start: DateTime(2000, 1, 1),
      end: DateTime.now(),
    );

    double totalDistance = 0;
    double totalCalories = 0;
    int totalDurationSeconds = 0;

    for (final activity in activities) {
      totalDistance += activity.distanceKm ?? 0;
      totalCalories += activity.calories;
      totalDurationSeconds += activity.durationSeconds;
    }

    final totalHours = totalDurationSeconds / 3600.0;

    return [
      MilestoneProgress(
        id: 'distance_100',
        title: '100 km',
        description: 'Quãng đường đã hoàn thành',
        target: 100,
        current: totalDistance,
        unit: 'km',
      ),
      MilestoneProgress(
        id: 'calories_1000',
        title: '1000 kcal',
        description: 'Năng lượng đã đốt cháy',
        target: 1000,
        current: totalCalories,
        unit: 'kcal',
      ),
      MilestoneProgress(
        id: 'duration_100',
        title: '100 giờ tập',
        description: 'Tổng thời lượng luyện tập',
        target: 100,
        current: totalHours,
        unit: 'giờ',
      ),
    ];
  }

  PeriodStats _calculateStats(List<ActivitySession> activities, int dayCount) {
    double totalDistance = 0;
    double totalCalories = 0;
    int totalDuration = 0;

    for (final session in activities) {
      totalDistance += session.distanceKm ?? 0;
      totalCalories += session.calories;
      totalDuration += session.durationSeconds;
    }

    return PeriodStats(
      totalCalories: totalCalories,
      totalDistanceKm: totalDistance,
      totalDurationSeconds: totalDuration,
      sessionCount: activities.length,
      dayCount: dayCount,
    );
  }

  PeriodRange _buildRange(TimeRange range, DateTime reference) {
    switch (range) {
      case TimeRange.day:
        final start = DateTime(reference.year, reference.month, reference.day);
        final end = start
            .add(const Duration(days: 1))
            .subtract(const Duration(seconds: 1));
        return PeriodRange(start: start, end: end, dayCount: 1);
      case TimeRange.week:
        final normalized =
            DateTime(reference.year, reference.month, reference.day);
        final start =
            normalized.subtract(Duration(days: normalized.weekday - 1));
        final end = start
            .add(const Duration(days: 7))
            .subtract(const Duration(seconds: 1));
        return PeriodRange(start: start, end: end, dayCount: 7);
      case TimeRange.month:
        final start = DateTime(reference.year, reference.month, 1);
        final end = DateTime(reference.year, reference.month + 1, 1)
            .subtract(const Duration(seconds: 1));
        final dayCount = end.difference(start).inDays + 1;
        return PeriodRange(start: start, end: end, dayCount: dayCount);
      case TimeRange.year:
        final start = DateTime(reference.year, 1, 1);
        final end = DateTime(reference.year + 1, 1, 1)
            .subtract(const Duration(seconds: 1));
        final dayCount = _isLeapYear(reference.year) ? 366 : 365;
        return PeriodRange(start: start, end: end, dayCount: dayCount);
      case TimeRange.custom:
        final start = DateTime(reference.year, reference.month, reference.day)
            .subtract(const Duration(days: 6));
        final end = DateTime(
            reference.year, reference.month, reference.day, 23, 59, 59, 999);
        return PeriodRange(start: start, end: end, dayCount: 7);
    }
  }

  PeriodRange _buildPreviousRange(TimeRange range, PeriodRange current) {
    switch (range) {
      case TimeRange.day:
        final start = current.start.subtract(const Duration(days: 1));
        final end = current.start.subtract(const Duration(seconds: 1));
        return PeriodRange(start: start, end: end, dayCount: 1);
      case TimeRange.week:
        final start = current.start.subtract(const Duration(days: 7));
        final end = current.end.subtract(const Duration(days: 7));
        return PeriodRange(start: start, end: end, dayCount: 7);
      case TimeRange.month:
        final prevMonthStart =
            DateTime(current.start.year, current.start.month - 1, 1);
        final prevMonthEnd =
            DateTime(current.start.year, current.start.month, 1)
                .subtract(const Duration(seconds: 1));
        final dayCount = prevMonthEnd.difference(prevMonthStart).inDays + 1;
        return PeriodRange(
          start: prevMonthStart,
          end: prevMonthEnd,
          dayCount: dayCount,
        );
      case TimeRange.year:
        final start = DateTime(current.start.year - 1, 1, 1);
        final end = DateTime(current.start.year, 1, 1)
            .subtract(const Duration(seconds: 1));
        final dayCount = _isLeapYear(current.start.year - 1) ? 366 : 365;
        return PeriodRange(start: start, end: end, dayCount: dayCount);
      case TimeRange.custom:
        final start = current.start.subtract(Duration(days: current.dayCount));
        final end = current.start.subtract(const Duration(seconds: 1));
        return PeriodRange(
          start: start,
          end: end,
          dayCount: current.dayCount,
        );
    }
  }

  bool _isLeapYear(int year) {
    if (year % 400 == 0) return true;
    if (year % 100 == 0) return false;
    return year % 4 == 0;
  }
}
