import '../entities/goal.dart';

abstract class GoalRepository {
  Future<void> createGoal(Goal goal);

  Future<void> updateGoal(Goal goal);

  Future<void> deleteGoal({
    required String userId,
    required String goalId,
  });

  Stream<List<Goal>> watchGoals({
    required String userId,
    GoalStatus? status,
  });

  Future<List<Goal>> fetchGoals({
    required String userId,
    GoalStatus? status,
  });
}

