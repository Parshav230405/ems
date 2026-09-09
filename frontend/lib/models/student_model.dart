class StudentModel {
  final String id;
  final String admissionNumber;
  final String name;
  final String dob;
  final String gender;
  final String classId;
  final String? className;
  final String? division;
  final String parentName;
  final String parentContact;
  final String? parentEmail;
  final String admissionDate;
  final String status;

  StudentModel({
    required this.id,
    required this.admissionNumber,
    required this.name,
    required this.dob,
    required this.gender,
    required this.classId,
    this.className,
    this.division,
    required this.parentName,
    required this.parentContact,
    this.parentEmail,
    required this.admissionDate,
    required this.status,
  });

  String get classDivision =>
      (className != null && division != null) ? '$className-$division' : '';

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    String? cName;
    String? cDiv;
    if (json['class'] is Map) {
      cName = json['class']['name'];
      cDiv = json['class']['division'];
    }

    return StudentModel(
      id: json['id'] ?? '',
      admissionNumber: json['admissionNumber'] ?? '',
      name: json['name'] ?? '',
      dob: json['dob'] ?? '',
      gender: json['gender'] ?? 'Other',
      classId: json['classId'] ?? '',
      className: cName,
      division: cDiv,
      parentName: json['parentName'] ?? '',
      parentContact: json['parentContact'] ?? '',
      parentEmail: json['parentEmail'],
      admissionDate: json['admissionDate'] ?? '',
      status: json['status'] ?? 'ACTIVE',
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'admissionNumber': admissionNumber,
    'dob': dob,
    'gender': gender,
    'classId': classId,
    'parentName': parentName,
    'parentContact': parentContact,
    'parentEmail': parentEmail,
    'status': status,
  };
}
