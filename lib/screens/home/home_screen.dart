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
        body: SafeArea(
          child: IndexedStack(index: _currentIndex, children: tabs),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              backgroundColor: Colors.transparent,
              selectedItemColor: AppTheme.primary,
              unselectedItemColor: AppTheme.textMuted,
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              selectedFontSize: 11,
              unselectedFontSize: 10,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_rounded),
                  activeIcon: Icon(Icons.dashboard_rounded),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.task_alt),
                  activeIcon: Icon(Icons.task_alt),
                  label: 'Tasks',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.timer_outlined),
                  activeIcon: Icon(Icons.timer),
                  label: 'Focus',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.calculate_outlined),
                  activeIcon: Icon(Icons.calculate),
                  label: 'GPA',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.smart_toy_outlined),
                  activeIcon: Icon(Icons.smart_toy),
                  label: 'AI Chat',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.school_outlined),
                  activeIcon: Icon(Icons.school),
                  label: 'Study',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
