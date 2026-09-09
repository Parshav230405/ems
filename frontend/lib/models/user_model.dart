class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // SUPERADMIN, ADMIN, or STAFF
  final int clientId;
  final String clientName;
  final String clientSlug;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.clientId = 2,
    this.clientName = 'AURA EMS',
    this.clientSlug = '',
  });

  bool get isSuperAdmin => role == 'SUPERADMIN' || clientId == 1;
  bool get isAdmin => role == 'ADMIN';
  bool get isStaff => role == 'STAFF';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'STAFF',
      clientId: json['clientId'] is int
          ? json['clientId']
          : int.tryParse(json['clientId']?.toString() ?? '2') ?? 2,
      clientName: json['clientName'] ?? 'AURA EMS',
      clientSlug: json['clientSlug'] ?? '',
    );
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    int? clientId,
    String? clientName,
    String? clientSlug,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      clientSlug: clientSlug ?? this.clientSlug,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role,
    'clientId': clientId,
    'clientName': clientName,
    'clientSlug': clientSlug,
  };
}
