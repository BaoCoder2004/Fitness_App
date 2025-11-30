import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../domain/entities/activity_session.dart';
import '../../../domain/repositories/activity_repository.dart';
import '../../../domain/repositories/auth_repository.dart';
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
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 28,
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
                    Icon(Icons.map_outlined,
                        size: 42, color: Theme.of(context).colorScheme.primary),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _MetricTile(
                    label: 'Quãng đường',
                    value: '${state.distanceKm.toStringAsFixed(2)} km',
                  ),
                  _MetricTile(
                    label: 'Calories',
                    value:
                        '${_estimateCalories(state, userWeight).toStringAsFixed(0)} kcal',
                  ),
                  _MetricTile(
                    label: 'Tốc độ/km',
                    value: _formatPace(state),
                  ),
                ],
              ),
              const Spacer(),
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
            onPressed: state.hasStarted ? () => _finish(context) : null,
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

  Future<void> _finish(BuildContext context) async {
    final vm = context.read<OutdoorTrackingViewModel>();
    vm.pause();

    final state = vm.state;
    final userWeight =
        context.read<UserProfileViewModel>().profile?.weightKg ?? 65.0;
    final shouldSave = await showDialog<bool>(
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
        ) ??
        false;

    if (!context.mounted) return;
    if (!shouldSave) {
      vm.stop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa buổi tập.')),
      );
      return;
    }

    final user = context.read<AuthRepository>().currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập lại.')),
      );
      return;
    }

    final session = ActivitySession(
      id: '',
      userId: user.uid,
      activityType: activityName,
      date: DateTime.now(),
      durationSeconds: state.duration.inSeconds,
      calories: _estimateCalories(state, userWeight),
      distanceKm: state.distanceKm,
      averageSpeed: state.averageSpeed,
      notes: null,
      createdAt: DateTime.now(),
    );

    final activityRepo = context.read<ActivityRepository>();
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ActivitySummaryPage(
          session: session,
          activityRepository: activityRepo,
        ),
      ),
    );

    if (!context.mounted) return;
    if (saved == true) {
      Navigator.of(context).pop();
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

  String _formatPace(OutdoorTrackingState state) {
    if (state.distanceKm <= 0) {
      return '--';
    }
    final paceMinutes = state.duration.inSeconds / 60 / state.distanceKm;
    final minutes = paceMinutes.floor();
    final seconds = ((paceMinutes - minutes) * 60).round();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
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
            style: Theme.of(context).textTheme.bodySmall,
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
