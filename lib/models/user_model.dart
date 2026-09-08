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

  bool get isAdmin => role == UserRole.admin;
  bool get isMember => role == UserRole.member;

  String get roleName => role == UserRole.admin ? 'Admin (Organizer)' : 'Member';
}
