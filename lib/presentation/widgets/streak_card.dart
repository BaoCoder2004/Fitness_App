import 'package:flutter/material.dart';

import '../../core/services/streak_service.dart';
import '../../domain/entities/streak.dart';

class StreakCard extends StatelessWidget {
  const StreakCard({
    super.key,
    required this.streak,
    this.onTap,
    this.isWarning = false,
  });

  final Streak streak;
  final VoidCallback? onTap;
  final bool isWarning; // Cảnh báo khi sắp mất chuỗi

  @override
  Widget build(BuildContext context) {
    final hasReachedMilestone = StreakService.hasReachedMilestone(streak.currentStreak);
    final milestones = StreakService.getMilestones();
    final nextMilestone = milestones.firstWhere(
      (m) => m > streak.currentStreak,
      orElse: () => streak.currentStreak + 1,
    );
    final progress = streak.currentStreak / nextMilestone;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: hasReachedMilestone
                ? Colors.amber.withAlpha(128)
                : Theme.of(context).colorScheme.outline.withAlpha(51),
            width: hasReachedMilestone ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(30),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.local_fire_department,
                    color: Colors.orange,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chuỗi ngày',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '${streak.currentStreak} ngày',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tiến tới $nextMilestone ngày',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: Theme.of(context).colorScheme.outline.withAlpha(30),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      hasReachedMilestone ? Colors.amber : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatItem(
                  label: 'Chuỗi dài nhất',
                  value: '${streak.longestStreak}',
                ),
                _StatItem(
                  label: 'Loại mục tiêu',
                  value: _getGoalTypeName(streak.goalType),
                ),
              ],
            ),
            if (isWarning) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.red.withAlpha(51),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cảnh báo! Bạn chưa đạt mục tiêu hôm nay. Chuỗi ${streak.currentStreak} ngày có thể bị mất!',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.red.shade900,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (hasReachedMilestone) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.amber.withAlpha(51),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.celebration,
                      color: Colors.amber,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Chúc mừng! Bạn đã đạt ${streak.currentStreak} ngày liên tiếp!',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.amber.shade900,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getGoalTypeName(String goalType) {
    switch (goalType) {
      case 'distance':
        return 'Quãng đường';
      case 'calories':
        return 'Calories';
      case 'duration':
        return 'Thời gian';
      default:
        return goalType;
    }
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

