import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/unlock_request.dart';

class UnlockRequestModel {
  const UnlockRequestModel(this.request);

  final UnlockRequest request;

  Map<String, dynamic> toMap() {
    return {
      'userId': request.userId,
      'userEmail': request.userEmail,
      'userName': request.userName,
      'reason': request.reason,
      'status': request.status,
      'createdAt': request.createdAt.toUtc(),
      'processedAt': request.processedAt?.toUtc(),
      'processedBy': request.processedBy,
      'adminNote': request.adminNote,
    };
  }

  static UnlockRequest fromMap(String id, Map<String, dynamic> data) {
    DateTime? _toDate(dynamic raw) {
      if (raw is Timestamp) return raw.toDate();
      if (raw is DateTime) return raw;
      return DateTime.tryParse(raw?.toString() ?? '');
    }

    final createdAt = _toDate(data['createdAt']) ?? DateTime.now();
    final processedAt = _toDate(data['processedAt']);

    return UnlockRequest(
      id: id,
      userId: (data['userId'] ?? '') as String,
      userEmail: (data['userEmail'] ?? '') as String,
      userName: (data['userName'] ?? '') as String,
      reason: data['reason'] as String?,
      status: (data['status'] ?? 'pending') as String,
      createdAt: createdAt.toUtc(),
      processedAt: processedAt?.toUtc(),
      processedBy: data['processedBy'] as String?,
      adminNote: data['adminNote'] as String?,
    );
  }
}
