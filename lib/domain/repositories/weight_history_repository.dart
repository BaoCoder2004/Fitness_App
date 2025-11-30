import '../entities/weight_record.dart';

abstract class WeightHistoryRepository {
  Stream<List<WeightRecord>> watchRecords(String userId);

  Future<void> addRecord({
    required String userId,
    required double weightKg,
    required DateTime recordedAt,
    String? note,
  });
}

