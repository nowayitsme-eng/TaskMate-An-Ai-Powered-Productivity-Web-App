import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/task.dart';
import '../../models/user_profile.dart';
import '../../services/task_service.dart';
import '../../services/auth_service.dart';
import '../../services/gamification_service.dart';
import '../../services/ai_service.dart';
import '../../services/cache_service.dart';
import '../../services/activity_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/virtual_pet.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/empty_state_widget.dart';

class DashboardTab extends StatefulWidget {
  final void Function(int tabIndex) onNavigateToTab;
  final void Function(TaskModel task) onFocusTask;

  const DashboardTab({
    super.key,
    required this.onNavigateToTab,
    required this.onFocusTask,
  });

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  final AiService _aiService = AiService();
  final GamificationService _gamService = GamificationService();
  final CacheService _cacheService = CacheService();

  String? _weeklyInsight;
  bool _insightLoading = false;
  bool _insightLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_insightLoaded) {
      _insightLoaded = true;
      _loadCachedInsight();
    }
  }

  Future<void> _loadCachedInsight() async {
    final userId = context.read<AuthService>().user?.uid;
    if (userId == null) return;
    final cached = await _aiService.getLastWeeklyInsight(userId);
    if (mounted) setState(() => _weeklyInsight = cached);
  }

  Future<void> _generateInsight(List<TaskModel> tasks) async {
    final userId = context.read<AuthService>().user?.uid;
    if (userId == null) return;

    setState(() => _insightLoading = true);

    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));

      final recentCompleted = tasks
          .where((t) => t.completed && t.dueDate.isAfter(weekAgo))
          .toList();
      final overdue = tasks
          .where((t) => !t.completed && t.dueDate.isBefore(now))
          .toList();
      final pomodoroMinutes = tasks.fold<int>(
        0,
        (sum, t) => sum + t.pomodoroMinutes,
      );

      final catCount = <String, int>{};
      for (final t in recentCompleted) {
        if (t.subject != null && t.subject!.isNotEmpty) {
          catCount[t.subject!] = (catCount[t.subject!] ?? 0) + 1;
        }
      }
      final topCategories = catCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
      final upcomingTasks = tasks
          .where((t) => !t.completed && t.dueDate.isAfter(todayEnd))
          .toList();

      final insight = await _aiService.generateWeeklyInsight(
        userId: userId,
        completedTasks: recentCompleted.length,
        overdueTasks: overdue.length,
        upcomingTasks: upcomingTasks.length,
        pomodoroMinutes: pomodoroMinutes,
        topCategories: topCategories.take(3).map((e) => e.key).toList(),
      );

      if (mounted) setState(() => _weeklyInsight = insight);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not generate insight. Try again later.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _insightLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthService>().user?.uid;
    if (userId == null) return const SizedBox.shrink();

    final taskService = TaskService();

    return StreamBuilder<List<TaskModel>>(
      stream: taskService.getTasks(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonLoader(height: 120, borderRadius: 24),
                const SizedBox(height: 28),
                const SkeletonLoader(height: 40, width: 200),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: const SkeletonLoader(
                        height: 100,
                        borderRadius: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: const SkeletonLoader(
                        height: 100,
                        borderRadius: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                const SkeletonLoader(height: 80, borderRadius: 24),
              ],
            ),
          );
        }

        final tasks = snapshot.data ?? [];
        if (snapshot.hasData) {
          _cacheService.cacheTasks(userId, tasks);
        }
        final now = DateTime.now();
        final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

        final overdueTasks = tasks
            .where((t) => !t.completed && t.dueDate.isBefore(now))
            .toList();
        final todayTasks = tasks
            .where(
              (t) =>
                  !t.completed &&
                  t.dueDate.isAfter(now) &&
                  t.dueDate.isBefore(todayEnd),
            )
            .toList();
        final upcomingTasks =
            tasks
                .where((t) => !t.completed && t.dueDate.isAfter(todayEnd))
                .toList()
              ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Virtual Pet
              _buildVirtualPet(tasks, now),
              const SizedBox(height: 28),

              // Greeting Header
              _buildGreeting(context),
              const SizedBox(height: 24),

              // Stats Row
              _buildStatsRow(tasks, overdueTasks, context),
              const SizedBox(height: 28),

              // Quick Actions
              _buildQuickActions(context),
              const SizedBox(height: 32),

              // Overdue Tasks
              if (overdueTasks.isNotEmpty) ...[
                _buildSectionHeader(
                  '🔥 Overdue',
                  '${overdueTasks.length} tasks',
                  AppTheme.danger,
                ),
                const SizedBox(height: 16),
                ...overdueTasks
                    .take(5)
                    .map((t) => _buildTaskCard(context, t, isOverdue: true)),
                const SizedBox(height: 28),
              ],

              // Today's Tasks
              if (todayTasks.isNotEmpty) ...[
                _buildSectionHeader(
                  '📋 Due Today',
                  '${todayTasks.length} tasks',
                  AppTheme.primary,
                ),
                const SizedBox(height: 16),
                ...todayTasks.map((t) => _buildTaskCard(context, t)),
                const SizedBox(height: 28),
              ],

              // Upcoming
              if (upcomingTasks.isNotEmpty) ...[
                _buildSectionHeader(
                  '📅 Upcoming',
                  '${upcomingTasks.length} tasks',
                  AppTheme.textSecondary,
                ),
                const SizedBox(height: 16),
                ...upcomingTasks.take(5).map((t) => _buildTaskCard(context, t)),
                const SizedBox(height: 28),
              ],

              // Weekly AI Insights
              _buildWeeklyInsightCard(tasks),
              const SizedBox(height: 32),

              // Empty state
              if (tasks.isEmpty)
                EmptyStateWidget(
                  icon: Icons.rocket_launch_rounded,
                  title: 'Your slate is clean!',
                  subtitle: 'Add a task to get started and keep your momentum going.',
                  actionLabel: 'New Task',
                  onAction: () => widget.onNavigateToTab(1),
                ),
            ],
          ),
        );
      },
    );
  }

  // ─── Weekly AI Insight Card ───────────────────────────────────────────────

  Widget _buildWeeklyInsightCard(List<TaskModel> tasks) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.psychology,
                  color: AppTheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekly AI Insight',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Powered by AI',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: _insightLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primary,
                        ),
                      )
                    : const Icon(
                        Icons.refresh,
                        color: AppTheme.primary,
                        size: 22,
                      ),
                tooltip: 'Refresh insight',
                onPressed: _insightLoading
                    ? null
                    : () => _generateInsight(tasks),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_insightLoading && _weeklyInsight == null)
            _buildShimmer()
          else if (_weeklyInsight != null)
            Text(
              _weeklyInsight!,
              style: const TextStyle(
                fontSize: 15,
                height: 1.6,
                color: AppTheme.textSecondary,
              ),
            )
          else
            _buildInsightEmptyState(tasks),
        ],
      ),
    );
  }

  Widget _buildInsightEmptyState(List<TaskModel> tasks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Get a personalized weekly report from your AI coach — based on your task completions and Pomodoro focus time.',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _insightLoading ? null : () => _generateInsight(tasks),
          icon: const Icon(Icons.auto_awesome, size: 18),
          label: const Text('Generate My Insight'),
        ),
      ],
    );
  }

  Widget _buildShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(4, (i) {
        return _ShimmerBar(width: i % 2 == 0 ? double.infinity : 220);
      }),
    );
  }

  // ─── Virtual Pet ──────────────────────────────────────────────────────────

  Widget _buildVirtualPet(List<TaskModel> tasks, DateTime now) {
    final userId = context.read<AuthService>().user?.uid ?? '';
    final today = DateTime(now.year, now.month, now.day);
    final overdue = tasks
        .where((t) => !t.completed && t.dueDate.isBefore(now))
        .length;
    final completedToday = tasks.where((t) {
      if (!t.completed || t.completionDate == null) return false;
      final c = t.completionDate!;
      return c.year == now.year && c.month == now.month && c.day == now.day;
    }).length;

    return StreamBuilder<UserProfile>(
      stream: _gamService.getUserProfile(userId),
      builder: (context, profileSnap) {
        final profile = profileSnap.data ?? const UserProfile();
        return FutureBuilder<bool>(
          future: ActivityService().hasSevenDayStreak(userId),
          builder: (context, streakSnap) {
            return VirtualPet(
              overdueTasks: overdue,
              completedToday: completedToday,
              level: profile.level,
              levelProgress: profile.levelProgress,
              hasSevenDayStreak: streakSnap.data ?? false,
              lastActiveDate: profile.lastActiveDate,
            );
          },
        );
      },
    );
  }

  // ─── Greeting ─────────────────────────────────────────────────────────────

  Widget _buildGreeting(BuildContext context) {
    final hour = DateTime.now().hour;
    String greeting;
    IconData icon;
    if (hour < 12) {
      greeting = 'Good Morning';
      icon = Icons.wb_sunny_rounded;
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
      icon = Icons.wb_cloudy_rounded;
    } else {
      greeting = 'Good Evening';
      icon = Icons.nightlight_round;
    }

    final userId = context.read<AuthService>().user?.uid;
    final defaultName =
        context.read<AuthService>().user?.email?.split('@').first ?? 'there';

    return StreamBuilder<UserProfile>(
      stream: userId != null ? _gamService.getUserProfile(userId) : null,
      builder: (context, snapshot) {
        final userName = snapshot.data?.displayName ?? defaultName;
        return Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primarySurface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: AppTheme.primary, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    userName,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ─── Stats Row ────────────────────────────────────────────────────────────

  Widget _buildStatsRow(
    List<TaskModel> all,
    List<TaskModel> overdue,
    BuildContext context,
  ) {
    final userId = context.read<AuthService>().user?.uid;

    return StreamBuilder<UserProfile>(
      stream: userId != null ? _gamService.getUserProfile(userId) : null,
      builder: (context, snapshot) {
        final profile = snapshot.data ?? const UserProfile();

        return Row(
          children: [
            _buildStatCard(
              'Total',
              '${all.length}',
              Icons.list_alt,
              AppTheme.skySurface,
              AppTheme.skyBlue,
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              'Overdue',
              '${overdue.length}',
              Icons.warning_amber_rounded,
              AppTheme.roseSurface,
              AppTheme.rosePink,
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              'Done',
              '${profile.lifetimeTasksCompleted}',
              Icons.check_circle_outline,
              AppTheme.secondarySurface,
              AppTheme.secondary,
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              'Focus',
              '${profile.lifetimePomodoroMinutes}m',
              Icons.timer_outlined,
              AppTheme.accentSurface,
              AppTheme.accent,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color bgColor,
    Color iconColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Quick Actions ────────────────────────────────────────────────────────

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionButton(
            icon: Icons.add_task,
            label: 'New Task',
            bgColor: const Color(0xFFFDF4FF), // fuchsia-50
            iconColor: const Color(0xFFC026D3), // fuchsia-600
            onTap: () => widget.onNavigateToTab(1),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickActionButton(
            icon: Icons.play_arrow_rounded,
            label: 'Focus Time',
            bgColor: const Color(0xFFF0FDFA), // teal-50
            iconColor: const Color(0xFF0D9488), // teal-600
            onTap: () => widget.onNavigateToTab(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickActionButton(
            icon: Icons.smart_toy_outlined,
            label: 'Ask AI',
            bgColor: const Color(0xFFFFFBEB), // amber-50
            iconColor: const Color(0xFFD97706), // amber-600
            onTap: () => widget.onNavigateToTab(4),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: iconColor.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  color: iconColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Section Header ───────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title, String subtitle, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ─── Task Card ────────────────────────────────────────────────────────────

  Widget _buildTaskCard(
    BuildContext context,
    TaskModel task, {
    bool isOverdue = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOverdue ? AppTheme.dangerSurface : AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOverdue ? AppTheme.dangerLight : AppTheme.border,
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.text,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: isOverdue ? AppTheme.danger : AppTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: isOverdue ? AppTheme.danger : AppTheme.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('MMM d, h:mm a').format(task.dueDate),
                      style: TextStyle(
                        fontSize: 12,
                        color: isOverdue ? AppTheme.danger : AppTheme.textMuted,
                      ),
                    ),
                    if (task.pomodoroMinutes > 0) ...[
                      const SizedBox(width: 14),
                      const Icon(
                        Icons.timer_outlined,
                        size: 14,
                        color: AppTheme.accent,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${task.pomodoroMinutes}m',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.primarySurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.bolt, color: AppTheme.primary),
              tooltip: 'Focus on this task',
              onPressed: () => widget.onFocusTask(task),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerBar extends StatefulWidget {
  final double width;
  const _ShimmerBar({required this.width});

  @override
  State<_ShimmerBar> createState() => _ShimmerBarState();
}

class _ShimmerBarState extends State<_ShimmerBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) => Container(
        width: widget.width,
        height: 14,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.border.withValues(alpha: _anim.value),
          borderRadius: BorderRadius.circular(7),
        ),
      ),
    );
  }
}
