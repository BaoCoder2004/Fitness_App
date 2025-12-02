import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/sync_service.dart';

class SyncIndicator extends StatelessWidget {
  const SyncIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final syncService = context.watch<SyncService?>();
    if (syncService == null) return const SizedBox.shrink();

    return StreamBuilder<SyncStatus>(
      stream: syncService.statusStream,
      initialData: syncService.currentStatus,
      builder: (context, snapshot) {
        final status = snapshot.data ?? SyncStatus.idle;
        
        if (status == SyncStatus.idle) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _getStatusColor(status),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (status == SyncStatus.syncing)
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else
                Icon(
                  _getStatusIcon(status),
                  size: 12,
                  color: Colors.white,
                ),
              const SizedBox(width: 6),
              Text(
                _getStatusText(status),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(SyncStatus status) {
    switch (status) {
      case SyncStatus.syncing:
        return Colors.blue;
      case SyncStatus.success:
        return Colors.green;
      case SyncStatus.error:
        return Colors.red;
      case SyncStatus.idle:
        return Colors.transparent;
    }
  }

  IconData _getStatusIcon(SyncStatus status) {
    switch (status) {
      case SyncStatus.success:
        return Icons.check_circle;
      case SyncStatus.error:
        return Icons.error;
      default:
        return Icons.sync;
    }
  }

  String _getStatusText(SyncStatus status) {
    switch (status) {
      case SyncStatus.syncing:
        return 'Đang đồng bộ...';
      case SyncStatus.success:
        return 'Đồng bộ thành công';
      case SyncStatus.error:
        return 'Lỗi đồng bộ';
      case SyncStatus.idle:
        return '';
    }
  }
}

