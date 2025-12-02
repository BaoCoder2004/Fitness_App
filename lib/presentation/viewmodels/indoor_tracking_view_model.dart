import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/workout_types.dart';

class IndoorTrackingResult {
  IndoorTrackingResult({
    required this.duration,
    required this.calories,
    required this.note,
  });

  final Duration duration;
  final double calories;
  final String? note;
}

class IndoorTrackingViewModel extends ChangeNotifier {
  IndoorTrackingViewModel({
    required this.workoutType,
    required this.weightKg,
  });

  final IndoorWorkoutType workoutType;
  final double weightKg;

  Duration _activeDuration = Duration.zero;
  Timer? _timer;
  bool _isRunning = false;
  bool _hasStarted = false;
  String? _note;
  int? _heartRate;

  Duration get activeDuration => _activeDuration;
  bool get isRunning => _isRunning;
  bool get hasStarted => _hasStarted;
  double get calories => _calculateCalories(_activeDuration);
  String? get note => _note;
  int? get heartRate => _heartRate;

  void updateNote(String value) {
    _note = value;
  }

  /// Cập nhật nhịp tim từ thiết bị đo (BLE)
  /// Chỉ được gọi từ HeartRateService khi có thiết bị kết nối
  void updateHeartRateFromDevice(int? value) {
    _heartRate = value;
    notifyListeners();
  }

  void start() {
    if (_hasStarted) return;
    _hasStarted = true;
    _isRunning = true;
    _startTimer();
    notifyListeners();
  }

  void pause() {
    if (!_isRunning) return;
    _timer?.cancel();
    _isRunning = false;
    notifyListeners();
  }

  void resume() {
    if (_isRunning) return;
    _isRunning = true;
    _startTimer();
    notifyListeners();
  }

  IndoorTrackingResult snapshot() {
    return IndoorTrackingResult(
      duration: _activeDuration,
      calories: calories,
      note: _note,
    );
  }

  void resetSession() {
    _timer?.cancel();
    _isRunning = false;
    _hasStarted = false;
    _activeDuration = Duration.zero;
    _note = null;
    _heartRate = null;
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _activeDuration += const Duration(seconds: 1);
      notifyListeners();
    });
  }

  double _calculateCalories(Duration duration) {
    final hours = duration.inSeconds / 3600;
    return workoutType.met * weightKg * hours;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

