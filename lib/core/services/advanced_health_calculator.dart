import '../../domain/entities/activity_session.dart';
import 'health_calculator.dart';

enum ActivityIntensity {
  sedentary,
  light,
  moderate,
  active,
  veryActive,
}

extension ActivityIntensityX on ActivityIntensity {
  double get factor {
    switch (this) {
      case ActivityIntensity.sedentary:
        return 1.2;
      case ActivityIntensity.light:
        return 1.375;
      case ActivityIntensity.moderate:
        return 1.55;
      case ActivityIntensity.active:
        return 1.725;
      case ActivityIntensity.veryActive:
        return 1.9;
    }
  }

  String get label {
    switch (this) {
      case ActivityIntensity.sedentary:
        return 'Ít vận động';
      case ActivityIntensity.light:
        return 'Vận động nhẹ';
      case ActivityIntensity.moderate:
        return 'Vận động vừa';
      case ActivityIntensity.active:
        return 'Hoạt động nhiều';
      case ActivityIntensity.veryActive:
        return 'Rất năng động';
    }
  }

  String get description {
    switch (this) {
      case ActivityIntensity.sedentary:
        return 'Chủ yếu ngồi hoặc di chuyển rất ít trong ngày.';
      case ActivityIntensity.light:
        return 'Tập nhẹ 1-2 buổi/tuần hoặc đi bộ thường xuyên.';
      case ActivityIntensity.moderate:
        return 'Tập 3-4 buổi/tuần với cường độ trung bình.';
      case ActivityIntensity.active:
        return 'Tập gần như mỗi ngày, kết hợp cardio & sức mạnh.';
      case ActivityIntensity.veryActive:
        return 'Tập luyện 2 lần/ngày hoặc công việc đòi hỏi vận động liên tục.';
    }
  }
}

class ActivityLevelSummary {
  const ActivityLevelSummary({
    required this.intensity,
    required this.totalActiveMinutes,
    required this.sessionCount,
  });

  final ActivityIntensity intensity;
  final double totalActiveMinutes;
  final int sessionCount;
}

class AdvancedHealthCalculator {
  /// Ước lượng level vận động dựa trên tổng thời gian tập trong 7 ngày gần nhất
  static ActivityLevelSummary evaluateActivityLevel(
    List<ActivitySession> activities, {
    DateTime? reference,
    Duration window = const Duration(days: 7),
  }) {
    if (activities.isEmpty) {
      return const ActivityLevelSummary(
        intensity: ActivityIntensity.sedentary,
        totalActiveMinutes: 0,
        sessionCount: 0,
      );
    }

    final now = reference ?? DateTime.now();
    final windowStart = now.subtract(window);

    double totalMinutes = 0;
    int sessions = 0;

    for (final session in activities) {
      if (!session.date.isBefore(windowStart) && !session.date.isAfter(now)) {
        totalMinutes += session.durationSeconds / 60.0;
        sessions += 1;
      }
    }

    return ActivityLevelSummary(
      intensity: _mapMinutesToIntensity(totalMinutes),
      totalActiveMinutes: totalMinutes,
      sessionCount: sessions,
    );
  }

  static ActivityIntensity _mapMinutesToIntensity(double minutes) {
    if (minutes < 60) return ActivityIntensity.sedentary;
    if (minutes < 150) return ActivityIntensity.light;
    if (minutes < 300) return ActivityIntensity.moderate;
    if (minutes < 450) return ActivityIntensity.active;
    return ActivityIntensity.veryActive;
  }

  static double calculateBMR({
    required double weightKg,
    required double heightCm,
    required int age,
    required bool isMale,
  }) {
    return HealthCalculator.calculateBMR(
      weightKg: weightKg,
      heightCm: heightCm,
      age: age,
      isMale: isMale,
    );
  }

  static double calculateTDEE({
    required double bmr,
    required ActivityIntensity intensity,
  }) {
    return HealthCalculator.calculateTDEE(
      bmr: bmr,
      activityFactor: intensity.factor,
    );
  }
}
