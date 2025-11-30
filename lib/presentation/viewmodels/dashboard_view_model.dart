import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/entities/activity_session.dart';
import '../../domain/repositories/activity_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/user_profile_repository.dart';

class DashboardStats {
  const DashboardStats({
    required this.totalDistanceKm,
    required this.totalCalories,
    required this.totalDuration,
    required this.currentWeight,
    this.recentActivity,
  });

  final double totalDistanceKm;
  final double totalCalories;
  final Duration totalDuration;
  final double? currentWeight;
  final ActivitySession? recentActivity;
}

class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel({
    required AuthRepository authRepository,
    required UserProfileRepository userProfileRepository,
    required ActivityRepository activityRepository,
  })  : _authRepository = authRepository,
        _userProfileRepository = userProfileRepository,
        _activityRepository = activityRepository;

  final AuthRepository _authRepository;
  final UserProfileRepository _userProfileRepository;
  final ActivityRepository _activityRepository;

  DashboardStats _stats = const DashboardStats(
    totalDistanceKm: 0,
    totalCalories: 0,
    totalDuration: Duration.zero,
    currentWeight: null,
  );
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<List<ActivitySession>>? _activitySub;

  DashboardStats get stats => _stats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    final user = _authRepository.currentUser;
    if (user == null) {
      _setError('Chưa đăng nhập');
      return;
    }
    _setLoading(true);
    try {
      final profile = await _userProfileRepository.fetchProfile(user.uid);
      final recentActivity =
          await _activityRepository.fetchMostRecentActivity(user.uid);
      _stats = DashboardStats(
        totalDistanceKm: 0,
        totalCalories: 0,
        totalDuration: Duration.zero,
        currentWeight: profile?.weightKg,
        recentActivity: recentActivity,
      );
      notifyListeners();
      _activitySub?.cancel();
      _activitySub = _activityRepository
          .watchActivitiesOfDay(userId: user.uid, day: DateTime.now())
          .listen(_updateFromActivities);
      _setError(null);
    } catch (e) {
      _setError('Không thể tải dữ liệu dashboard');
    } finally {
      _setLoading(false);
    }
  }

  void _updateFromActivities(List<ActivitySession> sessions) {
    final distance = sessions.fold<double>(
      0,
      (sum, session) => sum + (session.distanceKm ?? 0),
    );
    final calories = sessions.fold<double>(
      0,
      (sum, session) => sum + session.calories,
    );
    final duration = sessions.fold<Duration>(
      Duration.zero,
      (sum, session) => sum + Duration(seconds: session.durationSeconds),
    );
    _stats = DashboardStats(
      totalDistanceKm: distance,
      totalCalories: calories,
      totalDuration: duration,
      currentWeight: _stats.currentWeight,
      // Nếu không còn buổi tập nào trong ngày, ẩn thẻ "Hoạt động gần đây"
      recentActivity: sessions.isNotEmpty ? sessions.first : null,
    );
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  @override
  void dispose() {
    _activitySub?.cancel();
    super.dispose();
  }
}

