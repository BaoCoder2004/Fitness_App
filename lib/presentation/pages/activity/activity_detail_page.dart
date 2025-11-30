import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/helpers/activity_type_helper.dart';
import '../../../domain/entities/activity_session.dart';
import '../../../domain/repositories/activity_repository.dart';

class ActivityDetailPage extends StatelessWidget {
  const ActivityDetailPage({super.key, required this.session});

  final ActivitySession session;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy HH:mm');
    final duration = Duration(seconds: session.durationSeconds);
    final durationStr =
        '${duration.inHours}h ${duration.inMinutes % 60}m ${duration.inSeconds % 60}s';
    final meta = ActivityTypeHelper.resolve(session.activityType);

    return Scaffold(
      appBar: AppBar(
        title: Text(meta.displayName),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon + type
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  child: Icon(meta.icon, size: 32),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meta.displayName,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      df.format(session.date),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            // Stats
            _StatRow(label: 'Thời gian', value: durationStr),
            if (session.distanceKm != null)
              _StatRow(
                label: 'Quãng đường',
                value: '${session.distanceKm!.toStringAsFixed(2)} km',
              ),
            if (session.averageSpeed != null)
              _StatRow(
                label: 'Tốc độ TB',
                value: '${session.averageSpeed!.toStringAsFixed(1)} km/h',
              ),
            _StatRow(
              label: 'Calories',
              value: '${session.calories.toStringAsFixed(0)} kcal',
            ),
            if (session.averageHeartRate != null)
              _StatRow(
                label: 'Nhịp tim TB',
                value: '${session.averageHeartRate} bpm',
              ),
            if (session.notes != null && session.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Ghi chú',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(session.notes!),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa buổi tập?'),
        content: const Text('Bạn có chắc chắn muốn xóa buổi tập này không? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    try {
      await context.read<ActivityRepository>().deleteSession(
            userId: session.userId,
            sessionId: session.id,
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa buổi tập.')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
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

