import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

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
      DashboardTab(
        onNavigateToTab: _navigateToTab,
        onFocusTask: _focusOnTask,
      ),
      TasksTab(
        onFocusTask: _focusOnTask,
      ),
      PomodoroTab(
        key: ValueKey(_focusedTask?.id ?? 'no-focus'), // Force rebuild when focused task changes
        focusedTask: _focusedTask,
        onClearFocus: _clearFocus,
      ),
      const GpaTab(),
      const AiChatTab(),
      const SummarizerTab(),
      const ProfileTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('TaskMate', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                authService.user?.email ?? '',
                style: const TextStyle(color: AppTheme.grayLight, fontSize: 12),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.dangerLight),
            onPressed: () => authService.signOut(),
          )
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          ),
        ),
        child: SafeArea(
          child: tabs[_currentIndex],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: AppTheme.dark,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: AppTheme.gray,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 11,
        unselectedFontSize: 10,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.task_alt), label: 'Tasks'),
          BottomNavigationBarItem(icon: Icon(Icons.timer), label: 'Pomodoro'),
          BottomNavigationBarItem(icon: Icon(Icons.calculate), label: 'GPA Calc'),
          BottomNavigationBarItem(icon: Icon(Icons.smart_toy), label: 'AI Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Study Hub'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
