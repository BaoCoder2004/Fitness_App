import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/weight_record.dart';
import '../../domain/repositories/weight_history_repository.dart';
import '../models/weight_record_model.dart';

class FirestoreWeightHistoryRepository implements WeightHistoryRepository {
  FirestoreWeightHistoryRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String userId) =>
      _firestore.collection('users').doc(userId).collection('weight_history');

  @override
  Stream<List<WeightRecord>> watchRecords(String userId) {
    return _collection(userId)
        .orderBy('recordedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => WeightRecordModel.fromDoc(doc))
              .toList(),
        );
  }

  @override
  Future<void> addRecord({
    required String userId,
    required double weightKg,
    required DateTime recordedAt,
    String? note,
  }) {
    final model = WeightRecordModel(
      id: '',
      userId: userId,
      weightKg: weightKg,
      recordedAt: recordedAt,
      createdAt: DateTime.now(),
      note: note,
    );
    final data = model.toMap();
    data.remove('id');
    return _collection(userId).add(data);
  }
}

