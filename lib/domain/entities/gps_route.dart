class GpsRoutePoint {
  GpsRoutePoint({
    required this.lat,
    required this.lng,
    required this.timestamp,
  });

  final double lat;
  final double lng;
  final DateTime timestamp;
}

class GpsRouteSegment {
  GpsRouteSegment({
    required this.points,
    required this.startTime,
    this.endTime,
  });

  final List<GpsRoutePoint> points;
  final DateTime startTime;
  final DateTime? endTime;
}

class GpsRoute {
  GpsRoute({
    required this.id,
    required this.userId,
    required this.activityId,
    required this.segments,
    required this.totalDistanceKm,
    required this.totalDurationSeconds,
    required this.createdAt,
  })  : startPoint = segments.isNotEmpty && segments.first.points.isNotEmpty
            ? segments.first.points.first
            : null,
        endPoint = segments.isNotEmpty && segments.last.points.isNotEmpty
            ? segments.last.points.last
            : null;

  final String id;
  final String userId;
  final String activityId;
  final List<GpsRouteSegment> segments;
  final double totalDistanceKm;
  final int totalDurationSeconds;
  final DateTime createdAt;

  final GpsRoutePoint? startPoint;
  final GpsRoutePoint? endPoint;
}


