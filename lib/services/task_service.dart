import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task.dart';

class TaskService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<TaskModel>> getTasks(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaskModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<String> addTask(String userId, TaskModel task) async {
    final docRef = await _db.collection('users').doc(userId).collection('tasks').add({
      ...task.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  Future<void> updateTask(String userId, String taskId, Map<String, dynamic> updates) async {
    final batch = _db.batch();
    final taskRef = _db.collection('users').doc(userId).collection('tasks').doc(taskId);
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
  }

  Future<void> deleteTask(String userId, String taskId) async {
    final batch = _db.batch();
    
    // Delete parent
    final taskRef = _db.collection('users').doc(userId).collection('tasks').doc(taskId);
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
  }
}
