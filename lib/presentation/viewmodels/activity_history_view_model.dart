import 'package:flutter/foundation.dart';

import '../../core/helpers/activity_type_helper.dart';
import '../../domain/entities/activity_session.dart';
import '../../domain/repositories/activity_repository.dart';
import '../../domain/repositories/auth_repository.dart';

enum HistoryFilter { day, week, month, year }

class ActivityHistoryViewModel extends ChangeNotifier {
  ActivityHistoryViewModel({
    required AuthRepository authRepository,
    required ActivityRepository activityRepository,
  })  : _authRepository = authRepository,
        _activityRepository = activityRepository;

  final AuthRepository _authRepository;
  final ActivityRepository _activityRepository;

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

  void setFilter(HistoryFilter f) {
    _filter = f;
    notifyListeners();
    loadHistory();
  }

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

    DateTime start;
    DateTime end;
    final now = _selectedDate;

    switch (_filter) {
      case HistoryFilter.day:
        start = DateTime(now.year, now.month, now.day);
        end = start.add(const Duration(days: 1));
        break;
      case HistoryFilter.week:
        // Lấy đầu tuần (thứ 2)
        final weekday = now.weekday;
        start = DateTime(now.year, now.month, now.day - (weekday - 1));
        end = start.add(const Duration(days: 7));
        break;
      case HistoryFilter.month:
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 1);
        break;
      case HistoryFilter.year:
        start = DateTime(now.year, 1, 1);
        end = DateTime(now.year + 1, 1, 1);
        break;
    }

    try {
      _allSessions = await _activityRepository.getActivitiesInRange(
        userId: userId,
        start: start,
        end: end,
      );
      _applyFilters();
    } catch (e) {
      debugPrint('Error loading history: $e');
      _allSessions = [];
      _sessions = [];
    }

    _loading = false;
    notifyListeners();
  }

  List<String> get availableActivityTypes {
    final types = _allSessions.map((s) => s.activityType).toSet().toList();
    types.sort();
    return types;
  }
}

