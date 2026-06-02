class UserProfile {
  final int xp;
  final int level;
  final List<String> badges;
  final String? displayName;
  final DateTime? lastUpdated;
  final DateTime? lastActiveDate;

  const UserProfile({
    this.xp = 0,
    this.level = 1,
    this.badges = const [],
    this.displayName,
    this.lastUpdated,
    this.lastActiveDate,
  });

  factory UserProfile.fromMap(Map<String, dynamic> data) {
    return UserProfile(
      xp: (data['xp'] as num?)?.toInt() ?? 0,
      level: (data['level'] as num?)?.toInt() ?? 1,
      badges: List<String>.from(data['badges'] ?? []),
      displayName: data['displayName'] as String?,
      lastActiveDate: data['lastActiveDate'] != null
          ? DateTime.tryParse(data['lastActiveDate'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'xp': xp,
        'level': level,
        'badges': badges,
        'displayName': displayName,
        if (lastActiveDate != null)
          'lastActiveDate': lastActiveDate!.toIso8601String(),
      };

  /// XP required to reach the next level.
  int get xpForNextLevel => level * 100;

  /// XP accumulated within the current level (resets each level).
  int get xpInCurrentLevel => xp - ((level - 1) * 100);

  /// Progress fraction [0.0 – 1.0] toward next level.
  double get levelProgress =>
      (xpInCurrentLevel / xpForNextLevel).clamp(0.0, 1.0);
}

// ─── Badge Catalog ────────────────────────────────────────────────────────────

class BadgeInfo {
  final String id;
  final String name;
  final String emoji;
  final String description;

  const BadgeInfo({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
  });
}

const List<BadgeInfo> kAllBadges = [
  BadgeInfo(
    id: 'first_task',
    name: 'First Step',
    emoji: '🎯',
    description: 'Complete your very first task',
  ),
  BadgeInfo(
    id: 'early_bird',
    name: 'Early Bird',
    emoji: '🌅',
    description: 'Complete a task before 8 AM',
  ),
  BadgeInfo(
    id: 'night_owl',
    name: 'Night Owl',
    emoji: '🦉',
    description: 'Complete a task after 11 PM',
  ),
  BadgeInfo(
    id: 'deep_focus',
    name: 'Deep Focus',
    emoji: '🧠',
    description: 'Complete 4 Pomodoro sessions in a row',
  ),
  BadgeInfo(
    id: 'streak_7',
    name: '7-Day Streak',
    emoji: '🔥',
    description: 'Stay active 7 days in a row',
  ),
  BadgeInfo(
    id: 'century',
    name: 'Century Club',
    emoji: '💯',
    description: 'Complete 100 tasks total',
  ),
  BadgeInfo(
    id: 'marathon',
    name: 'Marathon',
    emoji: '⏱️',
    description: 'Accumulate 500 Pomodoro minutes',
  ),
];
