import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/gps_route.dart';
import '../../domain/repositories/gps_route_repository.dart';
import '../models/gps_route_model.dart';

class FirestoreGpsRouteRepository implements GpsRouteRepository {
  FirestoreGpsRouteRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String userId) {
    return _firestore.collection('users').doc(userId).collection('gps_routes');
  }

  @override
  Future<void> saveRoute(GpsRoute route) async {
    final model = GpsRouteModel(
      id: route.id,
      userId: route.userId,
      activityId: route.activityId,
      segments: route.segments,
      totalDistanceKm: route.totalDistanceKm,
      totalDurationSeconds: route.totalDurationSeconds,
      createdAt: route.createdAt,
    );
    final data = model.toMap();

    if (route.id.isEmpty) {
      await _collection(route.userId).add(data);
    } else {
      await _collection(route.userId).doc(route.id).set(data);
    }
  }

  @override
  Future<GpsRoute?> getRouteForActivity({
    required String userId,
    required String activityId,
  }) async {
    final snapshot = await _collection(userId)
        .where('activityId', isEqualTo: activityId)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    final model = GpsRouteModel.fromDoc(snapshot.docs.first);
    return model.toEntity();
  }

  @override
  Stream<List<GpsRoute>> watchRoutes({required String userId}) {
    return _collection(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(GpsRouteModel.fromDoc)
              .map((m) => m.toEntity())
              .toList(growable: false),
        );
  }

  @override
  Future<void> deleteRoutesForActivity({
    required String userId,
    required String activityId,
  }) async {
    final snapshot = await _collection(userId)
        .where('activityId', isEqualTo: activityId)
        .get();
    if (snapshot.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}


