import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subject.dart';

class GpaService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<SubjectModel>> getSubjects(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return [];
      final data = doc.data() as Map<String, dynamic>;
      final map = data['subjectsMap'] as Map<String, dynamic>? ?? {};
      return map.entries
          .map((e) => SubjectModel.fromMap(e.key, Map<String, dynamic>.from(e.value as Map)))
          .toList();
    });
  }

  Future<void> addSubject(String userId, SubjectModel subject) {
    final docId = DateTime.now().millisecondsSinceEpoch.toString();
    subject.id = docId;
    return _db.collection('users').doc(userId).set({
      'subjectsMap': {
        docId: {
          ...subject.toMap(),
          'createdAt': FieldValue.serverTimestamp(),
        }
      }
    }, SetOptions(merge: true));
  }

  Future<void> deleteSubject(String userId, String subjectId) {
    return _db.collection('users').doc(userId).update({
      'subjectsMap.$subjectId': FieldValue.delete(),
    });
  }
}
