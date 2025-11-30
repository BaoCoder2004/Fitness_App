import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/user_profile_view_model.dart';

class WeightHistoryPage extends StatelessWidget {
  const WeightHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('dd/MM/yyyy HH:mm');
    final viewModel = context.watch<UserProfileViewModel>();
    final records = viewModel.weightHistory;

    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử cân nặng')),
      body: records.isEmpty
          ? const Center(
              child: Text('Chưa có bản ghi cân nặng nào.'),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final record = records[index];
                return ListTile(
                  leading: const Icon(Icons.monitor_weight),
                  title: Text('${record.weightKg.toStringAsFixed(1)} kg'),
                  subtitle: Text(dateFormatter.format(record.recordedAt)),
                );
              },
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemCount: records.length,
            ),
    );
  }
}

