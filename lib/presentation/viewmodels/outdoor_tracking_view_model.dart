import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class OutdoorTrackingState {
  const OutdoorTrackingState({
    required this.isTracking,
    required this.hasStarted,
    required this.distanceKm,
    required this.duration,
    required this.averageSpeed,
  });

  final bool isTracking;
  final bool hasStarted;
  final double distanceKm;
  final Duration duration;
  final double averageSpeed;
}

class OutdoorTrackingViewModel extends ChangeNotifier {
  OutdoorTrackingViewModel({required this.activityType});

  final String activityType;

  Position? _lastPosition;
  double _distanceMeters = 0;
  Duration _activeDuration = Duration.zero;
  Timer? _timer;
  StreamSubscription<Position>? _positionSub;
  bool _isTracking = false;
  bool _hasStarted = false;

  OutdoorTrackingState get state => OutdoorTrackingState(
        isTracking: _isTracking,
        hasStarted: _hasStarted,
        distanceKm: _distanceMeters / 1000,
        duration: _activeDuration,
        averageSpeed: _calculateAverageSpeed(),
      );

  Future<void> start() async {
    final hasPermission = await _ensurePermission();
    if (!hasPermission) {
      throw Exception('Không có quyền truy cập vị trí.');
    }

    _distanceMeters = 0;
    _activeDuration = Duration.zero;
    _isTracking = true;
    _hasStarted = true;
    notifyListeners();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _activeDuration += const Duration(seconds: 1);
      notifyListeners();
    });

    _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5,
      ),
    ).listen(_onNewPosition);
  }

  void pause() {
    if (!_isTracking) return;
    _isTracking = false;
    _timer?.cancel();
    _positionSub?.pause();
    notifyListeners();
  }

  void resume() {
    if (_isTracking) return;
    _isTracking = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _activeDuration += const Duration(seconds: 1);
      notifyListeners();
    });
    _positionSub?.resume();
    notifyListeners();
  }

  void stop() {
    _isTracking = false;
    _hasStarted = false;
    _timer?.cancel();
    _positionSub?.cancel();
    _distanceMeters = 0;
    _activeDuration = Duration.zero;
    notifyListeners();
  }

  double _calculateAverageSpeed() {
    if (_activeDuration.inSeconds == 0) return 0;
    final hours = _activeDuration.inSeconds / 3600;
    if (hours == 0) return 0;
    return (_distanceMeters / 1000) / hours;
  }

  void _onNewPosition(Position position) {
    if (_lastPosition != null) {
      final distance = Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        position.latitude,
        position.longitude,
      );
      _distanceMeters += distance;
    }
    _lastPosition = position;
    notifyListeners();
  }

  Future<bool> _ensurePermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionSub?.cancel();
    super.dispose();
  }
}

