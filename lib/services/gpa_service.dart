import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/subject.dart';
import '../models/semester.dart';

class GpaData {
  final List<SemesterModel> semesters;
  final List<SubjectModel> subjects;

  GpaData(this.semesters, this.subjects);
}

class GpaService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<GpaData> getGpaData(String providedUserId) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? providedUserId;
    return _db.collection('users').doc(userId).snapshots().map((doc) {
      if (!doc.exists) return GpaData([], []);
      final data = doc.data() as Map<String, dynamic>;
      
      final subjectsMap = data['subjectsMap'] as Map<String, dynamic>? ?? {};
      final subjects = subjectsMap.entries
          .map(
            (e) => SubjectModel.fromMap(
              e.key,
              Map<String, dynamic>.from(e.value as Map),
            ),
          )
          .toList();

      final semestersList = data['semestersList'] as List<dynamic>? ?? [];
      final semesters = semestersList.map((e) {
        final map = Map<String, dynamic>.from(e as Map);
        return SemesterModel.fromMap(map['id'] as String? ?? '', map);
      }).toList();

      return GpaData(semesters, subjects);
    });
  }

  Future<void> addSemester(String providedUserId, String name) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? providedUserId;
    final docId = DateTime.now().millisecondsSinceEpoch.toString();
    final newSemester = {
      'id': docId,
      'name': name,
      'createdAt': Timestamp.now(),
    };
    return _db.collection('users').doc(userId).set({
      'semestersList': FieldValue.arrayUnion([newSemester]),
    }, SetOptions(merge: true));
  }

  Future<void> deleteSemester(String providedUserId, SemesterModel semester) async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? providedUserId;
    
    // First remove it from the list
    await _db.collection('users').doc(userId).update({
      'semestersList': FieldValue.arrayRemove([
        {
          'id': semester.id,
          'name': semester.name,
          'createdAt': semester.createdAt != null ? Timestamp.fromDate(semester.createdAt!) : null,
        }
      ])
    });

    // Then we ideally should delete all subjects that have this semesterId.
    // For simplicity, we can fetch the user doc, find subjects with this semesterId, and delete them.
    final doc = await _db.collection('users').doc(userId).get();
    if (doc.exists) {
      final data = doc.data()!;
      final subjectsMap = data['subjectsMap'] as Map<String, dynamic>? ?? {};
      final updates = <String, dynamic>{};
      
      subjectsMap.forEach((key, value) {
        final subMap = value as Map<String, dynamic>;
        if (subMap['semesterId'] == semester.id) {
          updates['subjectsMap.$key'] = FieldValue.delete();
        }
      });

      if (updates.isNotEmpty) {
        await _db.collection('users').doc(userId).update(updates);
      }
    }
  }

  Future<void> addSubject(String providedUserId, SubjectModel subject) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? providedUserId;
    final docId = DateTime.now().millisecondsSinceEpoch.toString();
    subject.id = docId;
    return _db.collection('users').doc(userId).set({
      'subjectsMap': {
        docId: {...subject.toMap(), 'createdAt': FieldValue.serverTimestamp()},
      },
    }, SetOptions(merge: true));
  }

  Future<void> deleteSubject(String providedUserId, String subjectId) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? providedUserId;
    return _db.collection('users').doc(userId).update({
      'subjectsMap.$subjectId': FieldValue.delete(),
    });
  }

  Future<void> updateSubject(String providedUserId, SubjectModel subject) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? providedUserId;
    return _db.collection('users').doc(userId).update({
      'subjectsMap.${subject.id}': subject.toMap(),
    });
  }
}
