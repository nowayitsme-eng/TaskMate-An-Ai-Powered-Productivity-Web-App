import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import 'activity_service.dart';
import 'cache_service.dart';

class GamificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final ActivityService _activityService = ActivityService();
  final CacheService _cacheService = CacheService();

  static const int xpPerTask = 10;

  DocumentReference _profileRef(String userId) => _db
      .collection('users')
      .doc(userId);

  // ─── Profile Stream ───────────────────────────────────────────────────────

  Stream<UserProfile> getUserProfile(String userId) async* {
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

  Future<void> updateDisplayName(String userId, String newName) async {
    await _profileRef(userId).set(
      {'displayName': newName},
      SetOptions(merge: true),
    );
  }

  // ─── XP Management ───────────────────────────────────────────────────────

  /// Adds XP atomically and recalculates level.
  Future<void> addXp(String userId, int amount) async {
    if (amount <= 0) return;
    final ref = _profileRef(userId);

    await _db.runTransaction((tx) async {
      final doc = await tx.get(ref);
      final current =
          doc.exists ? UserProfile.fromMap(doc.data() as Map<String, dynamic>) : const UserProfile();

      final newXp = current.xp + amount;
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
      );
    });
  }

  // ─── Badge Management ─────────────────────────────────────────────────────

  /// Checks applicable badge conditions and awards any not yet earned.
  Future<List<String>> checkAndAwardBadges(
    String userId, {
    required int totalCompleted,
    required int totalPomodoroMinutes,
    required DateTime actionTime,
    int consecutivePomodoros = 0,
  }) async {
    final ref = _profileRef(userId);
    final doc = await ref.get();
    final current =
        doc.exists ? UserProfile.fromMap(doc.data() as Map<String, dynamic>) : const UserProfile();

    final already = Set<String>.from(current.badges);
    final toAward = <String>[];

    // Evaluate each badge condition
    if (!already.contains('first_task') && totalCompleted >= 1) {
      toAward.add('first_task');
    }
    if (!already.contains('century') && totalCompleted >= 100) {
      toAward.add('century');
    }
    if (!already.contains('marathon') && totalPomodoroMinutes >= 500) {
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
