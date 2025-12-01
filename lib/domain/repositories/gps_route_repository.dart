import '../entities/gps_route.dart';

abstract class GpsRouteRepository {
  Future<void> saveRoute(GpsRoute route);

  Future<GpsRoute?> getRouteForActivity({
    required String userId,
    required String activityId,
  });

  /// Stream danh sách tất cả GPS routes của user, sắp xếp mới nhất trước.
  Stream<List<GpsRoute>> watchRoutes({required String userId});

  /// Xóa tất cả GPS routes gắn với một buổi tập (dùng khi xóa buổi tập).
  Future<void> deleteRoutesForActivity({
    required String userId,
    required String activityId,
  });
}


