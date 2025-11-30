import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/streak.dart';

class StreakModel {
  StreakModel({
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
  final String goalType;
  final int currentStreak;
  final int longestStreak;
  final DateTime lastDate;
  final DateTime? updatedAt;

  factory StreakModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return StreakModel(
      id: doc.id,
      userId: data['userId'] as String,
      goalType: data['goalType'] as String,
      currentStreak: (data['currentStreak'] as num).toInt(),
      longestStreak: (data['longestStreak'] as num).toInt(),
      lastDate: (data['lastDate'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'goalType': goalType,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastDate': Timestamp.fromDate(lastDate),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  Streak toEntity() {
    return Streak(
      id: id,
      userId: userId,
      goalType: goalType,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      lastDate: lastDate,
      updatedAt: updatedAt,
    );
  }

  static StreakModel fromEntity(Streak streak) {
    return StreakModel(
      id: streak.id,
      userId: streak.userId,
      goalType: streak.goalType,
      currentStreak: streak.currentStreak,
      longestStreak: streak.longestStreak,
      lastDate: streak.lastDate,
      updatedAt: streak.updatedAt,
    );
  }
}

