import '../../domain/entities/goal.dart';
import '../../domain/repositories/goal_repository.dart';
import '../../domain/repositories/user_profile_repository.dart';
import 'data_analyzer.dart';

/// Service tổng hợp dữ liệu người dùng thành text context cho AI
class DataSummarizer {
  DataSummarizer({
    required DataAnalyzer dataAnalyzer,
    required UserProfileRepository userProfileRepository,
    required GoalRepository goalRepository,
  })  : _dataAnalyzer = dataAnalyzer,
        _userProfileRepository = userProfileRepository,
        _goalRepository = goalRepository;

  final DataAnalyzer _dataAnalyzer;
  final UserProfileRepository _userProfileRepository;
  final GoalRepository _goalRepository;

  /// Tổng hợp tất cả dữ liệu của user thành text context
  Future<String> summarizeUserData(String userId, {int days = 30}) async {
    final buffer = StringBuffer();

    // 1. Thông tin cơ bản của user
    final profile = await _userProfileRepository.fetchProfile(userId);
    if (profile != null) {
      buffer.writeln('=== THÔNG TIN NGƯỜI DÙNG ===');
      buffer.writeln('Tên: ${profile.name}');
      if (profile.age != null) buffer.writeln('Tuổi: ${profile.age}');
      if (profile.heightCm != null) {
        buffer.writeln('Chiều cao: ${profile.heightCm} cm');
      }
      if (profile.weightKg != null) {
        buffer.writeln('Cân nặng hiện tại: ${profile.weightKg} kg');
      }
      if (profile.gender != null) {
        buffer.writeln('Giới tính: ${profile.gender}');
      }
      buffer.writeln();
    }

    // 2. Mục tiêu hiện tại
    try {
      final goals = await _goalRepository.fetchGoals(
        userId: userId,
        status: GoalStatus.active,
      );
      if (goals.isNotEmpty) {
        buffer.writeln('=== MỤC TIÊU HIỆN TẠI ===');
        for (final goal in goals) {
          buffer.write('- ${_formatGoal(goal)}');
          buffer.writeln();
        }
        buffer.writeln();
      }
    } catch (e) {
      // Không có mục tiêu hoặc lỗi
    }

    // 3. Phân tích xu hướng cân nặng
    try {
      final weightAnalysis = await _dataAnalyzer.analyzeWeightTrend(userId, days);
      buffer.writeln('=== PHÂN TÍCH CÂN NẶNG (${days} ngày gần nhất) ===');
      buffer.writeln('Xu hướng: ${_translateTrend(weightAnalysis.trend)}');
      buffer.writeln('Cân nặng hiện tại: ${weightAnalysis.currentWeight.toStringAsFixed(1)} kg');
      if (weightAnalysis.previousWeight != null) {
        buffer.writeln(
            'Cân nặng trước đó: ${weightAnalysis.previousWeight!.toStringAsFixed(1)} kg');
      }
      if (weightAnalysis.weightChange != null) {
        final change = weightAnalysis.weightChange!;
        buffer.writeln(
            'Thay đổi: ${change > 0 ? '+' : ''}${change.toStringAsFixed(1)} kg');
      }
      if (weightAnalysis.weightChangePerWeek != null) {
        buffer.writeln(
            'Tốc độ thay đổi: ${weightAnalysis.weightChangePerWeek!.toStringAsFixed(2)} kg/tuần');
      }
      if (weightAnalysis.targetWeight != null) {
        buffer.writeln('Mục tiêu: ${weightAnalysis.targetWeight!.toStringAsFixed(1)} kg');
      }
      if (weightAnalysis.isOnTrack != null) {
        buffer.writeln(
            'Tình trạng: ${weightAnalysis.isOnTrack! ? "Đang đúng hướng" : "Chưa đúng hướng"}');
      }
      buffer.writeln();
    } catch (e) {
      buffer.writeln('=== PHÂN TÍCH CÂN NẶNG ===');
      buffer.writeln('Không có đủ dữ liệu để phân tích.');
      buffer.writeln();
    }

    // 4. Phân tích mức độ hoạt động
    try {
      final activityAnalysis =
          await _dataAnalyzer.analyzeActivityLevel(userId, days);
      buffer.writeln('=== PHÂN TÍCH HOẠT ĐỘNG (${days} ngày gần nhất) ===');
      buffer.writeln('Tổng số buổi tập: ${activityAnalysis.totalSessions}');
      buffer.writeln(
          'Tần suất: ${activityAnalysis.sessionsPerWeek.toStringAsFixed(1)} buổi/tuần');
      buffer.writeln(
          'Tổng calories: ${activityAnalysis.totalCalories.toStringAsFixed(0)} kcal');
      buffer.writeln(
          'Tổng quãng đường: ${activityAnalysis.totalDistanceKm.toStringAsFixed(1)} km');
      buffer.writeln(
          'Tổng thời gian: ${_formatDuration(activityAnalysis.totalDurationSeconds)}');
      if (activityAnalysis.activityChange != null) {
        final change = activityAnalysis.activityChange!;
        buffer.writeln(
            'So với tuần trước: ${change > 0 ? '+' : ''}${change.toStringAsFixed(1)}%');
      }
      buffer.writeln();
    } catch (e) {
      buffer.writeln('=== PHÂN TÍCH HOẠT ĐỘNG ===');
      buffer.writeln('Không có đủ dữ liệu để phân tích.');
      buffer.writeln();
    }

    // 5. Phân tích thói quen tập luyện
    try {
      final habitsAnalysis =
          await _dataAnalyzer.analyzeWorkoutHabits(userId, days);
      if (habitsAnalysis.favoriteActivityType.isNotEmpty) {
        buffer.writeln('=== THÓI QUEN TẬP LUYỆN (${days} ngày gần nhất) ===');
        buffer.writeln(
            'Loại hoạt động yêu thích: ${_translateActivityType(habitsAnalysis.favoriteActivityType)}');
        buffer.writeln(
            'Ngày tập nhiều nhất: ${_translateDayOfWeek(habitsAnalysis.mostActiveDayOfWeek)}');
        buffer.writeln(
            'Thời gian tập thường xuyên: ${_translateTimeOfDay(habitsAnalysis.mostActiveTimeOfDay)}');
        if (habitsAnalysis.activityTypeDistribution.isNotEmpty) {
          buffer.writeln('Phân bố loại hoạt động:');
          for (final entry in habitsAnalysis.activityTypeDistribution.entries) {
            buffer.writeln(
                '  - ${_translateActivityType(entry.key)}: ${entry.value} buổi');
          }
        }
        buffer.writeln();
      }
    } catch (e) {
      // Không có dữ liệu
    }

    // 6. Phân tích dữ liệu GPS
    try {
      final gpsAnalysis = await _dataAnalyzer.analyzeGPSData(userId, days);
      if (gpsAnalysis.totalRoutes > 0) {
        buffer.writeln('=== PHÂN TÍCH GPS (${days} ngày gần nhất) ===');
        buffer.writeln('Tổng số buổi có GPS: ${gpsAnalysis.totalRoutes}');
        buffer.writeln(
            'Quãng đường trung bình: ${gpsAnalysis.averageDistanceKm.toStringAsFixed(1)} km/buổi');
        buffer.writeln(
            'Tốc độ trung bình: ${gpsAnalysis.averageSpeedKmh.toStringAsFixed(1)} km/h');
        buffer.writeln(
            'Thời gian trung bình: ${_formatDuration(gpsAnalysis.averageDurationSeconds)}');
        if (gpsAnalysis.speedImprovement != null) {
          final improvement = gpsAnalysis.speedImprovement!;
          buffer.writeln(
              'Cải thiện tốc độ: ${improvement > 0 ? '+' : ''}${improvement.toStringAsFixed(1)}%');
        }
        if (gpsAnalysis.distanceImprovement != null) {
          final improvement = gpsAnalysis.distanceImprovement!;
          buffer.writeln(
              'Cải thiện quãng đường: ${improvement > 0 ? '+' : ''}${improvement.toStringAsFixed(1)}%');
        }
        buffer.writeln();
      }
    } catch (e) {
      // Không có dữ liệu GPS
    }

    return buffer.toString();
  }

  String _formatGoal(goal) {
    final type = _translateGoalType(goal.goalType);
    final direction = goal.direction == 'increase'
        ? 'tăng'
        : goal.direction == 'decrease'
            ? 'giảm'
            : '';
    return '$type: ${direction.isNotEmpty ? "$direction " : ""}${goal.currentValue.toStringAsFixed(1)}/${goal.targetValue.toStringAsFixed(1)}';
  }

  String _translateGoalType(goalType) {
    switch (goalType.toString()) {
      case 'GoalType.weight':
        return 'Cân nặng';
      case 'GoalType.distance':
        return 'Quãng đường';
      case 'GoalType.calories':
        return 'Calories';
      case 'GoalType.duration':
        return 'Thời gian';
      default:
        return goalType.toString();
    }
  }

  String _translateTrend(String trend) {
    switch (trend) {
      case 'increasing':
        return 'Đang tăng';
      case 'decreasing':
        return 'Đang giảm';
      case 'stable':
        return 'Ổn định';
      default:
        return trend;
    }
  }

  String _translateActivityType(String type) {
    switch (type.toLowerCase()) {
      case 'running':
        return 'Chạy bộ';
      case 'walking':
        return 'Đi bộ';
      case 'cycling':
        return 'Đạp xe';
      case 'swimming':
        return 'Bơi lội';
      case 'gym':
        return 'Tập gym';
      case 'yoga':
        return 'Yoga';
      case 'other':
        return 'Khác';
      default:
        return type;
    }
  }

  String _translateDayOfWeek(int day) {
    // 0 = Monday, 6 = Sunday
    const days = [
      'Thứ 2',
      'Thứ 3',
      'Thứ 4',
      'Thứ 5',
      'Thứ 6',
      'Thứ 7',
      'Chủ nhật'
    ];
    return days[day];
  }

  String _translateTimeOfDay(String time) {
    switch (time) {
      case 'morning':
        return 'Buổi sáng (5h-12h)';
      case 'afternoon':
        return 'Buổi chiều (12h-17h)';
      case 'evening':
        return 'Buổi tối (17h+)';
      default:
        return time;
    }
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return '$hours giờ ${minutes > 0 ? "$minutes phút" : ""}';
    } else {
      return '$minutes phút';
    }
  }
}

