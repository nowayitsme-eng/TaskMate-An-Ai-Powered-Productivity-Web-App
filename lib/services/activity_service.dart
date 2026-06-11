import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ActivityService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _dateKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  Future<void> logActivity(
    String providedUserId, {
    int tasksCompleted = 0,
    int pomodoroMinutes = 0,
    String? subject, // optional: track which subject the minutes belong to
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? providedUserId;
    final key = _dateKey(DateTime.now());
    final ref = _db.collection('users').doc(userId);

    final Map<String, dynamic> update = {
      'activityMap': {
        key: {
          'tasksCompleted': FieldValue.increment(tasksCompleted),
          'pomodoroMinutes': FieldValue.increment(pomodoroMinutes),
        }
      }
    };

    // Track per-subject pomodoro minutes for analytics
    if (subject != null && subject.isNotEmpty && pomodoroMinutes > 0) {
      update['subjectMinutes'] = {
        subject: FieldValue.increment(pomodoroMinutes),
      };
    }

    await ref.set(update, SetOptions(merge: true));
  }

  /// Fetches the full activity map for the past 365 days.
  /// Returns a map of `yyyy-MM-dd` → combined score (tasks*10 + pomodoro minutes).
  Future<Map<String, int>> getActivityMap(String providedUserId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? providedUserId;
    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (!doc.exists) return {};
      
      final data = doc.data() as Map<String, dynamic>;
      final activityData = data['activityMap'] as Map<String, dynamic>? ?? {};

      final map = <String, int>{};
      activityData.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          final tasks = (value['tasksCompleted'] as num?)?.toInt() ?? 0;
          final pomodoro = (value['pomodoroMinutes'] as num?)?.toInt() ?? 0;
          map[key] = tasks * 10 + pomodoro;
        }
      });
      return map;
    } catch (_) {
      return {};
    }
  }

  /// Streams the full activity map.
  Stream<Map<String, int>> streamActivityMap(String providedUserId) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? providedUserId;
    return _db.collection('users').doc(userId).snapshots().map((doc) {
      if (!doc.exists) return {};
      final data = doc.data() as Map<String, dynamic>;
      final activityData = data['activityMap'] as Map<String, dynamic>? ?? {};
      final map = <String, int>{};
      activityData.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          final tasks = (value['tasksCompleted'] as num?)?.toInt() ?? 0;
          final pomodoro = (value['pomodoroMinutes'] as num?)?.toInt() ?? 0;
          map[key] = tasks * 10 + pomodoro;
        }
      });
      return map;
    });
  }

  /// Fetches per-subject pomodoro minutes for analytics charts.
  /// Returns a map of subjectName → total minutes.
  Future<Map<String, int>> getSubjectMinutes(String providedUserId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? providedUserId;
    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (!doc.exists) return {};
      final data = doc.data() as Map<String, dynamic>;
      final subjectData = data['subjectMinutes'] as Map<String, dynamic>? ?? {};
      return subjectData.map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (_) {
      return {};
    }
  }

  /// Streams per-subject pomodoro minutes.
  Stream<Map<String, int>> streamSubjectMinutes(String providedUserId) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? providedUserId;
    return _db.collection('users').doc(userId).snapshots().map((doc) {
      if (!doc.exists) return {};
      final data = doc.data() as Map<String, dynamic>;
      final subjectData = data['subjectMinutes'] as Map<String, dynamic>? ?? {};
      return subjectData.map((k, v) => MapEntry(k, (v as num).toInt()));
    });
  }

  /// Checks whether the user has been active for 7 consecutive days.
  Future<bool> hasSevenDayStreak(String userId) async {
    final map = await getActivityMap(userId);
    int streak = 0;
    final today = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final key = _dateKey(today.subtract(Duration(days: i)));
      if ((map[key] ?? 0) > 0) {
        streak++;
      } else {
        break;
      }
    }
    return streak >= 7;
  }
}
