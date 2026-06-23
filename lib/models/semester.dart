class SemesterModel {
  String id;
  String name;
  DateTime? createdAt;

  SemesterModel({
    required this.id,
    required this.name,
    this.createdAt,
  });

  factory SemesterModel.fromMap(String id, Map<String, dynamic> data) {
    return SemesterModel(
      id: id,
      name: data['name'] ?? '',
      createdAt: data['createdAt']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      // Note: createdAt is typically set via FieldValue.serverTimestamp() in Firestore
    };
  }
}
