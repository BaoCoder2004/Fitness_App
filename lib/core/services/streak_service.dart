import '../../../domain/entities/streak.dart';
import '../../../domain/repositories/activity_repository.dart';
import '../../../domain/repositories/streak_repository.dart';

enum GoalType {
  distance,
  calories,
  duration,
}

class StreakService {
  StreakService({
    required ActivityRepository activityRepository,
    StreakRepository? streakRepository,
  })  : _activityRepository = activityRepository,
        _streakRepository = streakRepository;

  final ActivityRepository _activityRepository;
  final StreakRepository? _streakRepository;

  /// Tính toán streak dựa trên activities và goal
  Future<Streak> calculateStreak({
    required String userId,
    required GoalType goalType,
    required double goalValue, // Mục tiêu mỗi ngày (km, kcal, hoặc phút)
    DateTime? startDate,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = startDate ?? today.subtract(const Duration(days: 365));

    // Lấy tất cả activities trong khoảng thời gian
    final activities = await _activityRepository.getActivitiesInRange(
      userId: userId,
      start: start,
      end: today.add(const Duration(days: 1)),
    );

    // Group activities theo ngày
    final Map<DateTime, double> dailyTotals = {};
    for (final activity in activities) {
      final date = DateTime(
        activity.date.year,
        activity.date.month,
        activity.date.day,
      );

      double value = 0;
      switch (goalType) {
        case GoalType.distance:
          value = activity.distanceKm ?? 0;
          break;
        case GoalType.calories:
          value = activity.calories;
          break;
        case GoalType.duration:
          value = activity.durationSeconds / 60.0; // phút
          break;
      }

      dailyTotals[date] = (dailyTotals[date] ?? 0) + value;
    }

    // Tính streak từ hôm nay ngược lại
    int currentStreak = 0;
    DateTime? lastAchievedDate;
    int longestStreak = 0;
    int tempStreak = 0;

    DateTime checkDate = today;
    while (checkDate.isAfter(start.subtract(const Duration(days: 1)))) {
      final total = dailyTotals[checkDate] ?? 0;
      final achieved = total >= goalValue;

      if (achieved) {
        lastAchievedDate ??= checkDate;
        if (checkDate == today || 
            checkDate.difference(lastAchievedDate).inDays <= 1) {
          currentStreak++;
          tempStreak++;
        } else {
          // Streak bị gián đoạn
          longestStreak = tempStreak > longestStreak ? tempStreak : longestStreak;
          tempStreak = 1;
        }
        lastAchievedDate = checkDate;
      } else {
        // Nếu hôm nay chưa đạt mục tiêu, streak hiện tại = 0
        if (checkDate == today) {
          currentStreak = 0;
        } else {
          longestStreak = tempStreak > longestStreak ? tempStreak : longestStreak;
          tempStreak = 0;
        }
      }

      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    // Cập nhật longest streak nếu cần
    longestStreak = tempStreak > longestStreak ? tempStreak : longestStreak;

    // Lấy streak hiện tại từ Firestore (nếu có)
    Streak? existingStreak;
    final repository = _streakRepository;
    if (repository != null) {
      existingStreak = await repository.getStreak(
        userId: userId,
        goalType: goalType.name,
      );
    }

    final streak = Streak(
      id: existingStreak?.id ?? '',
      userId: userId,
      goalType: goalType.name,
      currentStreak: currentStreak,
      longestStreak: longestStreak > (existingStreak?.longestStreak ?? 0)
          ? longestStreak
          : (existingStreak?.longestStreak ?? longestStreak),
      lastDate: lastAchievedDate ?? today,
      updatedAt: now,
    );

    // Lưu vào Firestore nếu có repository
    if (repository != null) {
      await repository.saveStreak(streak);
    }

    return streak;
  }

  /// Kiểm tra xem hôm nay đã đạt mục tiêu chưa
  Future<bool> checkTodayGoal({
    required String userId,
    required GoalType goalType,
    required double goalValue,
  }) async {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(const Duration(days: 1));

    final activities = await _activityRepository.getActivitiesInRange(
      userId: userId,
      start: start,
      end: end,
    );

    double total = 0;
    for (final activity in activities) {
      switch (goalType) {
        case GoalType.distance:
          total += activity.distanceKm ?? 0;
          break;
        case GoalType.calories:
          total += activity.calories;
          break;
        case GoalType.duration:
          total += activity.durationSeconds / 60.0; // phút
          break;
      }
    }

    return total >= goalValue;
  }

  /// Lấy danh sách milestones
  static List<int> getMilestones() {
    return [7, 30, 60, 100, 365];
  }

  /// Kiểm tra xem có đạt milestone không
  static bool hasReachedMilestone(int streak) {
    return getMilestones().contains(streak);
  }
}

