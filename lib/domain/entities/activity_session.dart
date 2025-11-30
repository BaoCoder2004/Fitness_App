class ActivitySession {
  const ActivitySession({
    required this.id,
    required this.userId,
    required this.activityType,
    required this.date,
    required this.durationSeconds,
    required this.calories,
    this.distanceKm,
    this.averageSpeed,
    this.notes,
    this.averageHeartRate,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String activityType;
  final DateTime date;
  final int durationSeconds;
  final double calories;
  final double? distanceKm;
  final double? averageSpeed;
  final String? notes;
  final int? averageHeartRate; // bpm - chỉ có khi kết nối thiết bị đo nhịp tim
  final DateTime? createdAt;
}

