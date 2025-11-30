import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/weight_record.dart';

class WeightRecordModel extends WeightRecord {
  const WeightRecordModel({
    required super.id,
    required super.userId,
    required super.weightKg,
    required super.recordedAt,
    required super.createdAt,
    super.note,
  });

  factory WeightRecordModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return WeightRecordModel(
      id: doc.id,
      userId: data['userId'] as String,
      weightKg: (data['weightKg'] as num).toDouble(),
      recordedAt: (data['recordedAt'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      note: data['note'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'weightKg': weightKg,
      'recordedAt': Timestamp.fromDate(recordedAt),
      'createdAt': Timestamp.fromDate(createdAt),
      'note': note,
    };
  }
}

