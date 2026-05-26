import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';

/// Lightweight offline cache for tasks using SharedPreferences.
/// Keeps a fresh copy of the last-known Firestore task list per user,
/// so the app can show data when connectivity is lost.
class CacheService {
  static String _key(String userId) => 'tasks_cache_$userId';

  /// Persists the latest task list for [userId].
  Future<void> cacheTasks(String userId, List<TaskModel> tasks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(tasks.map((t) => t.toMap()..['id'] = t.id).toList());
      await prefs.setString(_key(userId), encoded);
    } catch (_) {}
  }

  /// Returns the last cached task list for [userId], or [] if none.
  Future<List<TaskModel>> getCachedTasks(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(userId));
      if (raw == null) return [];
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded.map((e) {
        final map = Map<String, dynamic>.from(e as Map);
        final id = map.remove('id') as String? ?? '';
        return TaskModel.fromMap(id, map);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Clears the cache for [userId].
  Future<void> clearCache(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(userId));
  }
}
