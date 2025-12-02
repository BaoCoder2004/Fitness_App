import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/services/local_storage_service.dart';
import '../../core/services/sync_service.dart';
import '../../domain/entities/activity_session.dart';
import '../../domain/repositories/activity_repository.dart';
import '../models/activity_session_model.dart';

class FirestoreActivityRepository implements ActivityRepository {
  FirestoreActivityRepository({
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
  Future<void> saveSession(ActivitySession session) async {
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
    
    // Generate ID nếu chưa có (cần cho offline storage)
    String finalId = session.id;
    if (finalId.isEmpty) {
      finalId = 'offline_${DateTime.now().millisecondsSinceEpoch}';
    }

    // Convert Timestamp to String for offline storage (JSON serializable) BEFORE adding ID
    final dataForOffline = _convertToJsonSerializable(data);
    // Add ID to converted data
    dataForOffline['id'] = finalId;

    // Check if online
    final hasConnection = await (_syncService?.hasInternetConnection() ?? Future.value(true));
    if (!hasConnection) {
      // Save offline (sẽ generate ID nếu chưa có)
      await _localStorage.saveActivityOffline(session.userId, dataForOffline);
      // Add to pending operations
      if (_syncService != null) {
        final operationId = '${DateTime.now().millisecondsSinceEpoch}_$finalId';
        await _syncService.addPendingOperation(
          PendingOperation(
            id: operationId,
            type: PendingOperationType.createActivity,
            data: dataForOffline,
            timestamp: DateTime.now(),
            userId: session.userId,
          ),
        );
      }
      return;
    }

    // Save online
    try {
      if (session.id.isEmpty || finalId.startsWith('offline_')) {
        // Tạo document mới với ID từ Firestore
        data.remove('id'); // Remove offline ID để Firestore tự generate
        await _collection(session.userId).add(data);
      } else {
        // Đã có ID → update
        await _collection(session.userId).doc(session.id).set(data);
      }
      
      // Remove from offline storage với old ID (nếu có)
      await _localStorage.removeActivityOffline(session.userId, finalId);
      
      // QUAN TRỌNG: Remove TẤT CẢ pending operations có cùng data để tránh sync duplicate
      // Chỉ remove khi save online thành công để đảm bảo dữ liệu đã có trong Firestore
      if (_syncService != null) {
        try {
          final pendingOps = await _syncService.getPendingOperations();
          final sessionDate = dataForOffline['date'] as String?;
          final sessionActivityType = dataForOffline['activityType'] as String?;
          // Handle both int and double for duration (JSON can store as double)
          final sessionDurationRaw = dataForOffline['duration'];
          final sessionDuration = sessionDurationRaw is int 
              ? sessionDurationRaw 
              : (sessionDurationRaw is double ? sessionDurationRaw.toInt() : null);
          // Note: dataForOffline may have 'distanceKm' but Firestore uses 'distance'
          final sessionDistanceRaw = dataForOffline['distance'] ?? dataForOffline['distanceKm'];
          final sessionDistance = sessionDistanceRaw is double 
              ? sessionDistanceRaw 
              : (sessionDistanceRaw is num ? sessionDistanceRaw.toDouble() : null);
          // Handle both int and double for calories
          final sessionCaloriesRaw = dataForOffline['calories'];
          final sessionCalories = sessionCaloriesRaw is int 
              ? sessionCaloriesRaw 
              : (sessionCaloriesRaw is double ? sessionCaloriesRaw.toInt() : null);
          
          if (sessionDate != null && sessionActivityType != null) {
            final opsToRemove = <String>[];
            for (final op in pendingOps) {
              if (op.type == PendingOperationType.createActivity &&
                  op.userId == session.userId) {
                final opDate = op.data['date'] as String?;
                final opActivityType = op.data['activityType'] as String?;
                // Handle both int and double
                final opDurationRaw = op.data['duration'];
                final opDuration = opDurationRaw is int 
                    ? opDurationRaw 
                    : (opDurationRaw is double ? opDurationRaw.toInt() : null);
                // Note: op.data may have 'distanceKm' but Firestore uses 'distance'
                final opDistanceRaw = op.data['distance'] ?? op.data['distanceKm'];
                final opDistance = opDistanceRaw is double 
                    ? opDistanceRaw 
                    : (opDistanceRaw is num ? opDistanceRaw.toDouble() : null);
                final opCaloriesRaw = op.data['calories'];
                final opCalories = opCaloriesRaw is int 
                    ? opCaloriesRaw 
                    : (opCaloriesRaw is double ? opCaloriesRaw.toInt() : null);
                
                // Check match: cùng date, activityType, và các metrics chính
                bool isMatch = opDate == sessionDate && opActivityType == sessionActivityType;
                
                // Nếu có duration, check duration (trong vòng 5 giây)
                if (isMatch && sessionDuration != null && opDuration != null) {
                  isMatch = isMatch && (opDuration - sessionDuration).abs() <= 5;
                }
                
                // Nếu có distance, check distance (trong vòng 0.01 km)
                if (isMatch && sessionDistance != null && opDistance != null) {
                  isMatch = isMatch && (opDistance - sessionDistance).abs() <= 0.01;
                }
                
                // Nếu có calories, check calories (trong vòng 5 calories)
                if (isMatch && sessionCalories != null && opCalories != null) {
                  isMatch = isMatch && (opCalories - sessionCalories).abs() <= 5;
                }
                
                if (isMatch) {
                  // Match → remove để tránh duplicate khi sync
                  opsToRemove.add(op.id);
                }
              }
            }
            
            // Remove tất cả matching operations
            for (final opId in opsToRemove) {
              await _syncService.removePendingOperation(opId);
            }
          }
        } catch (e) {
          print('Warning: Could not remove pending operations: $e');
        }
      }
    } catch (e) {
      // If save fails, save offline
      await _localStorage.saveActivityOffline(session.userId, dataForOffline);
      if (_syncService != null) {
        final operationId = '${DateTime.now().millisecondsSinceEpoch}_$finalId';
        await _syncService.addPendingOperation(
          PendingOperation(
            id: operationId,
            type: PendingOperationType.createActivity,
            data: dataForOffline,
            timestamp: DateTime.now(),
            userId: session.userId,
          ),
        );
      }
      rethrow;
    }
  }

  /// Convert Firestore data (with Timestamp) to JSON-serializable format (with String dates)
  Map<String, dynamic> _convertToJsonSerializable(Map<String, dynamic> data) {
    final result = <String, dynamic>{};
    for (final entry in data.entries) {
      final value = entry.value;
      if (value is Timestamp) {
        result[entry.key] = value.toDate().toIso8601String();
      } else if (value is Map) {
        // Recursively convert nested maps
        result[entry.key] = _convertToJsonSerializable(Map<String, dynamic>.from(value));
      } else if (value is List) {
        // Convert lists that might contain Timestamps or Maps
        result[entry.key] = value.map((item) {
          if (item is Timestamp) {
            return item.toDate().toIso8601String();
          } else if (item is Map) {
            return _convertToJsonSerializable(Map<String, dynamic>.from(item));
          }
          return item;
        }).toList();
      } else {
        result[entry.key] = value;
      }
    }
    return result;
  }

  /// Convert JSON-serializable format (with String dates) back to Firestore format (with Timestamp)
  Map<String, dynamic> _convertFromJsonSerializable(Map<String, dynamic> data) {
    final result = <String, dynamic>{};
    for (final entry in data.entries) {
      // Check if it's a date field (date, createdAt) and convert String to Timestamp
      if ((entry.key == 'date' || entry.key == 'createdAt') && entry.value is String) {
        result[entry.key] = Timestamp.fromDate(DateTime.parse(entry.value as String));
      } else {
        result[entry.key] = entry.value;
      }
    }
    return result;
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
  }) async {
    // Check if online
    final hasConnection = await (_syncService?.hasInternetConnection() ?? Future.value(true));
    if (!hasConnection) {
      // Add to pending operations
      if (_syncService != null) {
        final operationId = '${DateTime.now().millisecondsSinceEpoch}_$sessionId';
        await _syncService.addPendingOperation(
          PendingOperation(
            id: operationId,
            type: PendingOperationType.deleteActivity,
            data: {'sessionId': sessionId},
            timestamp: DateTime.now(),
            userId: userId,
          ),
        );
      }
      // Remove from offline storage
      await _localStorage.removeActivityOffline(userId, sessionId);
      return;
    }

    // Delete online
    try {
      await _collection(userId).doc(sessionId).delete();
    } catch (e) {
      // If delete fails, add to pending operations
      if (_syncService != null) {
        final operationId = '${DateTime.now().millisecondsSinceEpoch}_$sessionId';
        await _syncService.addPendingOperation(
          PendingOperation(
            id: operationId,
            type: PendingOperationType.deleteActivity,
            data: {'sessionId': sessionId},
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
      PendingOperationType.createActivity,
      (operation) async {
        try {
          final data = Map<String, dynamic>.from(operation.data);
          final userId = operation.userId;
          final id = data['id'] as String?;
          final oldId = id ?? '';
          
          // Convert String dates back to Timestamp for Firestore
          final dataForFirestore = _convertFromJsonSerializable(data);
          
          // QUAN TRỌNG: Check duplicate trước khi tạo document mới
          // Fetch activities trong cùng ngày để check duplicate (không dùng query phức tạp)
          final activityDate = dataForFirestore['date'] as Timestamp?;
          bool isDuplicate = false;
          String? existingActivityId;
          
          if (activityDate != null) {
            final startOfDay = DateTime(
              activityDate.toDate().year,
              activityDate.toDate().month,
              activityDate.toDate().day,
            );
            final endOfDay = startOfDay.add(const Duration(days: 1));
            
            // Fetch activities trong ngày (chỉ dùng date range, không dùng activityType filter)
            final activitiesInDay = await _collection(userId)
                .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
                .where('date', isLessThan: Timestamp.fromDate(endOfDay))
                .get();
            
            // Filter ở client để tìm duplicate
            final activityType = dataForFirestore['activityType'] as String?;
            // Handle both int and num for duration
            final durationRaw = dataForFirestore['duration'];
            final duration = durationRaw is int 
                ? durationRaw 
                : (durationRaw is num ? durationRaw.toInt() : null);
            // Note: Firestore uses 'distance' not 'distanceKm'
            final distanceRaw = dataForFirestore['distance'] ?? dataForFirestore['distanceKm'];
            final distance = distanceRaw is double 
                ? distanceRaw 
                : (distanceRaw is num ? distanceRaw.toDouble() : null);
            // Handle both int and num for calories
            final caloriesRaw = dataForFirestore['calories'];
            final calories = caloriesRaw is int 
                ? caloriesRaw 
                : (caloriesRaw is num ? caloriesRaw.toInt() : null);
            
            for (final doc in activitiesInDay.docs) {
              final docData = doc.data();
              final docActivityType = docData['activityType'] as String?;
              // Handle both int and num
              final docDurationRaw = docData['duration'];
              final docDuration = docDurationRaw is int 
                  ? docDurationRaw 
                  : (docDurationRaw is num ? docDurationRaw.toInt() : null);
              // Note: Firestore uses 'distance' not 'distanceKm'
              final docDistanceRaw = docData['distance'] ?? docData['distanceKm'];
              final docDistance = docDistanceRaw is double 
                  ? docDistanceRaw 
                  : (docDistanceRaw is num ? docDistanceRaw.toDouble() : null);
              // Handle both int and num
              final docCaloriesRaw = docData['calories'];
              final docCalories = docCaloriesRaw is int 
                  ? docCaloriesRaw 
                  : (docCaloriesRaw is num ? docCaloriesRaw.toInt() : null);
              
              // Check match: cùng activityType và các metrics chính
              bool match = docActivityType == activityType;
              
              if (match && duration != null && docDuration != null) {
                match = match && (docDuration - duration).abs() <= 5;
              }
              
              if (match && distance != null && docDistance != null) {
                match = match && (docDistance - distance).abs() <= 0.01;
              }
              
              if (match && calories != null && docCalories != null) {
                match = match && (docCalories - calories).abs() <= 5;
              }
              
              if (match) {
                // Tìm thấy duplicate → update thay vì tạo mới
                isDuplicate = true;
                existingActivityId = doc.id;
                break;
              }
            }
          }
          
          // Nếu là offline ID, tạo document mới với ID từ Firestore (hoặc update nếu duplicate)
          String newActivityId = oldId;
          if (id == null || id.isEmpty || id.startsWith('offline_')) {
            if (isDuplicate && existingActivityId != null) {
              // Update existing document thay vì tạo mới
              await _collection(userId).doc(existingActivityId).set(dataForFirestore, SetOptions(merge: true));
              newActivityId = existingActivityId;
            } else {
              // Tạo document mới
              dataForFirestore.remove('id'); // Remove offline ID để Firestore tự generate
              final docRef = await _collection(userId).add(dataForFirestore);
              newActivityId = docRef.id; // Lấy ID mới từ Firestore
            }
            
            // Update GPS routes có activityId = oldId thành newActivityId
            // QUAN TRỌNG: Update cả offline storage, pending operations, và Firestore
            try {
              // 1. Update offline GPS routes
              final offlineRoutes = await _localStorage.getGpsRoutesOffline(userId);
              bool hasUpdates = false;
              for (final routeData in offlineRoutes) {
                if (routeData['activityId'] == oldId) {
                  routeData['activityId'] = newActivityId;
                  hasUpdates = true;
                }
              }
              if (hasUpdates) {
                // Re-save all routes
                for (final routeData in offlineRoutes) {
                  await _localStorage.saveGpsRouteOffline(userId, routeData);
                }
              }
              
              // 2. Update pending GPS route operations
              final pendingOps = await syncService.getPendingOperations();
              for (final op in pendingOps) {
                if (op.type == PendingOperationType.createGpsRoute &&
                    op.data['activityId'] == oldId) {
                  // Tạo operation mới với activityId đã update
                  final updatedData = Map<String, dynamic>.from(op.data);
                  updatedData['activityId'] = newActivityId;
                  await syncService.removePendingOperation(op.id);
                  await syncService.addPendingOperation(
                    PendingOperation(
                      id: op.id,
                      type: op.type,
                      data: updatedData,
                      timestamp: op.timestamp,
                      userId: op.userId,
                      retryCount: op.retryCount,
                    ),
                  );
                }
              }
              
              // 3. Update GPS routes đã được sync lên Firestore (nếu có)
              try {
                // Tìm GPS routes với oldId (offline ID)
                final gpsRoutesSnapshot = await _firestore
                    .collection('users')
                    .doc(userId)
                    .collection('gps_routes')
                    .where('activityId', isEqualTo: oldId)
                    .get();
                
                if (gpsRoutesSnapshot.docs.isNotEmpty) {
                  final batch = _firestore.batch();
                  for (final doc in gpsRoutesSnapshot.docs) {
                    batch.update(doc.reference, {'activityId': newActivityId});
                    print('Updating GPS route ${doc.id} from activityId $oldId to $newActivityId');
                  }
                  await batch.commit();
                  print('✅ Updated ${gpsRoutesSnapshot.docs.length} GPS routes in Firestore from activityId $oldId to $newActivityId');
                } else {
                  print('⚠️ No GPS routes found in Firestore with activityId $oldId');
                  
                  // Nếu không tìm thấy với oldId, thử tìm GPS routes với offline activityId bằng cách match date/duration/distance
                  // Điều này xử lý trường hợp GPS route đã được sync trước activity nhưng không match được
                  try {
                    final activityData = dataForFirestore;
                    final activityDate = (activityData['date'] as Timestamp?)?.toDate();
                    final activityDuration = activityData['duration'] as int?;
                    final activityDistance = activityData['distance'] as double?;
                    final activityType = activityData['activityType'] as String?;
                    
                    if (activityDate != null) {
                      // Tìm GPS routes trong cùng ngày với offline activityId
                      final startOfDay = DateTime(activityDate.year, activityDate.month, activityDate.day);
                      final endOfDay = startOfDay.add(const Duration(days: 1));
                      
                      print('  🔍 Searching for GPS routes in same day (${startOfDay.year}-${startOfDay.month}-${startOfDay.day})');
                      print('  Activity: date=$activityDate, duration=$activityDuration, distance=$activityDistance, type=$activityType');
                      
                      final allGpsRoutesSnapshot = await _firestore
                          .collection('users')
                          .doc(userId)
                          .collection('gps_routes')
                          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
                          .where('createdAt', isLessThan: Timestamp.fromDate(endOfDay))
                          .get();
                      
                      print('  Found ${allGpsRoutesSnapshot.docs.length} GPS routes in same day');
                      
                      final batch = _firestore.batch();
                      int matchedCount = 0;
                      
                      for (final doc in allGpsRoutesSnapshot.docs) {
                        final routeData = doc.data();
                        final routeActivityId = routeData['activityId'] as String?;
                        
                        // Chỉ xử lý routes có offline activityId hoặc empty activityId
                        if (routeActivityId == null || 
                            (!routeActivityId.startsWith('offline_') && routeActivityId.isNotEmpty)) {
                          continue;
                        }
                        
                        final routeDate = (routeData['createdAt'] as Timestamp?)?.toDate();
                        final routeDuration = routeData['totalDurationSeconds'] as int?;
                        final routeDistance = routeData['totalDistanceKm'] as double?;
                        
                        print('  Checking GPS route ${doc.id}: activityId=$routeActivityId, date=$routeDate, duration=$routeDuration, distance=$routeDistance');
                        
                        if (routeDate == null) continue;
                        
                        // Match date (cùng ngày)
                        bool match = routeDate.year == activityDate.year &&
                            routeDate.month == activityDate.month &&
                            routeDate.day == activityDate.day;
                        
                        if (!match) {
                          print('    ❌ Date mismatch: route=$routeDate, activity=$activityDate');
                          continue;
                        }
                        
                        // Match duration (nếu có, trong vòng 30 giây)
                        bool durationMatch = true;
                        if (activityDuration != null && routeDuration != null) {
                          final durationDiff = (activityDuration - routeDuration).abs();
                          durationMatch = durationDiff <= 30;
                          if (!durationMatch) {
                            print('    ⚠️ Duration mismatch: route=$routeDuration, activity=$activityDuration, diff=${durationDiff}s');
                          }
                        }
                        
                        // Match distance (nếu có, trong vòng 0.1 km)
                        bool distanceMatch = true;
                        if (activityDistance != null && routeDistance != null) {
                          final distanceDiff = (activityDistance - routeDistance).abs();
                          distanceMatch = distanceDiff <= 0.1;
                          if (!distanceMatch) {
                            print('    ⚠️ Distance mismatch: route=$routeDistance, activity=$activityDistance, diff=${distanceDiff}km');
                          }
                        }
                        
                        // Match nếu cùng ngày và (match duration hoặc distance, hoặc chỉ có 1 route)
                        match = match && (durationMatch || distanceMatch || allGpsRoutesSnapshot.docs.length == 1);
                        
                        // Nếu chỉ có 1 route trong ngày, vẫn match
                        if (!match && allGpsRoutesSnapshot.docs.length == 1) {
                          match = true;
                          print('    ✅ Only 1 route in day, matching anyway');
                        }
                        
                        if (match) {
                          batch.update(doc.reference, {'activityId': newActivityId});
                          matchedCount++;
                          print('  ✅ Matched GPS route ${doc.id} (offline activityId: $routeActivityId) to new activity $newActivityId');
                        } else {
                          print('    ❌ No match for GPS route ${doc.id}');
                        }
                      }
                      
                      if (matchedCount > 0) {
                        await batch.commit();
                        print('✅ Updated $matchedCount GPS routes in Firestore by matching date/duration/distance');
                      } else {
                        print('  ⚠️ No GPS routes found matching activity date/duration/distance');
                      }
                    }
                  } catch (e2) {
                    print('⚠️ Warning: Could not find GPS routes by matching: $e2');
                  }
                }
              } catch (e) {
                print('Warning: Could not update GPS routes in Firestore: $e');
              }
            } catch (e) {
              print('Warning: Could not update GPS routes activityId: $e');
            }
            
            // Remove from offline storage với old ID
            await _localStorage.removeActivityOffline(userId, oldId);
          } else {
            await _collection(userId).doc(id).set(dataForFirestore);
            await _localStorage.removeActivityOffline(userId, id);
          }
          return true;
        } catch (e) {
          return false;
        }
      },
    );

    syncService.registerOperationHandler(
      PendingOperationType.deleteActivity,
      (operation) async {
        try {
          final sessionId = operation.data['sessionId'] as String;
          await _collection(operation.userId).doc(sessionId).delete();
          return true;
        } catch (e) {
          return false;
        }
      },
    );
  }
}

