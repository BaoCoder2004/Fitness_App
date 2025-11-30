import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/goal.dart';

class GoalModel extends Goal {
  const GoalModel({
    required super.id,
    required super.userId,
    required super.goalType,
    required super.targetValue,
    required super.currentValue,
    required super.startDate,
    required super.status,
    super.deadline,
    super.direction,
    super.initialValue,
    super.createdAt,
    super.updatedAt,
    super.reminderEnabled,
    super.reminderHour,
    super.reminderMinute,
    super.activityTypeFilter,
    super.timeFrame,
  });

  factory GoalModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return GoalModel(
      id: doc.id,
      userId: data['userId'] as String,
      goalType: GoalType.values.firstWhere(
        (type) => type.name == (data['goalType'] as String? ?? 'distance'),
        orElse: () => GoalType.distance,
      ),
      targetValue: (data['targetValue'] as num).toDouble(),
      currentValue: (data['currentValue'] as num).toDouble(),
      startDate: (data['startDate'] as Timestamp).toDate(),
      deadline: (data['deadline'] as Timestamp?)?.toDate(),
      status: GoalStatus.values.firstWhere(
        (status) => status.name == (data['status'] as String? ?? 'active'),
        orElse: () => GoalStatus.active,
      ),
      direction: data['direction'] as String?,
      initialValue: (data['initialValue'] as num?)?.toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      reminderEnabled: data['reminderEnabled'] as bool? ?? false,
      reminderHour: data['reminderHour'] as int?,
      reminderMinute: data['reminderMinute'] as int?,
      activityTypeFilter: data['activityTypeFilter'] as String?,
      timeFrame: data['timeFrame'] != null
          ? GoalTimeFrame.values.firstWhere(
              (tf) => tf.name == (data['timeFrame'] as String),
              orElse: () => GoalTimeFrame.daily,
            )
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'goalType': goalType.name,
      'targetValue': targetValue,
      'currentValue': currentValue,
      'startDate': Timestamp.fromDate(startDate),
      'deadline': deadline != null ? Timestamp.fromDate(deadline!) : null,
      'status': status.name,
      'direction': direction,
      'initialValue': initialValue,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'reminderEnabled': reminderEnabled,
      'reminderHour': reminderHour,
      'reminderMinute': reminderMinute,
      'activityTypeFilter': activityTypeFilter,
      'timeFrame': timeFrame?.name,
    };
  }
}

