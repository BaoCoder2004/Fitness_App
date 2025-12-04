import '../entities/ai_insight.dart';

abstract class AIInsightRepository {
  /// Lưu insight vào Firestore
  Future<void> saveInsight(AIInsight insight);

  /// Lấy tất cả insights của user
  Future<List<AIInsight>> getInsights(String userId);

  /// Stream insights của user (real-time)
  Stream<List<AIInsight>> watchInsights(String userId);

  /// Lấy insight theo ID
  Future<AIInsight?> getInsightById(String userId, String insightId);

  /// Xóa insight
  Future<void> deleteInsight(String userId, String insightId);

  /// Lấy insights theo loại
  Future<List<AIInsight>> getInsightsByType(
    String userId,
    InsightType type,
  );
}

