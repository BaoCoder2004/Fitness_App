import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/unlock_request.dart';
import '../../domain/repositories/unlock_request_repository.dart';
import '../models/unlock_request_model.dart';

class FirestoreUnlockRequestRepository implements UnlockRequestRepository {
  FirestoreUnlockRequestRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('unlock_requests');

  @override
  Future<void> createRequest(UnlockRequest request) async {
    await _collection.doc(request.id).set(
          UnlockRequestModel(request).toMap(),
        );
  }

  @override
  Stream<List<UnlockRequest>> watchAllRequests() {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_mapSnapshot);
  }

  @override
  Stream<List<UnlockRequest>> watchUserRequests(String userId) {
    return _collection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_mapSnapshot);
  }

  @override
  Future<void> updateRequestStatus({
    required String requestId,
    required String status,
    String? adminNote,
    String? processedBy,
  }) async {
    await _collection.doc(requestId).update({
      'status': status,
      'adminNote': adminNote,
      'processedBy': processedBy,
      'processedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<bool> hasPendingRequest(String userId) async {
    final snapshot = await _collection
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  @override
  Future<void> deleteRequest(String requestId) async {
    await _collection.doc(requestId).delete();
  }

  List<UnlockRequest> _mapSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs
        .map((doc) => UnlockRequestModel.fromMap(doc.id, doc.data()))
        .toList();
  }
}

