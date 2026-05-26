import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/task.dart';

/// Service for local push notifications (Android/iOS only — skipped on web).
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

  static const String _pomodoroChannelId = 'pomodoro_alerts';
  static const String _pomodoroChannelName = 'Pomodoro Alerts';

  // ─── Initialization ───────────────────────────────────────────────────────

  Future<void> init() async {
    if (kIsWeb) return; // Not supported on web
    if (_initialized) return;

    tz_data.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _plugin.initialize(settings);

    // Request Android 13+ permission
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  // ─── Task Reminders ───────────────────────────────────────────────────────

  /// Schedules a notification 1 hour before [task.dueDate].
  Future<void> scheduleTaskReminder(TaskModel task) async {
    if (kIsWeb || !_initialized) return;

    final reminderTime = task.dueDate.subtract(const Duration(hours: 1));
    if (reminderTime.isBefore(DateTime.now())) return; // Already past

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _taskChannelId,
        _taskChannelName,
        channelDescription: 'Reminders 1 hour before task due dates',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    );

    try {
      await _plugin.zonedSchedule(
        task.id.hashCode.abs() % 2147483647, // unique int ID from task id
        '⏰ Due Soon: ${task.text}',
        'This task is due in 1 hour!',
        tz.TZDateTime.from(reminderTime, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      // Silently fail if exact alarm permission not granted
    }
  }

  /// Cancels a previously scheduled task reminder.
  Future<void> cancelTaskReminder(String taskId) async {
    if (kIsWeb || !_initialized) return;
    await _plugin.cancel(taskId.hashCode.abs() % 2147483647);
  }

  // ─── Pomodoro Notifications ───────────────────────────────────────────────

  /// Shows an immediate notification for Pomodoro state transitions.
  Future<void> showPomodoroNotification({
    required String title,
    required String body,
  }) async {
    if (kIsWeb || !_initialized) return;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _pomodoroChannelId,
        _pomodoroChannelName,
        channelDescription: 'Alerts when Pomodoro sessions start or end',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
      ),
    );

    await _plugin.show(0, title, body, details);
  }
}
