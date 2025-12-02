import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/gps_route.dart';

class GpsRouteModel {
  GpsRouteModel({
    required this.id,
    required this.userId,
    required this.activityId,
    required this.segments,
    required this.totalDistanceKm,
    required this.totalDurationSeconds,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String activityId;
  final List<GpsRouteSegment> segments;
  final double totalDistanceKm;
  final int totalDurationSeconds;
  final DateTime createdAt;

  /// Giới hạn số điểm mỗi segment để tối ưu storage
  static const int _maxPointsPerSegment = 800;

  /// Downsample points nếu quá nhiều, giữ lại điểm đầu và cuối
  static List<T> _downsamplePoints<T>(List<T> points, int maxPoints) {
    if (points.length <= maxPoints) return points;
    
    final result = <T>[];
    result.add(points.first); // Luôn giữ điểm đầu
    
    final step = (points.length - 2) / (maxPoints - 2);
    for (int i = 1; i < maxPoints - 1; i++) {
      final index = (1 + i * step).round();
      if (index < points.length) {
        result.add(points[index]);
      }
    }
    
    result.add(points.last); // Luôn giữ điểm cuối
    return result;
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'activityId': activityId,
      'segments': segments
          .map(
            (s) {
              // Downsample points nếu quá nhiều
              final pointsToSave = _downsamplePoints(s.points, _maxPointsPerSegment);
              return {
                'startTime': Timestamp.fromDate(s.startTime),
                'endTime': s.endTime != null ? Timestamp.fromDate(s.endTime!) : null,
                'points': pointsToSave
                    .map(
                      (p) => {
                        'lat': p.lat,
                        'lng': p.lng,
                        'timestamp': Timestamp.fromDate(p.timestamp),
                      },
                    )
                    .toList(),
              };
            },
          )
          .toList(),
      'totalDistanceKm': totalDistanceKm,
      'totalDurationSeconds': totalDurationSeconds,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static GpsRouteModel fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final segmentsData = data['segments'] as List<dynamic>? ?? [];

    final segments = segmentsData.map<GpsRouteSegment>((segment) {
      final segMap = segment as Map<String, dynamic>;
      final pointsData = segMap['points'] as List<dynamic>? ?? [];
      final points = pointsData.map<GpsRoutePoint>((p) {
        final pMap = p as Map<String, dynamic>;
        final ts = pMap['timestamp'] as Timestamp;
        return GpsRoutePoint(
          lat: (pMap['lat'] as num).toDouble(),
          lng: (pMap['lng'] as num).toDouble(),
          timestamp: ts.toDate(),
        );
      }).toList();

      final startTs = segMap['startTime'] as Timestamp;
      final endTs = segMap['endTime'] as Timestamp?;

      return GpsRouteSegment(
        points: points,
        startTime: startTs.toDate(),
        endTime: endTs?.toDate(),
      );
    }).toList();

    final createdAtTs = data['createdAt'] as Timestamp;

    return GpsRouteModel(
      id: doc.id,
      userId: data['userId'] as String,
      activityId: data['activityId'] as String,
      segments: segments,
      totalDistanceKm: (data['totalDistanceKm'] as num).toDouble(),
      totalDurationSeconds: data['totalDurationSeconds'] as int,
      createdAt: createdAtTs.toDate(),
    );
  }

  GpsRoute toEntity() {
    return GpsRoute(
      id: id,
      userId: userId,
      activityId: activityId,
      segments: segments,
      totalDistanceKm: totalDistanceKm,
      totalDurationSeconds: totalDurationSeconds,
      createdAt: createdAt,
    );
  }
}


