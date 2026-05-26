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

  Future<void> updateTask(String userId, String taskId, Map<String, dynamic> updates) {
    return _db.collection('users').doc(userId).collection('tasks').doc(taskId).update(updates);
  }

  Future<void> deleteTask(String userId, String taskId) {
    return _db.collection('users').doc(userId).collection('tasks').doc(taskId).delete();
  }
}
