import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/offline_banner.dart';

import '../dashboard/dashboard_tab.dart';
import '../tasks/tasks_tab.dart';
import '../pomodoro/pomodoro_tab.dart';
import '../gpa/gpa_tab.dart';
import '../ai_chat/ai_chat_tab.dart';
import '../summarizer/summarizer_tab.dart';
import '../profile/profile_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  TaskModel? _focusedTask;

  void _navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _focusOnTask(TaskModel task) {
    setState(() {
      _focusedTask = task;
      _currentIndex = 2; // Navigate to Pomodoro tab
    });
  }

  void _clearFocus() {
    setState(() {
      _focusedTask = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();

    // Build tabs dynamically so we can pass callbacks
    final List<Widget> tabs = [
      DashboardTab(onNavigateToTab: _navigateToTab, onFocusTask: _focusOnTask),
      TasksTab(onFocusTask: _focusOnTask),
      PomodoroTab(
        key: ValueKey(
          _focusedTask?.id ?? 'no-focus',
        ), // Force rebuild when focused task changes
        focusedTask: _focusedTask,
        onClearFocus: _clearFocus,
      ),
      const GpaTab(),
      const AiChatTab(),
      const SummarizerTab(),
      const ProfileTab(),
    ];

    return OfflineBanner(
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: Text(
            'TaskMate',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        body: IndexedStack(index: _currentIndex, children: tabs),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.surface.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  )
                ]
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(Icons.dashboard_rounded, 0),
                  _buildNavItem(Icons.task_alt, 1),
                  _buildNavItem(Icons.timer_outlined, 2),
                  _buildNavItem(Icons.calculate_outlined, 3),
                  _buildNavItem(Icons.smart_toy_outlined, 4),
                  _buildNavItem(Icons.school_outlined, 5),
                  _buildNavItem(Icons.person_outline, 6),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _navigateToTab(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 44,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.all(isSelected ? 6 : 0),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary.withValues(alpha: 0.1) : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isSelected ? AppTheme.primary : AppTheme.textMuted,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              height: 4,
              width: isSelected ? 16 : 0,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            )
          ],
        ),
      ),
    );
  }
}
