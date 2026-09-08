import '../models/user_model.dart';
import 'api_config.dart';
import 'api_service.dart';

class AuthApiService {
  /// Register a new user
  static Future<Map<String, dynamic>> signUp({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    final data = await ApiService.post('/auth/register', body: {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'password': password,
    });

    final token = data['accessToken'] as String?;
    if (token != null) {
      ApiConfig.setAuthToken(token);
    }

    final userJson = data['user'] as Map<String, dynamic>;
    return {
      'user': UserModel.fromJson(userJson),
      'accessToken': token,
    };
  }

  /// Authenticate user with Email/Phone + Password
  static Future<Map<String, dynamic>> signIn({
    required String emailOrPhone,
    required String password,
  }) async {
    final data = await ApiService.post('/auth/login', body: {
      'emailOrPhone': emailOrPhone,
      'password': password,
    });

    final token = data['accessToken'] as String?;
    if (token != null) {
      ApiConfig.setAuthToken(token);
    }

    final userJson = data['user'] as Map<String, dynamic>;
    return {
      'user': UserModel.fromJson(userJson),
      'accessToken': token,
    };
  }

  /// Get current authenticated user details
  static Future<UserModel> getCurrentUser() async {
    final data = await ApiService.get('/auth/me');
    return UserModel.fromJson(data as Map<String, dynamic>);
  }

  /// Sign out current user session
  static void signOut() {
    ApiConfig.clearAuthToken();
  }
}
