import 'package:flutter/material.dart';

class OutdoorTrackingPlaceholderPage extends StatelessWidget {
  const OutdoorTrackingPlaceholderPage({super.key, required this.activityName});

  final String activityName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(activityName)),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Chức năng GPS Tracking nâng cao sẽ được triển khai ở Plan 4.\n'
            'Hiện tại bạn có thể tập hoạt động tại nhà để ghi lại dữ liệu.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

