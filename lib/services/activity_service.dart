import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ActivityService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _dateKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  Future<void> logActivity(
    String userId, {
    int tasksCompleted = 0,
    int pomodoroMinutes = 0,
  }) async {
    final key = _dateKey(DateTime.now());
    final ref = _db.collection('users').doc(userId);

    await ref.set(
      {
        'activityMap': {
          key: {
            'tasksCompleted': FieldValue.increment(tasksCompleted),
            'pomodoroMinutes': FieldValue.increment(pomodoroMinutes),
          }
        }
      },
      SetOptions(merge: true),
    );
  }

  /// Fetches the full activity map for the past 365 days.
  /// Returns a map of `yyyy-MM-dd` → combined score (tasks*10 + pomodoro minutes).
  Future<Map<String, int>> getActivityMap(String userId) async {
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
