import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/helpers/activity_type_helper.dart';
import '../../../core/services/notification_service.dart';
import '../../../domain/entities/activity_session.dart';
import '../../../domain/entities/goal.dart';
import '../../../domain/repositories/activity_repository.dart';
import '../../../domain/repositories/goal_repository.dart';

class ActivitySummaryPage extends StatefulWidget {
  const ActivitySummaryPage({
    super.key,
    required this.session,
    required this.activityRepository,
  });

  final ActivitySession session;
  final ActivityRepository activityRepository;

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
                            onPressed:
                                _saving ? null : () => Navigator.of(context).pop(false),
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

    await widget.activityRepository.saveSession(updatedSession);
    if (!mounted) return;
    await _checkGoalCompletions(updatedSession);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã lưu buổi tập.')),
    );
    Navigator.of(context).pop(true);
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
        final newCurrent = goal.currentValue + increment;
        if (newCurrent + 1e-6 < goal.targetValue) continue;
        final updatedGoal = goal.copyWith(
          currentValue: newCurrent,
          status: GoalStatus.completed,
          updatedAt: DateTime.now(),
        );
        await goalRepository.updateGoal(updatedGoal);
        // Lấy tên hiển thị: ưu tiên activity type, nếu không có thì dùng goal type
        final goalDisplayName = goal.activityTypeFilter != null && goal.activityTypeFilter!.isNotEmpty
            ? ActivityTypeHelper.resolve(goal.activityTypeFilter).displayName
            : goal.goalType.displayName;
        await notificationService.showGoalCompletedNotification(goalDisplayName);
      }
    } catch (e, stack) {
      debugPrint('Failed to check goal completion: $e');
      debugPrint(stack.toString());
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

