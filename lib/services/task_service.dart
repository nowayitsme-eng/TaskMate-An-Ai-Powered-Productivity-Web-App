import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task.dart';
import 'calendar_service.dart';

class TaskService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final CalendarService _calendarService = CalendarService();

  Stream<List<TaskModel>> getTasks(String providedUserId) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? providedUserId;
    return _db
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaskModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<String> addTask(String providedUserId, TaskModel task) async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? providedUserId;

    // Sync to Google Calendar if connected
    if (_calendarService.isConnected && !task.isSubTask) {
      final eventId = await _calendarService.createCalendarEvent(task);
      if (eventId != null) {
        task.calendarEventId = eventId;
      }
    }

    final docRef = await _db
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .add({
      ...task.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  Future<void> updateTask(
      String providedUserId, String taskId, Map<String, dynamic> updates) async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? providedUserId;
    final batch = _db.batch();
    final taskRef = _db
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .doc(taskId);
    batch.update(taskRef, updates);

    // Cascade completion to sub-tasks if marking as completed
    if (updates['completed'] == true) {
      final subtasksSnapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .where('parentTaskId', isEqualTo: taskId)
          .get();

      for (var doc in subtasksSnapshot.docs) {
        batch.update(doc.reference, {'completed': true});
      }
    }

    await batch.commit();

    // Sync to Google Calendar if connected
    if (_calendarService.isConnected) {
      final doc = await taskRef.get();
      if (doc.exists) {
        final task = TaskModel.fromMap(doc.id, doc.data()!);
        await _calendarService.updateCalendarEvent(task);
      }
    }
  }

  Future<void> deleteTask(String providedUserId, String taskId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? providedUserId;

    // Fetch the task first to get calendarEventId before deletion
    final taskDoc = await _db
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .doc(taskId)
        .get();

    String? calendarEventId;
    if (taskDoc.exists) {
      final data = taskDoc.data()!;
      calendarEventId = data['calendarEventId'] as String?;
    }

    final batch = _db.batch();

    // Delete parent
    final taskRef = _db
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .doc(taskId);
    batch.delete(taskRef);

    // Find and delete sub-tasks
    final subtasksSnapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .where('parentTaskId', isEqualTo: taskId)
        .get();

    for (var doc in subtasksSnapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();

    // Delete corresponding calendar event if connected
    if (_calendarService.isConnected && calendarEventId != null) {
      await _calendarService.deleteCalendarEvent(calendarEventId);
    }
  }
}
