import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/services/gps_tracking_service.dart';

class OutdoorTrackingState {
  const OutdoorTrackingState({
    required this.isTracking,
    required this.hasStarted,
    required this.distanceKm,
    required this.duration,
    required this.averageSpeed,
    required this.segments,
    required this.startPoint,
    required this.currentPoint,
  });

  final bool isTracking;
  final bool hasStarted;
  final double distanceKm;
  final Duration duration;
  final double averageSpeed;
  final List<GpsSegment> segments;
  final GpsPoint? startPoint;
  final GpsPoint? currentPoint;
}

class OutdoorTrackingViewModel extends ChangeNotifier {
  OutdoorTrackingViewModel({required this.activityType}) {
    _stateSub = _gpsService.stateStream.listen((gpsState) {
      _lastGpsState = gpsState;
      notifyListeners();
    });
  }

  final String activityType;

  final GpsTrackingService _gpsService = GpsTrackingService();
  StreamSubscription<GpsTrackingState>? _stateSub;
  GpsTrackingState? _lastGpsState;

  OutdoorTrackingState get state {
    final gps = _lastGpsState ?? _gpsService.currentState;

    // Tính tốc độ trung bình km/h từ tổng quãng đường và thời gian di chuyển
    double averageSpeed = 0;
    if (gps.activeDuration.inSeconds > 0) {
      final hours = gps.activeDuration.inSeconds / 3600.0;
      if (hours > 0) {
        averageSpeed = gps.totalDistanceKm / hours;
      }
    }

    return OutdoorTrackingState(
      isTracking: gps.isTracking,
      hasStarted: gps.hasStarted,
      distanceKm: gps.totalDistanceKm,
      duration: gps.activeDuration,
      averageSpeed: averageSpeed,
      segments: gps.segments,
      startPoint: gps.startPoint,
      currentPoint: gps.currentPoint,
    );
  }

  Future<void> start() async {
    await _gpsService.startTracking();
  }

  Future<void> pause() async {
    await _gpsService.pauseTracking();
  }

  Future<void> resume() async {
    await _gpsService.resumeTracking();
  }

  Future<void> stop() async {
    await _gpsService.stopTracking();
    _lastGpsState = _gpsService.currentState;
    notifyListeners();
  }

  /// Reset toàn bộ dữ liệu buổi tập (thời gian, quãng đường, segments) về 0.
  Future<void> reset() async {
    await _gpsService.reset();
    _lastGpsState = _gpsService.currentState;
    notifyListeners();
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _gpsService.dispose();
    super.dispose();
  }
}
