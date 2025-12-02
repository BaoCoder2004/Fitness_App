import 'package:flutter/foundation.dart';

import '../../core/helpers/activity_type_helper.dart';
import '../../core/services/history_service.dart';
import '../../domain/entities/activity_session.dart';
import '../../domain/repositories/activity_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/weight_history_repository.dart';

enum HistoryFilter { day, week, month, year }

class ActivityHistoryViewModel extends ChangeNotifier {
  ActivityHistoryViewModel({
    required AuthRepository authRepository,
    required ActivityRepository activityRepository,
    WeightHistoryRepository? weightHistoryRepository,
  })  : _authRepository = authRepository,
        _activityRepository = activityRepository {
    _historyService = HistoryService(
      activityRepository: _activityRepository,
      weightHistoryRepository: weightHistoryRepository ?? _dummyWeightRepo,
    );
  }

  final AuthRepository _authRepository;
  final ActivityRepository _activityRepository;
  late final HistoryService _historyService;
  
  // Dummy weight repository nếu không được cung cấp (không ảnh hưởng đến logic)
  static final _dummyWeightRepo = _DummyWeightHistoryRepository();

  List<ActivitySession> _allSessions = [];
  List<ActivitySession> _sessions = [];
  List<ActivitySession> get sessions => _sessions;

  bool _loading = false;
  bool get loading => _loading;

  HistoryFilter _filter = HistoryFilter.week;
  HistoryFilter get filter => _filter;

  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  String? _activityTypeFilter;
  String? get activityTypeFilter => _activityTypeFilter;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;


  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
    loadHistory();
  }

  void setActivityTypeFilter(String? type) {
    _activityTypeFilter = type;
    _applyFilters();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void _applyFilters() {
    var filtered = _allSessions;

    if (_activityTypeFilter != null && _activityTypeFilter!.isNotEmpty) {
      filtered = filtered.where((s) => s.activityType == _activityTypeFilter).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((s) {
        final note = s.notes?.toLowerCase() ?? '';
        final display = ActivityTypeHelper.resolve(s.activityType).displayName.toLowerCase();
        return note.contains(q) || display.contains(q);
      }).toList();
    }

    _sessions = filtered;
    notifyListeners();
  }

  void removeSessionById(String id) {
    _allSessions = _allSessions.where((s) => s.id != id).toList();
    _sessions = _sessions.where((s) => s.id != id).toList();
    notifyListeners();
  }

  Future<void> loadHistory() async {
    final userId = _authRepository.currentUser?.uid;
    if (userId == null) return;

    _loading = true;
    notifyListeners();

    // Load available periods (weeks, months, years) with data
    _availableWeeks = await _historyService.getAvailableWeeks(userId);
    _availableMonths = await _historyService.getAvailableMonths(userId);
    _availableYears = await _historyService.getAvailableYears(userId);

    // Auto-select the most recent period if current selection is not available
    _autoSelectAvailablePeriod();

    DateTime start;
    DateTime end;
    final now = _selectedDate;

    switch (_filter) {
      case HistoryFilter.day:
        // Cho "Ngày": Tự động lấy dữ liệu hôm nay (không cần chọn ngày cụ thể)
        final today = DateTime.now();
        start = DateTime(today.year, today.month, today.day, 0, 0, 0);
        end = start.add(const Duration(days: 1));
        break;
      case HistoryFilter.week:
        // Lấy đầu tuần (thứ 2)
        final weekday = now.weekday;
        // Tính số ngày cần trừ để về thứ 2
        final daysToSubtract = weekday == 1 ? 0 : weekday - 1;
        final monday = now.subtract(Duration(days: daysToSubtract));
        start = DateTime(monday.year, monday.month, monday.day, 0, 0, 0);
        // End là 00:00:00 của thứ 2 tuần sau (7 ngày sau thứ 2 hiện tại)
        end = start.add(const Duration(days: 7));
        break;
      case HistoryFilter.month:
        start = DateTime(now.year, now.month, 1, 0, 0, 0);
        // End là 00:00:00 của tháng tiếp theo
        end = DateTime(now.year, now.month + 1, 1, 0, 0, 0);
        break;
      case HistoryFilter.year:
        start = DateTime(now.year, 1, 1, 0, 0, 0);
        // End là 00:00:00 của năm tiếp theo
        end = DateTime(now.year + 1, 1, 1, 0, 0, 0);
        break;
    }

    try {
      debugPrint('Loading history: filter=$_filter, start=$start, end=$end');
      _allSessions = await _activityRepository.getActivitiesInRange(
        userId: userId,
        start: start,
        end: end,
      );
      debugPrint('Loaded ${_allSessions.length} activities');
      
      // Debug: Log all activity dates to check if any are outside the range
      for (final session in _allSessions) {
        debugPrint('Activity: id=${session.id}, date=${session.date}, type=${session.activityType}');
      }
      
      _applyFilters();
    } catch (e) {
      debugPrint('Error loading history: $e');
      _allSessions = [];
      _sessions = [];
    }

    _loading = false;
    notifyListeners();
  }

  void _autoSelectAvailablePeriod() {
    // Tìm period gần nhất với _selectedDate hoặc chọn period đầu tiên
    switch (_filter) {
      case HistoryFilter.day:
        // Cho "Ngày": Tự động chọn hôm nay
        _selectedDate = DateTime.now();
        break;
      case HistoryFilter.week:
        if (_availableWeeks.isNotEmpty) {
          // Tìm tuần chứa _selectedDate hoặc gần nhất
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
      case HistoryFilter.month:
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
      case HistoryFilter.year:
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
    }
  }

  List<String> get availableActivityTypes {
    final types = _allSessions.map((s) => s.activityType).toSet().toList();
    types.sort();
    return types;
  }

  List<DateTime> _availableWeeks = [];
  List<DateTime> get availableWeeks => _availableWeeks;

  List<DateTime> _availableMonths = [];
  List<DateTime> get availableMonths => _availableMonths;

  List<DateTime> _availableYears = [];
  List<DateTime> get availableYears => _availableYears;

  void setFilter(HistoryFilter f) {
    _filter = f;
    // Auto-select first available period when changing filter
    _autoSelectFirstAvailablePeriod();
    notifyListeners();
    loadHistory();
  }

  void _autoSelectFirstAvailablePeriod() {
    switch (_filter) {
      case HistoryFilter.day:
        // Cho "Ngày": Tự động chọn hôm nay
        _selectedDate = DateTime.now();
        break;
      case HistoryFilter.week:
        if (_availableWeeks.isNotEmpty) {
          _selectedDate = _availableWeeks.first;
        }
        break;
      case HistoryFilter.month:
        if (_availableMonths.isNotEmpty) {
          _selectedDate = _availableMonths.first;
        }
        break;
      case HistoryFilter.year:
        if (_availableYears.isNotEmpty) {
          _selectedDate = _availableYears.first;
        }
        break;
    }
  }
}

// Dummy class để tránh lỗi khi không có WeightHistoryRepository
class _DummyWeightHistoryRepository implements WeightHistoryRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

