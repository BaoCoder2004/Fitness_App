import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/workout_types.dart';
import '../../../core/services/heart_rate_service.dart';
import '../../../domain/entities/activity_session.dart';
import '../../../domain/repositories/activity_repository.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../viewmodels/indoor_tracking_view_model.dart';
import '../../viewmodels/user_profile_view_model.dart';
import 'activity_summary_page.dart';

class IndoorTrackingPage extends StatelessWidget {
  const IndoorTrackingPage({super.key, required this.workoutType});

  final IndoorWorkoutType workoutType;

  @override
  Widget build(BuildContext context) {
    final weight = context.read<UserProfileViewModel>().profile?.weightKg ?? 60;
    return ChangeNotifierProvider(
      create: (_) => IndoorTrackingViewModel(
        workoutType: workoutType,
        weightKg: weight,
      ),
      child: _IndoorTrackingView(workoutType: workoutType),
    );
  }
}

class _IndoorTrackingView extends StatefulWidget {
  const _IndoorTrackingView({required this.workoutType});

  final IndoorWorkoutType workoutType;

  @override
  State<_IndoorTrackingView> createState() => _IndoorTrackingViewState();
}

class _IndoorTrackingViewState extends State<_IndoorTrackingView> {
  late HeartRateService _heartRateService;
  StreamSubscription<int>? _heartRateSubscription;
  bool _isScanning = false;
  List<ScanResult> _scanResults = [];

  @override
  void initState() {
    super.initState();
    _heartRateService = HeartRateService();
    _setupHeartRateListener();
  }

  void _setupHeartRateListener() {
    _heartRateSubscription = _heartRateService.heartRateStream.listen((heartRate) {
      if (mounted) {
        context.read<IndoorTrackingViewModel>().updateHeartRateFromDevice(heartRate);
      }
    });
  }

  @override
  void dispose() {
    _heartRateSubscription?.cancel();
    _heartRateService.stopScan();
    _heartRateService.dispose();
    super.dispose();
  }

  Future<void> _requestBluetoothPermissions() async {
    // Request Bluetooth permissions
    final status = await Permission.bluetoothScan.request();
    if (status.isDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cần quyền Bluetooth để kết nối thiết bị đo nhịp tim')),
        );
      }
      return;
    }
  }

  Future<void> _scanDevices() async {
    await _requestBluetoothPermissions();

    final isEnabled = await _heartRateService.isBluetoothEnabled();
    if (!isEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng bật Bluetooth')),
        );
      }
      return;
    }

    setState(() {
      _isScanning = true;
      _scanResults = [];
    });

    try {
      await for (final results in _heartRateService.scanDevices()) {
        if (mounted) {
          setState(() {
            _scanResults = results;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  Future<void> _connectDevice(ScanResult result) async {
    try {
      await _heartRateService.connectDevice(result.device);
      if (mounted) {
        Navigator.of(context).pop(); // Đóng dialog quét
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã kết nối: ${result.device.platformName.isNotEmpty ? result.device.platformName : result.device.remoteId}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi kết nối: $e')),
        );
      }
    }
  }

  Future<void> _showDeviceScanDialog() async {
    await _scanDevices();
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Quét thiết bị đo nhịp tim'),
            content: SizedBox(
              width: double.maxFinite,
              child: _isScanning
                  ? const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Đang quét thiết bị...'),
                      ],
                    )
                  : _scanResults.isEmpty
                      ? const Text('Không tìm thấy thiết bị nào. Vui lòng thử lại.')
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: _scanResults.length,
                          itemBuilder: (context, index) {
                            final result = _scanResults[index];
                            final deviceName = result.device.platformName.isNotEmpty
                                ? result.device.platformName
                                : result.device.remoteId.toString();
                            return ListTile(
                              leading: const Icon(Icons.favorite),
                              title: Text(deviceName),
                              subtitle: Text('RSSI: ${result.rssi}'),
                              onTap: () => _connectDevice(result),
                            );
                          },
                        ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _isScanning = false;
                    _scanResults = [];
                  });
                },
                child: const Text('Đóng'),
              ),
              if (!_isScanning)
                TextButton(
                  onPressed: () {
                    _scanDevices();
                    setDialogState(() {});
                  },
                  child: const Text('Quét lại'),
                ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<IndoorTrackingViewModel>();
    final duration = vm.activeDuration;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final isConnected = _heartRateService.isConnected;

    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return PopScope(
      canPop: !vm.hasStarted,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (vm.hasStarted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Vui lòng Hoàn thành hoặc Tạm dừng trước khi rời khỏi.'),
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(widget.workoutType.title)),
        body: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: viewInsets + 16,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - viewInsets,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 32,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withAlpha(20),
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.workoutType.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(color: Colors.black54),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '${duration.inHours.toString().padLeft(2, '0')}:$minutes:$seconds',
                                  style: Theme.of(context)
                                      .textTheme
                                      .displayMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  vm.isRunning ? 'Đang chạy' : 'Đang dừng',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                            Icon(
                              widget.workoutType.icon,
                              size: 42,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: [
                          _MetricTile(
                            label: 'Giờ hiện tại',
                            value: DateFormat.Hm().format(DateTime.now()),
                          ),
                          _MetricTile(
                            label: 'Calories',
                            value: vm.calories.toStringAsFixed(1),
                          ),
                          _MetricTile(
                            label: 'Nhịp tim',
                            value: vm.heartRate != null
                                ? '${vm.heartRate} bpm'
                                : '--:--',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Nút kết nối thiết bị đo nhịp tim
                      OutlinedButton.icon(
                        onPressed: isConnected
                            ? () async {
                                final messenger = ScaffoldMessenger.of(context);
                                await _heartRateService.disconnectDevice();
                                if (!mounted) return;
                                messenger.showSnackBar(
                                  const SnackBar(content: Text('Đã ngắt kết nối thiết bị')),
                                );
                              }
                            : _showDeviceScanDialog,
                        icon: Icon(isConnected ? Icons.bluetooth_connected : Icons.bluetooth),
                        label: Text(isConnected ? 'Ngắt kết nối' : 'Kết nối thiết bị đo nhịp tim'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isConnected
                              ? Colors.green
                              : Theme.of(context).colorScheme.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          side: BorderSide(
                            color: isConnected
                                ? Colors.green
                                : Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        onChanged: vm.updateNote,
                        decoration: InputDecoration(
                          labelText: 'Ghi chú buổi tập (tùy chọn)',
                          filled: true,
                          suffixIcon: const Icon(Icons.edit_note),
                        ),
                        maxLines: 2,
                      ),
                    const SizedBox(height: 24),
                    _buildControls(context, vm),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildControls(BuildContext context, IndoorTrackingViewModel vm) {
    final canFinish = vm.hasStarted;
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              if (!vm.hasStarted) {
                vm.start();
              } else if (vm.isRunning) {
                vm.pause();
              } else {
                vm.resume();
              }
            },
            child: Text(
              !vm.hasStarted
                  ? 'Bắt đầu'
                  : vm.isRunning
                      ? 'Tạm dừng'
                      : 'Tiếp tục',
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: canFinish ? () => _finish(context) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Hoàn thành'),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Future<void> _finish(BuildContext context) async {
    final vm = context.read<IndoorTrackingViewModel>();
    final wasRunning = vm.isRunning;
    vm.pause();

    final heartRate = vm.heartRate;
    final snapshot = vm.snapshot();
    final heartRateText =
        heartRate != null ? '\nNhịp tim TB: $heartRate bpm' : '';
    final dialogResult = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lưu buổi tập?'),
        content: Text(
          'Thời gian: ${snapshot.duration.inMinutes} phút\nKcal: ${snapshot.calories.toStringAsFixed(1)}$heartRateText',
        ),
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

    if (!context.mounted) return;
    if (dialogResult == null) {
      if (wasRunning) vm.resume();
      return;
    }
    if (!dialogResult) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
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
      if (!context.mounted) return;
      if (confirmed != true) {
        if (wasRunning) vm.resume();
        return;
      }
      vm.resetSession();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa buổi tập.')),
      );
      return;
    }

    final authRepo = context.read<AuthRepository>();
    final activityRepo = context.read<ActivityRepository>();
    final user = authRepo.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập lại.')),
      );
      return;
    }

    final session = ActivitySession(
      id: '',
      userId: user.uid,
      activityType: widget.workoutType.id,
      date: DateTime.now(),
      durationSeconds: snapshot.duration.inSeconds,
      calories: snapshot.calories,
      distanceKm: null,
      averageSpeed: null,
      notes: snapshot.note,
      averageHeartRate: heartRate,
      createdAt: DateTime.now(),
    );

    final summaryResult =
        await Navigator.of(context).push<ActivitySummaryResult>(
      MaterialPageRoute(
        builder: (_) => ActivitySummaryPage(
          session: session,
          activityRepository: activityRepo,
        ),
      ),
    );

    if (!context.mounted) return;
    if (summaryResult == ActivitySummaryResult.saved) {
      vm.resetSession();
      Navigator.of(context).pop();
    } else if (wasRunning) {
      vm.resume();
    }
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withAlpha(51),
          width: 2,
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

