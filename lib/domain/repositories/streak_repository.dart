import '../entities/streak.dart';

abstract class StreakRepository {
  /// Lấy streak của user theo goalType
  Future<Streak?> getStreak({
    required String userId,
    required String goalType,
  });

  /// Lưu hoặc cập nhật streak
  Future<void> saveStreak(Streak streak);

  /// Xóa streak
  Future<void> deleteStreak({
    required String userId,
    required String streakId,
  });

  /// Lấy tất cả streaks của user
  Stream<List<Streak>> watchStreaks(String userId);
}

