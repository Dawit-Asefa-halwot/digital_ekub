/// Role authorization types for Digital Ekub.
enum UserRole {
  member,
  admin,
}

/// User profile model for Digital Ekub.
class UserModel {
  final String id;
  final String name;
  final String phone;
  final String email;
  UserRole role;
  final bool isVerified;
  bool notificationsEnabled;

  UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    this.role = UserRole.member,
    this.isVerified = true,
    this.notificationsEnabled = true,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final roleStr = json['role']?.toString().toUpperCase() ?? 'MEMBER';
    return UserModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: roleStr == 'ADMIN' ? UserRole.admin : UserRole.member,
      isVerified: json['isVerified'] as bool? ?? true,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
    );
  }

  bool get isAdmin => role == UserRole.admin;
  bool get isMember => role == UserRole.member;

  String get roleName => role == UserRole.admin ? 'Admin (Organizer)' : 'Member';
}
