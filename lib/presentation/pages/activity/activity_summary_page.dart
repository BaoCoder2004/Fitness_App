import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/helpers/activity_type_helper.dart';
import '../../../core/services/gps_tracking_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../domain/entities/activity_session.dart';
import '../../../domain/entities/goal.dart';
import '../../../domain/entities/gps_route.dart';
import '../../../domain/repositories/activity_repository.dart';
import '../../../domain/repositories/gps_route_repository.dart';
import '../../../domain/repositories/goal_repository.dart';

enum ActivitySummaryResult {
  saved,
  cancelled,
}

class ActivitySummaryPage extends StatefulWidget {
  const ActivitySummaryPage({
    super.key,
    required this.session,
    required this.activityRepository,
    this.gpsSegments,
    this.gpsTotalDistanceKm,
    this.gpsActiveDurationSeconds,
  });

  final ActivitySession session;
  final ActivityRepository activityRepository;
  final List<GpsSegment>? gpsSegments;
  final double? gpsTotalDistanceKm;
  final int? gpsActiveDurationSeconds;

  @override
  State<ActivitySummaryPage> createState() => _ActivitySummaryPageState();
}

class _ActivitySummaryPageState extends State<ActivitySummaryPage> {
  late TextEditingController _notesController;
  late int _durationSeconds;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.session.notes ?? '');
    _durationSeconds = widget.session.durationSeconds;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final duration = Duration(seconds: _durationSeconds);
    final durationStr =
        '${duration.inHours}h ${duration.inMinutes % 60}m ${duration.inSeconds % 60}s';

    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tóm tắt buổi tập'),
        automaticallyImplyLeading: false,
      ),
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
              constraints: BoxConstraints(minHeight: constraints.maxHeight - viewInsets),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ActivityTypeHelper.resolve(widget.session.activityType)
                          .displayName,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 24),
                    _StatRow(label: 'Thời gian', value: durationStr),
                    if (widget.session.distanceKm != null)
                      _StatRow(
                        label: 'Quãng đường',
                        value: '${widget.session.distanceKm!.toStringAsFixed(2)} km',
                      ),
                    if (widget.session.averageSpeed != null)
                      _StatRow(
                        label: 'Tốc độ TB',
                        value: '${widget.session.averageSpeed!.toStringAsFixed(1)} km/h',
                      ),
                    _StatRow(
                      label: 'Calories',
                      value: '${widget.session.calories.toStringAsFixed(0)} kcal',
                    ),
                    if (widget.session.averageHeartRate != null)
                      _StatRow(
                        label: 'Nhịp tim TB',
                        value: '${widget.session.averageHeartRate} bpm',
                      ),
                    const SizedBox(height: 24),
                    const Text('Ghi chú:'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        hintText: 'Nhập ghi chú (tùy chọn)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _saving
                                ? null
                                : () => Navigator.of(context)
                                    .pop(ActivitySummaryResult.cancelled),
                            child: const Text('Hủy'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saving ? null : _save,
                            child: _saving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Lưu'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    try {
      final updatedSession = ActivitySession(
        id: widget.session.id,
        userId: widget.session.userId,
        activityType: widget.session.activityType,
        date: widget.session.date,
        durationSeconds: _durationSeconds,
        calories: widget.session.calories,
        distanceKm: widget.session.distanceKm,
        averageSpeed: widget.session.averageSpeed,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        averageHeartRate: widget.session.averageHeartRate,
        createdAt: widget.session.createdAt,
      );

      // Lưu activity trước
      await widget.activityRepository.saveSession(updatedSession);
      if (!mounted) {
        setState(() => _saving = false);
        return;
      }

      // QUAN TRỌNG: Lấy ID thực tế từ Firestore sau khi save
      // Nếu session.id là empty hoặc offline ID, Firestore sẽ generate ID mới
      // Cần fetch lại activity mới nhất để lấy ID thực tế
      String activityId = updatedSession.id;
      
      // Nếu offline, dùng offline ID (sync service sẽ update sau khi có mạng)
      // Khi offline, activityId sẽ là offline ID, sync handler sẽ update GPS route sau
      if (activityId.isEmpty || activityId.startsWith('offline_')) {
        try {
          // Fetch activities trong cùng ngày để tìm activity vừa save
          final startOfDay = DateTime(
            updatedSession.date.year,
            updatedSession.date.month,
            updatedSession.date.day,
          );
          final endOfDay = startOfDay.add(const Duration(days: 1));
          
          final activitiesInDay = await widget.activityRepository.getActivitiesInRange(
            userId: updatedSession.userId,
            start: startOfDay,
            end: endOfDay,
          );
          
          // Tìm activity match: cùng date (chính xác), duration, activityType, calories
          // QUAN TRỌNG: Tìm activity gần nhất về thời gian với updatedSession.date
          ActivitySession? matchingActivity;
          Duration? bestTimeDiff;
          
          for (final a in activitiesInDay) {
            // Match date (chính xác đến phút)
            final sameDate = a.date.year == updatedSession.date.year &&
                a.date.month == updatedSession.date.month &&
                a.date.day == updatedSession.date.day &&
                a.date.hour == updatedSession.date.hour &&
                a.date.minute == updatedSession.date.minute;
            if (!sameDate) continue;
            
            // Match duration (trong vòng 5 giây)
            final sameDuration = (a.durationSeconds - updatedSession.durationSeconds).abs() <= 5;
            if (!sameDuration) continue;
            
            // Match activityType
            final sameType = a.activityType == updatedSession.activityType;
            if (!sameType) continue;
            
            // Match calories (trong vòng 5 calories) để chắc chắn hơn
            final sameCalories = (a.calories - updatedSession.calories).abs() <= 5;
            if (!sameCalories) continue;
            
            // Tính thời gian chênh lệch
            final timeDiff = (a.date.difference(updatedSession.date)).abs();
            
            // Chọn activity có thời gian gần nhất
            if (matchingActivity == null || bestTimeDiff == null || timeDiff < bestTimeDiff) {
              matchingActivity = a;
              bestTimeDiff = timeDiff;
            }
          }
          
          if (matchingActivity != null) {
            activityId = matchingActivity.id;
            print('Found saved activity with ID: $activityId (date: ${matchingActivity.date}, type: ${matchingActivity.activityType}, duration: ${matchingActivity.durationSeconds}s)');
          } else {
            print('Warning: Could not find matching activity after save. Will use offline ID and let sync service handle it.');
            print('  Looking for: date=${updatedSession.date}, type=${updatedSession.activityType}, duration=${updatedSession.durationSeconds}s, calories=${updatedSession.calories}');
            print('  Found ${activitiesInDay.length} activities in day');
            // KHÔNG dùng most recent fallback vì có thể link sai với activity khác
            // Nếu không tìm thấy, giữ nguyên offline ID, sync service sẽ xử lý khi sync
          }
        } catch (e) {
          print('Warning: Could not fetch most recent activity: $e');
          // Fallback: vẫn dùng ID cũ (có thể là offline ID, sync service sẽ xử lý)
        }
      }

      // Nếu có dữ liệu GPS thì lưu route vào collection gps_routes
      if (widget.gpsSegments != null &&
          widget.gpsSegments!.isNotEmpty &&
          widget.gpsTotalDistanceKm != null &&
          widget.gpsActiveDurationSeconds != null) {
        try {
          final gpsRepo = context.read<GpsRouteRepository>();

          final routeSegments = widget.gpsSegments!
              .map<GpsRouteSegment>(
                (s) => GpsRouteSegment(
                  points: s.points
                      .map(
                        (p) => GpsRoutePoint(
                          lat: p.position.latitude,
                          lng: p.position.longitude,
                          timestamp: p.timestamp,
                        ),
                      )
                      .toList(),
                  startTime: s.startTime,
                  endTime: s.endTime,
                ),
              )
              .toList();

          // Sử dụng thời gian bắt đầu từ segment đầu tiên thay vì DateTime.now()
          // Điều này giúp matching chính xác hơn với activity date
          final routeStartTime = routeSegments.isNotEmpty 
              ? routeSegments.first.startTime 
              : updatedSession.date;
          
          final route = GpsRoute(
            id: '',
            userId: updatedSession.userId,
            activityId: activityId,
            segments: routeSegments,
            totalDistanceKm: widget.gpsTotalDistanceKm!,
            totalDurationSeconds: widget.gpsActiveDurationSeconds!,
            createdAt: routeStartTime,
          );

          // Save GPS route
          await gpsRepo.saveRoute(route);
        } catch (e) {
          // Log lỗi nhưng vẫn tiếp tục (GPS route có thể được sync sau)
          print('Warning: Could not save GPS route: $e');
        }
      }

      if (!mounted) {
        setState(() => _saving = false);
        return;
      }

      // Check goal completions (không block nếu lỗi)
      try {
        await _checkGoalCompletions(updatedSession);
      } catch (e) {
        print('Warning: Could not check goal completions: $e');
      }

      if (!mounted) {
        setState(() => _saving = false);
        return;
      }

      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu buổi tập.')),
      );
      Navigator.of(context).pop(ActivitySummaryResult.saved);
    } catch (e) {
      setState(() => _saving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi lưu buổi tập: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _checkGoalCompletions(ActivitySession session) async {
    try {
      final goalRepository = context.read<GoalRepository>();
      final notificationService = context.read<NotificationService>();
      // Fetch tất cả goals (không filter status) để tránh lỗi Firestore index
      // Sau đó filter ở client để chỉ check active goals
      final allGoals = await goalRepository.fetchGoals(
        userId: session.userId,
        status: null,
      );
      final goals = allGoals.where((g) => g.status == GoalStatus.active).toList();
      if (goals.isEmpty) return;
      
      final resolvedActivityKey =
          ActivityTypeHelper.resolve(session.activityType).key;
      
      // Update TẤT CẢ goals phù hợp (không chỉ check completion)
      for (final goal in goals) {
        if (goal.goalType == GoalType.weight) continue;
        if (session.date.isBefore(goal.startDate)) continue;
        if (goal.deadline != null) {
          final d = goal.deadline!;
          final endOfDeadline =
              DateTime(d.year, d.month, d.day, 23, 59, 59); // bao trùm cả ngày
          if (session.date.isAfter(endOfDeadline)) {
            continue; // đã quá hạn thì không tính cho mục tiêu này
          }
        }
        
        // Check xem ngày của activity có nằm trong timeframe của goal không
        if (!_isDateInGoalTimeFrame(session.date, goal)) {
          continue; // Ngày không nằm trong timeframe của goal
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
        
        if (!activityMatch) continue;
        
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
            break;
        }
        if (increment <= 0) continue;
        
        // Skip nếu goal đã completed và currentValue đã đạt target (không cần update nữa)
        final wasCompleted = goal.status == GoalStatus.completed;
        if (wasCompleted && goal.currentValue >= goal.targetValue) {
          // Goal đã completed, không cần update nữa
          continue;
        }
        
        // Update progress cho TẤT CẢ goals phù hợp (không chỉ khi đạt target)
        final newCurrent = (goal.currentValue + increment)
            .clamp(0.0, goal.targetValue)
            .toDouble();
        
        final isNowCompleted = newCurrent >= goal.targetValue;
        
        final updatedGoal = goal.copyWith(
          currentValue: newCurrent,
          status: isNowCompleted ? GoalStatus.completed : goal.status,
          updatedAt: DateTime.now(),
        );
        await goalRepository.updateGoal(updatedGoal);
        
        // Gửi notification nếu goal vừa đạt target (chưa completed trước đó)
        if (isNowCompleted && !wasCompleted) {
          // Lấy tên hiển thị: ưu tiên activity type, nếu không có thì dùng goal type
          final goalDisplayName = goal.activityTypeFilter != null && goal.activityTypeFilter!.isNotEmpty
              ? ActivityTypeHelper.resolve(goal.activityTypeFilter).displayName
              : goal.goalType.displayName;
          await notificationService.showGoalCompletedNotification(goalDisplayName);
        }
      }
    } catch (e, stack) {
      debugPrint('Failed to check goal completion: $e');
      debugPrint(stack.toString());
    }
  }

  /// Kiểm tra xem ngày của activity có nằm trong timeframe của goal không
  /// - Daily: cùng ngày với startDate của goal
  /// - Weekly: cùng tuần với startDate của goal (tuần bắt đầu từ Thứ 2)
  /// - Monthly: cùng tháng với startDate của goal
  /// - Yearly: cùng năm với startDate của goal
  /// - Nếu timeFrame == null: return true (check theo deadline đã được xử lý ở trên)
  bool _isDateInGoalTimeFrame(DateTime activityDate, Goal goal) {
    if (goal.timeFrame == null) {
      // Nếu không có timeFrame, check theo deadline (logic cũ)
      return true;
    }

    final activityDay = DateTime(activityDate.year, activityDate.month, activityDate.day);
    final goalStartDay = DateTime(goal.startDate.year, goal.startDate.month, goal.startDate.day);

    switch (goal.timeFrame!) {
      case GoalTimeFrame.daily:
        // Cùng ngày với startDate của goal
        return activityDay.isAtSameMomentAs(goalStartDay);
      
      case GoalTimeFrame.weekly:
        // Cùng tuần với startDate của goal (tuần bắt đầu từ Thứ 2)
        final startWeekday = goal.startDate.weekday;
        final startDaysFromMonday = startWeekday == 7 ? 0 : startWeekday - 1;
        final weekStart = DateTime(
          goal.startDate.year,
          goal.startDate.month,
          goal.startDate.day - startDaysFromMonday,
        );
        final weekEnd = weekStart.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
        
        // Activity phải nằm trong khoảng từ đầu tuần đến cuối tuần của startDate
        return activityDate.isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
               activityDate.isBefore(weekEnd.add(const Duration(seconds: 1)));
      
      case GoalTimeFrame.monthly:
        // Cùng tháng với startDate của goal
        return activityDate.year == goal.startDate.year &&
               activityDate.month == goal.startDate.month;
      
      case GoalTimeFrame.yearly:
        // Cùng năm với startDate của goal
        return activityDate.year == goal.startDate.year;
    }
  }

}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
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

