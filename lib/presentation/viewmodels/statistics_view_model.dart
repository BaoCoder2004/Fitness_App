import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/services/advanced_health_calculator.dart';
import '../../core/services/chart_service.dart';
import '../../core/services/history_service.dart';
import '../../core/services/statistics_service.dart';
import '../../core/services/streak_service.dart' as streakLib;
import '../../core/services/notification_service.dart';
import '../../domain/entities/activity_session.dart';
import '../../domain/entities/streak.dart';
import '../../domain/entities/weight_record.dart';
import '../../domain/entities/goal.dart';
import '../../domain/repositories/activity_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/goal_repository.dart';
import '../../domain/repositories/streak_repository.dart';
import '../../domain/repositories/weight_history_repository.dart';

class StatisticsViewModel extends ChangeNotifier {
  StatisticsViewModel({
    required AuthRepository authRepository,
    required ActivityRepository activityRepository,
    required WeightHistoryRepository weightHistoryRepository,
    GoalRepository? goalRepository,
    StreakRepository? streakRepository,
    NotificationService? notificationService,
  })  : _authRepository = authRepository,
        _activityRepository = activityRepository,
        _weightHistoryRepository = weightHistoryRepository,
        _goalRepository = goalRepository,
        _streakRepository = streakRepository,
        _notificationService = notificationService {
    _historyService = HistoryService(
      activityRepository: _activityRepository,
      weightHistoryRepository: _weightHistoryRepository,
    );
    _chartService = ChartService();
    _streakService = streakLib.StreakService(
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
  final GoalRepository? _goalRepository;
  final StreakRepository? _streakRepository;
  late final HistoryService _historyService;
  late final ChartService _chartService;
  late final streakLib.StreakService _streakService;
  late final StatisticsService _statisticsService;
  final NotificationService? _notificationService;

  StreamSubscription<List<ActivitySession>>? _activitySub;
  StreamSubscription<List<WeightRecord>>? _weightSub;

  TimeRange _selectedRange = TimeRange.week;
  TimeRange get selectedRange => _selectedRange;

  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

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

  // Dùng GoalType từ streak_service để tính streak
  streakLib.GoalType _goalType = streakLib.GoalType.calories;
  streakLib.GoalType get goalType => _goalType;

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

  List<DateTime> _availableWeeks = [];
  List<DateTime> get availableWeeks => _availableWeeks;

  List<DateTime> _availableMonths = [];
  List<DateTime> get availableMonths => _availableMonths;

  List<DateTime> _availableYears = [];
  List<DateTime> get availableYears => _availableYears;

  void setRange(TimeRange range) {
    _selectedRange = range;
    // Auto-select first available period when changing range (trừ "Ngày")
    if (range != TimeRange.day) {
      _autoSelectFirstAvailablePeriod();
    } else {
      // Cho "Ngày": Tự động chọn hôm nay
      _selectedDate = DateTime.now();
    }
    notifyListeners();
    _loadData();
  }

  void _autoSelectFirstAvailablePeriod() {
    switch (_selectedRange) {
      case TimeRange.week:
        if (_availableWeeks.isNotEmpty) {
          _selectedDate = _availableWeeks.first;
        }
        break;
      case TimeRange.month:
        if (_availableMonths.isNotEmpty) {
          _selectedDate = _availableMonths.first;
        }
        break;
      case TimeRange.year:
        if (_availableYears.isNotEmpty) {
          _selectedDate = _availableYears.first;
        }
        break;
      case TimeRange.day:
      case TimeRange.custom:
        break;
    }
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
    _loadData();
  }

  void _autoSelectAvailablePeriod() {
    // Tìm period gần nhất với _selectedDate hoặc chọn period đầu tiên
    switch (_selectedRange) {
      case TimeRange.week:
        if (_availableWeeks.isNotEmpty) {
          // Tìm tuần gần nhất với _selectedDate (không vượt quá)
          DateTime? closestWeek;
          for (final week in _availableWeeks) {
            final weekEnd = week.add(const Duration(days: 6));
            if (selectedDate.isAfter(week.subtract(const Duration(days: 1))) &&
                selectedDate.isBefore(weekEnd.add(const Duration(days: 1)))) {
              _selectedDate = week;
              return;
            }
            if (week.isBefore(_selectedDate) || week.isAtSameMomentAs(_selectedDate)) {
              closestWeek = week;
            }
          }
          if (closestWeek != null) {
            _selectedDate = closestWeek;
          } else {
            _selectedDate = _availableWeeks.first;
          }
        }
        break;
      case TimeRange.month:
        if (_availableMonths.isNotEmpty) {
          // Tìm tháng chứa _selectedDate hoặc gần nhất
          DateTime? closestMonth;
          for (final month in _availableMonths) {
            if (selectedDate.year == month.year && selectedDate.month == month.month) {
              _selectedDate = month;
              return;
            }
            if (month.isBefore(_selectedDate) || month.isAtSameMomentAs(_selectedDate)) {
              closestMonth = month;
            }
          }
          if (closestMonth != null) {
            _selectedDate = closestMonth;
          } else {
            _selectedDate = _availableMonths.first;
          }
        }
        break;
      case TimeRange.year:
        if (_availableYears.isNotEmpty) {
          // Tìm năm chứa _selectedDate hoặc gần nhất
          DateTime? closestYear;
          for (final year in _availableYears) {
            if (selectedDate.year == year.year) {
              _selectedDate = year;
              return;
            }
            if (year.isBefore(_selectedDate) || year.isAtSameMomentAs(_selectedDate)) {
              closestYear = year;
            }
          }
          if (closestYear != null) {
            _selectedDate = closestYear;
          } else {
            _selectedDate = _availableYears.first;
          }
        }
        break;
      case TimeRange.day:
      case TimeRange.custom:
        break;
    }
  }

  void setMetric(ChartMetric metric) {
    _selectedMetric = metric;
    notifyListeners();
    _updateChartData();
  }

  void setGoalType(streakLib.GoalType goalType) {
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

    // Load và aggregate goals để set goalType và goalValue cho streak
    await _loadAndAggregateGoals(userId);

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
    // Load available periods (weeks, months, years) with data
    _availableWeeks = await _historyService.getAvailableWeeks(userId);
    _availableMonths = await _historyService.getAvailableMonths(userId);
    _availableYears = await _historyService.getAvailableYears(userId);

    // Auto-select the most recent period if current selection is not available
    _autoSelectAvailablePeriod();

    // Load activities
    _activities = await _historyService.getActivitiesInRange(
      userId: userId,
      range: _selectedRange,
      referenceDate: _selectedDate,
    );

    // Load weight records
    final now = _selectedDate;
    DateTime start;
    DateTime end;

    switch (_selectedRange) {
      case TimeRange.day:
        // Cho "Ngày": Lấy hôm qua và hôm nay để so sánh
        final today = DateTime.now();
        final yesterday = today.subtract(const Duration(days: 1));
        start = DateTime(yesterday.year, yesterday.month, yesterday.day);
        end = DateTime(today.year, today.month, today.day, 23, 59, 59);
        break;
      case TimeRange.week:
        // Cho "Tuần": Lấy từ đầu tuần (thứ 2) đến cuối tuần (chủ nhật)
        final weekday = now.weekday;
        start = now.subtract(Duration(days: weekday - 1));
        start = DateTime(start.year, start.month, start.day);
        // Tính cuối tuần (chủ nhật)
        end = start.add(const Duration(days: 6));
        end = DateTime(end.year, end.month, end.day, 23, 59, 59);
        break;
      case TimeRange.month:
        // Cho "Tháng": Lấy trọn tháng được chọn
        start = DateTime(now.year, now.month, 1);
        final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
        end = DateTime(
          lastDayOfMonth.year,
          lastDayOfMonth.month,
          lastDayOfMonth.day,
          23,
          59,
          59,
        );
        break;
      case TimeRange.year:
        start = DateTime(now.year, 1, 1);
        end = DateTime(now.year, 12, 31, 23, 59, 59);
        break;
      case TimeRange.custom:
        start = DateTime(now.year - 1, 1, 1);
        end = DateTime(now.year, now.month, now.day, 23, 59, 59);
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
      final now = _selectedDate;
      DateTime start;
      DateTime end;

      switch (_selectedRange) {
        case TimeRange.day:
          // Cho "Ngày": Lấy hôm qua và hôm nay để so sánh
          final today = DateTime.now();
          final yesterday = today.subtract(const Duration(days: 1));
          start = DateTime(yesterday.year, yesterday.month, yesterday.day);
          end = DateTime(today.year, today.month, today.day, 23, 59, 59);
          break;
        case TimeRange.week:
          // Cho "Tuần": Lấy từ đầu tuần (thứ 2) đến cuối tuần (chủ nhật)
          final weekday = now.weekday;
          start = now.subtract(Duration(days: weekday - 1));
          start = DateTime(start.year, start.month, start.day);
          // Tính cuối tuần (chủ nhật)
          end = start.add(const Duration(days: 6));
          end = DateTime(end.year, end.month, end.day, 23, 59, 59);
          break;
        case TimeRange.month:
          // Cho "Tháng": Lấy trọn tháng được chọn
          start = DateTime(now.year, now.month, 1);
          final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
          end = DateTime(
            lastDayOfMonth.year,
            lastDayOfMonth.month,
            lastDayOfMonth.day,
            23,
            59,
            59,
          );
          break;
        case TimeRange.year:
          start = DateTime(now.year, 1, 1);
          end = DateTime(now.year, 12, 31, 23, 59, 59);
          break;
        case TimeRange.custom:
          start = DateTime(now.year - 1, 1, 1);
          end = DateTime(now.year, now.month, now.day, 23, 59, 59);
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
        referenceDate: _selectedDate,
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

  Future<void> _loadAndAggregateGoals(String userId) async {
    if (_goalRepository == null) return;

    try {
      // Load tất cả active goals
      final allGoals = await _goalRepository.fetchGoals(userId: userId);
      final activeGoals = allGoals.where((g) => g.status == GoalStatus.active).toList();

      // Chỉ tính streak cho daily goals (timeFrame = daily hoặc null)
      final dailyGoals = activeGoals.where((g) => 
        g.timeFrame == null || g.timeFrame == GoalTimeFrame.daily
      ).toList();

      if (dailyGoals.isEmpty) {
        // Không có daily goals, giữ giá trị mặc định
        return;
      }

      // Aggregate goals theo loại: ưu tiên calories > distance > duration
      double? caloriesTotal;
      double? distanceTotal;
      double? durationTotal;

      for (final goal in dailyGoals) {
        switch (goal.goalType) {
          case GoalType.calories:
            caloriesTotal = (caloriesTotal ?? 0) + goal.targetValue;
            break;
          case GoalType.distance:
            distanceTotal = (distanceTotal ?? 0) + goal.targetValue;
            break;
          case GoalType.duration:
            durationTotal = (durationTotal ?? 0) + goal.targetValue;
            break;
          case GoalType.weight:
            // Weight goals không tính vào streak
            break;
        }
      }

      // Set goalType và goalValue theo thứ tự ưu tiên
      if (caloriesTotal != null && caloriesTotal > 0) {
        _goalType = streakLib.GoalType.calories;
        _goalValue = caloriesTotal;
        debugPrint('Streak: Set goalType=calories, goalValue=$caloriesTotal (from ${dailyGoals.length} daily goals)');
      } else if (distanceTotal != null && distanceTotal > 0) {
        _goalType = streakLib.GoalType.distance;
        _goalValue = distanceTotal;
        debugPrint('Streak: Set goalType=distance, goalValue=$distanceTotal (from ${dailyGoals.length} daily goals)');
      } else if (durationTotal != null && durationTotal > 0) {
        _goalType = streakLib.GoalType.duration;
        _goalValue = durationTotal;
        debugPrint('Streak: Set goalType=duration, goalValue=$durationTotal (from ${dailyGoals.length} daily goals)');
      } else {
        debugPrint('Streak: No daily goals found, using default goalValue=$_goalValue');
      }
    } catch (e) {
      debugPrint('Error loading goals for streak: $e');
      // Giữ giá trị mặc định nếu có lỗi
    }
  }

  Future<void> _loadStreak() async {
    final userId = _authRepository.currentUser?.uid;
    if (userId == null) return;

    try {
      debugPrint('Streak: Calculating with goalType=${_goalType.name}, goalValue=$_goalValue');
      _streak = await _streakService.calculateStreak(
        userId: userId,
        goalType: _goalType,
        goalValue: _goalValue,
      );
      debugPrint('Streak: Result - currentStreak=${_streak?.currentStreak}, longestStreak=${_streak?.longestStreak}');
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading streak: $e');
      _streak = null;
      // Không set error message cho streak vì nó không quan trọng
    }
  }

  void _updateChartData() {
    // Tính start và end dựa trên selectedRange và selectedDate
    final now = _selectedDate;
    DateTime? start;
    DateTime? end;

    switch (_selectedRange) {
      case TimeRange.day:
        // Cho "Ngày": Lấy hôm qua và hôm nay để so sánh
        final today = DateTime.now();
        final yesterday = today.subtract(const Duration(days: 1));
        start = DateTime(yesterday.year, yesterday.month, yesterday.day);
        end = DateTime(today.year, today.month, today.day, 23, 59, 59);
        break;
      case TimeRange.week:
        // Cho "Tuần": Từ thứ 2 đến Chủ nhật
        final weekday = now.weekday;
        final monday = now.subtract(Duration(days: weekday - 1));
        start = DateTime(monday.year, monday.month, monday.day);
        final sunday = monday.add(const Duration(days: 6));
        end = DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59);
        break;
      case TimeRange.month:
        // Cho "Tháng": Từ đầu tháng đến cuối tháng
        start = DateTime(now.year, now.month, 1);
        final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
        end = DateTime(now.year, now.month, lastDayOfMonth.day, 23, 59, 59);
        break;
      case TimeRange.year:
        // Cho "Năm": Từ đầu năm đến cuối năm
        start = DateTime(now.year, 1, 1);
        end = DateTime(now.year, 12, 31, 23, 59, 59);
        break;
      case TimeRange.custom:
        // Không filter cho custom
        break;
    }

    if (_selectedMetric == ChartMetric.weight) {
      _chartData = _chartService.aggregateWeights(
        records: _weightRecords,
        range: _selectedRange,
        start: start,
        end: end,
      );
    } else {
      _chartData = _chartService.aggregateActivities(
        activities: _activities,
        metric: _selectedMetric,
        range: _selectedRange,
        start: start,
        end: end,
      );
    }
    notifyListeners();
  }

  void _updateActivityLevel() {
    // Tính activity level dựa trên range được chọn
    // "Phút/tuần" và "Buổi/tuần" hiển thị dữ liệu của period được chọn
    List<ActivitySession> activitiesToEvaluate = _activities;
    DateTime? reference;
    Duration window = const Duration(days: 7);
    
    switch (_selectedRange) {
      case TimeRange.week:
        // Cho "Tuần": Tính theo tuần được chọn (từ thứ 2 đến Chủ nhật)
        // _selectedDate là thứ 2 của tuần, tính từ thứ 2 đến Chủ nhật (7 ngày)
        final monday = _selectedDate;
        final sunday = monday.add(const Duration(days: 6));
        // Filter activities trong tuần được chọn
        activitiesToEvaluate = _activities.where((activity) {
          final activityDate = DateTime(
            activity.date.year,
            activity.date.month,
            activity.date.day,
          );
          final mondayDate = DateTime(monday.year, monday.month, monday.day);
          final sundayDate = DateTime(sunday.year, sunday.month, sunday.day);
          return !activityDate.isBefore(mondayDate) && !activityDate.isAfter(sundayDate);
        }).toList();
        
        // Tính từ thứ 2 đến Chủ nhật (reference = Chủ nhật)
        reference = DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59);
        window = const Duration(days: 7);
        break;
      case TimeRange.month:
        // Cho "Tháng": Tính theo tháng được chọn
        // _selectedDate là ngày đầu tháng, tính tất cả activities trong tháng đó
        final monthStart = _selectedDate;
        final lastDayOfMonth = DateTime(monthStart.year, monthStart.month + 1, 0);
        final monthEnd = DateTime(monthStart.year, monthStart.month, lastDayOfMonth.day, 23, 59, 59);
        
        // Filter activities trong tháng được chọn
        activitiesToEvaluate = _activities.where((activity) {
          final activityDate = DateTime(
            activity.date.year,
            activity.date.month,
            activity.date.day,
          );
          final startDate = DateTime(monthStart.year, monthStart.month, monthStart.day);
          final endDate = DateTime(monthEnd.year, monthEnd.month, monthEnd.day);
          return !activityDate.isBefore(startDate) && !activityDate.isAfter(endDate);
        }).toList();
        
        // Tính tổng phút và số buổi trong tháng
        double totalMinutes = 0;
        int sessions = 0;
        for (final session in activitiesToEvaluate) {
          totalMinutes += session.durationSeconds / 60.0;
          sessions += 1;
        }
        
        // Tính số tuần trong tháng (số ngày trong tháng / 7)
        final daysInMonth = monthEnd.difference(monthStart).inDays + 1;
        final weeksInMonth = (daysInMonth / 7.0);
        
        // Hiển thị trung bình/tuần
        // Nếu có ít nhất 1 buổi, đảm bảo hiển thị ít nhất 1 buổi/tuần (làm tròn lên)
        _weeklyActiveMinutes = weeksInMonth > 0 ? (totalMinutes / weeksInMonth) : totalMinutes;
        if (sessions > 0 && weeksInMonth > 0) {
          // Làm tròn lên để đảm bảo nếu có ít nhất 1 buổi thì hiển thị ít nhất 1
          _weeklySessions = (sessions / weeksInMonth).ceil().clamp(1, sessions);
        } else {
          _weeklySessions = sessions;
        }
        
        // Tính activity level dựa trên tổng phút
        _activityLevel = AdvancedHealthCalculator.evaluateActivityLevel(
          activitiesToEvaluate,
          reference: monthEnd,
          window: Duration(days: daysInMonth),
        ).intensity;
        return; // Return sớm vì đã tính xong
      case TimeRange.year:
        // Cho "Năm": Tính theo 7 ngày gần nhất từ hôm nay
        reference = DateTime.now();
        window = const Duration(days: 7);
        break;
      case TimeRange.day:
      case TimeRange.custom:
        // Cho "Ngày" và "Custom": Tính theo 7 ngày gần nhất
        reference = DateTime.now();
        window = const Duration(days: 7);
        break;
    }
    
    final summary = AdvancedHealthCalculator.evaluateActivityLevel(
      activitiesToEvaluate,
      reference: reference,
      window: window,
    );
    _activityLevel = summary.intensity;
    _weeklyActiveMinutes = summary.totalActiveMinutes;
    _weeklySessions = summary.sessionCount;
  }

  Future<void> _loadDetailedStatsForUser(String userId) async {
    // Clear cache when date changes to ensure fresh data
    _detailedCache.clear();
    try {
      _detailedStats = await _statisticsService.getStats(
        userId: userId,
        range: _selectedRange,
        reference: _selectedDate,
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

  /// Lấy giá trị cao nhất và thấp nhất từ dữ liệu gốc (đặc biệt quan trọng cho cân nặng)
  double? get maxValue {
    if (_selectedMetric == ChartMetric.weight) {
      // Với cân nặng, lấy từ dữ liệu gốc (tất cả records)
      if (_weightRecords.isEmpty) return null;
      return _weightRecords.map((r) => r.weightKg).reduce((a, b) => a > b ? a : b);
    } else {
      // Với các metrics khác, lấy từ dữ liệu đã aggregate
      final dataPoints = sortedDataPoints;
      if (dataPoints.isEmpty) return null;
      return dataPoints.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    }
  }

  double? get minValue {
    if (_selectedMetric == ChartMetric.weight) {
      // Với cân nặng, lấy từ dữ liệu gốc (tất cả records)
      if (_weightRecords.isEmpty) return null;
      return _weightRecords.map((r) => r.weightKg).reduce((a, b) => a < b ? a : b);
    } else {
      // Với các metrics khác, lấy từ dữ liệu đã aggregate
      final dataPoints = sortedDataPoints;
      if (dataPoints.isEmpty) return null;
      return dataPoints.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    }
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
