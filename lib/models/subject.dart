class SubjectModel {
  String id;
  String name;
  String grade;
  double gradeValue;
  double credits;
  String semesterId;

  SubjectModel({
    required this.id,
    required this.name,
    required this.grade,
    required this.gradeValue,
    required this.credits,
    required this.semesterId,
  });

  factory SubjectModel.fromMap(String id, Map<String, dynamic> data) {
    return SubjectModel(
      id: id,
      name: data['name'] ?? '',
      grade: data['grade'] ?? '',
      gradeValue: (data['gradeValue'] ?? 0.0).toDouble(),
      credits: (data['credits'] ?? 0.0).toDouble(),
      semesterId: data['semesterId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'grade': grade,
      'gradeValue': gradeValue,
      'credits': credits,
      'semesterId': semesterId,
    };
  }
}
