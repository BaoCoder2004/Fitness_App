import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/streak.dart';
import '../../domain/repositories/streak_repository.dart';
import '../models/streak_model.dart';

class FirestoreStreakRepository implements StreakRepository {
  FirestoreStreakRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String userId) =>
      _firestore.collection('users').doc(userId).collection('streaks');

  @override
  Future<Streak?> getStreak({
    required String userId,
    required String goalType,
  }) async {
    final snapshot = await _collection(userId)
        .where('goalType', isEqualTo: goalType)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return StreakModel.fromDoc(snapshot.docs.first).toEntity();
  }

  @override
  Future<void> saveStreak(Streak streak) async {
    final model = StreakModel.fromEntity(streak);
    final data = model.toMap();
    data.remove('id');

    if (streak.id.isEmpty) {
      // Tạo mới
      await _collection(streak.userId).add(data);
    } else {
      // Cập nhật
      await _collection(streak.userId).doc(streak.id).set(data);
    }
  }

  @override
  Future<void> deleteStreak({
    required String userId,
    required String streakId,
  }) async {
    await _collection(userId).doc(streakId).delete();
  }

  @override
  Stream<List<Streak>> watchStreaks(String userId) {
    return _collection(userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => StreakModel.fromDoc(doc).toEntity())
              .toList(),
        );
  }
}

