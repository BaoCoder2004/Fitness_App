import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/activity_session.dart';

class ActivitySessionModel extends ActivitySession {
  const ActivitySessionModel({
    required super.id,
    required super.userId,
    required super.activityType,
    required super.date,
    required super.durationSeconds,
    required super.calories,
    super.distanceKm,
    super.averageSpeed,
    super.notes,
    super.averageHeartRate,
    super.createdAt,
  });

  factory ActivitySessionModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return ActivitySessionModel(
      id: doc.id,
      userId: data['userId'] as String,
      activityType: data['activityType'] as String? ?? 'khác',
      date: (data['date'] as Timestamp).toDate(),
      durationSeconds: (data['duration'] as num?)?.toInt() ?? 0,
      calories: (data['calories'] as num?)?.toDouble() ?? 0,
      distanceKm: (data['distance'] as num?)?.toDouble(),
      averageSpeed: (data['averageSpeed'] as num?)?.toDouble(),
      notes: data['notes'] as String?,
      averageHeartRate: (data['averageHeartRate'] as num?)?.toInt(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'activityType': activityType,
      'date': Timestamp.fromDate(date),
      'duration': durationSeconds,
      'calories': calories,
      'distance': distanceKm,
      'averageSpeed': averageSpeed,
      'notes': notes,
      'averageHeartRate': averageHeartRate,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }
}

