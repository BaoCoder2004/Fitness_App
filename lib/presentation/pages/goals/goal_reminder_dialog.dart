import 'package:flutter/material.dart';

import '../../../core/services/goal_service.dart';
import '../../../domain/entities/goal.dart';
import '../../../domain/repositories/goal_repository.dart';

class GoalReminderDialog extends StatefulWidget {
  const GoalReminderDialog({
    super.key,
    required this.goal,
    required this.goalRepository,
    required this.goalService,
  });

  final Goal goal;
  final GoalRepository goalRepository;
  final GoalService goalService;

  @override
  State<GoalReminderDialog> createState() => _GoalReminderDialogState();
}

class _GoalReminderDialogState extends State<GoalReminderDialog> {
  late bool _reminderEnabled;
  late TimeOfDay? _reminderTime;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _reminderEnabled = widget.goal.reminderEnabled;
    if (widget.goal.reminderHour != null && widget.goal.reminderMinute != null) {
      _reminderTime = TimeOfDay(
        hour: widget.goal.reminderHour!,
        minute: widget.goal.reminderMinute!,
      );
    } else {
      _reminderTime = const TimeOfDay(hour: 8, minute: 0);
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final updatedGoal = widget.goal.copyWith(
        reminderEnabled: _reminderEnabled,
        reminderHour: _reminderEnabled ? _reminderTime?.hour : null,
        reminderMinute: _reminderEnabled ? _reminderTime?.minute : null,
        updatedAt: DateTime.now(),
      );
      await widget.goalRepository.updateGoal(updatedGoal);
      // Cập nhật reminder trong GoalService
      if (_reminderEnabled && _reminderTime != null) {
        await widget.goalService.setupGoalDailyReminder(
          updatedGoal,
          false, // not completed
        );
      } else {
        await widget.goalService.cancelGoalReminder(updatedGoal.id);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể cập nhật cài đặt nhắc nhở'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nhắc nhở hàng ngày'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Bật nhắc nhở'),
              subtitle: const Text(
                'Nhận thông báo mỗi ngày để nhắc về mục tiêu',
              ),
              value: _reminderEnabled,
              onChanged: (value) {
                setState(() {
                  _reminderEnabled = value;
                  if (!value) {
                    _reminderTime = null;
                  } else {
                    _reminderTime ??= const TimeOfDay(hour: 8, minute: 0);
                  }
                });
              },
            ),
            if (_reminderEnabled) ...[
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Giờ nhắc nhở'),
                subtitle: Text(
                  _reminderTime == null
                      ? 'Chưa chọn'
                      : _reminderTime!.format(context),
                ),
                trailing: const Icon(Icons.schedule),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: _reminderTime ?? const TimeOfDay(hour: 8, minute: 0),
                    initialEntryMode: TimePickerEntryMode.dial,
                    helpText: 'Chọn giờ nhắc nhở',
                    cancelText: 'Hủy',
                    confirmText: 'Chọn',
                  );
                  if (time != null) {
                    setState(() => _reminderTime = time);
                  }
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Lưu'),
        ),
      ],
    );
  }
}

