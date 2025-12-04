import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/ai_insight.dart';
import '../../domain/repositories/ai_insight_repository.dart';
import '../models/ai_insight_model.dart';

class FirestoreAIInsightRepository implements AIInsightRepository {
  FirestoreAIInsightRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String userId) =>
      _firestore.collection('users').doc(userId).collection('ai_insights');

  @override
  Future<void> saveInsight(AIInsight insight) async {
    final model = AIInsightModel.fromEntity(insight);
    final data = model.toMap();
    data.remove('id'); // Remove id before saving

    if (insight.id.isEmpty) {
      // Tạo mới
      await _collection(insight.userId).add(data);
    } else {
      // Cập nhật
      await _collection(insight.userId).doc(insight.id).set(data);
    }
  }

  @override
  Future<List<AIInsight>> getInsights(String userId) async {
    final snapshot = await _collection(userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => AIInsightModel.fromDoc(doc).toEntity())
        .toList();
  }

  @override
  Stream<List<AIInsight>> watchInsights(String userId) {
    return _collection(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AIInsightModel.fromDoc(doc).toEntity())
            .toList());
  }

  @override
  Future<AIInsight?> getInsightById(String userId, String insightId) async {
    final doc = await _collection(userId).doc(insightId).get();
    if (!doc.exists) return null;
    return AIInsightModel.fromDoc(doc).toEntity();
  }

  @override
  Future<void> deleteInsight(String userId, String insightId) async {
    await _collection(userId).doc(insightId).delete();
  }

  @override
  Future<List<AIInsight>> getInsightsByType(
    String userId,
    InsightType type,
  ) async {
    final typeString = _insightTypeToString(type);
    final snapshot = await _collection(userId)
        .where('insightType', isEqualTo: typeString)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => AIInsightModel.fromDoc(doc).toEntity())
        .toList();
  }

  static String _insightTypeToString(InsightType type) {
    switch (type) {
      case InsightType.weight:
        return 'weight';
      case InsightType.activity:
        return 'activity';
      case InsightType.goal:
        return 'goal';
      case InsightType.gps:
        return 'gps';
      case InsightType.general:
        return 'general';
    }
  }
}

