enum GoalType {
  weight,
  distance,
  calories,
  duration,
}

enum GoalStatus {
  active,
  completed,
  cancelled,
}

enum GoalTimeFrame {
  daily,
  weekly,
  monthly,
  yearly,
}

class Goal {
  const Goal({
    required this.id,
    required this.userId,
    required this.goalType,
    required this.targetValue,
    required this.currentValue,
    required this.startDate,
    required this.status,
    this.deadline,
    this.direction,
    this.initialValue,
    this.createdAt,
    this.updatedAt,
    this.reminderEnabled = false,
    this.reminderHour,
    this.reminderMinute,
    this.activityTypeFilter,
    this.timeFrame,
  });

  final String id;
  final String userId;
  final GoalType goalType;
  final double targetValue;
  final double currentValue;
  final DateTime startDate;
  final DateTime? deadline;
  final GoalStatus status;
  final String? direction; // Ví dụ: 'increase' hoặc 'decrease' cho weight goal
  final double? initialValue;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool reminderEnabled;
  final int? reminderHour;
  final int? reminderMinute;
  final String? activityTypeFilter; // Loại hoạt động được chọn (null = tất cả)
  final GoalTimeFrame? timeFrame; // Khung thời gian (ngày/tuần/tháng/năm)

  Goal copyWith({
    String? id,
    String? userId,
    GoalType? goalType,
    double? targetValue,
    double? currentValue,
    DateTime? startDate,
    DateTime? deadline,
    GoalStatus? status,
    String? direction,
    double? initialValue,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? reminderEnabled,
    int? reminderHour,
    int? reminderMinute,
    String? activityTypeFilter,
    GoalTimeFrame? timeFrame,
  }) {
    return Goal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      goalType: goalType ?? this.goalType,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      startDate: startDate ?? this.startDate,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      direction: direction ?? this.direction,
      initialValue: initialValue ?? this.initialValue,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      activityTypeFilter: activityTypeFilter ?? this.activityTypeFilter,
      timeFrame: timeFrame ?? this.timeFrame,
    );
  }
}

extension GoalTypeX on GoalType {
  String get displayName {
    switch (this) {
      case GoalType.weight:
        return 'Cân nặng';
      case GoalType.distance:
        return 'Quãng đường';
      case GoalType.calories:
        return 'Calories';
      case GoalType.duration:
        return 'Thời gian tập';
    }
  }

  String get unitLabel {
    switch (this) {
      case GoalType.weight:
        return 'kg';
      case GoalType.distance:
        return 'km';
      case GoalType.calories:
        return 'kcal';
      case GoalType.duration:
        return 'phút';
    }
  }
}

extension GoalStatusX on GoalStatus {
  String get label {
    switch (this) {
      case GoalStatus.active:
        return 'Đang theo dõi';
      case GoalStatus.completed:
        return 'Đã hoàn thành';
      case GoalStatus.cancelled:
        return 'Đã hủy';
    }
  }
}

extension GoalTimeFrameX on GoalTimeFrame {
  String get displayName {
    switch (this) {
      case GoalTimeFrame.daily:
        return 'Theo ngày';
      case GoalTimeFrame.weekly:
        return 'Theo tuần';
      case GoalTimeFrame.monthly:
        return 'Theo tháng';
      case GoalTimeFrame.yearly:
        return 'Theo năm';
    }
  }
}

