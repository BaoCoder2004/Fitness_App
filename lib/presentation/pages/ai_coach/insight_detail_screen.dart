import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/ai_insight.dart';

class InsightDetailScreen extends StatelessWidget {
  const InsightDetailScreen({super.key, required this.insight});

  final AIInsight insight;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết Insight'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                _getInsightIcon(insight.insightType),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        insight.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getInsightTypeLabel(insight.insightType),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('dd/MM/yyyy HH:mm').format(insight.createdAt),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const Divider(height: 32),

            // Content
            const Text(
              'Phân tích',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              insight.content,
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),

            // Suggestions
            if (insight.suggestions.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),
              const Text(
                'Gợi ý',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...insight.suggestions.asMap().entries.map((entry) {
                final index = entry.key;
                final suggestion = entry.value;
                return _SuggestionCard(
                  index: index + 1,
                  suggestion: suggestion,
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _getInsightIcon(InsightType type) {
    IconData icon;
    Color color;

    switch (type) {
      case InsightType.weight:
        icon = Icons.monitor_weight;
        color = Colors.blue;
        break;
      case InsightType.activity:
        icon = Icons.fitness_center;
        color = Colors.green;
        break;
      case InsightType.goal:
        icon = Icons.flag;
        color = Colors.orange;
        break;
      case InsightType.gps:
        icon = Icons.route;
        color = Colors.purple;
        break;
      case InsightType.general:
        icon = Icons.insights;
        color = Colors.teal;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 32),
    );
  }

  String _getInsightTypeLabel(InsightType type) {
    switch (type) {
      case InsightType.weight:
        return 'Cân nặng';
      case InsightType.activity:
        return 'Hoạt động';
      case InsightType.goal:
        return 'Mục tiêu';
      case InsightType.gps:
        return 'GPS';
      case InsightType.general:
        return 'Tổng quát';
    }
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.index,
    required this.suggestion,
  });

  final int index;
  final Suggestion suggestion;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  '$index',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    suggestion.description,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                  if (suggestion.actionable) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Có thể áp dụng ngay',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

