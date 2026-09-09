class ClientModel {
  final int id;
  final String name;
  final String slug;
  final String status; // 'active', 'suspended', 'deleted'
  final String adminEmail;
  final String createdAt;
  final int totalStudents;
  final int totalTeachers;
  final int totalClasses;
  final int totalUsers;

  ClientModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.status,
    required this.adminEmail,
    required this.createdAt,
    this.totalStudents = 0,
    this.totalTeachers = 0,
    this.totalClasses = 0,
    this.totalUsers = 0,
  });

  bool get isActive => status == 'active';
  bool get isSuspended => status == 'suspended';
  bool get isDeleted => status == 'deleted';

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    final counts = json['_count'] as Map<String, dynamic>? ?? {};
    return ClientModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      status: json['status'] ?? 'active',
      adminEmail: json['adminEmail'] ?? '',
      createdAt: json['createdAt']?.toString().split('T').first ?? '',
      totalStudents: counts['students'] ?? 0,
      totalTeachers: counts['teachers'] ?? 0,
      totalClasses: counts['classes'] ?? 0,
      totalUsers: counts['users'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slug': slug,
    'status': status,
    'adminEmail': adminEmail,
    'createdAt': createdAt,
  };
}
