import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import 'activity_service.dart';
import 'cache_service.dart';
import 'package:intl/intl.dart';

class GamificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final ActivityService _activityService = ActivityService();
  final CacheService _cacheService = CacheService();

  static const int xpPerTask = 10;

  DocumentReference _profileRef(String userId) => _db
      .collection('users')
      .doc(userId);

  // ─── Profile Stream ───────────────────────────────────────────────────────

  Stream<UserProfile> getUserProfile(String providedUserId) async* {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? providedUserId;
    try {
      final cachedProfile = await _cacheService.getCachedProfile(userId);
      if (cachedProfile != null) {
        yield cachedProfile;
      }
    } catch (_) {}

    yield* _profileRef(userId).snapshots().map((doc) {
      if (!doc.exists) return const UserProfile();
      final profile = UserProfile.fromMap(doc.data() as Map<String, dynamic>);
      _cacheService.cacheProfile(userId, profile);
      return profile;
    }).handleError((error) {});
  }

  Future<void> updateDisplayName(String providedUserId, String newName) async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? providedUserId;
    await _profileRef(userId).set(
      {'displayName': newName},
      SetOptions(merge: true),
    );
  }

  // ─── XP Management ───────────────────────────────────────────────────────

  /// Adds or removes XP atomically and recalculates level.
  Future<void> addXp(String providedUserId, int amount) async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? providedUserId;
    if (amount == 0) return;
    final ref = _profileRef(userId);

    await _db.runTransaction((tx) async {
      final doc = await tx.get(ref);
      final current =
          doc.exists ? UserProfile.fromMap(doc.data() as Map<String, dynamic>) : const UserProfile();

      final newXp = (current.xp + amount).clamp(0, double.maxFinite.toInt());
      // Level thresholds: 100 XP per level (cumulative)
      final newLevel = (newXp / 100).floor() + 1;

      tx.set(
        ref,
        {
          'xp': newXp,
          'level': newLevel,
          'badges': current.badges,
          'lastUpdated': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  // ─── Lifetime Stats ───────────────────────────────────────────────────────

  Future<void> updateLifetimeStats(
    String providedUserId, {
    int tasksDelta = 0,
    int pomodoroDelta = 0,
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? providedUserId;
    if (tasksDelta == 0 && pomodoroDelta == 0) return;

    final ref = _profileRef(userId);

    // Fix 6: Use a transaction to safely clamp values to >= 0 (prevents negative stats)
    await _db.runTransaction((tx) async {
      final doc = await tx.get(ref);
      final current = doc.exists
          ? UserProfile.fromMap(doc.data() as Map<String, dynamic>)
          : const UserProfile();

      final newTasks = (current.lifetimeTasksCompleted + tasksDelta).clamp(0, double.maxFinite.toInt());
      final newPomodoro = (current.lifetimePomodoroMinutes + pomodoroDelta).clamp(0, double.maxFinite.toInt());

      tx.set(
        ref,
        {
          if (tasksDelta != 0) 'lifetimeTasksCompleted': newTasks,
          if (pomodoroDelta != 0) 'lifetimePomodoroMinutes': newPomodoro,
        },
        SetOptions(merge: true),
      );
    });
  }

  // ─── Unified Processing ───────────────────────────────────────────────────

  /// Safely processes a task check/uncheck event, combining XP, Lifetime Stats,
  /// and Activity Map logging into a single Firestore transaction to prevent
  /// multiple rapid writes on the same user document.
  Future<void> processTaskCompletion(
    String providedUserId, {
    required bool isCompleted,
    required DateTime actionDate,
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? providedUserId;
    final ref = _profileRef(userId);

    await _db.runTransaction((tx) async {
      final doc = await tx.get(ref);
      final data = doc.exists ? doc.data() as Map<String, dynamic> : <String, dynamic>{};
      final current = UserProfile.fromMap(data);

      // 1. Calculate XP
      final xpDelta = isCompleted ? xpPerTask : -xpPerTask;
      final newXp = (current.xp + xpDelta).clamp(0, double.maxFinite.toInt());
      final newLevel = (newXp / 100).floor() + 1;

      // 2. Calculate Lifetime Stats
      final tasksDelta = isCompleted ? 1 : -1;
      final newTasks = (current.lifetimeTasksCompleted + tasksDelta).clamp(0, double.maxFinite.toInt());

      // 3. Activity Map (Heatmap)
      final dateKey = DateFormat('yyyy-MM-dd').format(actionDate);
      final activityMap = data['activityMap'] as Map<String, dynamic>? ?? {};
      final dayData = activityMap[dateKey] as Map<String, dynamic>? ?? {};
      final currentDayTasks = (dayData['tasksCompleted'] as num?)?.toInt() ?? 0;
      final newDayTasks = (currentDayTasks + tasksDelta).clamp(0, double.maxFinite.toInt());

      // Merge Update
      final update = {
        'xp': newXp,
        'level': newLevel,
        'lifetimeTasksCompleted': newTasks,
        'lastUpdated': FieldValue.serverTimestamp(),
        'activityMap': {
          dateKey: {
            'tasksCompleted': newDayTasks,
          }
        }
      };

      tx.set(ref, update, SetOptions(merge: true));
    });
  }

  // ─── Badge Management ─────────────────────────────────────────────────────

  /// Checks applicable badge conditions and awards any not yet earned.
  Future<List<String>> checkAndAwardBadges(
    String providedUserId, {
    required DateTime actionTime,
    int consecutivePomodoros = 0,
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? providedUserId;
    final ref = _profileRef(userId);
    final doc = await ref.get();
    final current =
        doc.exists ? UserProfile.fromMap(doc.data() as Map<String, dynamic>) : const UserProfile();

    final already = Set<String>.from(current.badges);
    final toAward = <String>[];

    // Evaluate each badge condition
    if (!already.contains('first_task') && current.lifetimeTasksCompleted >= 1) {
      toAward.add('first_task');
    }
    if (!already.contains('century') && current.lifetimeTasksCompleted >= 100) {
      toAward.add('century');
    }
    if (!already.contains('marathon') && current.lifetimePomodoroMinutes >= 500) {
      toAward.add('marathon');
    }
    if (!already.contains('deep_focus') && consecutivePomodoros >= 4) {
      toAward.add('deep_focus');
    }
    if (!already.contains('early_bird') && actionTime.hour < 8) {
      toAward.add('early_bird');
    }
    if (!already.contains('night_owl') && actionTime.hour >= 23) {
      toAward.add('night_owl');
    }

    // Check 7-day streak
    if (!already.contains('streak_7')) {
      final hasStreak = await _activityService.hasSevenDayStreak(userId);
      if (hasStreak) toAward.add('streak_7');
    }

    if (toAward.isNotEmpty) {
      await ref.set(
        {'badges': FieldValue.arrayUnion(toAward)},
        SetOptions(merge: true),
      );
    }

    return toAward;
  }
}
