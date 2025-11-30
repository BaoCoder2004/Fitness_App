import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/notification_service.dart';

class NotificationSettingsViewModel extends ChangeNotifier {
  NotificationSettingsViewModel({
    required NotificationService notificationService,
  }) : _notificationService = notificationService;

  final NotificationService _notificationService;

  static const _dailyEnabledKey = 'notifications.daily.enabled';
  static const _dailyHourKey = 'notifications.daily.hour';
  static const _dailyMinuteKey = 'notifications.daily.minute';

  static const _weeklyEnabledKey = 'notifications.weekly.enabled';
  static const _weeklyHourKey = 'notifications.weekly.hour';
  static const _weeklyMinuteKey = 'notifications.weekly.minute';
  static const _weeklyDaysKey = 'notifications.weekly.days';

  static const _goalEnabledKey = 'notifications.goal.enabled';
  static const _goalHourKey = 'notifications.goal.hour';
  static const _goalMinuteKey = 'notifications.goal.minute';
  static const _goalDayKey = 'notifications.goal.day';

  bool _loading = true;
  bool _dailyEnabled = false;
  TimeOfDay _dailyTime = const TimeOfDay(hour: 7, minute: 0);

  bool _weeklyEnabled = false;
  TimeOfDay _weeklyTime = const TimeOfDay(hour: 18, minute: 0);
  final Set<int> _weeklyDays = {
    DateTime.monday,
    DateTime.wednesday,
    DateTime.friday,
  };

  bool _goalCheckEnabled = false;
  TimeOfDay _goalCheckTime = const TimeOfDay(hour: 20, minute: 0);
  int _goalCheckDay = DateTime.sunday;
  bool _permissionDenied = false;
  bool _exactAlarmWarning = false;

  bool get loading => _loading;
  bool get dailyEnabled => _dailyEnabled;
  TimeOfDay get dailyTime => _dailyTime;

  bool get weeklyEnabled => _weeklyEnabled;
  TimeOfDay get weeklyTime => _weeklyTime;
  List<int> get weeklyDays => _weeklyDays.toList()..sort();

  bool get goalCheckEnabled => _goalCheckEnabled;
  TimeOfDay get goalCheckTime => _goalCheckTime;
  int get goalCheckDay => _goalCheckDay;
  bool get permissionDenied => _permissionDenied;
  bool get exactAlarmWarning => _exactAlarmWarning;

  Future<void> load() async {
    _loading = true;
    notifyListeners();

    await _refreshPermissionState();
    await _refreshExactAlarmState();

    final prefs = await SharedPreferences.getInstance();
    _dailyEnabled = prefs.getBool(_dailyEnabledKey) ?? false;
    _dailyTime = _readTime(prefs, _dailyHourKey, _dailyMinuteKey) ?? _dailyTime;

    _weeklyEnabled = prefs.getBool(_weeklyEnabledKey) ?? false;
    final savedWeeklyDays =
        prefs.getStringList(_weeklyDaysKey)?.map(int.parse).toSet();
    if (savedWeeklyDays != null && savedWeeklyDays.isNotEmpty) {
      _weeklyDays
        ..clear()
        ..addAll(savedWeeklyDays);
    }
    _weeklyTime =
        _readTime(prefs, _weeklyHourKey, _weeklyMinuteKey) ?? _weeklyTime;

    _goalCheckEnabled = prefs.getBool(_goalEnabledKey) ?? false;
    _goalCheckTime =
        _readTime(prefs, _goalHourKey, _goalMinuteKey) ?? _goalCheckTime;
    _goalCheckDay = prefs.getInt(_goalDayKey) ?? _goalCheckDay;

    _loading = false;
    notifyListeners();
  }

  Future<bool> setDailyEnabled(bool value) async {
    _log('setDailyEnabled -> $value');
    final previous = _dailyEnabled;
    _dailyEnabled = value;
    notifyListeners();

    if (value && !await _ensurePermission()) {
      _log('Permission check failed for daily toggle');
      _dailyEnabled = previous;
      notifyListeners();
      return false;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_dailyEnabledKey, value);
      if (value) {
        final fallbackUsed = await _notificationService.scheduleDailyReminder(
          hour: _dailyTime.hour,
          minute: _dailyTime.minute,
          title: 'Đến giờ luyện tập rồi!',
          body: 'Hãy hoàn thành bài tập hôm nay để giữ phong độ nhé.',
        );
        _setExactAlarmWarning(fallbackUsed);
      } else {
        await _notificationService.cancelDailyReminder();
        await _refreshExactAlarmState();
      }
      return true;
    } catch (e, stack) {
      _log('Failed to update daily reminder: $e');
      debugPrint(stack.toString());
      _dailyEnabled = previous;
      notifyListeners();
      return false;
    }
  }

  Future<void> setDailyTime(TimeOfDay time) async {
    _dailyTime = time;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dailyHourKey, time.hour);
    await prefs.setInt(_dailyMinuteKey, time.minute);
    if (_dailyEnabled) {
      final fallbackUsed = await _notificationService.scheduleDailyReminder(
        hour: time.hour,
        minute: time.minute,
        title: 'Đến giờ luyện tập rồi!',
        body: 'Hãy hoàn thành bài tập hôm nay để giữ phong độ nhé.',
      );
      _setExactAlarmWarning(fallbackUsed);
    }
    notifyListeners();
  }

  Future<bool> setWeeklyEnabled(bool value) async {
    _log('setWeeklyEnabled -> $value');
    final previous = _weeklyEnabled;
    _weeklyEnabled = value;
    notifyListeners();

    if (value && !await _ensurePermission()) {
      _log('Permission check failed for weekly toggle');
      _weeklyEnabled = previous;
      notifyListeners();
      return false;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_weeklyEnabledKey, value);
      if (value && _weeklyDays.isNotEmpty) {
        final fallbackUsed = await _notificationService.scheduleWeeklyReminder(
          weekdays: _weeklyDays.toList(),
          hour: _weeklyTime.hour,
          minute: _weeklyTime.minute,
          title: 'Hẹn tập luyện',
          body: 'Hôm nay nằm trong lịch tập của bạn. Sẵn sàng thôi nào!',
        );
        _setExactAlarmWarning(fallbackUsed);
      } else {
        await _notificationService.cancelWeeklyReminder();
        await _refreshExactAlarmState();
      }
      return true;
    } catch (e, stack) {
      _log('Failed to update weekly reminder: $e');
      debugPrint(stack.toString());
      _weeklyEnabled = previous;
      notifyListeners();
      return false;
    }
  }

  Future<void> setWeeklyTime(TimeOfDay time) async {
    _weeklyTime = time;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_weeklyHourKey, time.hour);
    await prefs.setInt(_weeklyMinuteKey, time.minute);
    if (_weeklyEnabled && _weeklyDays.isNotEmpty) {
      final fallbackUsed = await _notificationService.scheduleWeeklyReminder(
        weekdays: _weeklyDays.toList(),
        hour: time.hour,
        minute: time.minute,
        title: 'Hẹn tập luyện',
        body: 'Hôm nay nằm trong lịch tập của bạn. Sẵn sàng thôi nào!',
      );
      _setExactAlarmWarning(fallbackUsed);
    }
    notifyListeners();
  }

  Future<void> toggleWeeklyDay(int weekday) async {
    if (_weeklyDays.contains(weekday)) {
      _weeklyDays.remove(weekday);
    } else {
      _weeklyDays.add(weekday);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _weeklyDaysKey,
      _weeklyDays.map((e) => e.toString()).toList(),
    );

    if (_weeklyEnabled && _weeklyDays.isNotEmpty) {
      final fallbackUsed = await _notificationService.scheduleWeeklyReminder(
        weekdays: _weeklyDays.toList(),
        hour: _weeklyTime.hour,
        minute: _weeklyTime.minute,
        title: 'Hẹn tập luyện',
        body: 'Hôm nay nằm trong lịch tập của bạn. Sẵn sàng thôi nào!',
      );
      _setExactAlarmWarning(fallbackUsed);
    } else if (_weeklyEnabled && _weeklyDays.isEmpty) {
      await _notificationService.cancelWeeklyReminder();
      await _refreshExactAlarmState();
    }
    notifyListeners();
  }

  Future<bool> setGoalCheckEnabled(bool value) async {
    _log('setGoalCheckEnabled -> $value');
    final previous = _goalCheckEnabled;
    _goalCheckEnabled = value;
    notifyListeners();

    if (value && !await _ensurePermission()) {
      _log('Permission check failed for goal-check toggle');
      _goalCheckEnabled = previous;
      notifyListeners();
      return false;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_goalEnabledKey, value);
      if (value) {
        final fallbackUsed = await _notificationService.scheduleGoalCheckReminder(
          weekdays: [_goalCheckDay],
          hour: _goalCheckTime.hour,
          minute: _goalCheckTime.minute,
        );
        _setExactAlarmWarning(fallbackUsed);
      } else {
        await _notificationService.cancelGoalCheckReminder();
        await _refreshExactAlarmState();
      }
      return true;
    } catch (e, stack) {
      _log('Failed to update goal-check reminder: $e');
      debugPrint(stack.toString());
      _goalCheckEnabled = previous;
      notifyListeners();
      return false;
    }
  }

  Future<void> setGoalCheckTime(TimeOfDay time) async {
    _goalCheckTime = time;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_goalHourKey, time.hour);
    await prefs.setInt(_goalMinuteKey, time.minute);
    if (_goalCheckEnabled) {
      final fallbackUsed = await _notificationService.scheduleGoalCheckReminder(
        weekdays: [_goalCheckDay],
        hour: time.hour,
        minute: time.minute,
      );
      _setExactAlarmWarning(fallbackUsed);
    }
    notifyListeners();
  }

  Future<void> setGoalCheckDay(int weekday) async {
    _goalCheckDay = weekday;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_goalDayKey, weekday);
    if (_goalCheckEnabled) {
      final fallbackUsed = await _notificationService.scheduleGoalCheckReminder(
        weekdays: [_goalCheckDay],
        hour: _goalCheckTime.hour,
        minute: _goalCheckTime.minute,
      );
      _setExactAlarmWarning(fallbackUsed);
    }
    notifyListeners();
  }

  Future<void> openExactAlarmSettings() async {
    await _notificationService.openExactAlarmSettings();
  }

  TimeOfDay? _readTime(
    SharedPreferences prefs,
    String hourKey,
    String minuteKey,
  ) {
    final hour = prefs.getInt(hourKey);
    final minute = prefs.getInt(minuteKey);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<bool> _ensurePermission() async {
    _log('_ensurePermission start');
    try {
      final alreadyGranted =
          await _notificationService.areNotificationsEnabled();
      _log('areNotificationsEnabled => $alreadyGranted');
      if (alreadyGranted) {
        _setPermissionDenied(false);
        return true;
      }
    } catch (e) {
      _log('areNotificationsEnabled threw $e');
    }

    var status = await Permission.notification.status;
    _log('permission_handler status => $status');
    if (status.isGranted) {
      _setPermissionDenied(false);
      return true;
    }

    try {
      final pluginGranted = await _notificationService.requestPermission();
      _log('plugin requestPermission => $pluginGranted');
      if (pluginGranted) {
        _setPermissionDenied(false);
        return true;
      }
    } catch (e) {
      _log('requestPermission threw $e');
    }

    if (status.isDenied || status.isRestricted) {
      final requested = await Permission.notification.request();
      _log('permission_handler request() => $requested');
      if (requested.isGranted) {
        await _notificationService.requestPermission();
        _setPermissionDenied(false);
        return true;
      }
      status = requested;
    }

    _log('permission final status => ${status.isGranted}');
    _setPermissionDenied(!status.isGranted);
    return status.isGranted;
  }

  Future<void> _refreshPermissionState() async {
    _log('_refreshPermissionState start');
    try {
      final enabled = await _notificationService.areNotificationsEnabled();
      _log('_refreshPermissionState areNotificationsEnabled => $enabled');
      if (enabled) {
        _setPermissionDenied(false);
        return;
      }
    } catch (e) {
      _log('_refreshPermissionState areNotificationsEnabled threw $e');
    }
    final status = await Permission.notification.status;
    _log('_refreshPermissionState permission_handler status => $status');
    _setPermissionDenied(!status.isGranted);
  }

  Future<void> _refreshExactAlarmState() async {
    final allowed = await _notificationService.hasExactAlarmPermission();
    _setExactAlarmWarning(!allowed && (_dailyEnabled || _weeklyEnabled || _goalCheckEnabled));
  }

  void _setPermissionDenied(bool value) {
    if (_permissionDenied == value) return;
    _permissionDenied = value;
    notifyListeners();
  }

  void _setExactAlarmWarning(bool value) {
    if (_exactAlarmWarning == value) return;
    _exactAlarmWarning = value;
    notifyListeners();
  }

  void _log(String message) {
    debugPrint('[NotificationSettingsVM] $message');
  }
}
