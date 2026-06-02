class TaskModel {
  String id;
  String text;
  String? subject;
  String? type;
  DateTime dueDate;
  bool completed;
  int pomodoroMinutes;
  String? parentTaskId;
  bool isSubTask;
  String? calendarEventId; // Google Calendar event ID for two-way sync

  TaskModel({
    required this.id,
    required this.text,
    this.subject,
    this.type,
    required this.dueDate,
    this.completed = false,
    this.pomodoroMinutes = 0,
    this.parentTaskId,
    this.isSubTask = false,
    this.calendarEventId,
  });

  factory TaskModel.fromMap(String id, Map<String, dynamic> data) {
    return TaskModel(
      id: id,
      text: data['text'] ?? '',
      subject: data['subject'],
      type: data['type'],
      dueDate: DateTime.parse(data['dueDate']),
      completed: data['completed'] ?? false,
      pomodoroMinutes: data['pomodoroMinutes'] ?? 0,
      parentTaskId: data['parentTaskId'],
      isSubTask: data['isSubTask'] ?? false,
      calendarEventId: data['calendarEventId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'subject': subject,
      'type': type,
      'dueDate': dueDate.toIso8601String(),
      'completed': completed,
      'pomodoroMinutes': pomodoroMinutes,
      'parentTaskId': parentTaskId,
      'isSubTask': isSubTask,
      'calendarEventId': calendarEventId,
    };
  }
}
