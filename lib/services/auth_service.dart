import 'package:flutter/material.dart';
import '../models/user_model.dart';

/// Central Authentication and Authorization Service for Digital Ekub prototype.
/// Manages session authentication state, user registration, local credentials, and user roles.
class AuthService extends ChangeNotifier {
  static final AuthService instance = AuthService._internal();
  AuthService._internal() {
    // Seed default demo credentials for local prototype testing
    _registerMockUser(
      email: 'dawit@ekub.et',
      phone: '0911234567',
      password: 'password123',
      user: UserModel(
        id: 'usr_admin_01',
        name: 'Dawit Asefa',
        phone: '+251 91 123 4567',
        email: 'dawit@ekub.et',
        role: UserRole.admin,
      ),
    );

    _registerMockUser(
      email: 'abebe@ekub.et',
      phone: '0922345678',
      password: 'password123',
      user: UserModel(
        id: 'usr_member_02',
        name: 'Abebe Tadesse',
        phone: '+251 92 234 5678',
        email: 'abebe@ekub.et',
        role: UserRole.member,
      ),
    );
  }

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  // Local mock credentials database: key -> {password, user}
  final Map<String, Map<String, dynamic>> _userStore = {};

  void _registerMockUser({
    required String email,
    required String phone,
    required String password,
    required UserModel user,
  }) {
    final entry = {'password': password, 'user': user};
    _userStore[email.toLowerCase().trim()] = entry;
    _userStore[phone.trim()] = entry;
  }

  /// Sign Up new user locally
  String? signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
  }) {
    final cleanEmail = email.toLowerCase().trim();
    final cleanPhone = phone.trim();

    // Check existing registration
    if (_userStore.containsKey(cleanEmail)) {
      return 'An account with this email address already exists.';
    }
    if (_userStore.containsKey(cleanPhone)) {
      return 'An account with this phone number already exists.';
    }

    final newUser = UserModel(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      phone: cleanPhone,
      email: cleanEmail,
      role: role,
    );

    _registerMockUser(
      email: cleanEmail,
      phone: cleanPhone,
      password: password,
      user: newUser,
    );

    _currentUser = newUser;
    _isAuthenticated = true;

    notifyListeners();
    return null; // Success
  }

  /// Sign In user locally
  String? signIn({
    required String emailOrPhone,
    required String password,
  }) {
    final key = emailOrPhone.toLowerCase().trim();

    if (!_userStore.containsKey(key)) {
      return 'No account found with this email or phone number.';
    }

    final record = _userStore[key]!;
    final storedPassword = record['password'] as String;

    if (storedPassword != password) {
      return 'Incorrect password. Please try again.';
    }

    _currentUser = record['user'] as UserModel;
    _isAuthenticated = true;

    notifyListeners();
    return null; // Success
  }

  /// Log Out user session
  void signOut() {
    _isAuthenticated = false;
    _currentUser = null;
    notifyListeners();
  }

  /// Switch user role (Helper to easily test Admin vs Member authorization)
  void switchRole(UserRole newRole) {
    if (_currentUser != null) {
      _currentUser!.role = newRole;
      notifyListeners();
    }
  }

  /// Toggle notifications for current user
  void toggleNotifications(bool enabled) {
    if (_currentUser != null) {
      _currentUser!.notificationsEnabled = enabled;
      notifyListeners();
    }
  }
}
