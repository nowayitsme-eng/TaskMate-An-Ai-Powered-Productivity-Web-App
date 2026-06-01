import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../models/user_profile.dart';

/// Lightweight offline cache for tasks using SharedPreferences.
/// Keeps a fresh copy of the last-known Firestore task list per user,
/// so the app can show data when connectivity is lost.
class CacheService {
  static String _key(String userId) => 'tasks_cache_$userId';
  static String _profileKey(String userId) => 'profile_cache_$userId';

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

  /// Persists the latest UserProfile for [userId].
  Future<void> cacheProfile(String userId, UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(profile.toMap());
      await prefs.setString(_profileKey(userId), encoded);
    } catch (_) {}
  }

  /// Returns the last cached UserProfile for [userId], or null if none.
  Future<UserProfile?> getCachedProfile(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_profileKey(userId));
      if (raw == null) return null;
      final Map<String, dynamic> decoded = jsonDecode(raw);
      return UserProfile.fromMap(decoded);
    } catch (_) {
      return null;
    }
  }

  /// Clears the cache for [userId].
  Future<void> clearCache(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(userId));
    await prefs.remove(_profileKey(userId));
  }
}
