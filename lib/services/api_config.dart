import 'package:flutter/foundation.dart';

class ApiConfig {
  /// Centralized REST API Base URL
  /// For Local Web / Windows Desktop: http://localhost:3000/api/v1
  /// For Android Emulator: http://10.0.2.2:3000/api/v1
  static const String webBaseUrl = 'http://localhost:3000/api/v1';
  static const String androidBaseUrl = 'http://10.0.2.2:3000/api/v1';

  static String get baseUrl {
    if (kIsWeb) return webBaseUrl;
    return webBaseUrl; // Default to localhost for desktop/web
  }

  /// In-memory storage for current session JWT token
  static String? _authToken;

  static String? get authToken => _authToken;

  static void setAuthToken(String? token) {
    _authToken = token;
  }

  static void clearAuthToken() {
    _authToken = null;
  }

  static bool get isAuthenticated => _authToken != null && _authToken!.isNotEmpty;

  /// Default HTTP Headers
  static Map<String, String> get headers {
    final map = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null && _authToken!.isNotEmpty) {
      map['Authorization'] = 'Bearer $_authToken';
    }
    return map;
  }
}
