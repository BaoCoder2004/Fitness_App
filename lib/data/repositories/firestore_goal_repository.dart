import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/goal.dart';
import '../../domain/repositories/goal_repository.dart';
import '../models/goal_model.dart';

class FirestoreGoalRepository implements GoalRepository {
  FirestoreGoalRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

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
    data.remove('id');
    await _collection(goal.userId).add(data);
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
    await _collection(goal.userId).doc(goal.id).set(data, SetOptions(merge: true));
  }

  @override
  Future<void> deleteGoal({
    required String userId,
    required String goalId,
  }) {
    return _collection(userId).doc(goalId).delete();
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

