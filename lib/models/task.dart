/// Priority levels for tasks.
/// 0 = Low, 1 = Medium, 2 = High
enum TaskPriority { low, medium, high }

extension TaskPriorityExtension on TaskPriority {
  String get label {
    switch (this) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
    }
  }

  String get emoji {
    switch (this) {
      case TaskPriority.low:
        return '🟢';
      case TaskPriority.medium:
        return '🟡';
      case TaskPriority.high:
        return '🔴';
    }
  }
}

class TaskModel {
  String id;
  String text;
  String? subject;
  String? type;
  DateTime dueDate;
  bool completed;
  DateTime? completionDate;
  int pomodoroMinutes;
  String? parentTaskId;
  bool isSubTask;
  String? calendarEventId; // Google Calendar event ID for two-way sync
  int priority; // 0=Low, 1=Medium, 2=High
  bool isArchived; // Soft delete flag

  TaskModel({
    required this.id,
    required this.text,
    this.subject,
    this.type,
    required this.dueDate,
    this.completed = false,
    this.completionDate,
    this.pomodoroMinutes = 0,
    this.parentTaskId,
    this.isSubTask = false,
    this.calendarEventId,
    this.priority = 0,
    this.isArchived = false,
  });

  factory TaskModel.fromMap(String id, Map<String, dynamic> data) {
    return TaskModel(
      id: id,
      text: data['text'] ?? '',
      subject: data['subject'],
      type: data['type'],
      dueDate: DateTime.parse(data['dueDate']),
      completed: data['completed'] ?? false,
      completionDate: data['completionDate'] != null ? DateTime.tryParse(data['completionDate']) : null,
      pomodoroMinutes: data['pomodoroMinutes'] ?? 0,
      parentTaskId: data['parentTaskId'],
      isSubTask: data['isSubTask'] ?? false,
      calendarEventId: data['calendarEventId'],
      priority: (data['priority'] as num?)?.toInt() ?? 0,
      isArchived: data['isArchived'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'subject': subject,
      'type': type,
      'dueDate': dueDate.toIso8601String(),
      'completed': completed,
      if (completionDate != null) 'completionDate': completionDate!.toIso8601String(),
      'pomodoroMinutes': pomodoroMinutes,
      'parentTaskId': parentTaskId,
      'isSubTask': isSubTask,
      'calendarEventId': calendarEventId,
      'priority': priority,
      'isArchived': isArchived,
    };
  }

  TaskPriority get priorityEnum => TaskPriority.values[priority.clamp(0, 2)];
}
