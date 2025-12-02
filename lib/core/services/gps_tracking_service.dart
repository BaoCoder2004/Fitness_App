import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Điểm GPS đơn lẻ với timestamp
class GpsPoint {
  GpsPoint({
    required this.position,
    required this.timestamp,
  });

  final LatLng position;
  final DateTime timestamp;
}

/// Một segment là một chuỗi các điểm liên tục giữa hai lần Pause/Resume
class GpsSegment {
  GpsSegment({
    required this.points,
    required this.startTime,
    this.endTime,
  });

  final List<GpsPoint> points;
  final DateTime startTime;
  DateTime? endTime;
}

/// Trạng thái tracking hiện tại, dùng để hiển thị UI real-time
class GpsTrackingState {
  const GpsTrackingState({
    required this.isTracking,
    required this.hasStarted,
    required this.totalDistanceKm,
    required this.activeDuration,
    required this.segments,
    required this.startPoint,
    required this.currentPoint,
  });

  final bool isTracking;
  final bool hasStarted;
  final double totalDistanceKm;
  final Duration activeDuration;
  final List<GpsSegment> segments;
  final GpsPoint? startPoint;
  final GpsPoint? currentPoint;
}

/// Service chịu trách nhiệm quản lý GPS tracking với nhiều segment
///
/// - startTracking(): bắt đầu buổi theo dõi mới, tạo segment đầu tiên
/// - pauseTracking(): dừng cập nhật, đóng segment hiện tại
/// - resumeTracking(): tạo segment MỚI, KHÔNG nối với segment cũ
/// - stopTracking(): dừng hẳn, đóng segment cuối
///
/// Khoảng cách chỉ được tính TRONG từng segment, không cộng khoảng
/// cách giữa các segment với nhau.
class GpsTrackingService {
  GpsTrackingService() {
    _stateController = StreamController<GpsTrackingState>.broadcast();
  }

  /// Ngưỡng tối thiểu để coi là có di chuyển thực sự.
  /// GPS thường dao động vài mét ngay cả khi đứng yên, nên đặt cao hơn một chút (~8–12m),
  /// nhưng không quá cao để vẫn ghi nhận được các bước chân ngắn.
  static const double _minMovementDistanceMeters = 9.0;

  /// Nếu cảm biến tốc độ báo nhỏ hơn giá trị này, coi như người dùng đang đứng yên.
  /// 0.5 m/s ~ 1.8 km/h.
  static const double _minSpeedMetersPerSecond = 0.5;

  /// Bỏ qua các điểm có độ chính xác (accuracy) quá kém để tránh jump bất thường.
  static const double _maxAcceptableAccuracyMeters = 25.0;

  // Streams
  late final StreamController<GpsTrackingState> _stateController;
  Stream<GpsTrackingState> get stateStream => _stateController.stream;

  // Nội bộ
  final List<GpsSegment> _segments = [];
  Timer? _timer;
  StreamSubscription<Position>? _positionSub;
  bool _isTracking = false;
  bool _hasStarted = false;
  Duration _activeDuration = Duration.zero;
  Position? _lastPositionInSegment;

  /// Trạng thái hiện tại (dùng một lần, không phải stream)
  GpsTrackingState get currentState {
    final startPoint = _segments.isNotEmpty && _segments.first.points.isNotEmpty
        ? _segments.first.points.first
        : null;
    final currentPoint =
        _segments.isNotEmpty && _segments.last.points.isNotEmpty
            ? _segments.last.points.last
            : null;

    return GpsTrackingState(
      isTracking: _isTracking,
      hasStarted: _hasStarted,
      totalDistanceKm: _calculateTotalDistanceKm(),
      activeDuration: _activeDuration,
      segments: List.unmodifiable(_segments),
      startPoint: startPoint,
      currentPoint: currentPoint,
    );
  }

  /// Bắt đầu buổi tracking mới
  Future<void> startTracking() async {
    final hasPermission = await _ensurePermission();
    if (!hasPermission) {
      throw Exception('Không có quyền truy cập vị trí.');
    }

    // Reset mọi thứ cho buổi tập mới
    _segments.clear();
    _activeDuration = Duration.zero;
    _isTracking = true;
    _hasStarted = true;
    _lastPositionInSegment = null;

    // Tạo segment đầu tiên (sẽ được thêm điểm khi có GPS)
    _segments.add(
      GpsSegment(
        points: [],
        startTime: DateTime.now(),
      ),
    );

    _startTimer();
    await _startPositionStream();
    _emitState();
  }

  /// Tạm dừng segment hiện tại (không huỷ buổi tập)
  Future<void> pauseTracking() async {
    if (!_isTracking) return;
    _isTracking = false;
    _timer?.cancel();
    _positionSub?.pause();

    if (_segments.isNotEmpty) {
      _segments.last.endTime ??= DateTime.now();
    }
    _emitState();
  }

  /// Tiếp tục bằng cách tạo segment mới, không nối với segment cũ
  Future<void> resumeTracking() async {
    if (_isTracking || !_hasStarted) return;

    _isTracking = true;
    _lastPositionInSegment = null; // Không nối với segment trước

    _segments.add(
      GpsSegment(
        points: [],
        startTime: DateTime.now(),
      ),
    );

    _startTimer();
    if (_positionSub == null) {
      await _startPositionStream();
    } else {
      _positionSub?.resume();
    }
    _emitState();
  }

  /// Dừng hẳn buổi tracking
  Future<void> stopTracking() async {
    _isTracking = false;
    _hasStarted = false;
    _timer?.cancel();
    await _positionSub?.cancel();
    _positionSub = null;

    if (_segments.isNotEmpty) {
      _segments.last.endTime ??= DateTime.now();
    }

    _emitState();
  }

  // Timer đếm thời gian di chuyển (chỉ khi tracking)
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isTracking) {
        _activeDuration += const Duration(seconds: 1);
        _emitState();
      }
    });
  }

  Future<void> _startPositionStream() async {
    _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        // Sử dụng high thay vì best để tiết kiệm pin
        // Vẫn đủ chính xác cho tracking nhưng không tốn pin quá nhiều
        accuracy: LocationAccuracy.high,
        // Chỉ nhận điểm mới khi thay đổi vị trí đủ lớn để coi là di chuyển.
        distanceFilter: 10,
      ),
    ).listen(_onNewPosition);
  }

  void _onNewPosition(Position position) {
    if (!_isTracking || _segments.isEmpty) return;

    final currentSegment = _segments.last;
    final point = GpsPoint(
      position: LatLng(position.latitude, position.longitude),
      timestamp: DateTime.now(),
    );

    if (_lastPositionInSegment != null) {
      final distance = Geolocator.distanceBetween(
        _lastPositionInSegment!.latitude,
        _lastPositionInSegment!.longitude,
        position.latitude,
        position.longitude,
      );

      // Bỏ qua các jump QUÁ LỚN (ví dụ > 2km trong 1 tick) vì có thể là GPS lỗi.
      if (distance > 2000) {
        return;
      }

      // Bỏ qua các điểm có sai số lớn.
      if (position.accuracy > _maxAcceptableAccuracyMeters) {
        return;
      }

      final speed = position.speed; // m/s, có thể -1 nếu không khả dụng.
      final isSpeedReliable = speed >= 0 && !speed.isNaN;
      final isMovingFastEnough =
          isSpeedReliable ? speed >= _minSpeedMetersPerSecond : false;

      // Bỏ qua các dao động nhỏ hoặc khi speed báo đứng yên.
      if (!isMovingFastEnough && distance < _minMovementDistanceMeters) {
        return;
      }
    } else {
      // Điểm đầu tiên của segment
      currentSegment.points.add(point);
      _lastPositionInSegment = position;
      _emitState();
      return;
    }

    currentSegment.points.add(point);
    _lastPositionInSegment = position;
    _emitState();
  }

  double _calculateTotalDistanceKm() {
    double totalMeters = 0;
    for (final segment in _segments) {
      if (segment.points.length < 2) continue;
      for (var i = 1; i < segment.points.length; i++) {
        final prev = segment.points[i - 1].position;
        final curr = segment.points[i].position;
        totalMeters += Geolocator.distanceBetween(
          prev.latitude,
          prev.longitude,
          curr.latitude,
          curr.longitude,
        );
      }
    }
    return totalMeters / 1000.0;
  }

  void _emitState() {
    if (_stateController.isClosed) return;
    _stateController.add(currentState);
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

  /// Reset toàn bộ trạng thái về mặc định (dùng khi Xóa buổi tập).
  Future<void> reset() async {
    _isTracking = false;
    _hasStarted = false;
    _timer?.cancel();
    await _positionSub?.cancel();
    _positionSub = null;
    _segments.clear();
    _activeDuration = Duration.zero;
    _lastPositionInSegment = null;
    _emitState();
  }

  Future<void> dispose() async {
    _timer?.cancel();
    await _positionSub?.cancel();
    await _stateController.close();
  }
}


