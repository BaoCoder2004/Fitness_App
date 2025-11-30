import 'package:flutter/material.dart';

import '../../core/services/health_calculator.dart';

class BMICard extends StatelessWidget {
  const BMICard({
    super.key,
    required this.bmi,
    this.weightKg,
    this.heightCm,
  });

  final double bmi;
  final double? weightKg;
  final double? heightCm;

  @override
  Widget build(BuildContext context) {
    if (bmi <= 0) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withAlpha(51),
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.info_outline,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              'Chưa có thông tin',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Vui lòng cập nhật cân nặng và chiều cao trong hồ sơ',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final category = HealthCalculator.getBMICategory(bmi);
    final categoryName = HealthCalculator.getBMICategoryName(category);
    final categoryColor = Color(HealthCalculator.getBMICategoryColor(category));
    final isAbnormal = HealthCalculator.isBMIAbnormal(bmi);
    final advice = HealthCalculator.getBMIAdvice(category);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isAbnormal
              ? categoryColor.withAlpha(128)
              : Theme.of(context).colorScheme.outline.withAlpha(51),
          width: isAbnormal ? 2 : 1,
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
                  color: categoryColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.monitor_weight,
                  color: categoryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BMI',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      bmi.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: categoryColor,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: categoryColor.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getCategoryIcon(category),
                  size: 16,
                  color: categoryColor,
                ),
                const SizedBox(width: 6),
                Text(
                  categoryName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: categoryColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          if (isAbnormal) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: categoryColor.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: categoryColor.withAlpha(51),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: categoryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      advice,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: categoryColor,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getCategoryIcon(BMICategory category) {
    switch (category) {
      case BMICategory.underweight:
        return Icons.trending_down;
      case BMICategory.normal:
        return Icons.check_circle;
      case BMICategory.overweight:
        return Icons.trending_up;
      case BMICategory.obese:
        return Icons.warning;
    }
  }
}

