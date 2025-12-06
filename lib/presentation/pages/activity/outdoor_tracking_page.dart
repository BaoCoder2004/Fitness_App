import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../domain/entities/activity_session.dart';
import '../../../domain/entities/goal.dart';
import '../../../domain/repositories/activity_repository.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/repositories/goal_repository.dart';
import '../../../core/helpers/activity_type_helper.dart';
import '../../viewmodels/outdoor_tracking_view_model.dart';
import '../../viewmodels/user_profile_view_model.dart';
import 'activity_summary_page.dart';

class OutdoorTrackingPage extends StatelessWidget {
  const OutdoorTrackingPage({super.key, required this.activityName});

  final String activityName;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OutdoorTrackingViewModel(activityType: activityName),
      child: _OutdoorTrackingView(activityName: activityName),
    );
  }
}

class _OutdoorTrackingView extends StatelessWidget {
  const _OutdoorTrackingView({required this.activityName});

  final String activityName;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OutdoorTrackingViewModel>();
    final state = vm.state;
    final userWeight =
        context.watch<UserProfileViewModel>().profile?.weightKg ?? 65.0;
    final duration = state.duration;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    return PopScope(
      canPop: !state.hasStarted,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (state.hasStarted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vui lòng Hoàn thành trước khi rời khỏi buổi tập.'),
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(activityName)),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activityName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${duration.inHours.toString().padLeft(2, '0')}:$minutes:$seconds',
                          style: Theme.of(context)
                              .textTheme
                              .displayMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          state.isTracking ? 'Đang theo dõi...' : 'Tạm dừng',
                        ),
                      ],
                    ),
                    Icon(
                      Icons.map_outlined,
                      size: 42,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _GpsMap(state: state),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _MetricTile(
                      label: 'Quãng đường',
                      value: '${state.distanceKm.toStringAsFixed(2)} km',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricTile(
                      label: 'Calories',
                      value:
                          '${_estimateCalories(state, userWeight).toStringAsFixed(1)} kcal',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricTile(
                      label: 'Tốc độ TB',
                      value: _formatAverageSpeed(state),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
                // Card mục tiêu đã được bỏ theo yêu cầu
                _buildControls(context, vm),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControls(
      BuildContext context, OutdoorTrackingViewModel trackingVm) {
    final state = trackingVm.state;
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _handlePrimaryAction(context, trackingVm),
            child: Text(
              !state.hasStarted
                  ? 'Bắt đầu'
                  : state.isTracking
                      ? 'Tạm dừng'
                      : 'Tiếp tục',
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: state.hasStarted ? () => _handleFinishFlow(context) : null,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Hoàn thành'),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Future<void> _handlePrimaryAction(
    BuildContext context,
    OutdoorTrackingViewModel vm,
  ) async {
    final state = vm.state;
    try {
      if (!state.hasStarted) {
        await vm.start();
      } else if (state.isTracking) {
        vm.pause();
      } else {
        vm.resume();
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is Exception
                ? e.toString().replaceFirst('Exception: ', '')
                : 'Không thể bắt đầu theo dõi.',
          ),
        ),
      );
    }
  }

  Future<void> _handleFinishFlow(BuildContext context) async {
    final vm = context.read<OutdoorTrackingViewModel>();
    final wasTrackingBeforeFinish = vm.state.isTracking;
    vm.pause();

    final state = vm.state;
    final userWeight =
        context.read<UserProfileViewModel>().profile?.weightKg ?? 65.0;
    final dialogResult = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Lưu buổi tập?'),
            content: Text(
                'Thời gian: ${state.duration.inMinutes} phút\nQuãng đường: ${state.distanceKm.toStringAsFixed(2)} km'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Xóa'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Lưu'),
              ),
            ],
          ),
        );

    if (dialogResult == null) {
      vm.resume();
      return;
    }

    if (!context.mounted) return;
    if (!dialogResult) {
      final confirmed = await _confirmDiscardSession(context);
      if (!context.mounted) return;
      if (!confirmed) {
        if (wasTrackingBeforeFinish) {
          vm.resume();
        }
        return;
      }
      await vm.reset();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa buổi tập.')),
      );
      return;
    }

    final user = context.read<AuthRepository>().currentUser;
    if (user == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập lại.')),
      );
      return;
    }

    final session = ActivitySession(
      id: '',
      userId: user.uid,
      activityType: ActivityTypeHelper.resolve(activityName).key,
      date: DateTime.now(),
      durationSeconds: state.duration.inSeconds,
      calories: _estimateCalories(state, userWeight),
      distanceKm: state.distanceKm,
      averageSpeed: state.averageSpeed,
      notes: null,
      createdAt: DateTime.now(),
    );

    final activityRepo = context.read<ActivityRepository>();
    final summaryResult = await Navigator.of(context)
        .push<ActivitySummaryResult>(
      MaterialPageRoute(
        builder: (_) => ActivitySummaryPage(
          session: session,
          activityRepository: activityRepo,
          gpsSegments: state.segments,
          gpsTotalDistanceKm: state.distanceKm,
          gpsActiveDurationSeconds: state.duration.inSeconds,
        ),
      ),
    );

    if (!context.mounted) return;

    if (summaryResult == ActivitySummaryResult.saved) {
      await vm.stop();
      if (!context.mounted) return;
      await _updateGoalProgress(
        context: context,
        session: session,
      );
      if (!context.mounted) return;
      Navigator.of(context).pop();
      return;
    }

    // User cancelled summary -> resume tracking with current progress intact.
    if (wasTrackingBeforeFinish) {
      await vm.resume();
    }
  }

  Future<bool> _confirmDiscardSession(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa buổi tập?'),
        content: const Text(
          'Toàn bộ dữ liệu vừa ghi lại sẽ bị mất. Bạn có chắc chắn muốn xóa?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Không'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _updateGoalProgress({
    required BuildContext context,
    required ActivitySession session,
  }) async {
    try {
      final goalRepo = context.read<GoalRepository>();
      final goals = await goalRepo.fetchGoals(
        userId: session.userId,
        status: GoalStatus.active,
      );
      if (goals.isEmpty) return;

      final resolvedActivityKey =
          ActivityTypeHelper.resolve(session.activityType).key;

      // Tìm TẤT CẢ goals phù hợp (không chỉ 1 goal)
      final matchedGoals = <Goal>[];
      for (final goal in goals) {
        // Skip weight goals
        if (goal.goalType == GoalType.weight) continue;
        
        // Check date range
        if (session.date.isBefore(goal.startDate)) continue;
        if (goal.deadline != null) {
          final d = goal.deadline!;
          final endOfDeadline =
              DateTime(d.year, d.month, d.day, 23, 59, 59);
          if (session.date.isAfter(endOfDeadline)) continue;
        }
        
        // Check activity type match
        bool activityMatch = false;
        if (goal.activityTypeFilter == null || goal.activityTypeFilter!.isEmpty) {
          // Goal không filter activity type -> match tất cả
          activityMatch = true;
        } else {
          final goalKey =
              ActivityTypeHelper.resolve(goal.activityTypeFilter).key;
          activityMatch = goalKey == resolvedActivityKey;
        }
        
        if (activityMatch) {
          matchedGoals.add(goal);
        }
      }

      if (matchedGoals.isEmpty) return;

      // Update TẤT CẢ goals phù hợp
      for (final goal in matchedGoals) {
        double increment = 0;
        switch (goal.goalType) {
          case GoalType.distance:
            increment = session.distanceKm ?? 0;
            break;
          case GoalType.calories:
            increment = session.calories;
            break;
          case GoalType.duration:
            increment = session.durationSeconds / 60.0;
            break;
          case GoalType.weight:
            increment = 0;
            break;
        }
        if (increment <= 0) continue;
        
        // Skip nếu goal đã completed và currentValue đã đạt target (không cần update nữa)
        final wasCompleted = goal.status == GoalStatus.completed;
        if (wasCompleted && goal.currentValue >= goal.targetValue) {
          // Goal đã completed, không cần update nữa
          continue;
        }

        final newCurrentValue = (goal.currentValue + increment)
            .clamp(0, goal.targetValue);

        final updatedGoal = goal.copyWith(
          currentValue: newCurrentValue.toDouble(),
          updatedAt: DateTime.now(),
          status: newCurrentValue >= goal.targetValue
              ? GoalStatus.completed
              : goal.status,
        );

        await goalRepo.updateGoal(updatedGoal);
      }
    } catch (e) {
      debugPrint('Failed to update goal progress: $e');
    }
  }

  /// Tính kcal theo công thức ACSM (chuẩn cho chạy/đi bộ) kết hợp tốc độ GPS.
  /// - Nếu chưa di chuyển: 0 kcal.
  /// - Đi bộ/chạy: dùng VO2 (mL/kg/phút) → kcal/phút = VO2 * weight / 200.
  /// - Đạp xe: dùng MET x weight x thời gian (giờ) với MET theo dải tốc độ.
  double _estimateCalories(OutdoorTrackingState state, double weightKg) {
    if (state.distanceKm <= 0 || state.duration.inSeconds == 0) return 0;

    final durationMinutes = state.duration.inSeconds / 60.0;
    final speedKmh = state.distanceKm /
        (state.duration.inHours == 0
            ? (state.duration.inSeconds / 3600.0)
            : state.duration.inHours.toDouble());

    // Nếu là đạp xe -> dùng MET theo tốc độ
    if (activityName == 'Đạp xe') {
      double met;
      if (speedKmh < 16) {
        met = 4.0; // very light
      } else if (speedKmh < 19) {
        met = 6.0;
      } else if (speedKmh < 23) {
        met = 8.0;
      } else {
        met = 10.0;
      }
      final hours = durationMinutes / 60.0;
      return met * weightKg * hours;
    }

    // Đi bộ / chạy: dùng công thức ACSM theo tốc độ (m/phút)
    final speedMPerMin = speedKmh * 1000.0 / 60.0;

    // Ngưỡng phân biệt đi bộ vs chạy ~ 7.2 km/h (120 m/phút)
    final bool isWalking = speedKmh < 7.2;

    // VO2 (mL/kg/phút)
    final vo2 = isWalking
        ? 0.1 * speedMPerMin + 3.5 // walking
        : 0.2 * speedMPerMin + 3.5; // running

    // kcal/phút = VO2 (mL/kg/phút) * weight(kg) / 200
    final kcalPerMin = vo2 * weightKg / 200.0;
    return kcalPerMin * durationMinutes;
  }

  /// Hiển thị **tốc độ trung bình km/h** dựa trên `state.averageSpeed`.
  /// - Nếu chưa di chuyển: hiển thị `0 km/h`.
  /// - Khi đứng yên (quãng đường không tăng): tốc độ sẽ giảm dần về 0.
  String _formatAverageSpeed(OutdoorTrackingState state) {
    if (state.distanceKm <= 0 || state.duration.inSeconds == 0) {
      return '0 km/h';
    }

    final speed = state.averageSpeed;
    if (speed.isNaN || speed.isInfinite) {
      return '0 km/h';
    }

    // Nếu tốc độ rất nhỏ, coi như 0 để tránh hiển thị số lẻ khó hiểu.
    if (speed.abs() < 0.1) {
      return '0 km/h';
    }

    return '${speed.toStringAsFixed(2)} km/h';
  }
}

class _GpsMap extends StatefulWidget {
  const _GpsMap({required this.state});

  final OutdoorTrackingState state;

  @override
  State<_GpsMap> createState() => _GpsMapState();
}

class _GpsMapState extends State<_GpsMap> {
  late final MapController _mapController;
  LatLng? _manualLocation;

  @override
  void didUpdateWidget(covariant _GpsMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldPoint = oldWidget.state.currentPoint?.position;
    final newPoint = widget.state.currentPoint?.position;
    if (newPoint != null &&
        (oldPoint == null ||
            oldPoint.latitude != newPoint.latitude ||
            oldPoint.longitude != newPoint.longitude)) {
      _mapController.move(newPoint, _mapController.camera.zoom);
    }
  }

  Future<void> _moveToCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng bật GPS để định vị.')),
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Ứng dụng cần quyền truy cập vị trí.')),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hãy cấp quyền vị trí trong phần Cài đặt.'),
          ),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      final latLng = LatLng(position.latitude, position.longitude);
      _mapController.move(latLng, 16);
      if (mounted) {
        setState(() {
          _manualLocation = latLng;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể xác định vị trí: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  Widget build(BuildContext context) {
    final start = widget.state.startPoint;
    final current = widget.state.currentPoint;
    final effectiveCurrent = current?.position ?? _manualLocation;
    final centerLatLng =
        effectiveCurrent ?? start?.position ?? const LatLng(21.0285, 105.8542);

    final polylines = <Polyline>[];
    for (final segment in widget.state.segments) {
      if (segment.points.length < 2) continue;
      polylines.add(
        Polyline(
          points: segment.points.map((p) => p.position).toList(),
          strokeWidth: 4,
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }

    final markers = <Marker>[];
    if (start != null) {
      markers.add(
        Marker(
          width: 40,
          height: 40,
          point: start.position,
          child: const Icon(
            Icons.location_on,
            color: Colors.blue,
            size: 32,
          ),
        ),
      );
    }
    if (effectiveCurrent != null) {
      markers.add(
        Marker(
          width: 40,
          height: 40,
          point: effectiveCurrent,
          child: const Icon(
            Icons.my_location,
            color: Colors.green,
            size: 30,
          ),
        ),
      );
    }

    return SizedBox(
      height: 320,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: centerLatLng,
                initialZoom: 15,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.fitness_app',
                ),
                if (polylines.isNotEmpty)
                  PolylineLayer(
                    polylines: polylines,
                  ),
                if (markers.isNotEmpty)
                  MarkerLayer(
                    markers: markers.map((marker) {
                      if (marker == markers.last &&
                          marker.point == effectiveCurrent) {
                        return Marker(
                          width: 32,
                          height: 32,
                          point: marker.point,
                          child: const _BlueDotMarker(),
                        );
                      }
                      return marker;
                    }).toList(),
                  ),
              ],
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Material(
                color: Colors.white.withOpacity(0.9),
                shape: const CircleBorder(),
                child: IconButton(
                  icon: const Icon(Icons.my_location),
                  onPressed: _moveToCurrentLocation,
                ),
              ),
            ),
            if (start == null && effectiveCurrent == null)
              IgnorePointer(
                ignoring: true,
                child: Container(
                  color: Colors.black.withOpacity(0.05),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _BlueDotMarker(),
                      const SizedBox(height: 8),
                      Text(
                        'Đang tìm vị trí GPS...',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BlueDotMarker extends StatelessWidget {
  const _BlueDotMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0x332196F3),
      ),
      child: Center(
        child: Container(
          width: 18,
          height: 18,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF2196F3),
          ),
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withAlpha(51),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontSize: 11),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

