import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'auth_api_service.dart';
import 'api_service.dart';

/// Central Authentication Service connecting Flutter UI to NestJS REST API & PostgreSQL 18
class AuthService extends ChangeNotifier {
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Sign Up new user via NestJS REST API (`POST /auth/register`)
  Future<String?> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await AuthApiService.signUp(
        fullName: name,
        email: email,
        phone: phone,
        password: password,
      );

      _currentUser = res['user'] as UserModel;
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return null; // Success
    } on ApiException catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.message;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'Registration failed: ${e.toString()}';
    }
  }

  /// Sign In user via NestJS REST API (`POST /auth/login`)
  Future<String?> signIn({
    required String emailOrPhone,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await AuthApiService.signIn(
        emailOrPhone: emailOrPhone,
        password: password,
      );

      _currentUser = res['user'] as UserModel;
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return null; // Success
    } on ApiException catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.message;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'Authentication failed: ${e.toString()}';
    }
  }

  /// Refresh current authenticated user profile (`GET /auth/me`)
  Future<void> refreshProfile() async {
    try {
      final user = await AuthApiService.getCurrentUser();
      _currentUser = user;
      _isAuthenticated = true;
      notifyListeners();
    } catch (_) {}
  }

  /// Sign Out user session & clear JWT token
  void signOut() {
    AuthApiService.signOut();
    _isAuthenticated = false;
    _currentUser = null;
    notifyListeners();
  }

  /// Switch role (for demo testing switch between Member and Admin view)
  void switchRole(UserRole newRole) {
    if (_currentUser != null) {
      _currentUser!.role = newRole;
      notifyListeners();
    }
  }

  /// Toggle notifications
  void toggleNotifications(bool enabled) {
    if (_currentUser != null) {
      _currentUser!.notificationsEnabled = enabled;
      notifyListeners();
    }
  }
}
