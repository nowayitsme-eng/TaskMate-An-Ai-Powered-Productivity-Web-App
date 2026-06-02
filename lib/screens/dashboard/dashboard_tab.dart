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
    // Load cached insight once when the widget first builds with a valid user
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

      final recentCompleted =
          tasks.where((t) => t.completed && t.dueDate.isAfter(weekAgo)).toList();
      final overdue = tasks.where((t) => !t.completed && t.dueDate.isBefore(now)).toList();
      final pomodoroMinutes = tasks.fold<int>(0, (sum, t) => sum + t.pomodoroMinutes);

      // Collect top categories
      final catCount = <String, int>{};
      for (final t in recentCompleted) {
        if (t.subject != null && t.subject!.isNotEmpty) {
          catCount[t.subject!] = (catCount[t.subject!] ?? 0) + 1;
        }
      }
      final topCategories = catCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final insight = await _aiService.generateWeeklyInsight(
        userId: userId,
        completedTasks: recentCompleted.length,
        overdueTasks: overdue.length,
        pomodoroMinutes: pomodoroMinutes,
        topCategories: topCategories.take(3).map((e) => e.key).toList(),
      );

      if (mounted) setState(() => _weeklyInsight = insight);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not generate insight. Try again later.')),
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
        final tasks = snapshot.data ?? [];
        // Update cache whenever we get fresh data
        if (snapshot.hasData) {
          _cacheService.cacheTasks(userId, tasks);
        }
        final now = DateTime.now();
        final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

        final overdueTasks =
            tasks.where((t) => !t.completed && t.dueDate.isBefore(now)).toList();
        final todayTasks = tasks
            .where((t) =>
                !t.completed &&
                t.dueDate.isAfter(now) &&
                t.dueDate.isBefore(todayEnd))
            .toList();
        final upcomingTasks =
            tasks.where((t) => !t.completed && t.dueDate.isAfter(todayEnd)).toList()
              ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
        final completedTasks = tasks.where((t) => t.completed).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Virtual Pet
              _buildVirtualPet(tasks, now),
              const SizedBox(height: 20),

              // Greeting Header
              _buildGreeting(context),
              const SizedBox(height: 24),

              // Stats Row
              _buildStatsRow(tasks, overdueTasks, completedTasks),
              const SizedBox(height: 24),

              // Quick Actions
              _buildQuickActions(context),
              const SizedBox(height: 28),

              // Overdue Tasks
              if (overdueTasks.isNotEmpty) ...[
                _buildSectionHeader('🔥 Overdue', '${overdueTasks.length} tasks', AppTheme.danger),
                const SizedBox(height: 12),
                ...overdueTasks
                    .take(5)
                    .map((t) => _buildTaskCard(context, t, isOverdue: true)),
                const SizedBox(height: 24),
              ],

              // Today's Tasks
              if (todayTasks.isNotEmpty) ...[
                _buildSectionHeader('📋 Due Today', '${todayTasks.length} tasks', AppTheme.accent),
                const SizedBox(height: 12),
                ...todayTasks.map((t) => _buildTaskCard(context, t)),
                const SizedBox(height: 24),
              ],

              // Upcoming
              if (upcomingTasks.isNotEmpty) ...[
                _buildSectionHeader('📅 Upcoming', '${upcomingTasks.length} tasks', AppTheme.primaryLight),
                const SizedBox(height: 12),
                ...upcomingTasks.take(5).map((t) => _buildTaskCard(context, t)),
                const SizedBox(height: 24),
              ],

              // Weekly AI Insights
              _buildWeeklyInsightCard(tasks),
              const SizedBox(height: 24),

              // Empty state
              if (tasks.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 64),
                    child: Column(
                      children: [
                        Icon(Icons.rocket_launch,
                            size: 64, color: AppTheme.primary.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        const Text('Your slate is clean!',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text('Add a task to get started.',
                            style: TextStyle(color: AppTheme.gray)),
                      ],
                    ),
                  ),
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
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withOpacity(0.18),
            AppTheme.accent.withOpacity(0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.psychology, color: AppTheme.primaryLight, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekly AI Insight',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      'Powered by Claude',
                      style: TextStyle(fontSize: 11, color: AppTheme.grayLight),
                    ),
                  ],
                ),
              ),
              // Refresh button
              IconButton(
                icon: _insightLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryLight),
                      )
                    : const Icon(Icons.refresh, color: AppTheme.primaryLight, size: 20),
                tooltip: 'Refresh insight',
                onPressed: _insightLoading ? null : () => _generateInsight(tasks),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Insight body
          if (_insightLoading && _weeklyInsight == null)
            _buildShimmer()
          else if (_weeklyInsight != null)
            Text(
              _weeklyInsight!,
              style: const TextStyle(
                fontSize: 14,
                height: 1.65,
                color: Colors.white,
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
          style: TextStyle(color: AppTheme.grayLight, fontSize: 13, height: 1.6),
        ),
        const SizedBox(height: 14),
        ElevatedButton.icon(
          onPressed: _insightLoading ? null : () => _generateInsight(tasks),
          icon: const Icon(Icons.auto_awesome, size: 16),
          label: const Text('Generate My Insight'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: const TextStyle(fontSize: 13),
          ),
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
    final overdue =
        tasks.where((t) => !t.completed && t.dueDate.isBefore(now)).length;
    final completedToday = tasks.where((t) {
      if (!t.completed) return false;
      final due = t.dueDate;
      return due.isAfter(today) &&
          due.isBefore(today.add(const Duration(days: 1)));
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
              hasSevenDayStreak: streakSnap.data ?? false,
              lastActiveDate: profile.lastActiveDate,
            );
          },
        );
      },
    );
  }

  // ─── Existing widgets ─────────────────────────────────────────────────────

  Widget _buildGreeting(BuildContext context) {
    final hour = DateTime.now().hour;
    String greeting;
    IconData icon;
    if (hour < 12) {
      greeting = 'Good Morning';
      icon = Icons.wb_sunny;
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
      icon = Icons.wb_cloudy;
    } else {
      greeting = 'Good Evening';
      icon = Icons.nightlight_round;
    }

    final userId = context.read<AuthService>().user?.uid;
    final defaultName = context.read<AuthService>().user?.email?.split('@').first ?? 'there';

    return StreamBuilder<UserProfile>(
      stream: userId != null ? _gamService.getUserProfile(userId) : null,
      builder: (context, snapshot) {
        final userName = snapshot.data?.displayName ?? defaultName;
        return Row(
          children: [
            Icon(icon, color: AppTheme.accentLight, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$greeting,',
                      style: const TextStyle(fontSize: 14, color: AppTheme.grayLight)),
                  Text(
                    userName,
                    style: const TextStyle(
                        fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
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

  Widget _buildStatsRow(
      List<TaskModel> all, List<TaskModel> overdue, List<TaskModel> completed) {
    final totalFocusMinutes = all.fold<int>(0, (sum, t) => sum + t.pomodoroMinutes);

    return Row(
      children: [
        _buildStatCard('Total', '${all.length}', Icons.list_alt, AppTheme.primaryLight),
        const SizedBox(width: 12),
        _buildStatCard('Overdue', '${overdue.length}', Icons.warning_amber, AppTheme.dangerLight),
        const SizedBox(width: 12),
        _buildStatCard('Done', '${completed.length}', Icons.check_circle, AppTheme.secondaryLight),
        const SizedBox(width: 12),
        _buildStatCard('Focus', '${totalFocusMinutes}m', Icons.timer, AppTheme.accentLight),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value,
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w900, color: color)),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label,
                  style: const TextStyle(fontSize: 11, color: AppTheme.grayLight)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionButton(
            icon: Icons.add_task,
            label: 'New Task',
            color: AppTheme.primary,
            onTap: () => widget.onNavigateToTab(1),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickActionButton(
            icon: Icons.play_circle_fill,
            label: 'Start Pomodoro',
            color: AppTheme.secondary,
            onTap: () => widget.onNavigateToTab(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickActionButton(
            icon: Icons.smart_toy,
            label: 'Ask AI',
            color: AppTheme.accent,
            onTap: () => widget.onNavigateToTab(4),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.25), color.withOpacity(0.1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label,
                  style: TextStyle(
                      color: color, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.gray)),
      ],
    );
  }

  Widget _buildTaskCard(BuildContext context, TaskModel task,
      {bool isOverdue = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isOverdue ? AppTheme.danger.withOpacity(0.08) : AppTheme.glass,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOverdue
              ? AppTheme.danger.withOpacity(0.4)
              : Colors.white.withOpacity(0.08),
        ),
      ),
      child: Row(
        children: [
          // Task info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.text,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 12,
                        color: isOverdue ? AppTheme.dangerLight : AppTheme.gray),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM d, h:mm a').format(task.dueDate),
                      style: TextStyle(
                          fontSize: 12,
                          color: isOverdue ? AppTheme.dangerLight : AppTheme.grayLight),
                    ),
                    if (task.pomodoroMinutes > 0) ...[
                      const SizedBox(width: 12),
                      const Icon(Icons.timer, size: 12, color: AppTheme.accentLight),
                      const SizedBox(width: 4),
                      Text('${task.pomodoroMinutes}m',
                          style: const TextStyle(fontSize: 12, color: AppTheme.accentLight)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Focus button
          IconButton(
            icon: const Icon(Icons.bolt, color: AppTheme.accentLight),
            tooltip: 'Focus on this task',
            onPressed: () => widget.onFocusTask(task),
          ),
        ],
      ),
    );
  }
}

// ─── Shimmer Bar Widget ───────────────────────────────────────────────────────

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
    _anim = Tween<double>(begin: 0.04, end: 0.15).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
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
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(_anim.value),
          borderRadius: BorderRadius.circular(7),
        ),
      ),
    );
  }
}
