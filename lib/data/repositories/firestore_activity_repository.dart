import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/activity_session.dart';
import '../../domain/repositories/activity_repository.dart';
import '../models/activity_session_model.dart';

class FirestoreActivityRepository implements ActivityRepository {
  FirestoreActivityRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String userId) =>
      _firestore.collection('users').doc(userId).collection('activities');

  @override
  Stream<List<ActivitySession>> watchActivitiesOfDay({
    required String userId,
    required DateTime day,
  }) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));

    return _collection(userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(ActivitySessionModel.fromDoc)
              .toList(growable: false),
        );
  }

  @override
  Future<ActivitySession?> fetchMostRecentActivity(String userId) async {
    final snapshot = await _collection(userId)
        .orderBy('date', descending: true)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return ActivitySessionModel.fromDoc(snapshot.docs.first);
  }

  @override
  Future<void> saveSession(ActivitySession session) {
    final model = ActivitySessionModel(
      id: session.id,
      userId: session.userId,
      activityType: session.activityType,
      date: session.date,
      durationSeconds: session.durationSeconds,
      calories: session.calories,
      distanceKm: session.distanceKm,
      averageSpeed: session.averageSpeed,
      notes: session.notes,
      createdAt: session.createdAt ?? DateTime.now(),
    );
    final data = model.toMap();
    data.removeWhere((key, value) => value == null);
    if (session.id.isEmpty) {
      return _collection(session.userId).add(data);
    }
    return _collection(session.userId).doc(session.id).set(data);
  }

  @override
  Future<List<ActivitySession>> getActivitiesInRange({
    required String userId,
    required DateTime start,
    required DateTime end,
  }) async {
    final snapshot = await _collection(userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .orderBy('date', descending: true)
        .get();
    return snapshot.docs
        .map(ActivitySessionModel.fromDoc)
        .toList(growable: false);
  }

  @override
  Future<ActivitySession?> getActivityById({
    required String oderId,
    required String sessionId,
  }) async {
    final doc = await _collection(oderId).doc(sessionId).get();
    if (!doc.exists) return null;
    return ActivitySessionModel.fromDoc(doc);
  }

  @override
  Future<void> deleteSession({
    required String userId,
    required String sessionId,
  }) {
    return _collection(userId).doc(sessionId).delete();
  }
}

