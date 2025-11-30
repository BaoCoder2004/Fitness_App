import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/helpers/activity_type_helper.dart';
import '../../core/services/goal_service.dart';
import '../../domain/entities/goal.dart';
import '../../domain/repositories/goal_repository.dart';
import '../pages/goals/goal_reminder_dialog.dart';

class GoalCard extends StatelessWidget {
  const GoalCard({
    super.key,
    required this.progress,
    this.onEdit,
    this.onDelete,
  });

  final GoalProgress progress;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  Goal get goal => progress.goal;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool isCompleted = goal.status == GoalStatus.completed;
    
    // Ưu tiên hiển thị theo activityTypeFilter, nếu không có thì dùng goalType
    final activityMeta = goal.activityTypeFilter != null
        ? ActivityTypeHelper.resolve(goal.activityTypeFilter)
        : null;
    final iconData = activityMeta?.icon ?? _resolveIcon(goal.goalType);
    final displayName = activityMeta?.displayName ?? goal.goalType.displayName;
    
    final statusColor = isCompleted ? Colors.green : colorScheme.primary;
    final bool canEdit = onEdit != null && !isCompleted;
    final bool canDelete = onDelete != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isCompleted
              ? statusColor.withAlpha(80)
              : Theme.of(context).colorScheme.outline.withAlpha(50),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(iconData, color: statusColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Text(
                        isCompleted
                            ? '🎉 Đã hoàn thành'
                            : 'Đang theo dõi · ${goal.goalType.unitLabel}',
                        key: ValueKey(isCompleted),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: colorScheme.outline),
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedScale(
                scale: isCompleted ? 1 : 0,
                duration: const Duration(milliseconds: 350),
                child: Icon(
                  Icons.emoji_events,
                  color: statusColor,
                ),
              ),
              if (canEdit || canDelete)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz),
                  onSelected: (value) {
                    if (value == 'edit') onEdit?.call();
                    if (value == 'delete') onDelete?.call();
                    if (value == 'reminder') _showReminderDialog(context);
                  },
                  itemBuilder: (context) => [
                    if (canEdit)
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Chỉnh sửa'),
                      ),
                    const PopupMenuItem(
                      value: 'reminder',
                      child: Row(
                        children: [
                          Icon(Icons.notifications, size: 20),
                          SizedBox(width: 8),
                          Text('Nhắc nhở'),
                        ],
                      ),
                    ),
                    if (canDelete)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Xóa mục tiêu'),
                      ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Tiến độ',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: 0,
                end: progress.progress,
              ),
              duration: const Duration(milliseconds: 400),
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 10,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(
                    isCompleted ? Colors.green : colorScheme.primary,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Đã đạt: ${progress.currentValue.toStringAsFixed(1)} ${progress.unitLabel}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                'Mục tiêu: ${progress.targetValue.toStringAsFixed(1)} ${progress.unitLabel}',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: colorScheme.outline),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (goal.deadline != null)
            Row(
              children: [
                Icon(Icons.event, size: 16, color: colorScheme.outline),
                const SizedBox(width: 6),
                Text(
                  'Trước: ${goal.deadline!.day}/${goal.deadline!.month}/${goal.deadline!.year}',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: colorScheme.outline),
                ),
              ],
            ),
        ],
      ),
    );
  }

  IconData _resolveIcon(GoalType type) {
    switch (type) {
      case GoalType.weight:
        return Icons.monitor_weight;
      case GoalType.distance:
        return Icons.route;
      case GoalType.calories:
        return Icons.local_fire_department;
      case GoalType.duration:
        return Icons.timer;
    }
  }

  void _showReminderDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => GoalReminderDialog(
        goal: goal,
        goalRepository: context.read<GoalRepository>(),
        goalService: context.read<GoalService>(),
      ),
    ).then((updated) {
      if (updated == true) {
        // Refresh goal list if needed
        // This will be handled by the parent view model
      }
    });
  }
}
