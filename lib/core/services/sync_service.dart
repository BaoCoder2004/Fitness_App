import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SyncStatus {
  idle,
  syncing,
  success,
  error,
}

enum PendingOperationType {
  createActivity,
  updateActivity,
  deleteActivity,
  createGoal,
  updateGoal,
  deleteGoal,
  createGpsRoute,
  deleteGpsRoute,
}

class PendingOperation {
  final String id;
  final PendingOperationType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final String userId;
  final int retryCount;

  PendingOperation({
    required this.id,
    required this.type,
    required this.data,
    required this.timestamp,
    required this.userId,
    this.retryCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
      'retryCount': retryCount,
    };
  }

  factory PendingOperation.fromMap(Map<String, dynamic> map) {
    return PendingOperation(
      id: map['id'] as String,
      type: PendingOperationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => PendingOperationType.createActivity,
      ),
      data: Map<String, dynamic>.from(map['data'] as Map),
      timestamp: DateTime.parse(map['timestamp'] as String),
      userId: map['userId'] as String,
      retryCount: (map['retryCount'] as int?) ?? 0,
    );
  }

  PendingOperation copyWith({int? retryCount}) {
    return PendingOperation(
      id: id,
      type: type,
      data: data,
      timestamp: timestamp,
      userId: userId,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}

class SyncService {
  SyncService({
    Connectivity? connectivity,
    SharedPreferences? prefs,
  })  : _connectivity = connectivity ?? Connectivity(),
        _prefs = prefs;

  final Connectivity _connectivity;
  SharedPreferences? _prefs;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;
  final _statusController = StreamController<SyncStatus>.broadcast();

  Stream<SyncStatus> get statusStream => _statusController.stream;
  SyncStatus _currentStatus = SyncStatus.idle;
  SyncStatus get currentStatus => _currentStatus;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    _startConnectivityListener();
  }

  void _startConnectivityListener() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final hasConnection = results.any(
          (result) =>
              result == ConnectivityResult.mobile ||
              result == ConnectivityResult.wifi ||
              result == ConnectivityResult.ethernet,
        );
        if (hasConnection && !_isSyncing) {
          syncPendingData();
        }
      },
    );
  }

  Future<bool> hasInternetConnection() async {
    final results = await _connectivity.checkConnectivity();
    return results.any(
      (result) =>
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet,
    );
  }

  Future<void> addPendingOperation(PendingOperation operation) async {
    _prefs ??= await SharedPreferences.getInstance();
    final pendingOps = await getPendingOperations();
    pendingOps.add(operation);
    await _savePendingOperations(pendingOps);
  }

  Future<List<PendingOperation>> getPendingOperations() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final jsonString = prefs.getString('pending_operations');
    if (jsonString == null) return [];
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => PendingOperation.fromMap(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _savePendingOperations(List<PendingOperation> operations) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final jsonList = operations.map((op) => op.toMap()).toList();
    await prefs.setString('pending_operations', jsonEncode(jsonList));
  }

  Future<void> removePendingOperation(String operationId) async {
    final pendingOps = await getPendingOperations();
    pendingOps.removeWhere((op) => op.id == operationId);
    await _savePendingOperations(pendingOps);
  }

  Future<void> clearPendingOperations() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.remove('pending_operations');
  }

  Future<SyncStatus> checkSyncStatus() async {
    final pendingOps = await getPendingOperations();
    final hasConnection = await hasInternetConnection();

    if (pendingOps.isEmpty) {
      _updateStatus(SyncStatus.idle);
      return SyncStatus.idle;
    }

    if (!hasConnection) {
      _updateStatus(SyncStatus.error);
      return SyncStatus.error;
    }

    if (_isSyncing) {
      return SyncStatus.syncing;
    }

    return SyncStatus.idle;
  }

  /// Số lần retry tối đa cho mỗi operation
  static const int _maxRetries = 3;

  Future<void> syncPendingData() async {
    if (_isSyncing) return;

    final hasConnection = await hasInternetConnection();
    if (!hasConnection) {
      _updateStatus(SyncStatus.error);
      return;
    }

    final pendingOps = await getPendingOperations();
    if (pendingOps.isEmpty) {
      _updateStatus(SyncStatus.idle);
      return;
    }

    _isSyncing = true;
    _updateStatus(SyncStatus.syncing);

    try {
      // QUAN TRỌNG: Sync activities trước GPS routes để đảm bảo activityId hợp lệ
      // Sort by type first (activities before GPS routes), then by timestamp
      pendingOps.sort((a, b) {
        // Ưu tiên: createActivity > updateActivity > deleteActivity > createGpsRoute > deleteGpsRoute > others
        final aPriority = _getOperationPriority(a.type);
        final bPriority = _getOperationPriority(b.type);
        if (aPriority != bPriority) {
          return aPriority.compareTo(bPriority);
        }
        // Nếu cùng priority, sort by timestamp
        return a.timestamp.compareTo(b.timestamp);
      });

      final List<PendingOperation> failedOps = [];

      for (final operation in pendingOps) {
        try {
          // Bỏ qua nếu đã retry quá nhiều lần
          if (operation.retryCount >= _maxRetries) {
            // Có thể log hoặc thông báo cho user về operation bị lỗi
            continue;
          }

          final success = await _processOperation(operation);
          if (success) {
            await removePendingOperation(operation.id);
          } else {
            // Tăng retry count và lưu lại
            final updatedOp = operation.copyWith(retryCount: operation.retryCount + 1);
            await removePendingOperation(operation.id);
            await addPendingOperation(updatedOp);
            failedOps.add(updatedOp);
          }
        } catch (e) {
          // Tăng retry count và lưu lại
          final updatedOp = operation.copyWith(retryCount: operation.retryCount + 1);
          await removePendingOperation(operation.id);
          await addPendingOperation(updatedOp);
          failedOps.add(updatedOp);
        }
      }

      if (failedOps.isEmpty) {
        _updateStatus(SyncStatus.success);
        // Tự động ẩn thông báo thành công sau 3 giây
        Future.delayed(const Duration(seconds: 3), () {
          if (_currentStatus == SyncStatus.success) {
            _updateStatus(SyncStatus.idle);
          }
        });
        // Tự động retry sau 30 giây nếu có operations đã retry nhưng chưa thành công
        Future.delayed(const Duration(seconds: 30), () {
          if (!_isSyncing) {
            syncPendingData();
          }
        });
      } else {
        _updateStatus(SyncStatus.error);
        // Retry với exponential backoff
        final retryableOps = failedOps.where((op) => op.retryCount < _maxRetries).toList();
        if (retryableOps.isNotEmpty) {
          final delaySeconds = 5 * (1 << retryableOps.first.retryCount); // 5s, 10s, 20s
          Future.delayed(Duration(seconds: delaySeconds), () {
            if (!_isSyncing) {
              syncPendingData();
            }
          });
        }
      }
    } catch (e) {
      _updateStatus(SyncStatus.error);
    } finally {
      _isSyncing = false;
    }
  }

  // Callback functions for repositories to register their sync handlers
  final Map<PendingOperationType, Future<bool> Function(PendingOperation)> _operationHandlers = {};

  /// Get priority for operation type (lower number = higher priority)
  int _getOperationPriority(PendingOperationType type) {
    switch (type) {
      case PendingOperationType.createActivity:
        return 1;
      case PendingOperationType.updateActivity:
        return 2;
      case PendingOperationType.deleteActivity:
        return 3;
      case PendingOperationType.createGpsRoute:
        return 4;
      case PendingOperationType.deleteGpsRoute:
        return 5;
      case PendingOperationType.createGoal:
        return 6;
      case PendingOperationType.updateGoal:
        return 7;
      case PendingOperationType.deleteGoal:
        return 8;
    }
  }

  void registerOperationHandler(
    PendingOperationType type,
    Future<bool> Function(PendingOperation) handler,
  ) {
    _operationHandlers[type] = handler;
  }

  Future<bool> _processOperation(PendingOperation operation) async {
    final handler = _operationHandlers[operation.type];
    if (handler == null) return false;
    try {
      return await handler(operation);
    } catch (e) {
      return false;
    }
  }

  void _updateStatus(SyncStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    await _statusController.close();
  }
}

