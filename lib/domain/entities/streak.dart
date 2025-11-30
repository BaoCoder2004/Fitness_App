class Streak {
  const Streak({
    required this.id,
    required this.userId,
    required this.goalType,
    required this.currentStreak,
    required this.longestStreak,
    required this.lastDate,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String goalType; // 'distance' | 'calories' | 'duration'
  final int currentStreak; // Số ngày liên tiếp hiện tại
  final int longestStreak; // Chuỗi dài nhất từ trước
  final DateTime lastDate; // Ngày cuối cùng đạt mục tiêu
  final DateTime? updatedAt;

  Streak copyWith({
    String? id,
    String? userId,
    String? goalType,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastDate,
    DateTime? updatedAt,
  }) {
    return Streak(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      goalType: goalType ?? this.goalType,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastDate: lastDate ?? this.lastDate,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

