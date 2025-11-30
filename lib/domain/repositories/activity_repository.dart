import '../entities/activity_session.dart';

abstract class ActivityRepository {
  Stream<List<ActivitySession>> watchActivitiesOfDay({
    required String userId,
    required DateTime day,
  });

  Future<ActivitySession?> fetchMostRecentActivity(String userId);

  Future<void> saveSession(ActivitySession session);

  /// Lấy danh sách hoạt động trong khoảng thời gian
  Future<List<ActivitySession>> getActivitiesInRange({
    required String userId,
    required DateTime start,
    required DateTime end,
  });

  /// Lấy chi tiết một buổi tập theo id
  Future<ActivitySession?> getActivityById({
    required String oderId,
    required String sessionId,
  });

  /// Xóa một buổi tập
  Future<void> deleteSession({
    required String userId,
    required String sessionId,
  });
}

