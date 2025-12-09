import '../entities/unlock_request.dart';

abstract class UnlockRequestRepository {
  Future<void> createRequest(UnlockRequest request);

  Stream<List<UnlockRequest>> watchAllRequests();

  Stream<List<UnlockRequest>> watchUserRequests(String userId);

  Future<void> updateRequestStatus({
    required String requestId,
    required String status, // pending | approved | rejected
    String? adminNote,
    String? processedBy,
  });

  Future<bool> hasPendingRequest(String userId);

  Future<void> deleteRequest(String requestId);
}

