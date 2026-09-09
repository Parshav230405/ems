class ClassModel {
  final String id;
  final String name;
  final String division;
  final String academicYear;
  final int studentCount;
  final int subjectCount;

  ClassModel({
    required this.id,
    required this.name,
    required this.division,
    required this.academicYear,
    this.studentCount = 0,
    this.subjectCount = 0,
  });

  String get displayName => '$name-$division ($academicYear)';

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    int sCount = 0;
    int subCount = 0;
    if (json['_count'] is Map) {
      sCount = json['_count']['students'] ?? 0;
      subCount = json['_count']['subjects'] ?? 0;
    }

    return ClassModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      division: json['division'] ?? '',
      academicYear: json['academicYear'] ?? '',
      studentCount: sCount,
      subjectCount: subCount,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'division': division,
    'academicYear': academicYear,
  };
}

class SubjectModel {
  final String id;
  final String name;
  final String? code;
  final String classId;
  final String? teacherId;
  final String? className;
  final String? teacherName;

  SubjectModel({
    required this.id,
    required this.name,
    this.code,
    required this.classId,
    this.teacherId,
    this.className,
    this.teacherName,
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    String? cName;
    if (json['class'] is Map) {
      cName = '${json['class']['name']}-${json['class']['division']}';
    }
    String? tName;
    if (json['teacher'] is Map) {
      tName = json['teacher']['name'];
    }

    return SubjectModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'],
      classId: json['classId'] ?? '',
      teacherId: json['teacherId'],
      className: cName,
      teacherName: tName,
    );
  }
}

class TeacherModel {
  final String id;
  final String name;
  final String email;
  final String contact;
  final String qualification;
  final String status;
  final List<SubjectModel> subjects;

  TeacherModel({
    required this.id,
    required this.name,
    required this.email,
    required this.contact,
    required this.qualification,
    required this.status,
    this.subjects = const [],
  });

  factory TeacherModel.fromJson(Map<String, dynamic> json) {
    List<SubjectModel> subs = [];
    if (json['subjects'] is List) {
      subs = (json['subjects'] as List).map((s) => SubjectModel.fromJson(s)).toList();
    }

    return TeacherModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      contact: json['contact'] ?? '',
      qualification: json['qualification'] ?? 'B.Ed',
      status: json['status'] ?? 'Active',
      subjects: subs,
    );
  }
}
