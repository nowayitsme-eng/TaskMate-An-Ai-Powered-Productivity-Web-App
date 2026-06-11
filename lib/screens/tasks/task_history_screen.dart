import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/task.dart';
import '../../services/task_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class TaskHistoryScreen extends StatelessWidget {
  const TaskHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final userId = authService.user?.uid;
    final taskService = TaskService();

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Not authenticated')),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Archived Tasks', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: StreamBuilder<List<TaskModel>>(
        stream: taskService.getArchivedTasks(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: AppTheme.danger)));
          }

          final tasks = snapshot.data ?? [];
          if (tasks.isEmpty) {
            return const Center(
              child: Text(
                'No archived tasks found.',
                style: TextStyle(color: AppTheme.gray),
              ),
            );
          }

          // Sort by due date, newest first
          tasks.sort((a, b) => b.dueDate.compareTo(a.dueDate));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                color: AppTheme.glass,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: ListTile(
                  leading: const Icon(Icons.history, color: AppTheme.textSecondary),
                  title: Text(
                    task.text,
                    style: TextStyle(
                      decoration: task.completed ? TextDecoration.lineThrough : null,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'Due: ${DateFormat('MMM d, y, h:mm a').format(task.dueDate)}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.gray),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.restore, color: AppTheme.primaryLight),
                        tooltip: 'Restore to Main List',
                        onPressed: () {
                          taskService.updateTask(userId, task.id, {'isArchived': false});
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_forever, color: AppTheme.dangerLight),
                        tooltip: 'Permanently Delete',
                        onPressed: () {
                          _showDeleteDialog(context, taskService, userId, task.id);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, TaskService service, String userId, String taskId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Permanent Delete', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('Are you sure you want to permanently delete this task? This action cannot be undone.', style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.gray)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () {
              service.permanentDeleteTask(userId, taskId);
              Navigator.of(ctx).pop();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
