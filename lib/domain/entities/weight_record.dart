class WeightRecord {
  const WeightRecord({
    required this.id,
    required this.userId,
    required this.weightKg,
    required this.recordedAt,
    required this.createdAt,
    this.note,
  });

  final String id;
  final String userId;
  final double weightKg;
  final DateTime recordedAt;
  final DateTime createdAt;
  final String? note;
}

