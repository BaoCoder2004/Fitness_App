import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/services/advanced_health_calculator.dart';
import '../../core/services/chart_service.dart';
import '../../core/services/history_service.dart';
import '../../core/services/statistics_service.dart';
import '../../core/services/streak_service.dart';
import '../../core/services/notification_service.dart';
import '../../domain/entities/activity_session.dart';
import '../../domain/entities/streak.dart';
import '../../domain/entities/weight_record.dart';
import '../../domain/repositories/activity_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/streak_repository.dart';
import '../../domain/repositories/weight_history_repository.dart';

class StatisticsViewModel extends ChangeNotifier {
  StatisticsViewModel({
    required AuthRepository authRepository,
    required ActivityRepository activityRepository,
    required WeightHistoryRepository weightHistoryRepository,
    StreakRepository? streakRepository,
    NotificationService? notificationService,
  })  : _authRepository = authRepository,
        _activityRepository = activityRepository,
        _weightHistoryRepository = weightHistoryRepository,
        _streakRepository = streakRepository,
        _notificationService = notificationService {
    _historyService = HistoryService(
      activityRepository: _activityRepository,
      weightHistoryRepository: _weightHistoryRepository,
    );
    _chartService = ChartService();
    _streakService = StreakService(
      activityRepository: _activityRepository,
      streakRepository: _streakRepository,
    );
    _statisticsService = StatisticsService(
      activityRepository: _activityRepository,
    );
  }

  final AuthRepository _authRepository;
  final ActivityRepository _activityRepository;
  final WeightHistoryRepository _weightHistoryRepository;
  final StreakRepository? _streakRepository;
  late final HistoryService _historyService;
  late final ChartService _chartService;
  late final StreakService _streakService;
  late final StatisticsService _statisticsService;
  final NotificationService? _notificationService;

  StreamSubscription<List<ActivitySession>>? _activitySub;
  StreamSubscription<List<WeightRecord>>? _weightSub;

  TimeRange _selectedRange = TimeRange.week;
  TimeRange get selectedRange => _selectedRange;

  ChartMetric _selectedMetric = ChartMetric.calories;
  ChartMetric get selectedMetric => _selectedMetric;

  bool _loading = false;
  bool get loading => _loading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<ActivitySession> _activities = [];
  List<WeightRecord> _weightRecords = [];

  Map<DateTime, double> _chartData = {};
  Map<DateTime, double> get chartData => _chartData;

  Streak? _streak;
  Streak? get streak => _streak;

  GoalType _goalType = GoalType.calories;
  GoalType get goalType => _goalType;

  double _goalValue = 500.0; // Mục tiêu mặc định: 500 kcal/ngày
  double get goalValue => _goalValue;

  ActivityIntensity _activityLevel = ActivityIntensity.sedentary;
  ActivityIntensity get activityLevel => _activityLevel;

  double _weeklyActiveMinutes = 0;
  double get weeklyActiveMinutes => _weeklyActiveMinutes;

  int _weeklySessions = 0;
  int get weeklySessions => _weeklySessions;

  DetailedStatsResult? _detailedStats;
  DetailedStatsResult? get detailedStats => _detailedStats;

  List<MilestoneProgress> _milestones = [];
  List<MilestoneProgress> get milestones => _milestones;
  final Map<String, bool> _milestoneStates = {};
  final Map<TimeRange, DetailedStatsResult> _detailedCache = {};

  void setRange(TimeRange range) {
    _selectedRange = range;
    notifyListeners();
    _loadData();
  }

  void setMetric(ChartMetric metric) {
    _selectedMetric = metric;
    notifyListeners();
    _updateChartData();
  }

  void setGoalType(GoalType goalType) {
    _goalType = goalType;
    notifyListeners();
    _loadStreak();
  }

  void setGoalValue(double value) {
    _goalValue = value;
    notifyListeners();
    _loadStreak();
  }

  Future<void> _loadData() async {
    final userId = _authRepository.currentUser?.uid;
    if (userId == null) return;

    _loading = true;
    notifyListeners();

    try {
      // Cancel existing subscriptions
      await _activitySub?.cancel();
      await _weightSub?.cancel();

      // Load initial data
      await _loadInitialData(userId);

      // Setup real-time listeners
      _setupRealtimeListeners(userId);

      _errorMessage = null;
    } catch (e) {
      debugPrint('Error loading statistics: $e');
      _activities = [];
      _weightRecords = [];
      _chartData = {};
      _streak = null;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> _loadInitialData(String userId) async {
    // Load activities
    _activities = await _historyService.getActivitiesInRange(
      userId: userId,
      range: _selectedRange,
    );

    // Load weight records
    final now = DateTime.now();
    DateTime start;
    DateTime end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (_selectedRange) {
      case TimeRange.day:
        start = DateTime(now.year, now.month, now.day);
        break;
      case TimeRange.week:
        final weekday = now.weekday;
        start = now.subtract(Duration(days: weekday - 1));
        start = DateTime(start.year, start.month, start.day);
        break;
      case TimeRange.month:
        start = DateTime(now.year, now.month, 1);
        break;
      case TimeRange.year:
        start = DateTime(now.year, 1, 1);
        break;
      case TimeRange.custom:
        start = DateTime(now.year - 1, 1, 1);
        break;
    }

    _weightRecords = await _historyService.getWeightHistoryInRange(
      userId: userId,
      start: start,
      end: end,
    );

    _updateChartData();
    _updateActivityLevel();
    _detailedCache.clear();
    await _loadDetailedStatsForUser(userId);
    await _loadMilestonesForUser(userId);
    _loadStreak();
  }

  void _setupRealtimeListeners(String userId) {
    // Listen to today's activities for real-time updates
    // When activities change, reload the data
    _activitySub = _activityRepository
        .watchActivitiesOfDay(userId: userId, day: DateTime.now())
        .listen((_) {
      // Reload data when activities change
      _reloadData(userId);
    });

    // Listen to weight history changes
    _weightSub =
        _weightHistoryRepository.watchRecords(userId).listen((records) {
      // Update weight records and chart if needed
      final now = DateTime.now();
      DateTime start;
      DateTime end = DateTime(now.year, now.month, now.day, 23, 59, 59);

      switch (_selectedRange) {
        case TimeRange.day:
          start = DateTime(now.year, now.month, now.day);
          break;
        case TimeRange.week:
          final weekday = now.weekday;
          start = now.subtract(Duration(days: weekday - 1));
          start = DateTime(start.year, start.month, start.day);
          break;
        case TimeRange.month:
          start = DateTime(now.year, now.month, 1);
          break;
        case TimeRange.year:
          start = DateTime(now.year, 1, 1);
          break;
        case TimeRange.custom:
          start = DateTime(now.year - 1, 1, 1);
          break;
      }

      _weightRecords = records.where((record) {
        return record.recordedAt
                .isAfter(start.subtract(const Duration(days: 1))) &&
            record.recordedAt.isBefore(end.add(const Duration(days: 1)));
      }).toList();

      if (_selectedMetric == ChartMetric.weight) {
        _updateChartData();
      }
      notifyListeners();
    });
  }

  Future<void> _reloadData(String userId) async {
    try {
      // Reload activities
      _activities = await _historyService.getActivitiesInRange(
        userId: userId,
        range: _selectedRange,
      );

      _updateChartData();
      _updateActivityLevel();
      _detailedCache.remove(_selectedRange);
      await _loadDetailedStatsForUser(userId);
      await _loadMilestonesForUser(userId);
      _loadStreak();
      notifyListeners();
    } catch (e) {
      debugPrint('Error reloading statistics: $e');
    }
  }

  Future<void> _loadStreak() async {
    final userId = _authRepository.currentUser?.uid;
    if (userId == null) return;

    try {
      _streak = await _streakService.calculateStreak(
        userId: userId,
        goalType: _goalType,
        goalValue: _goalValue,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading streak: $e');
      _streak = null;
      // Không set error message cho streak vì nó không quan trọng
    }
  }

  void _updateChartData() {
    if (_selectedMetric == ChartMetric.weight) {
      _chartData = _chartService.aggregateWeights(
        records: _weightRecords,
        range: _selectedRange,
      );
    } else {
      _chartData = _chartService.aggregateActivities(
        activities: _activities,
        metric: _selectedMetric,
        range: _selectedRange,
      );
    }
    notifyListeners();
  }

  void _updateActivityLevel() {
    final summary = AdvancedHealthCalculator.evaluateActivityLevel(_activities);
    _activityLevel = summary.intensity;
    _weeklyActiveMinutes = summary.totalActiveMinutes;
    _weeklySessions = summary.sessionCount;
  }

  Future<void> _loadDetailedStatsForUser(String userId) async {
    final cached = _detailedCache[_selectedRange];
    if (cached != null) {
      _detailedStats = cached;
      return;
    }
    try {
      _detailedStats = await _statisticsService.getStats(
        userId: userId,
        range: _selectedRange,
      );
      _detailedCache[_selectedRange] = _detailedStats!;
    } catch (e) {
      debugPrint('Error loading period stats: $e');
      _detailedStats = null;
    }
  }

  Future<void> _loadMilestonesForUser(String userId) async {
    try {
      final results = await _statisticsService.getMilestones(userId: userId);
      for (final milestone in results) {
        final previousAchieved = _milestoneStates[milestone.id] ?? false;
        if (milestone.achieved && !previousAchieved) {
          await _notificationService?.showMilestoneNotification(
            milestoneId: milestone.id,
            milestoneName: milestone.title,
          );
        }
        _milestoneStates[milestone.id] = milestone.achieved;
      }
      _milestones = results;
    } catch (e) {
      debugPrint('Error loading milestones: $e');
      _milestones = [];
    }
  }

  Future<void> load() => _loadData();

  List<MapEntry<DateTime, double>> get sortedDataPoints {
    return _chartService.getSortedDataPoints(_chartData);
  }

  String getXAxisLabel(DateTime date) {
    return _chartService.getXAxisLabel(date, _selectedRange);
  }

  String getMetricLabel() {
    return _chartService.getMetricLabel(_selectedMetric);
  }

  @override
  void dispose() {
    _activitySub?.cancel();
    _weightSub?.cancel();
    super.dispose();
  }
}
