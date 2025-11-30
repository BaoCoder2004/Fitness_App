import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationIds {
  static const int dailyReminder = 100;
  static const int weeklyBase = 200; // + weekday (1-7)
  static const int goalCheckBase = 300; // + weekday (1-7)
  static const int goalCompleted = 400;
  static const int milestoneBase = 500;
  static const int goalDeadlineBase = 600;
  static const int goalDeadlineWarningBase = 650;
  static const int goalDailyReminderBase = 700;
}

class NotificationLogEntry {
  const NotificationLogEntry({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.type,
  });

  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final String type;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'timestamp': timestamp.toIso8601String(),
        'type': type,
      };

  factory NotificationLogEntry.fromJson(Map<String, dynamic> json) {
    return NotificationLogEntry(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: json['type'] as String,
    );
  }
}

class NotificationService {
  static const MethodChannel _timezoneChannel =
      MethodChannel('fitness_app/timezone');
  static const MethodChannel _systemChannel =
      MethodChannel('fitness_app/system');

  NotificationService(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;
  bool _exactAlarmDenied = false;
  static const _historyKey = 'notifications.history';
  static const _lastReadKey = 'notifications.last_read';
  static const _historyLimit = 15;

  Future<void> init() async {
    if (_initialized) return;
    await _configureLocalTimeZone();
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );
    await _plugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    await requestPermission();
    _initialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Khi user tap vào notification, lưu vào history nếu chưa có
    // (đặc biệt quan trọng với recurring notifications)
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      // Kiểm tra nếu là notification cancel reminder
      if (payload.startsWith('cancel_reminder_')) {
        final goalId = payload.replaceFirst('cancel_reminder_', '');
        // Tự động cancel reminder khi deadline qua
        cancelGoalDailyReminder(goalId);
        return;
      }
      
      // Lấy thông tin từ notification
      String title = 'Thông báo';
      String body = '';

      // Với recurring notifications, payload có thể chứa thông tin
      if (payload == 'goal_daily_reminder') {
        title = 'Nhắc nhở mục tiêu';
        body = 'Đừng quên mục tiêu của bạn hôm nay!';
      } else if (payload == 'goal_completed') {
        title = 'Chúc mừng bạn!';
        body = 'Bạn đã hoàn thành mục tiêu.';
      } else if (payload == 'goal_deadline_warning') {
        title = 'Mục tiêu sắp hết hạn';
        body = 'Mục tiêu của bạn sẽ hết hạn sớm.';
      } else if (payload == 'goal_deadline') {
        title = 'Sắp quá hạn mục tiêu';
        body = 'Mục tiêu của bạn sắp hoặc đã quá hạn.';
      }

      // Luôn lưu vào history khi user tap vào notification (với timestamp mới)
      // Điều này đảm bảo recurring notifications được lưu mỗi lần hiển thị
      _saveNotificationToHistory(
        title: title,
        body: body,
        type: payload,
      );
    }
  }

  Future<void> _saveNotificationToHistory({
    required String title,
    required String body,
    required String type,
  }) async {
    // Luôn lưu vào history khi user tap vào notification
    // Điều này đảm bảo recurring notifications được lưu mỗi lần hiển thị
    final now = DateTime.now();
    await _saveHistoryEntry(
      NotificationLogEntry(
        id: '${type}_${now.millisecondsSinceEpoch}',
        title: title,
        body: body,
        timestamp: now,
        type: type,
      ),
    );
  }

  Future<bool> requestPermission() async {
    final androidImplementation = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted =
        await androidImplementation?.requestNotificationsPermission();
    return granted ?? true;
  }

  Future<bool> areNotificationsEnabled() async {
    final androidImplementation = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final enabled = await androidImplementation?.areNotificationsEnabled();
    return enabled ?? true;
  }

  bool get exactAlarmDenied => _exactAlarmDenied;

  Future<bool> hasExactAlarmPermission() async {
    if (!_supportsExactAlarmControl()) return true;
    try {
      final allowed =
          await _systemChannel.invokeMethod<bool>('canScheduleExactAlarms');
      return allowed ?? true;
    } catch (_) {
      return true;
    }
  }

  Future<void> openExactAlarmSettings() async {
    if (!_supportsExactAlarmControl()) return;
    try {
      await _systemChannel.invokeMethod('openExactAlarmSettings');
    } catch (_) {
      // Ignore – opening settings is best effort only.
    }
  }

  Future<bool> scheduleDailyReminder({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    final fallbackUsed = await _runWithExactFallback((mode) async {
      await _plugin.zonedSchedule(
        NotificationIds.dailyReminder,
        title,
        body,
        _nextInstanceOfTime(hour: hour, minute: minute),
        NotificationDetails(
          android: _buildAndroidDetails(
            channelId: 'daily_reminder_channel',
            channelName: 'Nhắc luyện tập hằng ngày',
            channelDescription: 'Thông báo nhắc luyện tập theo lịch mỗi ngày',
          ),
        ),
        androidScheduleMode: mode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    });
    return fallbackUsed;
  }

  Future<void> cancelDailyReminder() async {
    await _plugin.cancel(NotificationIds.dailyReminder);
  }

  Future<bool> scheduleWeeklyReminder({
    required List<int> weekdays,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    final fallbackUsed = await _runWithExactFallback((mode) async {
      await _scheduleWeeklyRange(
        baseId: NotificationIds.weeklyBase,
        weekdays: weekdays,
        hour: hour,
        minute: minute,
        title: title,
        body: body,
        channelId: 'weekly_reminder_channel',
        channelName: 'Nhắc luyện tập theo tuần',
        channelDescription: 'Thông báo luyện tập theo các ngày đã chọn',
        scheduleMode: mode,
      );
    });
    return fallbackUsed;
  }

  Future<void> cancelWeeklyReminder() async {
    await _cancelWeeklyRange(NotificationIds.weeklyBase);
  }

  Future<bool> scheduleGoalCheckReminder({
    required List<int> weekdays,
    required int hour,
    required int minute,
    String title = 'Đánh giá mục tiêu',
    String body = 'Kiểm tra tiến độ và cập nhật mục tiêu của bạn hôm nay',
  }) async {
    final fallbackUsed = await _runWithExactFallback((mode) async {
      await _scheduleWeeklyRange(
        baseId: NotificationIds.goalCheckBase,
        weekdays: weekdays,
        hour: hour,
        minute: minute,
        title: title,
        body: body,
        channelId: 'goal_check_channel',
        channelName: 'Nhắc kiểm tra mục tiêu',
        channelDescription:
            'Thông báo giúp bạn xem lại tiến độ mục tiêu mỗi tuần',
        scheduleMode: mode,
      );
    });
    return fallbackUsed;
  }

  Future<void> cancelGoalCheckReminder() async {
    await _cancelWeeklyRange(NotificationIds.goalCheckBase);
  }

  Future<void> showGoalCompletedNotification(String goalName) async {
    await _plugin.show(
      NotificationIds.goalCompleted,
      'Chúc mừng bạn!',
      'Bạn đã hoàn thành mục tiêu "$goalName". Tiếp tục duy trì nhé!',
      NotificationDetails(
        android: _buildAndroidDetails(
          channelId: 'goal_completed_channel',
          channelName: 'Thông báo mục tiêu',
          channelDescription: 'Thông báo khi bạn đạt mục tiêu đã đặt ra',
        ),
      ),
      payload: 'goal_completed',
    );
    await _saveHistoryEntry(
      NotificationLogEntry(
        id: 'goal_completed_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Chúc mừng bạn!',
        body: 'Bạn đã hoàn thành mục tiêu "$goalName".',
        timestamp: DateTime.now(),
        type: 'goal_completed',
      ),
    );
  }

  Future<void> showGoalDeadlineWarning({
    required String goalId,
    required String goalName,
  }) async {
    final uniqueId = _deadlineNotificationId(goalId);
    await _plugin.show(
      uniqueId,
      'Mục tiêu đã quá hạn',
      'Mục tiêu "$goalName" của bạn đã quá hạn, hãy kiểm tra và cập nhật ngay.',
      NotificationDetails(
        android: _buildAndroidDetails(
          channelId: 'goal_deadline_channel',
          channelName: 'Nhắc hạn mục tiêu',
          channelDescription:
              'Thông báo khi mục tiêu gần đến hạn nhưng chưa hoàn thành',
        ),
      ),
      payload: 'goal_deadline',
    );
    await _saveHistoryEntry(
      NotificationLogEntry(
        id: 'goal_deadline_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Mục tiêu sắp quá hạn',
        body: 'Mục tiêu "$goalName" đã hoặc sắp quá hạn, hãy kiểm tra ngay.',
        timestamp: DateTime.now(),
        type: 'goal_deadline',
      ),
    );
  }

  Future<void> showGoalDeadlineSoon({
    required String goalId,
    required String goalName,
  }) async {
    final uniqueId = _deadlineWarningNotificationId(goalId);
    await _plugin.show(
      uniqueId,
      'Mục tiêu sắp hết hạn',
      'Mục tiêu "$goalName" sẽ hết hạn vào ngày mai, hãy hoàn thành ngay nhé!',
      NotificationDetails(
        android: _buildAndroidDetails(
          channelId: 'goal_deadline_warning_channel',
          channelName: 'Nhắc sắp hết hạn mục tiêu',
          channelDescription:
              'Thông báo khi mục tiêu sắp đến hạn nhưng chưa hoàn thành',
        ),
      ),
      payload: 'goal_deadline_warning',
    );
    await _saveHistoryEntry(
      NotificationLogEntry(
        id: 'goal_deadline_warning_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Mục tiêu sắp hết hạn',
        body: 'Mục tiêu "$goalName" sẽ hết hạn vào ngày mai.',
        timestamp: DateTime.now(),
        type: 'goal_deadline_warning',
      ),
    );
  }

  Future<void> scheduleGoalDeadlineWarningNotification({
    required String goalId,
    required String goalName,
    required DateTime dateTime,
    bool isDaily = false,
  }) async {
    final title = 'Mục tiêu sắp hết hạn';
    final body = isDaily
        ? 'Mục tiêu "$goalName" sẽ hết hạn vào cuối ngày hôm nay, hãy hoàn thành ngay nhé!'
        : 'Mục tiêu "$goalName" sẽ hết hạn vào ngày mai, hãy hoàn thành ngay nhé!';

    await _scheduleOneTimeNotification(
      notificationId: _deadlineWarningNotificationId(goalId),
      title: title,
      body: body,
      channelId: 'goal_deadline_warning_channel',
      channelName: 'Nhắc sắp hết hạn mục tiêu',
      channelDescription:
          'Thông báo khi mục tiêu sắp đến hạn nhưng chưa hoàn thành',
      scheduledTime: dateTime,
      type: 'goal_deadline_warning',
    );
  }

  Future<void> scheduleGoalDeadlineOverdueNotification({
    required String goalId,
    required String goalName,
    required DateTime dateTime,
  }) async {
    await _scheduleOneTimeNotification(
      notificationId: _deadlineNotificationId(goalId),
      title: 'Mục tiêu đã quá hạn',
      body:
          'Mục tiêu "$goalName" của bạn đã quá hạn, hãy kiểm tra và cập nhật ngay.',
      channelId: 'goal_deadline_channel',
      channelName: 'Nhắc hạn mục tiêu',
      channelDescription:
          'Thông báo khi mục tiêu gần đến hạn nhưng chưa hoàn thành',
      scheduledTime: dateTime,
      type: 'goal_deadline',
    );
  }

  Future<void> cancelGoalDeadlineNotifications(String goalId) async {
    await _plugin.cancel(_deadlineWarningNotificationId(goalId));
    await _plugin.cancel(_deadlineNotificationId(goalId));
  }

  Future<bool> scheduleGoalDailyReminder({
    required String goalId,
    required String goalName,
    required int hour,
    required int minute,
    bool isDaily = false,
    DateTime? deadline,
  }) async {
    // Kiểm tra permission trước
    final hasPermission = await areNotificationsEnabled();
    if (!hasPermission) {
      debugPrint('[NotificationService] Permission not granted, requesting...');
      final granted = await requestPermission();
      if (!granted) {
        debugPrint(
            '[NotificationService] Permission denied, cannot schedule reminder');
        return false;
      }
    }

    final notificationId = _goalDailyReminderId(goalId);

    // Với daily goals: nếu đã qua giờ hôm nay thì không schedule
    // Với các goals khác: schedule cho lần tiếp theo (có thể là ngày mai)
    final scheduledTime = isDaily
        ? _nextInstanceOfTimeForDaily(hour: hour, minute: minute)
        : _nextInstanceOfTime(hour: hour, minute: minute);

    // Nếu daily goal và đã qua giờ → không schedule
    if (isDaily && scheduledTime == null) {
      debugPrint(
          '[NotificationService] Daily goal reminder time has passed, cancelling reminder');
      await _plugin.cancel(notificationId);
      return false;
    }

    final now = tz.TZDateTime.now(tz.local);
    debugPrint(
        '[NotificationService] 📅 Scheduling daily reminder for goal $goalId');
    debugPrint('[NotificationService] Current time: ${now.hour}:${now.minute}');
    debugPrint('[NotificationService] Requested time: $hour:$minute');
    debugPrint('[NotificationService] Is daily goal: $isDaily');
    debugPrint('[NotificationService] Scheduled time: $scheduledTime');
    if (scheduledTime != null) {
      final minutesUntil = scheduledTime.difference(now).inMinutes;
      debugPrint(
          '[NotificationService] ⏰ Notification will arrive in $minutesUntil minutes');
    }

    try {
      final now = tz.TZDateTime.now(tz.local);
      final isToday = scheduledTime!.year == now.year &&
          scheduledTime.month == now.month &&
          scheduledTime.day == now.day;

      // Với daily goals schedule cho hôm nay: schedule 1 phút trước giờ đã đặt
      // Sau đó schedule lại với time để lặp lại từ ngày mai
      if (isDaily && isToday) {
        final now = tz.TZDateTime.now(tz.local);
        // Tính thời gian notification: 1 phút trước giờ đã đặt
        final notificationTime =
            scheduledTime.subtract(const Duration(minutes: 1));
        final duration = notificationTime.difference(now);
        final secondsUntil = duration.inSeconds;

        debugPrint(
            '[NotificationService] ⏰ Notification will be sent 1 minute before reminder time');
        debugPrint(
            '[NotificationService] Reminder time: ${scheduledTime.hour}:${scheduledTime.minute}');
        debugPrint(
            '[NotificationService] Notification time: ${notificationTime.hour}:${notificationTime.minute} (1 minute before)');

        // Nếu thời gian notification đã qua hoặc đang ở hiện tại → gửi ngay
        if (secondsUntil <= 0) {
          debugPrint(
              '[NotificationService] ⚡ Notification time (1 min before) has passed or is now, sending immediately');
          await _plugin.show(
            notificationId,
            'Nhắc nhở mục tiêu',
            'Đừng quên mục tiêu "$goalName" của bạn hôm nay!',
            NotificationDetails(
              android: _buildAndroidDetails(
                channelId: 'goal_daily_reminder_channel',
                channelName: 'Nhắc nhở mục tiêu hàng ngày',
                channelDescription: 'Thông báo nhắc nhở về mục tiêu mỗi ngày',
              ),
            ),
            payload: 'goal_daily_reminder',
          );
          // Lưu vào history khi hiển thị ngay
          await _saveHistoryEntry(
            NotificationLogEntry(
              id: 'goal_daily_reminder_${goalId}_${DateTime.now().millisecondsSinceEpoch}',
              title: 'Nhắc nhở mục tiêu',
              body: 'Đừng quên mục tiêu "$goalName" của bạn hôm nay!',
              timestamp: DateTime.now(),
              type: 'goal_daily_reminder',
            ),
          );
          debugPrint('[NotificationService] ✅ Immediate notification sent');
        } else {
          // Schedule notification 1 phút trước giờ đã đặt
          debugPrint(
              '[NotificationService] ⏰ Scheduling notification for ${secondsUntil} seconds from now (1 minute before reminder time)');
          final fallbackUsed1 = await _runWithExactFallback((mode) async {
            await _plugin.zonedSchedule(
              notificationId,
              'Nhắc nhở mục tiêu',
              'Đừng quên mục tiêu "$goalName" của bạn hôm nay!',
              notificationTime,
              NotificationDetails(
                android: _buildAndroidDetails(
                  channelId: 'goal_daily_reminder_channel',
                  channelName: 'Nhắc nhở mục tiêu hàng ngày',
                  channelDescription: 'Thông báo nhắc nhở về mục tiêu mỗi ngày',
                ),
              ),
              androidScheduleMode: mode,
              uiLocalNotificationDateInterpretation:
                  UILocalNotificationDateInterpretation.absoluteTime,
              // Không dùng matchDateTimeComponents để đảm bảo notification đến đúng giờ đã schedule
            );

            // Lưu vào history khi schedule
            await _saveHistoryEntry(
              NotificationLogEntry(
                id: 'goal_daily_reminder_${goalId}_${notificationTime.millisecondsSinceEpoch}',
                title: 'Nhắc nhở mục tiêu',
                body: 'Đừng quên mục tiêu "$goalName" của bạn hôm nay!',
                timestamp: notificationTime,
                type: 'goal_daily_reminder',
              ),
            );
          });

          if (fallbackUsed1) {
            debugPrint(
                '[NotificationService] ⚠️ Using inexact alarms for today notification');
            debugPrint(
                '[NotificationService] ⚠️ Notification may not arrive at exact time');
            debugPrint(
                '[NotificationService] ⚠️ To enable exact alarms: Settings → Apps → Fitness App → Alarms & reminders → Allow');
          } else {
            debugPrint(
                '[NotificationService] ✅ Notification scheduled with exact alarm (will work even when app is closed)');
          }
        }

        // Schedule notification recurring từ ngày mai: 1 phút trước giờ đã đặt mỗi ngày
        final tomorrowNotificationTime =
            notificationTime.add(const Duration(days: 1));
        final recurringId =
            notificationId + 1000000; // Different ID for recurring
        final fallbackUsed2 = await _runWithExactFallback((mode) async {
          await _plugin.zonedSchedule(
            recurringId,
            'Nhắc nhở mục tiêu',
            'Đừng quên mục tiêu "$goalName" của bạn hôm nay!',
            tomorrowNotificationTime,
            NotificationDetails(
              android: _buildAndroidDetails(
                channelId: 'goal_daily_reminder_channel',
                channelName: 'Nhắc nhở mục tiêu hàng ngày',
                channelDescription: 'Thông báo nhắc nhở về mục tiêu mỗi ngày',
              ),
            ),
            androidScheduleMode: mode,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.time,
          );

          // Lưu vào history cho recurring notification (sẽ được hiển thị mỗi ngày)
          // Lưu với timestamp là thời gian đầu tiên sẽ hiển thị
          await _saveHistoryEntry(
            NotificationLogEntry(
              id: 'goal_daily_reminder_recurring_${goalId}_${tomorrowNotificationTime.millisecondsSinceEpoch}',
              title: 'Nhắc nhở mục tiêu',
              body: 'Đừng quên mục tiêu "$goalName" của bạn hôm nay!',
              timestamp: tomorrowNotificationTime,
              type: 'goal_daily_reminder',
            ),
          );
        });

        if (fallbackUsed2) {
          debugPrint(
              '[NotificationService] ⚠️ Using inexact alarms for recurring notification');
        }

        debugPrint(
            '[NotificationService] ✅ Daily reminder scheduled: today (1 min before) + recurring from tomorrow (1 min before)');
      } else {
        // Với các goals khác hoặc daily goals schedule cho ngày mai: schedule 1 phút trước giờ đã đặt
        final notificationTime =
            scheduledTime.subtract(const Duration(minutes: 1));
        final duration = notificationTime.difference(now);
        debugPrint(
            '[NotificationService] ⏰ Scheduling recurring notification 1 minute before reminder time');
        debugPrint(
            '[NotificationService] Reminder time: ${scheduledTime.hour}:${scheduledTime.minute}');
        debugPrint(
            '[NotificationService] Notification time: ${notificationTime.hour}:${notificationTime.minute} (1 minute before)');
        debugPrint(
            '[NotificationService] ⏰ Scheduling for ${duration.inMinutes} minutes from now (using zonedSchedule with matchDateTimeComponents.time)');
        final fallbackUsed = await _runWithExactFallback((mode) async {
          await _plugin.zonedSchedule(
            notificationId,
            'Nhắc nhở mục tiêu',
            'Đừng quên mục tiêu "$goalName" của bạn hôm nay!',
            notificationTime,
            NotificationDetails(
              android: _buildAndroidDetails(
                channelId: 'goal_daily_reminder_channel',
                channelName: 'Nhắc nhở mục tiêu hàng ngày',
                channelDescription: 'Thông báo nhắc nhở về mục tiêu mỗi ngày',
              ),
            ),
            androidScheduleMode: mode,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.time,
          );

          // Lưu vào history khi schedule
          await _saveHistoryEntry(
            NotificationLogEntry(
              id: 'goal_daily_reminder_${goalId}_${notificationTime.millisecondsSinceEpoch}',
              title: 'Nhắc nhở mục tiêu',
              body: 'Đừng quên mục tiêu "$goalName" của bạn hôm nay!',
              timestamp: notificationTime,
              type: 'goal_daily_reminder',
            ),
          );
        });

        if (fallbackUsed) {
          debugPrint(
              '[NotificationService] ⚠️ Using inexact alarms (exact alarm permission denied)');
          debugPrint(
              '[NotificationService] ⚠️ Notification may not arrive at exact time');
        }

        debugPrint(
            '[NotificationService] ✅ Reminder scheduled successfully (recurring, 1 min before)');
      }
      
      // Với weekly/monthly/yearly goals có deadline: schedule notification để tự động cancel reminder khi deadline qua
      if (!isDaily && deadline != null) {
        final now = tz.TZDateTime.now(tz.local);
        // Schedule cancel notification vào 23:59:59 ngày deadline
        final cancelTime = tz.TZDateTime(
          tz.local,
          deadline.year,
          deadline.month,
          deadline.day,
          23,
          59,
          59,
        );
        
        // Chỉ schedule nếu deadline chưa qua
        if (cancelTime.isAfter(now)) {
          final cancelNotificationId = notificationId + 2000000; // Different ID for cancel notification
          debugPrint(
              '[NotificationService] 📅 Scheduling auto-cancel reminder notification for goal $goalId at deadline (${deadline.year}-${deadline.month}-${deadline.day} 23:59:59)');
          await _runWithExactFallback((mode) async {
            await _plugin.zonedSchedule(
              cancelNotificationId,
              'Hủy nhắc nhở mục tiêu',
              'Mục tiêu "$goalName" đã hết hạn, nhắc nhở đã được tự động hủy.',
              cancelTime,
              NotificationDetails(
                android: _buildAndroidDetails(
                  channelId: 'goal_daily_reminder_channel',
                  channelName: 'Nhắc nhở mục tiêu hàng ngày',
                  channelDescription: 'Thông báo nhắc nhở về mục tiêu mỗi ngày',
                ),
              ),
              androidScheduleMode: mode,
              uiLocalNotificationDateInterpretation:
                  UILocalNotificationDateInterpretation.absoluteTime,
              payload: 'cancel_reminder_$goalId',
            );
            // Tự động cancel reminder khi notification cancel được hiển thị
            // Sử dụng Future.delayed để cancel reminder vào đúng thời điểm deadline
            final delay = cancelTime.difference(now);
            if (delay.inSeconds > 0) {
              Future.delayed(delay, () {
                cancelGoalDailyReminder(goalId);
                debugPrint('[NotificationService] ✅ Auto-cancelled reminder for goal $goalId at deadline');
              });
            }
          });
        }
      }
      
      return true;
    } catch (e, stackTrace) {
      debugPrint('[NotificationService] ❌ Error scheduling reminder: $e');
      debugPrint('[NotificationService] Stack trace: $stackTrace');
      return false;
    }
  }

  Future<void> cancelGoalDailyReminder(String goalId) async {
    final notificationId = _goalDailyReminderId(goalId);
    await _plugin.cancel(notificationId);
    // Cancel recurring notification nếu có
    await _plugin.cancel(notificationId + 1000000);
    debugPrint('[NotificationService] Cancelled reminder for goal $goalId');
  }

  /// Hiển thị thông báo test ngay lập tức (để test reminder)
  Future<void> showGoalDailyReminder({
    required String goalId,
    required String goalName,
  }) async {
    final notificationId = _goalDailyReminderId(goalId);
    await _plugin.show(
      notificationId,
      'Nhắc nhở mục tiêu',
      'Đừng quên mục tiêu "$goalName" của bạn hôm nay!',
      NotificationDetails(
        android: _buildAndroidDetails(
          channelId: 'goal_daily_reminder_channel',
          channelName: 'Nhắc nhở mục tiêu hàng ngày',
          channelDescription: 'Thông báo nhắc nhở về mục tiêu mỗi ngày',
        ),
      ),
      payload: 'goal_daily_reminder',
    );
  }

  int _goalDailyReminderId(String goalId) {
    return NotificationIds.goalDailyReminderBase +
        (goalId.hashCode & 0x7fffffff);
  }

  Future<void> showMilestoneNotification({
    required String milestoneId,
    required String milestoneName,
  }) async {
    final uniqueId =
        NotificationIds.milestoneBase + (milestoneId.hashCode & 0x7fffffff);
    await _plugin.show(
      uniqueId,
      'Đạt cột mốc mới',
      'Bạn đã hoàn thành cột mốc $milestoneName. Tuyệt vời!',
      NotificationDetails(
        android: _buildAndroidDetails(
          channelId: 'milestone_channel',
          channelName: 'Cột mốc luyện tập',
          channelDescription: 'Thông báo khi đạt các cột mốc quan trọng',
        ),
      ),
      payload: 'milestone_$milestoneId',
    );
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  Future<List<NotificationLogEntry>> getNotificationHistory({
    int limit = 10,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_historyKey) ?? [];
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    final entries = raw
        .map((item) => NotificationLogEntry.fromJson(
            jsonDecode(item) as Map<String, dynamic>))
        // Chỉ hiển thị thông báo đã đến thời điểm và trong vòng 7 ngày gần nhất
        .where((entry) =>
            !entry.timestamp.isAfter(now) &&
            !entry.timestamp.isBefore(sevenDaysAgo))
        .toList();
    // Sắp xếp theo timestamp giảm dần (mới nhất lên đầu)
    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    if (entries.length > limit) {
      return entries.sublist(0, limit);
    }
    return entries;
  }

  /// Đánh dấu tất cả thông báo là đã đọc
  Future<void> markAllAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastReadKey, DateTime.now().toIso8601String());
  }

  /// Lấy số thông báo chưa đọc
  Future<int> getUnreadCount() async {
    final prefs = await SharedPreferences.getInstance();
    final lastReadStr = prefs.getString(_lastReadKey);
    final now = DateTime.now();
    
    if (lastReadStr == null) {
      // Nếu chưa có last read, đếm tất cả thông báo đã đến thời điểm hiện tại
      final history = await getNotificationHistory(limit: 100);
      return history.where((entry) => !entry.timestamp.isAfter(now)).length;
    }

    final lastRead = DateTime.parse(lastReadStr);
    final history = await getNotificationHistory(limit: 100);
    // Đếm số thông báo có timestamp > lastRead và <= now (đã đến thời điểm hiện tại)
    return history.where((entry) => 
      entry.timestamp.isAfter(lastRead) && !entry.timestamp.isAfter(now)
    ).length;
  }

  AndroidNotificationDetails _buildAndroidDetails({
    required String channelId,
    required String channelName,
    required String channelDescription,
  }) {
    return AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: const BigTextStyleInformation(''),
    );
  }

  tz.TZDateTime _nextInstanceOfTime({required int hour, required int minute}) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// Tính thời gian schedule cho daily goals
  /// Nếu chưa qua giờ hôm nay → schedule cho giờ đó hôm nay
  /// Nếu đã qua giờ → trả về null (sẽ không schedule)
  tz.TZDateTime? _nextInstanceOfTimeForDaily(
      {required int hour, required int minute}) {
    final now = tz.TZDateTime.now(tz.local);
    final scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // Nếu đã qua giờ hôm nay → vẫn schedule cho hôm nay (ngay lập tức)
    // để nhắc người dùng hoàn thành goal trong ngày hôm đó
    if (scheduledDate.isBefore(now)) {
      // Trả về thời gian hiện tại + 1 phút để gửi ngay
      final immediateTime = now.add(const Duration(minutes: 1));
      final minutesUntil = immediateTime.difference(now).inMinutes;
      debugPrint(
          '[NotificationService] ⚠️ Daily goal reminder time ($hour:$minute) has passed today (now: ${now.hour}:${now.minute}), sending reminder immediately to remind user to complete today\'s goal');
      debugPrint(
          '[NotificationService] ✅ Daily goal reminder will be sent immediately (in $minutesUntil minutes)');
      return immediateTime;
    }

    // Nếu chưa qua giờ → schedule cho giờ đó hôm nay
    final minutesUntil = scheduledDate.difference(now).inMinutes;
    debugPrint(
        '[NotificationService] ✅ Daily goal reminder will be sent at $hour:$minute today (in $minutesUntil minutes)');
    return scheduledDate;
  }

  tz.TZDateTime _nextInstanceOfWeekday({
    required int weekday,
    required int hour,
    required int minute,
  }) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    while (scheduledDate.weekday != weekday || scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Future<void> _cancelWeeklyRange(int baseId) async {
    for (var weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++) {
      await _plugin.cancel(baseId + weekday);
    }
  }

  Future<void> _scheduleWeeklyRange({
    required int baseId,
    required List<int> weekdays,
    required int hour,
    required int minute,
    required String title,
    required String body,
    required String channelId,
    required String channelName,
    required String channelDescription,
    required AndroidScheduleMode scheduleMode,
  }) async {
    await _cancelWeeklyRange(baseId);
    for (final weekday in weekdays.toSet()) {
      await _plugin.zonedSchedule(
        baseId + weekday,
        title,
        body,
        _nextInstanceOfWeekday(
          weekday: weekday,
          hour: hour,
          minute: minute,
        ),
        NotificationDetails(
          android: _buildAndroidDetails(
            channelId: channelId,
            channelName: channelName,
            channelDescription: channelDescription,
          ),
        ),
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  Future<bool> _runWithExactFallback(
    Future<void> Function(AndroidScheduleMode mode) action,
  ) async {
    var fallbackUsed = false;
    try {
      await action(AndroidScheduleMode.exactAllowWhileIdle);
      _exactAlarmDenied = false;
      debugPrint(
          '[NotificationService] ✅ Using exact alarms (exact alarm permission granted)');
    } on PlatformException catch (e) {
      if (e.code == 'exact_alarms_not_permitted') {
        fallbackUsed = true;
        debugPrint(
            '[NotificationService] ⚠️ Exact alarm permission denied, falling back to inexact alarms');
        debugPrint(
            '[NotificationService] ⚠️ To enable exact alarms: Settings → Apps → Fitness App → Alarms & reminders → Allow');
        await action(AndroidScheduleMode.inexactAllowWhileIdle);
        _exactAlarmDenied = true;
      } else {
        debugPrint(
            '[NotificationService] ❌ Error scheduling notification: ${e.code} - ${e.message}');
        rethrow;
      }
    }
    return fallbackUsed;
  }

  Future<void> _configureLocalTimeZone() async {
    tz.initializeTimeZones();
    var locationName = 'Asia/Ho_Chi_Minh';
    try {
      final result =
          await _timezoneChannel.invokeMethod<String>('getLocalTimezone');
      if (result != null && result.isNotEmpty) {
        locationName = result;
      }
    } catch (_) {
      // fallback giữ nguyên giá trị mặc định
    }
    tz.setLocalLocation(tz.getLocation(locationName));
  }

  bool _supportsExactAlarmControl() => Platform.isAndroid;

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _saveHistoryEntry(NotificationLogEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_historyKey) ?? [];
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    final existing = <NotificationLogEntry>[];
    for (final item in raw) {
      try {
        final e = NotificationLogEntry.fromJson(
          jsonDecode(item) as Map<String, dynamic>,
        );
        // Bỏ qua thông báo quá cũ
        if (e.timestamp.isBefore(sevenDaysAgo)) continue;
        // Với cùng loại + cùng nội dung trong cùng một ngày, chỉ giữ bản mới nhất
        final isDuplicateSameDay = e.type == entry.type &&
            e.title == entry.title &&
            e.body == entry.body &&
            _isSameDay(e.timestamp, entry.timestamp);
        if (!isDuplicateSameDay) {
          existing.add(e);
        }
      } catch (_) {
        // Bỏ qua entry lỗi
      }
    }

    // Thêm bản ghi mới lên đầu
    existing.insert(0, entry);

    // Cắt bớt nếu vượt quá giới hạn
    if (existing.length > _historyLimit) {
      existing.removeRange(_historyLimit, existing.length);
    }

    final encoded =
        existing.map((e) => jsonEncode(e.toJson())).toList(growable: false);
    await prefs.setStringList(_historyKey, encoded);
  }

  Future<void> _scheduleOneTimeNotification({
    required int notificationId,
    required String title,
    required String body,
    required String channelId,
    required String channelName,
    required String channelDescription,
    required DateTime scheduledTime,
    String? type,
  }) async {
    final now = DateTime.now();
    final duration = scheduledTime.difference(now);
    
    // Nếu thời gian đã qua hoặc rất gần (< 5 giây), gửi ngay
    if (duration.inSeconds <= 5) {
      debugPrint('[NotificationService] ⚡ Scheduled time is very close or passed, sending immediately');
      await _plugin.show(
        notificationId,
        title,
        body,
        NotificationDetails(
          android: _buildAndroidDetails(
            channelId: channelId,
            channelName: channelName,
            channelDescription: channelDescription,
          ),
        ),
        payload: type,
      );
      // Lưu vào history khi hiển thị ngay
      if (type != null) {
        await _saveHistoryEntry(
          NotificationLogEntry(
            id: '${type}_${notificationId}_${DateTime.now().millisecondsSinceEpoch}',
            title: title,
            body: body,
            timestamp: DateTime.now(),
            type: type,
          ),
        );
      }
      return;
    }
    
    final tzTime = _toTzDateTime(scheduledTime);
    await _plugin.cancel(notificationId);
    await _runWithExactFallback((mode) async {
      await _plugin.zonedSchedule(
        notificationId,
        title,
        body,
        tzTime,
        NotificationDetails(
          android: _buildAndroidDetails(
            channelId: channelId,
            channelName: channelName,
            channelDescription: channelDescription,
          ),
        ),
        androidScheduleMode: mode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
        androidAllowWhileIdle: true,
      );
    });

    // Lưu vào history khi schedule notification
    if (type != null) {
      await _saveHistoryEntry(
        NotificationLogEntry(
          id: '${type}_${notificationId}_${scheduledTime.millisecondsSinceEpoch}',
          title: title,
          body: body,
          timestamp: scheduledTime,
          type: type,
        ),
      );
    }
  }

  tz.TZDateTime _toTzDateTime(DateTime dateTime) {
    return tz.TZDateTime.from(dateTime, tz.local);
  }

  int _goalHash(String goalId) => goalId.hashCode & 0x3fffffff;

  int _deadlineWarningNotificationId(String goalId) =>
      NotificationIds.goalDeadlineWarningBase + _goalHash(goalId);

  int _deadlineNotificationId(String goalId) =>
      NotificationIds.goalDeadlineBase + _goalHash(goalId);
}
