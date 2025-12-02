import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/services/local_storage_service.dart';
import '../../core/services/sync_service.dart';
import '../../domain/entities/goal.dart';
import '../../domain/repositories/goal_repository.dart';
import '../models/goal_model.dart';

class FirestoreGoalRepository implements GoalRepository {
  FirestoreGoalRepository({
    FirebaseFirestore? firestore,
    SyncService? syncService,
    LocalStorageService? localStorageService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _syncService = syncService,
        _localStorage = localStorageService ?? LocalStorageService();

  final FirebaseFirestore _firestore;
  final SyncService? _syncService;
  final LocalStorageService _localStorage;

  CollectionReference<Map<String, dynamic>> _collection(String userId) =>
      _firestore.collection('users').doc(userId).collection('goals');

  @override
  Future<void> createGoal(Goal goal) async {
    final model = GoalModel(
      id: '',
      userId: goal.userId,
      goalType: goal.goalType,
      targetValue: goal.targetValue,
      currentValue: goal.currentValue,
      startDate: goal.startDate,
      deadline: goal.deadline,
      status: goal.status,
      direction: goal.direction,
      initialValue: goal.initialValue,
      createdAt: goal.createdAt ?? DateTime.now(),
      updatedAt: goal.updatedAt ?? DateTime.now(),
      reminderEnabled: goal.reminderEnabled,
      reminderHour: goal.reminderHour,
      reminderMinute: goal.reminderMinute,
      activityTypeFilter: goal.activityTypeFilter,
      timeFrame: goal.timeFrame,
    );
    final data = model.toMap();
    
    // Generate ID nếu chưa có (cần cho offline storage)
    String finalId = goal.id;
    if (finalId.isEmpty) {
      finalId = 'offline_${DateTime.now().millisecondsSinceEpoch}';
      data['id'] = finalId;
    } else {
      data['id'] = finalId;
    }

    // Convert Timestamp to String for offline storage (JSON serializable)
    final dataForOffline = _convertToJsonSerializable(data);

    // Check if online
    final hasConnection = await (_syncService?.hasInternetConnection() ?? Future.value(true));
    if (!hasConnection) {
      // Save offline (sẽ generate ID nếu chưa có)
      await _localStorage.saveGoalOffline(goal.userId, dataForOffline);
      // Add to pending operations
      if (_syncService != null) {
        final operationId = '${DateTime.now().millisecondsSinceEpoch}_$finalId';
        await _syncService.addPendingOperation(
          PendingOperation(
            id: operationId,
            type: PendingOperationType.createGoal,
            data: dataForOffline,
            timestamp: DateTime.now(),
            userId: goal.userId,
          ),
        );
      }
      return;
    }

    // Save online
    try {
      if (goal.id.isEmpty || finalId.startsWith('offline_')) {
        // Nếu là offline ID, tạo document mới với ID mới từ Firestore
        data.remove('id'); // Remove offline ID để Firestore tự generate
        await _collection(goal.userId).add(data);
        // Goal đã được tạo thành công, cleanup operations (không throw nếu fail)
        _cleanupAfterCreateGoal(goal.userId, finalId);
      } else {
        await _collection(goal.userId).doc(goal.id).set(data);
        // Goal đã được tạo thành công, cleanup operations (không throw nếu fail)
        try {
          await _localStorage.removeGoalOffline(goal.userId, goal.id);
        } catch (e) {
          print('Warning: Failed to remove offline goal after creating: $e');
        }
      }
    } catch (e) {
      // If save fails, save offline
      await _localStorage.saveGoalOffline(goal.userId, dataForOffline);
      if (_syncService != null) {
        final operationId = '${DateTime.now().millisecondsSinceEpoch}_$finalId';
        await _syncService.addPendingOperation(
          PendingOperation(
            id: operationId,
            type: PendingOperationType.createGoal,
            data: dataForOffline,
            timestamp: DateTime.now(),
            userId: goal.userId,
          ),
        );
      }
      rethrow;
    }
  }

  /// Cleanup operations sau khi tạo goal thành công (không throw exception)
  void _cleanupAfterCreateGoal(String userId, String offlineId) {
    // Remove from offline storage
    _localStorage.removeGoalOffline(userId, offlineId).catchError((e) {
      print('Warning: Failed to remove offline goal after creating: $e');
    });
    
    // Remove pending operation (đã sync thành công)
    final syncService = _syncService;
    if (syncService != null) {
      syncService.getPendingOperations().then((pendingOps) {
        final matchingOps = pendingOps.where(
          (op) => op.type == PendingOperationType.createGoal &&
                  op.data['id'] == offlineId,
        ).toList();
        for (final op in matchingOps) {
          syncService.removePendingOperation(op.id).catchError((e) {
            print('Warning: Failed to remove pending operation after creating goal: $e');
          });
        }
      }).catchError((e) {
        print('Warning: Failed to get pending operations after creating goal: $e');
      });
    }
  }

  /// Convert Firestore data (with Timestamp) to JSON-serializable format (with String dates)
  Map<String, dynamic> _convertToJsonSerializable(Map<String, dynamic> data) {
    final result = <String, dynamic>{};
    for (final entry in data.entries) {
      if (entry.value is Timestamp) {
        result[entry.key] = (entry.value as Timestamp).toDate().toIso8601String();
      } else {
        result[entry.key] = entry.value;
      }
    }
    return result;
  }

  /// Convert JSON-serializable format (with String dates) back to Firestore format (with Timestamp)
  Map<String, dynamic> _convertFromJsonSerializable(Map<String, dynamic> data) {
    final result = <String, dynamic>{};
    for (final entry in data.entries) {
      // Check if it's a date field and convert String to Timestamp
      if ((entry.key == 'startDate' || entry.key == 'deadline' || entry.key == 'createdAt' || entry.key == 'updatedAt') && entry.value is String) {
        result[entry.key] = Timestamp.fromDate(DateTime.parse(entry.value as String));
      } else {
        result[entry.key] = entry.value;
      }
    }
    return result;
  }

  @override
  Future<void> updateGoal(Goal goal) async {
    if (goal.id.isEmpty) {
      throw ArgumentError('Goal id is required for update');
    }
    final model = GoalModel(
      id: goal.id,
      userId: goal.userId,
      goalType: goal.goalType,
      targetValue: goal.targetValue,
      currentValue: goal.currentValue,
      startDate: goal.startDate,
      deadline: goal.deadline,
      status: goal.status,
      direction: goal.direction,
      initialValue: goal.initialValue,
      createdAt: goal.createdAt,
      updatedAt: goal.updatedAt ?? DateTime.now(),
      reminderEnabled: goal.reminderEnabled,
      reminderHour: goal.reminderHour,
      reminderMinute: goal.reminderMinute,
      activityTypeFilter: goal.activityTypeFilter,
      timeFrame: goal.timeFrame,
    );
    final data = model.toMap()..remove('id');
    data['id'] = goal.id;

    // Convert Timestamp to String for offline storage (JSON serializable)
    final dataForOffline = _convertToJsonSerializable(data);

    // Check if online
    final hasConnection = await (_syncService?.hasInternetConnection() ?? Future.value(true));
    if (!hasConnection) {
      // Save offline
      await _localStorage.saveGoalOffline(goal.userId, dataForOffline);
      // Add to pending operations
      if (_syncService != null) {
        final operationId = '${DateTime.now().millisecondsSinceEpoch}_${goal.id}';
        await _syncService.addPendingOperation(
          PendingOperation(
            id: operationId,
            type: PendingOperationType.updateGoal,
            data: dataForOffline,
            timestamp: DateTime.now(),
            userId: goal.userId,
          ),
        );
      }
      return;
    }

    // Update online
    try {
      await _collection(goal.userId).doc(goal.id).set(data, SetOptions(merge: true));
    } catch (e) {
      // If update fails, save offline
      await _localStorage.saveGoalOffline(goal.userId, dataForOffline);
      if (_syncService != null) {
        final operationId = '${DateTime.now().millisecondsSinceEpoch}_${goal.id}';
        await _syncService.addPendingOperation(
          PendingOperation(
            id: operationId,
            type: PendingOperationType.updateGoal,
            data: dataForOffline,
            timestamp: DateTime.now(),
            userId: goal.userId,
          ),
        );
      }
      rethrow;
    }
  }

  @override
  Future<void> deleteGoal({
    required String userId,
    required String goalId,
  }) async {
    // Check if online
    final hasConnection = await (_syncService?.hasInternetConnection() ?? Future.value(true));
    if (!hasConnection) {
      // Add to pending operations
      if (_syncService != null) {
        final operationId = '${DateTime.now().millisecondsSinceEpoch}_$goalId';
        await _syncService.addPendingOperation(
          PendingOperation(
            id: operationId,
            type: PendingOperationType.deleteGoal,
            data: {'goalId': goalId},
            timestamp: DateTime.now(),
            userId: userId,
          ),
        );
      }
      // Remove from offline storage
      await _localStorage.removeGoalOffline(userId, goalId);
      return;
    }

    // Delete online
    try {
      await _collection(userId).doc(goalId).delete();
    } catch (e) {
      // If delete fails, add to pending operations
      if (_syncService != null) {
        final operationId = '${DateTime.now().millisecondsSinceEpoch}_$goalId';
        await _syncService.addPendingOperation(
          PendingOperation(
            id: operationId,
            type: PendingOperationType.deleteGoal,
            data: {'goalId': goalId},
            timestamp: DateTime.now(),
            userId: userId,
          ),
        );
      }
      rethrow;
    }
  }

  // Method to register sync handler
  void registerSyncHandler(SyncService syncService) {
    syncService.registerOperationHandler(
      PendingOperationType.createGoal,
      (operation) async {
        try {
          final data = Map<String, dynamic>.from(operation.data);
          final userId = operation.userId;
          final id = data['id'] as String?;
          final oldId = id ?? '';
          
          // Convert String dates back to Timestamp for Firestore
          final dataForFirestore = _convertFromJsonSerializable(data);
          
          // Nếu là offline ID, tạo document mới với ID từ Firestore
          if (id == null || id.isEmpty || id.startsWith('offline_')) {
            dataForFirestore.remove('id'); // Remove offline ID để Firestore tự generate
            await _collection(userId).add(dataForFirestore);
            // Remove from offline storage với old ID
            await _localStorage.removeGoalOffline(userId, oldId);
          } else {
            await _collection(userId).doc(id).set(dataForFirestore);
            await _localStorage.removeGoalOffline(userId, id);
          }
          return true;
        } catch (e) {
          return false;
        }
      },
    );

    syncService.registerOperationHandler(
      PendingOperationType.updateGoal,
      (operation) async {
        try {
          final data = Map<String, dynamic>.from(operation.data);
          final userId = operation.userId;
          final id = data['id'] as String;
          
          // Convert String dates back to Timestamp for Firestore
          final dataForFirestore = _convertFromJsonSerializable(data);
          
          await _collection(userId).doc(id).set(dataForFirestore, SetOptions(merge: true));
          return true;
        } catch (e) {
          return false;
        }
      },
    );

    syncService.registerOperationHandler(
      PendingOperationType.deleteGoal,
      (operation) async {
        try {
          final goalId = operation.data['goalId'] as String;
          await _collection(operation.userId).doc(goalId).delete();
          return true;
        } catch (e) {
          return false;
        }
      },
    );
  }

  @override
  Stream<List<Goal>> watchGoals({
    required String userId,
    GoalStatus? status,
  }) {
    Query<Map<String, dynamic>> query = _collection(userId).orderBy(
      'createdAt',
      descending: true,
    );
    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    return query.snapshots().map(
          (snapshot) =>
              snapshot.docs.map(GoalModel.fromDoc).toList(growable: false),
        );
  }

  @override
  Future<List<Goal>> fetchGoals({
    required String userId,
    GoalStatus? status,
  }) async {
    Query<Map<String, dynamic>> query = _collection(userId).orderBy(
      'createdAt',
      descending: true,
    );
    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    final snapshot = await query.get();
    return snapshot.docs.map(GoalModel.fromDoc).toList(growable: false);
  }
}

