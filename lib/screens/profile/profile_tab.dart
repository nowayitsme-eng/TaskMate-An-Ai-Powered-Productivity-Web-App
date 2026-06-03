import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/gamification_service.dart';
import '../../services/activity_service.dart';
import '../../services/calendar_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/notification_toast.dart';
import '../../widgets/activity_heatmap.dart';
import 'settings_screen.dart';
import 'change_password_modal.dart';
import 'analytics_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final GamificationService _gamService = GamificationService();
  final ActivityService _activityService = ActivityService();
  final CalendarService _calendarService = CalendarService();

  Map<String, int> _activityMap = {};
  bool _heatmapLoading = true;
  bool _calendarConnecting = false;
  bool _calendarSyncing = false;
  int _lastSyncCount = -1;

  @override
  void initState() {
    super.initState();
    _loadHeatmap();
  }

  Future<void> _loadHeatmap() async {
    final userId = context.read<AuthService>().user?.uid;
    if (userId == null) return;
    final map = await _activityService.getActivityMap(userId);
    if (mounted) {
      setState(() {
        _activityMap = map;
        _heatmapLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthService>().user?.uid;
    if (userId == null) return const SizedBox.shrink();

    return StreamBuilder<UserProfile>(
      stream: _gamService.getUserProfile(userId),
      builder: (context, snapshot) {
        final profile = snapshot.data ?? const UserProfile();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileHeader(profile),
              const SizedBox(height: 24),
              _buildXpCard(profile),
              const SizedBox(height: 24),
              _buildBadgesSection(profile),
              const SizedBox(height: 24),
              _buildHeatmapSection(),
              const SizedBox(height: 32),
              _buildSettingsSection(),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  // ─── Profile Header ───────────────────────────────────────────────────────

  Widget _buildProfileHeader(UserProfile profile) {
    final userId = context.read<AuthService>().user?.uid ?? '';
    final defaultName = context.read<AuthService>().user?.email?.split('@').first ?? 'User';
    final userName = profile.displayName ?? defaultName;
    final levelEmoji = _levelEmoji(profile.level);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary.withValues(alpha: 0.25), AppTheme.accent.withValues(alpha: 0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // Avatar with level ring
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [AppTheme.primary.withValues(alpha: 0.4), AppTheme.primaryDark.withValues(alpha: 0.2)],
              ),
              border: Border.all(color: AppTheme.primary, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.4),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Text(levelEmoji, style: const TextStyle(fontSize: 36)),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        userName,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 16, color: AppTheme.grayLight),
                      onPressed: () => _editUsername(context, userId, userName),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        'Level ${profile.level}',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryLight),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${profile.xp} XP total',
                      style: const TextStyle(color: AppTheme.gray, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${profile.badges.length} badge${profile.badges.length != 1 ? 's' : ''} earned',
                  style: const TextStyle(color: AppTheme.grayLight, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Edit Username ────────────────────────────────────────────────────────

  Future<void> _editUsername(BuildContext context, String userId, String currentName) async {
    final controller = TextEditingController(text: currentName);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.dark,
        title: const Text('Edit Username'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter new username'),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.grayLight)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != currentName) {
      await _gamService.updateDisplayName(userId, newName);
    }
  }

  // ─── XP Progress Card ─────────────────────────────────────────────────────

  Widget _buildXpCard(UserProfile profile) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('XP Progress',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  '${profile.xpInCurrentLevel} / ${profile.xpForNextLevel} XP',
                  style: const TextStyle(color: AppTheme.primaryLight, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: profile.levelProgress),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) => LinearProgressIndicator(
                  value: value,
                  minHeight: 14,
                  backgroundColor: Colors.white.withValues(alpha: 0.06),
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildXpHint('✅ Task', '+10 XP'),
                _buildXpHint('🍅 Pomodoro min', '+1 XP'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildXpHint(String label, String value) {
    return Row(
      children: [
        Text(label, style: const TextStyle(color: AppTheme.gray, fontSize: 12)),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.secondary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(value,
              style: const TextStyle(
                  color: AppTheme.secondaryLight,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  // ─── Badges Section ───────────────────────────────────────────────────────

  Widget _buildBadgesSection(UserProfile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Badges',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(
              '${profile.badges.length} / ${kAllBadges.length}',
              style: const TextStyle(fontSize: 12, color: AppTheme.gray),
            ),
          ],
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
          children: kAllBadges.map((badge) {
            final earned = profile.badges.contains(badge.id);
            return _buildBadgeCard(badge, earned);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBadgeCard(BadgeInfo badge, bool earned) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: earned
            ? AppTheme.primary.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: earned
              ? AppTheme.primary.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.06),
          width: earned ? 1.5 : 1,
        ),
        boxShadow: earned
            ? [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.2), blurRadius: 8)]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Text(
                badge.emoji,
                style: TextStyle(
                  fontSize: 32,
                  color: earned ? null : Colors.white.withValues(alpha: 0.15),
                ),
              ),
              if (!earned)
                const Icon(Icons.lock, size: 18, color: Colors.white30),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            badge.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: earned ? AppTheme.primaryLight : AppTheme.gray,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            badge.description,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9,
              color: earned
                  ? AppTheme.grayLight.withValues(alpha: 0.7)
                  : AppTheme.gray.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Heatmap Section ──────────────────────────────────────────────────────

  Widget _buildHeatmapSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('365-Day Activity',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (_heatmapLoading)
              const Center(child: CircularProgressIndicator())
            else
              ActivityHeatmap(activityMap: _activityMap),
          ],
        ),
      ),
    );
  }

  // ─── Settings Section ─────────────────────────────────────────────────────

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Text('Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 12),
        // App Settings button
        Card(
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.tune_rounded, color: AppTheme.primaryLight, size: 20),
            ),
            title: const Text('App Settings', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Theme, Pomodoro timers, notifications'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Change Password button
        Card(
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.lock_reset, color: AppTheme.accentLight, size: 20),
            ),
            title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Update your account password securely'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showDialog(
              context: context,
              builder: (_) => const ChangePasswordModal(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Study Analytics button
        Card(
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.secondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.bar_chart_rounded, color: AppTheme.secondaryLight, size: 20),
            ),
            title: const Text('Study Analytics', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('View time spent per subject with charts'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Google Calendar Panel
        _buildCalendarPanel(),
        const SizedBox(height: 12),
        // Danger Zone
        Card(
          color: AppTheme.danger.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppTheme.danger.withValues(alpha: 0.3)),
          ),
          child: ListTile(
            leading: const Icon(Icons.delete_forever, color: AppTheme.dangerLight),
            title: const Text('Delete Account',
                style: TextStyle(
                    color: AppTheme.dangerLight, fontWeight: FontWeight.bold)),
            subtitle: const Text(
                'Permanently delete your account and all data',
                style: TextStyle(color: AppTheme.grayLight, fontSize: 12)),
            trailing: const Icon(Icons.chevron_right, color: AppTheme.gray),
            onTap: _showDeleteAccountDialog,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarPanel() {
    final isConnected = _calendarService.isConnected;
    final userId = context.read<AuthService>().user?.uid ?? '';

    return Card(
      color: isConnected
          ? const Color(0xFF34A853).withValues(alpha: 0.08)
          : AppTheme.primary.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isConnected
              ? const Color(0xFF34A853).withValues(alpha: 0.35)
              : AppTheme.primary.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isConnected
                        ? const Color(0xFF34A853).withValues(alpha: 0.15)
                        : AppTheme.primary.withValues(alpha: 0.15),
                  ),
                  child: Icon(
                    Icons.calendar_month_rounded,
                    color: isConnected
                        ? const Color(0xFF34A853)
                        : AppTheme.primaryLight,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Google Calendar',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(
                        isConnected
                            ? 'Two-way sync is active'
                            : 'Connect for two-way sync',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.grayLight),
                      ),
                    ],
                  ),
                ),
                if (isConnected)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF34A853).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Active',
                        style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF34A853),
                            fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_lastSyncCount >= 0) ...([
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF34A853).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _lastSyncCount > 0
                      ? '✅ Imported $_lastSyncCount new task${_lastSyncCount > 1 ? 's' : ''} from Calendar!'
                      : '✅ Calendar is fully up to date!',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF34A853)),
                ),
              ),
              const SizedBox(height: 12),
            ]),
            Row(
              children: [
                if (!isConnected)
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: _calendarConnecting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.login, size: 16),
                      label: const Text('Connect Google Account'),
                      onPressed: _calendarConnecting
                          ? null
                          : () async {
                              setState(() => _calendarConnecting = true);
                              final ok =
                                  await _calendarService.connect();
                              setState(() => _calendarConnecting = false);
                              if (ok) {
                                ToastController().showSuccess(
                                  '📅 Calendar Connected!',
                                  'Tasks will now sync to Google Calendar automatically.',
                                );
                              }
                            },
                    ),
                  )
                else ...([
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF34A853),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: _calendarSyncing
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.sync, size: 16),
                      label: const Text('Sync from Calendar'),
                      onPressed: _calendarSyncing
                          ? null
                          : () async {
                              setState(() => _calendarSyncing = true);
                              final count = await _calendarService
                                  .syncFromCalendar(userId);
                              setState(() {
                                _calendarSyncing = false;
                                _lastSyncCount = count;
                              });
                            },
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () async {
                      await _calendarService.disconnect();
                      setState(() => _lastSyncCount = -1);
                    },
                    child: const Text('Disconnect',
                        style: TextStyle(
                            color: AppTheme.gray, fontSize: 12)),
                  ),
                ]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteAccountDialog() async {
    final passwordController = TextEditingController();
    bool isLoading = false;
    String errorMessage = '';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppTheme.dark,
              title: const Text('Delete Account', style: TextStyle(color: AppTheme.dangerLight)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'This action cannot be undone. All your tasks, XP, badges, and heatmap data will be permanently deleted.',
                    style: TextStyle(color: AppTheme.grayLight, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  const Text('Please enter your password to confirm:', style: TextStyle(fontSize: 13)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  if (errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(errorMessage, style: const TextStyle(color: AppTheme.dangerLight, fontSize: 12)),
                  ],
                ],
              ),
              actions: [
                if (!isLoading)
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel', style: TextStyle(color: AppTheme.grayLight)),
                  ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
                  onPressed: isLoading
                      ? null
                      : () async {
                          final pwd = passwordController.text;
                          if (pwd.isEmpty) {
                            setState(() => errorMessage = 'Password is required');
                            return;
                          }

                          setState(() {
                            isLoading = true;
                            errorMessage = '';
                          });

                          try {
                            final auth = context.read<AuthService>();
                            await auth.deleteAccount(pwd);
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              // User is logged out, the Auth stream will automatically redirect to Login.
                            }
                          } catch (e) {
                            setState(() {
                              isLoading = false;
                              errorMessage = e.toString().contains('wrong-password')
                                  ? 'Incorrect password.'
                                  : 'Failed to delete account. Please try again.';
                            });
                          }
                        },
                  child: isLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Delete Permanently'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ─── Helper ───────────────────────────────────────────────────────────────

  String _levelEmoji(int level) {
    if (level >= 20) return '👑';
    if (level >= 15) return '🔥';
    if (level >= 10) return '⚡';
    if (level >= 5) return '🌟';
    return '🌱';
  }
}
