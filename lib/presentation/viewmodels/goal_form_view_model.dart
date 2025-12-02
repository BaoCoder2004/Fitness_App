import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/entities/goal.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/goal_repository.dart';
import '../../domain/repositories/weight_history_repository.dart';

class GoalFormViewModel extends ChangeNotifier {
  GoalFormViewModel({
    required AuthRepository authRepository,
    required GoalRepository goalRepository,
    required WeightHistoryRepository weightHistoryRepository,
  })  : _authRepository = authRepository,
        _goalRepository = goalRepository,
        _weightHistoryRepository = weightHistoryRepository;

  final AuthRepository _authRepository;
  final GoalRepository _goalRepository;
  final WeightHistoryRepository _weightHistoryRepository;

  bool _isSubmitting = false;
  String? _errorMessage;

  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  Future<bool> submitGoal({
    required GoalType goalType,
    required double targetValue,
    String? direction,
    bool reminderEnabled = false,
    int? reminderHour,
    int? reminderMinute,
    String? activityTypeFilter,
    GoalTimeFrame? timeFrame,
  }) async {
    final userId = _authRepository.currentUser?.uid;
    if (userId == null) {
      _setError('Bạn cần đăng nhập để tạo mục tiêu');
      return false;
    }

    _setSubmitting(true);
    try {
      final now = DateTime.now();
      final initialValue = await _resolveInitialValue(
        userId: userId,
        goalType: goalType,
      );
      if (goalType == GoalType.weight && initialValue == null) {
        _setError('Bạn cần ghi nhận cân nặng trước khi tạo mục tiêu cân nặng');
        return false;
      }

      // Tính deadline tự động từ timeFrame
      final deadline = _calculateDeadline(now, timeFrame);

      final goal = Goal(
        id: '',
        userId: userId,
        goalType: goalType,
        targetValue: targetValue,
        currentValue: 0,
        startDate: now,
        deadline: deadline,
        status: GoalStatus.active,
        direction: direction,
        initialValue: initialValue,
        createdAt: now,
        updatedAt: now,
        reminderEnabled: reminderEnabled,
        reminderHour: reminderHour,
        reminderMinute: reminderMinute,
        activityTypeFilter: activityTypeFilter,
        timeFrame: timeFrame,
      );

      _setError(null);
      unawaited(_goalRepository.createGoal(goal).catchError((e) {
        debugPrint('Deferred goal creation failed: $e');
        _setError('Không thể đồng bộ mục tiêu. Vui lòng mở lại app khi có mạng.');
      }));
      return true;
    } catch (e) {
      _setError('Không thể tạo mục tiêu. Vui lòng thử lại.');
      return false;
    } finally {
      _setSubmitting(false);
    }
  }

  Future<bool> updateGoal({
    required Goal goal,
    required double targetValue,
    String? direction,
    bool? reminderEnabled,
    int? reminderHour,
    int? reminderMinute,
    String? activityTypeFilter,
    GoalTimeFrame? timeFrame,
  }) async {
    final userId = _authRepository.currentUser?.uid;
    if (userId == null || userId != goal.userId) {
      _setError('Bạn cần đăng nhập để cập nhật mục tiêu');
      return false;
    }

    _setSubmitting(true);
    try {
      // Tính deadline mới nếu timeFrame thay đổi
      final newTimeFrame = timeFrame ?? goal.timeFrame;
      final deadline = newTimeFrame != null
          ? _calculateDeadline(goal.startDate, newTimeFrame)
          : goal.deadline;

      final updatedGoal = goal.copyWith(
        targetValue: targetValue,
        deadline: deadline,
        direction: direction ?? goal.direction,
        updatedAt: DateTime.now(),
        reminderEnabled: reminderEnabled ?? goal.reminderEnabled,
        reminderHour: reminderHour ?? goal.reminderHour,
        reminderMinute: reminderMinute ?? goal.reminderMinute,
        activityTypeFilter: activityTypeFilter ?? goal.activityTypeFilter,
        timeFrame: newTimeFrame,
      );
      await _goalRepository.updateGoal(updatedGoal);
      _setError(null);
      return true;
    } catch (e) {
      _setError('Không thể cập nhật mục tiêu. Vui lòng thử lại.');
      return false;
    } finally {
      _setSubmitting(false);
    }
  }

  void _setSubmitting(bool value) {
    _isSubmitting = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<double?> _resolveInitialValue({
    required String userId,
    required GoalType goalType,
  }) async {
    if (goalType == GoalType.weight) {
      final records = await _weightHistoryRepository.watchRecords(userId).first;
      if (records.isEmpty) return null;
      return records.first.weightKg;
    }
    return 0;
  }

  /// Tính deadline tự động dựa trên timeFrame
  /// - daily: hết ngày hôm đó (23:59:59)
  /// - weekly: sau 1 tuần từ startDate
  /// - monthly: hết tháng hiện tại
  /// - yearly: hết năm hiện tại
  DateTime? _calculateDeadline(DateTime startDate, GoalTimeFrame? timeFrame) {
    if (timeFrame == null) return null;

    switch (timeFrame) {
      case GoalTimeFrame.daily:
        // Hết ngày hôm đó
        return DateTime(startDate.year, startDate.month, startDate.day, 23, 59, 59);
      case GoalTimeFrame.weekly:
        // Sau 1 tuần từ startDate
        return startDate.add(const Duration(days: 7));
      case GoalTimeFrame.monthly:
        // Hết tháng hiện tại
        final nextMonth = startDate.month == 12
            ? DateTime(startDate.year + 1, 1, 1)
            : DateTime(startDate.year, startDate.month + 1, 1);
        return nextMonth.subtract(const Duration(seconds: 1));
      case GoalTimeFrame.yearly:
        // Hết năm hiện tại
        return DateTime(startDate.year + 1, 1, 1)
            .subtract(const Duration(seconds: 1));
    }
  }
}

