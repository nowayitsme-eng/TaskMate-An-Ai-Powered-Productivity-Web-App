import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/task.dart';

/// Service for local push notifications.
/// - Android: Full support with exact alarms.
/// - iOS: Full support with UNUserNotificationCenter.
/// - Web: Silently no-ops (FCM handles web push instead via MessagingService).
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ─── Notification Channel IDs ─────────────────────────────────────────────

  static const String _taskChannelId = 'task_reminders';
  static const String _taskChannelName = 'Task Reminders';
  static const String _taskChannelDesc =
      'Reminders before task due dates (1 hour and 30 minutes)';

  static const String _pomodoroChannelId = 'pomodoro_alerts';
  static const String _pomodoroChannelName = 'Pomodoro Alerts';
  static const String _pomodoroChannelDesc =
      'Alerts when Pomodoro sessions start or end';

  static const String _dailyChannelId = 'daily_digest';
  static const String _dailyChannelName = 'Daily Digest';
  static const String _dailyChannelDesc =
      'Morning summary of tasks due today (9 AM)';

  static const int _dailyDigestId = 9000;

  // ─── Initialization ───────────────────────────────────────────────────────

  Future<void> init() async {
    if (kIsWeb) return;
    if (_initialized) return;

    tz_data.initializeTimeZones();

    // Android settings
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS / macOS settings
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: android,
      iOS: darwin,
      macOS: darwin,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationTap,
    );

    // Request Android 13+ permission
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Request iOS exact timing permission
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;

    // Schedule daily digest for 9AM today or tomorrow
    await _scheduleDailyDigest();
  }

  static void _onNotificationTap(NotificationResponse response) {
    // Navigation can be hooked here in future if needed
  }

  @pragma('vm:entry-point')
  static void _onBackgroundNotificationTap(NotificationResponse response) {}

  // ─── Task Reminders ───────────────────────────────────────────────────────

  /// Schedules notifications at 1 hour AND 30 minutes before [task.dueDate].
  Future<void> scheduleTaskReminder(TaskModel task) async {
    if (kIsWeb || !_initialized) return;

    final now = DateTime.now();
    final base = task.id.hashCode.abs() % 1000000;

    // 1-hour reminder
    final oneHour = task.dueDate.subtract(const Duration(hours: 1));
    if (oneHour.isAfter(now)) {
      await _scheduleNotification(
        id: base,
        title: '⏰ Due in 1 hour: ${task.text}',
        body: 'Make sure you are on track!',
        scheduledTime: oneHour,
        channelId: _taskChannelId,
        channelName: _taskChannelName,
        channelDesc: _taskChannelDesc,
      );
    }

    // 30-minute reminder
    final thirtyMin = task.dueDate.subtract(const Duration(minutes: 30));
    if (thirtyMin.isAfter(now)) {
      await _scheduleNotification(
        id: base + 1,
        title: '🚨 Due in 30 minutes: ${task.text}',
        body: 'Almost time! Wrap up now.',
        scheduledTime: thirtyMin,
        channelId: _taskChannelId,
        channelName: _taskChannelName,
        channelDesc: _taskChannelDesc,
      );
    }
  }

  /// Cancels both the 1-hour and 30-minute reminders for a task.
  Future<void> cancelTaskReminder(String taskId) async {
    if (kIsWeb || !_initialized) return;
    final base = taskId.hashCode.abs() % 1000000;
    await _plugin.cancel(base);
    await _plugin.cancel(base + 1);
  }

  // ─── Pomodoro Notifications ───────────────────────────────────────────────

  /// Shows an immediate notification for Pomodoro state transitions.
  Future<void> showPomodoroNotification({
    required String title,
    required String body,
  }) async {
    if (kIsWeb || !_initialized) return;

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _pomodoroChannelId,
        _pomodoroChannelName,
        channelDescription: _pomodoroChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
        color: const Color(0xFF00BCD4),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: false,
      ),
    );

    await _plugin.show(0, title, body, details);
  }

  // ─── Daily Digest ─────────────────────────────────────────────────────────

  /// Schedules a daily "Good morning" summary at 9:00 AM.
  Future<void> _scheduleDailyDigest() async {
    if (kIsWeb || !_initialized) return;

    // Cancel existing daily digest first
    await _plugin.cancel(_dailyDigestId);

    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, 9, 0, 0);

    // If 9AM already passed today, schedule for tomorrow
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _scheduleNotification(
      id: _dailyDigestId,
      title: '🌅 Good Morning! Ready to conquer today?',
      body: 'Open TaskMate to see your tasks and start your Pomodoro session.',
      scheduledTime: scheduled,
      channelId: _dailyChannelId,
      channelName: _dailyChannelName,
      channelDesc: _dailyChannelDesc,
    );
  }

  /// Schedules a daily digest with a custom task count summary.
  Future<void> scheduleDailyDigestWithCount(int tasksDueToday) async {
    if (kIsWeb || !_initialized) return;
    await _plugin.cancel(_dailyDigestId);

    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, 9, 0, 0);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final body = tasksDueToday > 0
        ? 'You have $tasksDueToday task${tasksDueToday > 1 ? 's' : ''} due today!'
        : 'No tasks due today. Keep your streak going!';

    await _scheduleNotification(
      id: _dailyDigestId,
      title: '🌅 Good Morning!',
      body: body,
      scheduledTime: scheduled,
      channelId: _dailyChannelId,
      channelName: _dailyChannelName,
      channelDesc: _dailyChannelDesc,
    );
  }

  // ─── Core Scheduling Helper ───────────────────────────────────────────────

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String channelId,
    required String channelName,
    required String channelDesc,
  }) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
        color: const Color(0xFF6C63FF),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
      ),
    );

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      // Silently fail if exact alarm permission not granted
    }
  }

  // ─── Cancel All ───────────────────────────────────────────────────────────

  Future<void> cancelAll() async {
    if (kIsWeb || !_initialized) return;
    await _plugin.cancelAll();
  }
}
