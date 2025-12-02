import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/services/local_storage_service.dart';
import '../../core/services/sync_service.dart';
import '../../domain/entities/gps_route.dart';
import '../../domain/repositories/gps_route_repository.dart';
import '../models/gps_route_model.dart';

class FirestoreGpsRouteRepository implements GpsRouteRepository {
  FirestoreGpsRouteRepository({
    FirebaseFirestore? firestore,
    SyncService? syncService,
    LocalStorageService? localStorageService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _syncService = syncService,
        _localStorage = localStorageService ?? LocalStorageService();

  final FirebaseFirestore _firestore;
  final SyncService? _syncService;
  final LocalStorageService _localStorage;

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
    
    // Generate ID nếu chưa có (cần cho offline storage)
    String finalId = route.id;
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
      await _localStorage.saveGpsRouteOffline(route.userId, dataForOffline);
      // Add to pending operations
      if (_syncService != null) {
        final operationId = '${DateTime.now().millisecondsSinceEpoch}_$finalId';
        await _syncService.addPendingOperation(
          PendingOperation(
            id: operationId,
            type: PendingOperationType.createGpsRoute,
            data: dataForOffline,
            timestamp: DateTime.now(),
            userId: route.userId,
          ),
        );
      }
      return;
    }

    // Save online
    try {
      // ActivityId sau cùng (có thể được cập nhật khi tìm thấy activity match)
      String finalActivityId = route.activityId;

      // Nếu activityId là offline ID, tìm activity đã được sync để link
      if (finalActivityId.isNotEmpty && finalActivityId.startsWith('offline_')) {
        final matchedActivityId = await _findMatchingActivityId(
          userId: route.userId,
          routeDate: route.createdAt,
          routeDuration: route.totalDurationSeconds,
          routeDistance: route.totalDistanceKm,
        );
        if (matchedActivityId != null) {
          finalActivityId = matchedActivityId;
          data['activityId'] = finalActivityId;
          print('✅ Matched GPS route to activity $finalActivityId (was offline ID: ${route.activityId})');
        } else {
          print('⚠️ Could not find matching activity for GPS route with offline activityId ${route.activityId}. Will keep offline ID.');
        }
      }
      
      // Nếu activityId đã xác định (không phải offline) kiểm tra xem đã có GPS route nào gắn với activity này chưa
      DocumentReference<Map<String, dynamic>>? existingRouteRef;
      if (finalActivityId.isNotEmpty && !finalActivityId.startsWith('offline_')) {
        final existingSnapshot = await _collection(route.userId)
            .where('activityId', isEqualTo: finalActivityId)
            .limit(1)
            .get();
        if (existingSnapshot.docs.isNotEmpty) {
          existingRouteRef = existingSnapshot.docs.first.reference;
          print('Found existing GPS route for activity $finalActivityId (docId=${existingRouteRef.id}) -> will update instead of create');
        }
      }

      if (existingRouteRef != null) {
        await existingRouteRef.set(data, SetOptions(merge: true));
        await _localStorage.removeGpsRouteOffline(route.userId, finalId);
        return;
      } else if (route.id.isEmpty || finalId.startsWith('offline_')) {
        // Nếu là offline ID, tạo document mới với ID mới từ Firestore
        data.remove('id'); // Remove offline ID để Firestore tự generate
        await _collection(route.userId).add(data);
        // Remove from offline storage với old ID
        await _localStorage.removeGpsRouteOffline(route.userId, finalId);
        // Remove pending operation nếu có (chỉ khi đây là sync từ offline)
        if (_syncService != null) {
          try {
            final pendingOps = await _syncService.getPendingOperations();
            final matchingOps = pendingOps.where(
              (op) => op.type == PendingOperationType.createGpsRoute &&
                      op.data['id'] == finalId,
            ).toList();
            for (final op in matchingOps) {
              await _syncService.removePendingOperation(op.id);
            }
          } catch (e) {
            // Không sao nếu không tìm thấy pending operation (có thể là save online trực tiếp)
            print('Note: No pending operation found for GPS route $finalId (this is OK for direct online saves)');
          }
        }
      } else {
        await _collection(route.userId).doc(route.id).set(data);
        await _localStorage.removeGpsRouteOffline(route.userId, route.id);
      }
    } catch (e) {
      // If save fails, save offline
      await _localStorage.saveGpsRouteOffline(route.userId, dataForOffline);
      if (_syncService != null) {
        final operationId = '${DateTime.now().millisecondsSinceEpoch}_$finalId';
        await _syncService.addPendingOperation(
          PendingOperation(
            id: operationId,
            type: PendingOperationType.createGpsRoute,
            data: dataForOffline,
            timestamp: DateTime.now(),
            userId: route.userId,
          ),
        );
      }
      rethrow;
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
    // Check if online
    final hasConnection = await (_syncService?.hasInternetConnection() ?? Future.value(true));
    
    final snapshot = await _collection(userId)
        .where('activityId', isEqualTo: activityId)
        .get();
    if (snapshot.docs.isEmpty) return;

    if (!hasConnection) {
      // Add to pending operations
      if (_syncService != null) {
        final routeIds = snapshot.docs.map((doc) => doc.id).toList();
        for (final routeId in routeIds) {
          final operationId = '${DateTime.now().millisecondsSinceEpoch}_$routeId';
          await _syncService.addPendingOperation(
            PendingOperation(
              id: operationId,
              type: PendingOperationType.deleteGpsRoute,
              data: {'routeId': routeId, 'activityId': activityId},
              timestamp: DateTime.now(),
              userId: userId,
            ),
          );
        }
      }
      // Remove from offline storage
      for (final doc in snapshot.docs) {
        await _localStorage.removeGpsRouteOffline(userId, doc.id);
      }
      return;
    }

    // Delete online
    try {
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      // If delete fails, add to pending operations
      if (_syncService != null) {
        final routeIds = snapshot.docs.map((doc) => doc.id).toList();
        for (final routeId in routeIds) {
          final operationId = '${DateTime.now().millisecondsSinceEpoch}_$routeId';
          await _syncService.addPendingOperation(
            PendingOperation(
              id: operationId,
              type: PendingOperationType.deleteGpsRoute,
              data: {'routeId': routeId, 'activityId': activityId},
              timestamp: DateTime.now(),
              userId: userId,
            ),
          );
        }
      }
      rethrow;
    }
  }

  /// Helper function để tìm activityId match với GPS route
  /// Trả về activityId nếu tìm thấy, null nếu không
  Future<String?> _findMatchingActivityId({
    required String userId,
    required DateTime routeDate,
    required int routeDuration,
    required double routeDistance,
  }) async {
    try {
      final startOfDay = DateTime(routeDate.year, routeDate.month, routeDate.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      // Fetch activities trong cùng ngày
      final activitiesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('activities')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .get();
      
      if (activitiesSnapshot.docs.isEmpty) {
        print('  No activities found in day for GPS route matching');
        return null;
      }
      
      String? bestMatchId;
      Duration? bestTimeDiff;
      int bestMatchScore = 0;
      
      for (final doc in activitiesSnapshot.docs) {
        final docData = doc.data();
        final docDate = (docData['date'] as Timestamp?)?.toDate();
        final docDuration = docData['duration'] as int?;
        final docDistance = docData['distance'] as double?;
        
        if (docDate == null) continue;
        
        // Match date (cùng ngày) - BẮT BUỘC
        bool sameDay = docDate.year == routeDate.year &&
            docDate.month == routeDate.month &&
            docDate.day == routeDate.day;
        
        if (!sameDay) continue;
        
        // Tính điểm match
        int matchScore = 1; // Cùng ngày = 1 điểm
        
        // Match duration (nếu có, trong vòng 30 giây)
        bool durationMatch = false;
        if (docDuration != null) {
          final durationDiff = (docDuration - routeDuration).abs();
          if (durationDiff <= 30) {
            durationMatch = true;
            matchScore += 2; // Match duration = +2 điểm
            if (durationDiff <= 10) {
              matchScore += 1; // Match chính xác = +1 điểm nữa
            }
          }
        }
        
        // Match distance (nếu có, trong vòng 0.1 km)
        bool distanceMatch = false;
        if (docDistance != null && routeDistance > 0) {
          final distanceDiff = (docDistance - routeDistance).abs();
          if (distanceDiff <= 0.1) {
            distanceMatch = true;
            matchScore += 2; // Match distance = +2 điểm
            if (distanceDiff <= 0.05) {
              matchScore += 1; // Match chính xác = +1 điểm nữa
            }
          }
        }
        
        // Tính thời gian chênh lệch
        final timeDiff = (docDate.difference(routeDate)).abs();
        
        // Nếu có match (cùng ngày và có ít nhất duration hoặc distance match), hoặc chỉ cùng ngày và gần nhất về thời gian
        bool isMatch = sameDay && (durationMatch || distanceMatch || activitiesSnapshot.docs.length == 1);
        
        // Nếu không có match tốt nhưng chỉ có 1 activity trong ngày, vẫn coi là match
        if (!isMatch && activitiesSnapshot.docs.length == 1) {
          isMatch = true;
          matchScore = 1; // Chỉ cùng ngày
        }
        
        if (isMatch) {
          // Chọn activity có điểm cao nhất, nếu bằng nhau thì chọn gần nhất về thời gian
          if (bestMatchId == null || 
              matchScore > bestMatchScore ||
              (matchScore == bestMatchScore && (bestTimeDiff == null || timeDiff < bestTimeDiff))) {
            bestMatchId = doc.id;
            bestTimeDiff = timeDiff;
            bestMatchScore = matchScore;
          }
        }
      }
      
      if (bestMatchId != null) {
        print('  ✅ Found matching activity: $bestMatchId (score=$bestMatchScore, timeDiff=${bestTimeDiff?.inSeconds}s)');
        return bestMatchId;
      } else {
        print('  ⚠️ No matching activity found');
        return null;
      }
    } catch (e) {
      print('  ⚠️ Error finding matching activity: $e');
      return null;
    }
  }

  // Method to register sync handler
  void registerSyncHandler(SyncService syncService) {
    syncService.registerOperationHandler(
      PendingOperationType.createGpsRoute,
      (operation) async {
        try {
          final data = Map<String, dynamic>.from(operation.data);
          final userId = operation.userId;
          final id = data['id'] as String?;
          final oldId = id ?? '';
          
          // Convert String dates back to Timestamp for Firestore
          final dataForFirestore = _convertFromJsonSerializable(data);
          
          // Nếu activityId là offline ID, tìm activity đã được sync để link
          final activityId = dataForFirestore['activityId'] as String?;
          if (activityId != null && activityId.startsWith('offline_')) {
            try {
              // Lấy date từ GPS route để tìm activity match
              final routeDate = dataForFirestore['createdAt'] as Timestamp?;
              final routeDuration = dataForFirestore['totalDurationSeconds'] as int? ?? 0;
              final routeDistance = dataForFirestore['totalDistanceKm'] as double? ?? 0.0;
              
              if (routeDate != null) {
                print('Looking for activity match for GPS route with offline activityId $activityId');
                print('  Route date: $routeDate, duration: $routeDuration, distance: $routeDistance');
                
                final matchedActivityId = await _findMatchingActivityId(
                  userId: userId,
                  routeDate: routeDate.toDate(),
                  routeDuration: routeDuration,
                  routeDistance: routeDistance,
                );
                
                if (matchedActivityId != null) {
                  dataForFirestore['activityId'] = matchedActivityId;
                  print('✅ Linked GPS route to activity $matchedActivityId (was offline ID: $activityId)');
                } else {
                  print('⚠️ Warning: Could not find matching activity for GPS route with offline activityId $activityId. Will keep offline ID and update later.');
                  // KHÔNG dùng most recent fallback vì có thể link sai
                  // GPS route sẽ được update khi activity được sync
                  // Nếu activity chưa được sync, giữ nguyên offline ID để có thể update sau
                }
              }
            } catch (e) {
              print('Warning: Could not find activity for GPS route: $e');
              // Nếu không tìm thấy, vẫn sync route nhưng activityId sẽ là offline ID
              // Có thể được update sau khi activity được sync
            }
          }
          
          // Nếu là offline ID, tạo document mới với ID từ Firestore
          if (id == null || id.isEmpty || id.startsWith('offline_')) {
            dataForFirestore.remove('id'); // Remove offline ID để Firestore tự generate
            await _collection(userId).add(dataForFirestore);
            // Remove from offline storage với old ID
            await _localStorage.removeGpsRouteOffline(userId, oldId);
          } else {
            await _collection(userId).doc(id).set(dataForFirestore);
            await _localStorage.removeGpsRouteOffline(userId, id);
          }
          return true;
        } catch (e) {
          return false;
        }
      },
    );

    syncService.registerOperationHandler(
      PendingOperationType.deleteGpsRoute,
      (operation) async {
        try {
          final routeId = operation.data['routeId'] as String;
          await _collection(operation.userId).doc(routeId).delete();
          return true;
        } catch (e) {
          return false;
        }
      },
    );
  }

  /// Convert Firestore data (with Timestamp) to JSON-serializable format (with String dates)
  Map<String, dynamic> _convertToJsonSerializable(Map<String, dynamic> data) {
    final result = <String, dynamic>{};
    for (final entry in data.entries) {
      if (entry.value is Timestamp) {
        result[entry.key] = (entry.value as Timestamp).toDate().toIso8601String();
      } else if (entry.key == 'segments' && entry.value is List) {
        // Convert nested segments with Timestamp
        final segments = (entry.value as List).map((segment) {
          if (segment is Map<String, dynamic>) {
            final segResult = <String, dynamic>{};
            for (final segEntry in segment.entries) {
              if (segEntry.value is Timestamp) {
                segResult[segEntry.key] = (segEntry.value as Timestamp).toDate().toIso8601String();
              } else if (segEntry.key == 'points' && segEntry.value is List) {
                // Convert nested points with Timestamp
                final points = (segEntry.value as List).map((point) {
                  if (point is Map<String, dynamic>) {
                    final pointResult = <String, dynamic>{};
                    for (final pointEntry in point.entries) {
                      if (pointEntry.value is Timestamp) {
                        pointResult[pointEntry.key] = (pointEntry.value as Timestamp).toDate().toIso8601String();
                      } else {
                        pointResult[pointEntry.key] = pointEntry.value;
                      }
                    }
                    return pointResult;
                  }
                  return point;
                }).toList();
                segResult[segEntry.key] = points;
              } else {
                segResult[segEntry.key] = segEntry.value;
              }
            }
            return segResult;
          }
          return segment;
        }).toList();
        result[entry.key] = segments;
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
      if (entry.key == 'createdAt' && entry.value is String) {
        result[entry.key] = Timestamp.fromDate(DateTime.parse(entry.value as String));
      } else if (entry.key == 'segments' && entry.value is List) {
        // Convert nested segments with String dates back to Timestamp
        final segments = (entry.value as List).map((segment) {
          if (segment is Map<String, dynamic>) {
            final segResult = <String, dynamic>{};
            for (final segEntry in segment.entries) {
              if ((segEntry.key == 'startTime' || segEntry.key == 'endTime') && segEntry.value is String) {
                segResult[segEntry.key] = Timestamp.fromDate(DateTime.parse(segEntry.value as String));
              } else if (segEntry.key == 'points' && segEntry.value is List) {
                // Convert nested points with String dates back to Timestamp
                final points = (segEntry.value as List).map((point) {
                  if (point is Map<String, dynamic>) {
                    final pointResult = <String, dynamic>{};
                    for (final pointEntry in point.entries) {
                      if (pointEntry.key == 'timestamp' && pointEntry.value is String) {
                        pointResult[pointEntry.key] = Timestamp.fromDate(DateTime.parse(pointEntry.value as String));
                      } else {
                        pointResult[pointEntry.key] = pointEntry.value;
                      }
                    }
                    return pointResult;
                  }
                  return point;
                }).toList();
                segResult[segEntry.key] = points;
              } else {
                segResult[segEntry.key] = segEntry.value;
              }
            }
            return segResult;
          }
          return segment;
        }).toList();
        result[entry.key] = segments;
      } else {
        result[entry.key] = entry.value;
      }
    }
    return result;
  }
}


