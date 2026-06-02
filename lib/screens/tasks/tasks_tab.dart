import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/task.dart';
import '../../models/user_profile.dart';
import '../../services/task_service.dart';
import '../../services/auth_service.dart';
import '../../services/ai_service.dart';
import '../../services/notification_service.dart';
import '../../services/gamification_service.dart';
import '../../services/activity_service.dart';
import '../../services/messaging_service.dart';
import '../../services/cache_service.dart';
import '../../theme/app_theme.dart';

class TasksTab extends StatefulWidget {
  final void Function(TaskModel task)? onFocusTask;

  const TasksTab({super.key, this.onFocusTask});

  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab> {
  final TaskService _taskService = TaskService();
  final AiService _aiService = AiService();
  final NotificationService _notificationService = NotificationService();
  final GamificationService _gamService = GamificationService();
  final ActivityService _activityService = ActivityService();
  final CacheService _cacheService = CacheService();

  final _textController = TextEditingController();
  final _subjectController = TextEditingController();
  String? _selectedType;
  DateTime? _dueDate;
  bool _isDecomposing = false;

  @override
  void dispose() {
    _textController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  void _addTask() {
    final authService = context.read<AuthService>();
    final userId = authService.user?.uid;
    if (userId == null) return;

    if (_textController.text.trim().isEmpty || _dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task description and due date are required!')),
      );
      return;
    }

    final task = TaskModel(
      id: '',
      text: _textController.text.trim(),
      subject: _subjectController.text.trim().isEmpty ? null : _subjectController.text.trim(),
      type: _selectedType,
      dueDate: _dueDate!,
    );

    _taskService.addTask(userId, task).then((taskId) {
      task.id = taskId;
      _notificationService.scheduleTaskReminder(task);
    });

    // Reset form
    _textController.clear();
    _subjectController.clear();
    setState(() {
      _selectedType = null;
      _dueDate = null;
    });
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      if (!context.mounted) return;
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        setState(() {
          _dueDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  /// Opens a bottom sheet showing AI-generated sub-tasks that can be added.
  Future<void> _showDecomposeSheet() async {
    final taskTitle = _textController.text.trim();
    if (taskTitle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a task description first to break it down.')),
      );
      return;
    }

    setState(() => _isDecomposing = true);

    List<String> subTasks = [];
    try {
      subTasks = await _aiService.decomposeTask(taskTitle);
    } catch (_) {
      // decomposeTask already returns a fallback list
    } finally {
      if (mounted) setState(() => _isDecomposing = false);
    }

    if (!mounted) return;

    final selected = List<bool>.filled(subTasks.length, true);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.65,
            maxChildSize: 0.9,
            builder: (_, controller) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.auto_awesome, color: AppTheme.primaryLight, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'AI Task Breakdown',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '"$taskTitle"',
                                style: const TextStyle(fontSize: 12, color: AppTheme.grayLight),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Select the sub-tasks you want to add:',
                      style: TextStyle(color: AppTheme.gray, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    // Sub-task list
                    Expanded(
                      child: ListView.builder(
                        controller: controller,
                        itemCount: subTasks.length,
                        itemBuilder: (_, i) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: selected[i]
                                  ? AppTheme.primary.withValues(alpha: 0.12)
                                  : Colors.white.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected[i]
                                    ? AppTheme.primary.withValues(alpha: 0.4)
                                    : Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: CheckboxListTile(
                              value: selected[i],
                              onChanged: (val) =>
                                  setSheetState(() => selected[i] = val ?? true),
                              activeColor: AppTheme.primary,
                              checkColor: Colors.white,
                              title: Text(
                                subTasks[i],
                                style: const TextStyle(fontSize: 14),
                              ),
                              secondary: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${i + 1}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryLight,
                                    ),
                                  ),
                                ),
                              ),
                              controlAffinity: ListTileControlAffinity.trailing,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.gray,
                              side: const BorderSide(color: Colors.white24),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final userId = context.read<AuthService>().user?.uid;
                              if (userId == null) return;

                              final selectedSubs = <String>[];
                              for (int i = 0; i < subTasks.length; i++) {
                                if (selected[i]) selectedSubs.add(subTasks[i]);
                              }

                              // First add the parent task
                              final parentTask = TaskModel(
                                id: '',
                                text: taskTitle,
                                subject: _subjectController.text.trim().isEmpty
                                    ? null
                                    : _subjectController.text.trim(),
                                type: _selectedType,
                                dueDate: _dueDate ?? DateTime.now().add(const Duration(days: 1)),
                              );
                              _taskService.addTask(userId, parentTask).then((parentId) async {
                                parentTask.id = parentId;
                                _notificationService.scheduleTaskReminder(parentTask);
                                // Then add each sub-task
                                for (final sub in selectedSubs) {
                                  final subTask = TaskModel(
                                    id: '',
                                    text: sub,
                                    subject: parentTask.subject,
                                    type: parentTask.type,
                                    dueDate: parentTask.dueDate,
                                    parentTaskId: parentId,
                                    isSubTask: true,
                                  );
                                  final subId = await _taskService.addTask(userId, subTask);
                                  subTask.id = subId;
                                  _notificationService.scheduleTaskReminder(subTask);
                                }
                              });

                              // Reset form
                              _textController.clear();
                              _subjectController.clear();
                              setState(() {
                                _selectedType = null;
                                _dueDate = null;
                              });

                              Navigator.pop(ctx);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      '✅ Added "$taskTitle" + ${selectedSubs.length} sub-tasks'),
                                  backgroundColor: AppTheme.secondary,
                                ),
                              );
                            },
                            icon: const Icon(Icons.add_task),
                            label: Text(
                              'Add ${selected.where((s) => s).length} Tasks',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        });
      },
    );
  }

  Widget _buildTaskForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.task, color: AppTheme.primaryLight),
                const SizedBox(width: 8),
                const Text('Task Manager', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            // Task description + AI wand button
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(hintText: 'Task description'),
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Break it down with AI',
                  child: Container(
                    height: 56,
                    width: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primary.withValues(alpha: 0.8), AppTheme.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _isDecomposing ? null : _showDecomposeSheet,
                        child: Center(
                          child: _isDecomposing
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _subjectController,
                    decoration: const InputDecoration(hintText: 'Category (optional)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _selectedType,
                    decoration: const InputDecoration(hintText: 'Select Type'),
                    items: const [
                      DropdownMenuItem(value: 'Assignment', child: Text('Assignment')),
                      DropdownMenuItem(value: 'Project', child: Text('Project')),
                      DropdownMenuItem(value: 'Exam', child: Text('Exam')),
                      DropdownMenuItem(value: 'Quiz', child: Text('Quiz')),
                      DropdownMenuItem(value: 'Personal', child: Text('Personal')),
                      DropdownMenuItem(value: 'Other', child: Text('Other')),
                    ],
                    onChanged: (value) => setState(() => _selectedType = value),
                    dropdownColor: AppTheme.dark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDateTime(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        hintText: 'Due Date',
                        prefixIcon: Icon(Icons.calendar_today, color: AppTheme.gray),
                      ),
                      child: Text(
                        _dueDate == null
                            ? 'Select Due Date'
                            : DateFormat('MMM d, y, h:mm a').format(_dueDate!),
                        style: TextStyle(color: _dueDate == null ? Colors.white54 : Colors.white),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _addTask,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Icon(Icons.add),
                  ),
                ),
              ],
            ),
            // AI hint text
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.auto_awesome, size: 13, color: AppTheme.primaryLight),
                const SizedBox(width: 5),
                Text(
                  'Tap ✨ to let AI break your task into sub-tasks',
                  style: TextStyle(fontSize: 12, color: AppTheme.primaryLight.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskList() {
    final userId = context.watch<AuthService>().user?.uid;
    if (userId == null) return const SizedBox.shrink();

    return StreamBuilder<List<TaskModel>>(
      stream: _taskService.getTasks(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return FutureBuilder<List<TaskModel>>(
            future: _cacheService.getCachedTasks(userId),
            builder: (context, cacheSnapshot) {
              if (!cacheSnapshot.hasData || cacheSnapshot.data!.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              return _buildListContent(userId, cacheSnapshot.data!, isOffline: true);
            },
          );
        }

        _cacheService.cacheTasks(userId, snapshot.data!);
        return _buildListContent(userId, snapshot.data!, isOffline: false);
      },
    );
  }

  Widget _buildListContent(String userId, List<TaskModel> tasks, {required bool isOffline}) {
    tasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    if (tasks.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No tasks yet. Add one above!', style: TextStyle(color: AppTheme.gray)),
        ),
      );
    }

    return Column(
      children: [
        if (isOffline)
          Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppTheme.danger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off, size: 16, color: AppTheme.dangerLight),
                SizedBox(width: 8),
                Text('Offline Mode — Showing cached tasks', style: TextStyle(color: AppTheme.dangerLight, fontSize: 12)),
              ],
            ),
          ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            final isOverdue = task.dueDate.isBefore(DateTime.now()) && !task.completed;

            return Padding(
              // Indent sub-tasks visually
              padding: EdgeInsets.only(left: task.isSubTask ? 20.0 : 0.0),
              child: Card(
                margin: const EdgeInsets.only(bottom: 10),
                color: isOverdue ? AppTheme.danger.withValues(alpha: 0.1) : AppTheme.glass,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: task.isSubTask
                        ? AppTheme.primary.withValues(alpha: 0.25)
                        : isOverdue
                            ? AppTheme.danger
                            : Colors.white.withValues(alpha: 0.05),
                    width: isOverdue ? 2 : 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: Checkbox(
                      value: task.completed,
                      activeColor: AppTheme.secondary,
                      onChanged: isOffline ? null : (val) async {
                        if (val != null) {
                          _taskService.updateTask(userId, task.id, {'completed': val});
                          if (val && !task.completed) {
                            // Task just completed!
                            MessagingService().notifyTaskCompleted(task.text);
                            
                            await _activityService.logActivity(userId, tasksCompleted: 1);
                            await _gamService.addXp(userId, GamificationService.xpPerTask);
                            
                            // Check badges
                            final allTasks = await _taskService.getTasks(userId).first;
                            final totalCompleted = allTasks.where((t) => t.completed).length + 1;
                            final totalPomodoro = allTasks.fold<int>(0, (sum, t) => sum + t.pomodoroMinutes);
                            
                            final earned = await _gamService.checkAndAwardBadges(
                              userId,
                              totalCompleted: totalCompleted,
                              totalPomodoroMinutes: totalPomodoro,
                              actionTime: DateTime.now(),
                            );
                            
                            if (earned.isNotEmpty) {
                              MessagingService().notifyBadgeEarned(
                                earned.map((id) => kAllBadges
                                  .firstWhere((b) => b.id == id,
                                      orElse: () => BadgeInfo(id: id, name: id, emoji: '🏆', description: ''))
                                  .name).toList(),
                              );
                            }
                          }
                        }
                      },
                    ),
                    title: Row(
                      children: [
                        if (task.isSubTask) ...[
                          const Text('↳ ', style: TextStyle(color: AppTheme.primaryLight, fontSize: 14)),
                        ],
                        Expanded(
                          child: Text(
                            task.text,
                            style: TextStyle(
                              decoration: task.completed ? TextDecoration.lineThrough : null,
                              color: task.completed ? AppTheme.gray : Colors.white,
                              fontSize: task.isSubTask ? 14 : 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Wrap(
                      spacing: 8,
                      children: [
                        if (task.subject != null)
                          Chip(
                            label: Text(task.subject!, style: const TextStyle(fontSize: 10)),
                            backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        if (task.type != null)
                          Chip(
                            label: Text(task.type!, style: const TextStyle(fontSize: 10)),
                            backgroundColor: AppTheme.secondary.withValues(alpha: 0.2),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        if (task.isSubTask)
                          Chip(
                            avatar: const Icon(Icons.auto_awesome, size: 12, color: AppTheme.primaryLight),
                            label: const Text('Sub-task', style: TextStyle(fontSize: 10, color: AppTheme.primaryLight)),
                            backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        if (task.pomodoroMinutes > 0)
                          Chip(
                            avatar: const Icon(Icons.timer, size: 14, color: AppTheme.accentLight),
                            label: Text('${task.pomodoroMinutes}m',
                                style: const TextStyle(fontSize: 10, color: AppTheme.accentLight)),
                            backgroundColor: AppTheme.accent.withValues(alpha: 0.15),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_today, size: 12, color: AppTheme.gray),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat('MMM d, y, h:mm a').format(task.dueDate),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isOverdue ? AppTheme.danger : AppTheme.grayLight,
                                  fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!task.completed && widget.onFocusTask != null)
                          IconButton(
                            icon: const Icon(Icons.bolt, color: AppTheme.accentLight),
                            tooltip: 'Focus on this task',
                            onPressed: () => widget.onFocusTask!(task),
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppTheme.dangerLight),
                          onPressed: isOffline ? null : () {
                            _taskService.deleteTask(userId, task.id);
                            _notificationService.cancelTaskReminder(task.id);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTaskForm(),
          const SizedBox(height: 24),
          _buildTaskList(),
        ],
      ),
    );
  }
}
