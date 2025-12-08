import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/services/goal_service.dart';
import '../../domain/entities/goal.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/goal_repository.dart';

class GoalListViewModel extends ChangeNotifier {
  GoalListViewModel({
    required AuthRepository authRepository,
    required GoalRepository goalRepository,
    required GoalService goalService,
  })  : _authRepository = authRepository,
        _goalRepository = goalRepository,
        _goalService = goalService;

  final AuthRepository _authRepository;
  final GoalRepository _goalRepository;
  final GoalService _goalService;

  StreamSubscription<List<Goal>>? _goalSub;

  bool _loading = false;
  String? _errorMessage;
  List<GoalProgress> _activeGoals = [];
  List<GoalProgress> _completedGoals = [];

  bool get loading => _loading;
  String? get errorMessage => _errorMessage;
  List<GoalProgress> get activeGoals => _activeGoals;
  List<GoalProgress> get completedGoals => _completedGoals;

  Future<void> load() async {
    final userId = _authRepository.currentUser?.uid;
    if (userId == null) {
      _setError('Bạn cần đăng nhập để xem mục tiêu');
      return;
    }

    _goalSub?.cancel();
    _setLoading(true);

    _goalSub = _goalRepository.watchGoals(userId: userId).listen(
      (goals) async {
        try {
          final progressList = <GoalProgress>[];
          for (final goal in goals) {
            // Tự động cancel reminder cho các goal đã expired
            await _goalService.cancelExpiredGoalReminder(goal);
            
            final progress = await _goalService.calculateProgress(goal);
            progressList.add(progress);
            // Không gọi setupGoalReminder ở đây để tránh schedule lại reminder mỗi lần load
            // Reminder đã được setup khi tạo goal mới hoặc thay đổi settings từ dialog
          }
          _activeGoals = progressList
              .where((p) => p.goal.status != GoalStatus.completed)
              .toList();
          _completedGoals = progressList
              .where((p) => p.goal.status == GoalStatus.completed)
              .toList();
          _setError(null);
        } catch (e) {
          if (e.toString().contains('network') || e.toString().contains('Network')) {
            _setError('Không có kết nối mạng. Vui lòng kiểm tra kết nối internet và thử lại.');
          } else if (e.toString().contains('permission-denied')) {
            _setError('Không có quyền xem mục tiêu. Vui lòng đăng nhập lại.');
          } else {
            _setError('Không thể tải danh sách mục tiêu. Vui lòng thử lại sau.');
          }
        } finally {
          _setLoading(false);
        }
      },
      onError: (error) {
        if (error.toString().contains('network') || error.toString().contains('Network')) {
          _setError('Không có kết nối mạng. Vui lòng kiểm tra kết nối internet và thử lại.');
        } else if (error.toString().contains('permission-denied')) {
          _setError('Không có quyền xem mục tiêu. Vui lòng đăng nhập lại.');
        } else {
          _setError('Không thể tải danh sách mục tiêu. Vui lòng thử lại sau.');
        }
        _setLoading(false);
      },
    );
  }

  Future<bool> deleteGoal(Goal goal) async {
    final userId = _authRepository.currentUser?.uid;
    if (userId == null || userId != goal.userId) {
      return false;
    }
    try {
      await _goalRepository.deleteGoal(
        userId: userId,
        goalId: goal.id,
      );
      await _goalService.cancelDeadlineNotifications(goal.id);
      await _goalService.cancelGoalReminder(goal.id);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> refresh() async {
    _setLoading(true);
    await load();
  }

  @override
  void dispose() {
    _goalSub?.cancel();
    super.dispose();
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

}
