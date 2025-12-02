import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/activity_session.dart';
import '../../domain/entities/goal.dart';
import '../../domain/repositories/activity_repository.dart';
import '../../domain/repositories/goal_repository.dart';
import '../../domain/repositories/weight_history_repository.dart';
import '../helpers/activity_type_helper.dart';
import 'notification_service.dart';

class GoalProgress {
  const GoalProgress({
    required this.goal,
    required this.progress,
    required this.currentValue,
    required this.targetValue,
    required this.remainingValue,
    required this.unitLabel,
  });

  final Goal goal;
  final double progress; // 0..1
  final double currentValue;
  final double targetValue;
  final double remainingValue;
  final String unitLabel;
}

class GoalService {
  GoalService({
    required ActivityRepository activityRepository,
    required WeightHistoryRepository weightHistoryRepository,
    required GoalRepository goalRepository,
    NotificationService? notificationService,
  })  : _activityRepository = activityRepository,
        _weightHistoryRepository = weightHistoryRepository,
        _goalRepository = goalRepository,
        _notificationService = notificationService;

  final ActivityRepository _activityRepository;
  final WeightHistoryRepository _weightHistoryRepository;
  final GoalRepository _goalRepository;
  final NotificationService? _notificationService;

  static const _deadlineWarnedPrefix = 'goal.deadline.warned.';
  static const _deadlineWarningPrefix = 'goal.deadline.warning.';

  /// Check và gửi notification cho tất cả goals nếu có goal completed
  /// Method này được gọi từ Dashboard để đảm bảo notification được gửi ngay khi goal completed
  Future<void> checkAndNotifyCompletedGoals(String userId) async {
    try {
      // Fetch tất cả goals (không filter status) để tránh lỗi Firestore index
      // Sau đó filter ở client để chỉ check active goals
      final allGoals = await _goalRepository.fetchGoals(
        userId: userId,
        status: null,
      );
      final activeGoals = allGoals.where((g) => g.status == GoalStatus.active).toList();
      for (final goal in activeGoals) {
        await calculateProgress(goal);
      }
    } catch (e) {
      debugPrint('[GoalService] Error checking completed goals: $e');
    }
  }

  /// Lấy tên hiển thị của goal: ưu tiên activity type, nếu không có thì dùng goal type
  String _getGoalDisplayName(Goal goal) {
    if (goal.activityTypeFilter != null && goal.activityTypeFilter!.isNotEmpty) {
      final meta = ActivityTypeHelper.resolve(goal.activityTypeFilter);
      return meta.displayName;
    }
    return goal.goalType.displayName;
  }

  Future<GoalProgress> calculateProgress(Goal goal) async {
    final currentValue = await _calculateCurrentValue(goal);
    double progress =
        goal.targetValue <= 0 ? 0 : currentValue / goal.targetValue;
    if (progress < 0) progress = 0;
    if (progress > 1) progress = 1;

    double remainingValue = goal.targetValue - currentValue;
    if (remainingValue < 0) remainingValue = 0;

    final wasCompleted = goal.status == GoalStatus.completed;
    final epsilon = 1e-6;
    final shouldComplete = progress >= 1.0 - epsilon;

    if (wasCompleted && !shouldComplete) {
      // Giữ nguyên trạng thái đã hoàn thành kể cả khi dữ liệu giảm (do xóa hoạt động)
      progress = 1;
      remainingValue = 0;
    } else {
      final desiredStatus =
          (shouldComplete || wasCompleted) ? GoalStatus.completed : GoalStatus.active;

      final statusChanged = goal.status != desiredStatus;
      final shouldUpdateValue =
          (currentValue - goal.currentValue).abs() > 0.1 ||
          statusChanged;

      if (shouldUpdateValue) {
        final updatedGoal = goal.copyWith(
          currentValue: desiredStatus == GoalStatus.completed
              ? goal.targetValue
              : currentValue,
          status: desiredStatus,
          updatedAt: DateTime.now(),
        );
        await _goalRepository.updateGoal(updatedGoal);
        goal = updatedGoal;

        if (statusChanged &&
            goal.status == GoalStatus.completed &&
            desiredStatus == GoalStatus.completed) {
          await _notificationService
              ?.showGoalCompletedNotification(_getGoalDisplayName(goal));
          await _notificationService?.cancelGoalDeadlineNotifications(goal.id);
          await _notificationService?.cancelGoalDailyReminder(goal.id);
          await _clearDeadlineFlags(goal.id);
        }
      }
    }

    await _maybeNotifyDeadlineWarning(goal, shouldComplete);
    await _maybeNotifyDeadlineOverdue(goal, shouldComplete);
    // Không gọi setupGoalReminder ở đây để tránh schedule lại reminder mỗi lần calculateProgress
    // Reminder chỉ được setup khi tạo goal mới hoặc thay đổi settings từ dialog

    return GoalProgress(
      goal: goal,
      progress: progress,
      currentValue: currentValue,
      targetValue: goal.targetValue,
      remainingValue: remainingValue,
      unitLabel: goal.goalType.unitLabel,
    );
  }

  Future<double> _calculateCurrentValue(Goal goal) async {
    switch (goal.goalType) {
      case GoalType.distance:
        return _sumActivities(
          goal.userId,
          goal.startDate,
          (session) => session.distanceKm ?? 0,
          goal.activityTypeFilter,
          goal.timeFrame,
        );
      case GoalType.calories:
        return _sumActivities(
          goal.userId,
          goal.startDate,
          (session) => session.calories,
          goal.activityTypeFilter,
          goal.timeFrame,
        );
      case GoalType.duration:
        return _sumActivities(
          goal.userId,
          goal.startDate,
          (session) => session.durationSeconds / 60.0,
          goal.activityTypeFilter,
          goal.timeFrame,
        );
      case GoalType.weight:
        return _calculateWeightDelta(goal);
    }
  }

  Future<double> _sumActivities(
    String userId,
    DateTime startDate,
    double Function(ActivitySession session) selector,
    String? activityTypeFilter,
    GoalTimeFrame? timeFrame,
  ) async {
    // Tính toán khoảng thời gian dựa trên timeFrame
    final (start, end) = _calculateTimeRange(startDate, timeFrame);
    
    final activities = await _activityRepository.getActivitiesInRange(
      userId: userId,
      start: start,
      end: end,
    );
    var total = 0.0;
    for (final session in activities) {
      // Filter theo activity type nếu có
      if (activityTypeFilter != null &&
          session.activityType != activityTypeFilter) {
        continue;
      }
      total += selector(session);
    }
    return total;
  }

  (DateTime start, DateTime end) _calculateTimeRange(
    DateTime startDate,
    GoalTimeFrame? timeFrame,
  ) {
    final now = DateTime.now();
    if (timeFrame == null) {
      return (startDate, now);
    }

    DateTime start;
    switch (timeFrame) {
      case GoalTimeFrame.daily:
        // Tính từ đầu ngày hôm nay
        start = DateTime(now.year, now.month, now.day);
        break;
      case GoalTimeFrame.weekly:
        // Tính từ đầu tuần (Thứ 2)
        final weekday = now.weekday;
        final daysFromMonday = weekday == 7 ? 0 : weekday - 1;
        start = DateTime(now.year, now.month, now.day - daysFromMonday);
        break;
      case GoalTimeFrame.monthly:
        // Tính từ đầu tháng
        start = DateTime(now.year, now.month, 1);
        break;
      case GoalTimeFrame.yearly:
        // Tính từ đầu năm
        start = DateTime(now.year, 1, 1);
        break;
    }
    // Đảm bảo start không sớm hơn startDate của goal
    if (start.isBefore(startDate)) {
      start = startDate;
    }
    return (start, now);
  }

  Future<double> _calculateWeightDelta(Goal goal) async {
    final initial = goal.initialValue;
    if (initial == null) return goal.currentValue;
    final records =
        await _weightHistoryRepository.watchRecords(goal.userId).first;
    if (records.isEmpty) return goal.currentValue;
    final latestWeight = records.first.weightKg;
    double delta;
    if (goal.direction == 'increase') {
      delta = latestWeight - initial;
    } else {
      delta = initial - latestWeight;
    }
    if (delta < 0) delta = 0;
    return delta;
  }

  Future<void> _maybeNotifyDeadlineWarning(
      Goal goal, bool shouldComplete) async {
    final notificationService = _notificationService;
    if (notificationService == null) return;
    if (goal.deadline == null) return;
    if (goal.status == GoalStatus.completed || shouldComplete) {
      await notificationService.cancelGoalDeadlineNotifications(goal.id);
      await _clearDeadlineFlags(goal.id);
      return;
    }

    // Với mục tiêu daily, deadline là trong ngày nên không cần warning "1 ngày trước"
    if (goal.timeFrame == GoalTimeFrame.daily) {
      await _clearWarningNotified(goal.id);
      return;
    }

    final now = DateTime.now();
    final warningTime = _buildWarningTime(goal.deadline!);
    if (now.isAfter(warningTime)) {
      final warned = await _isWarningNotified(goal.id);
      if (!warned) {
        await notificationService.showGoalDeadlineSoon(
          goalId: goal.id,
          goalName: _getGoalDisplayName(goal),
        );
        await _markWarningNotified(goal.id);
      }
    } else {
      await _clearWarningNotified(goal.id);
      await notificationService.scheduleGoalDeadlineWarningNotification(
        goalId: goal.id,
        goalName: _getGoalDisplayName(goal),
        dateTime: warningTime,
        isDaily: goal.timeFrame == GoalTimeFrame.daily,
      );
    }
  }

  Future<void> _maybeNotifyDeadlineOverdue(
      Goal goal, bool shouldComplete) async {
    final notificationService = _notificationService;
    if (notificationService == null) return;
    if (goal.deadline == null) return;
    if (goal.status == GoalStatus.completed || shouldComplete) {
      await notificationService.cancelGoalDeadlineNotifications(goal.id);
      await _clearDeadlineFlags(goal.id);
      return;
    }

    final now = DateTime.now();
    
    // Với daily goals, kiểm tra trực tiếp deadline (23:59:59) thay vì dueTime (9:00 AM)
    final checkTime = goal.timeFrame == GoalTimeFrame.daily
        ? goal.deadline!
        : _buildDeadlineTime(goal.deadline!);
    
    if (now.isAfter(checkTime)) {
      final notified = await _isDeadlineWarned(goal.id);
      if (!notified) {
        await notificationService.showGoalDeadlineWarning(
          goalId: goal.id,
          goalName: _getGoalDisplayName(goal),
        );
        await _markDeadlineWarned(goal.id);
      }
    } else {
      await _clearDeadlineNotified(goal.id);
      // Schedule notification "đã quá hạn" cho tất cả goals (kể cả daily) vào 23:59:59 ngày deadline
      await notificationService.scheduleGoalDeadlineOverdueNotification(
        goalId: goal.id,
        goalName: _getGoalDisplayName(goal),
        dateTime: checkTime,
      );
    }
  }

  DateTime _buildWarningTime(DateTime deadline) {
    final warningDay =
        DateTime(deadline.year, deadline.month, deadline.day).subtract(
      const Duration(days: 1),
    );
    return DateTime(
      warningDay.year,
      warningDay.month,
      warningDay.day,
      6,
      0,
    );
  }

  DateTime _buildDeadlineTime(DateTime deadline) {
    // Cảnh báo quá hạn nên kích hoạt vào cuối ngày deadline
    return DateTime(
      deadline.year,
      deadline.month,
      deadline.day,
      23,
      59,
      59,
    );
  }

  Future<bool> _isWarningNotified(String goalId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_deadlineWarningPrefix$goalId') ?? false;
  }

  Future<void> _markWarningNotified(String goalId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_deadlineWarningPrefix$goalId', true);
  }

  Future<void> _clearWarningNotified(String goalId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_deadlineWarningPrefix$goalId');
  }

  Future<bool> _isDeadlineWarned(String goalId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_deadlineWarnedPrefix$goalId') ?? false;
  }

  Future<void> _markDeadlineWarned(String goalId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_deadlineWarnedPrefix$goalId', true);
  }

  Future<void> _clearDeadlineNotified(String goalId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_deadlineWarnedPrefix$goalId');
  }

  Future<void> _clearDeadlineFlags(String goalId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_deadlineWarnedPrefix$goalId');
    await prefs.remove('$_deadlineWarningPrefix$goalId');
  }

  Future<void> cancelDeadlineNotifications(String goalId) async {
    final notificationService = _notificationService;
    if (notificationService != null) {
      await notificationService.cancelGoalDeadlineNotifications(goalId);
    }
    await _clearDeadlineFlags(goalId);
  }

  Future<void> setupGoalReminder(Goal goal) async {
    final notificationService = _notificationService;
    if (notificationService == null) {
      debugPrint('[GoalService] NotificationService is null, cannot setup reminder');
      return;
    }
    if (goal.status == GoalStatus.completed) {
      await notificationService.cancelGoalDailyReminder(goal.id);
      return;
    }
    if (goal.reminderEnabled &&
        goal.reminderHour != null &&
        goal.reminderMinute != null) {
      // Với mục tiêu daily: nếu đã qua giờ reminder hôm nay, vẫn schedule cho ngày mai
      // scheduleGoalDailyReminder sẽ tự động tính lần tiếp theo (ngày mai) nếu đã qua giờ hôm nay
      if (goal.timeFrame == GoalTimeFrame.daily) {
        final now = DateTime.now();
        final reminderTime = DateTime(
          now.year,
          now.month,
          now.day,
          goal.reminderHour!,
          goal.reminderMinute!,
        );
        
        // Kiểm tra xem goal có được tạo trong cùng ngày hôm nay không
        final isGoalCreatedToday = goal.startDate.year == now.year &&
            goal.startDate.month == now.month &&
            goal.startDate.day == now.day;
        
        // Nếu goal được tạo hôm nay và reminder time <= thời gian tạo mục tiêu
        // → vẫn schedule, nhưng sẽ schedule cho ngày mai (không phải hôm nay)
        if (isGoalCreatedToday) {
          final goalStartTime = DateTime(
            goal.startDate.year,
            goal.startDate.month,
            goal.startDate.day,
            goal.startDate.hour,
            goal.startDate.minute,
          );
          
          if (reminderTime.isBefore(goalStartTime) || reminderTime.isAtSameMomentAs(goalStartTime)) {
            debugPrint('[GoalService] Daily goal reminder time (${goal.reminderHour}:${goal.reminderMinute}) is before or equal to goal creation time (${goal.startDate.hour}:${goal.startDate.minute}), will schedule for tomorrow');
            // Vẫn tiếp tục schedule, scheduleGoalDailyReminder sẽ tự động tính cho ngày mai
          }
        }
        
        // Nếu đã qua giờ reminder hôm nay → vẫn schedule, nhưng sẽ schedule cho ngày mai
        if (reminderTime.isBefore(now)) {
          debugPrint('[GoalService] Daily goal reminder time (${goal.reminderHour}:${goal.reminderMinute}) has passed today, will schedule for tomorrow');
          // Vẫn tiếp tục schedule, scheduleGoalDailyReminder sẽ tự động tính cho ngày mai
        }
      }
      
      // Với weekly/monthly/yearly: kiểm tra xem goal đã hết hạn chưa
      if (goal.timeFrame != GoalTimeFrame.daily && goal.deadline != null) {
        final now = DateTime.now();
        if (now.isAfter(goal.deadline!)) {
          debugPrint('[GoalService] Goal ${goal.id} has expired, cancelling reminder');
          await notificationService.cancelGoalDailyReminder(goal.id);
          return;
        }
      }
      
      debugPrint('[GoalService] Setting up reminder for goal ${goal.id} at ${goal.reminderHour}:${goal.reminderMinute}');
      final success = await notificationService.scheduleGoalDailyReminder(
        goalId: goal.id,
        goalName: _getGoalDisplayName(goal),
        hour: goal.reminderHour!,
        minute: goal.reminderMinute!,
        isDaily: goal.timeFrame == GoalTimeFrame.daily,
        deadline: goal.deadline,
      );
      if (!success) {
        debugPrint('[GoalService] Failed to schedule reminder for goal ${goal.id}');
      }
    } else {
      debugPrint('[GoalService] Cancelling reminder for goal ${goal.id} (disabled or no time set)');
      await notificationService.cancelGoalDailyReminder(goal.id);
    }
  }

  Future<void> cancelGoalReminder(String goalId) async {
    final notificationService = _notificationService;
    if (notificationService != null) {
      await notificationService.cancelGoalDailyReminder(goalId);
    }
  }

  /// Tự động cancel reminder cho một goal đã expired
  Future<void> cancelExpiredGoalReminder(Goal goal) async {
    final notificationService = _notificationService;
    if (notificationService == null) return;

    final now = DateTime.now();
    // Chỉ cancel reminder cho weekly/monthly/yearly goals đã expired
    if (goal.timeFrame != GoalTimeFrame.daily &&
        goal.deadline != null &&
        now.isAfter(goal.deadline!) &&
        goal.reminderEnabled) {
      debugPrint('[GoalService] Auto-cancelling reminder for expired goal ${goal.id}');
      await notificationService.cancelGoalDailyReminder(goal.id);
    }
  }

  Future<void> setupGoalDailyReminder(Goal goal, bool shouldComplete) async {
    await setupGoalReminder(goal);
  }
}

/// Helper wrapper để tái sử dụng cấu trúc ActivitySession mà không import trực tiếp.
class ActivitySessionLike {
  ActivitySessionLike({
    required this.distanceKm,
    required this.calories,
    required this.durationSeconds,
  });

  final double? distanceKm;
  final double calories;
  final int durationSeconds;

  factory ActivitySessionLike.fromSession(dynamic session) {
    return ActivitySessionLike(
      distanceKm: session.distanceKm,
      calories: session.calories,
      durationSeconds: session.durationSeconds,
    );
  }
}

