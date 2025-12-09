import 'package:uuid/uuid.dart';

import '../../domain/entities/unlock_request.dart';
import '../../domain/repositories/unlock_request_repository.dart';

class UnlockRequestService {
  UnlockRequestService({
    required UnlockRequestRepository unlockRequestRepository,
  }) : _repo = unlockRequestRepository;

  final UnlockRequestRepository _repo;
  final _uuid = const Uuid();

  Future<bool> submitUnlockRequest({
    required String userId,
    required String email,
    required String name,
    String? reason,
  }) async {
    final request = UnlockRequest(
      id: _uuid.v4(),
      userId: userId,
      userEmail: email,
      userName: name,
      reason: reason,
      status: 'pending',
      createdAt: DateTime.now().toUtc(),
    );
    await _repo.createRequest(request);
    return true;
  }

  Future<bool> submitUnlockRequestByEmail({
    required String email,
    required String name,
    String? reason,
  }) async {
    final request = UnlockRequest(
      id: _uuid.v4(),
      userId: '', // sẽ được admin tìm/điền sau
      userEmail: email,
      userName: name,
      reason: reason,
      status: 'pending',
      createdAt: DateTime.now().toUtc(),
    );
    await _repo.createRequest(request);
    return true;
  }

  Future<bool> hasPendingRequest(String userId) {
    return _repo.hasPendingRequest(userId);
  }
}

