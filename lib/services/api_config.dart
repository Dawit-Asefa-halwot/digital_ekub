class ApiConfig {
  /// Centralized REST API Base URL
  /// Production Deployed Render API: https://digital-ekub-api.onrender.com/api/v1
  /// Local NestJS REST API: http://localhost:3000/api/v1
  static const String renderBaseUrl = 'https://digital-ekub-api.onrender.com/api/v1';
  static const String localBaseUrl = 'http://localhost:3000/api/v1';

  /// Toggle true to connect Flutter application to deployed Render backend
  /// Set false for local development backend (http://localhost:3000/api/v1)
  static bool useRenderApi = true;

  static String get baseUrl {
    if (useRenderApi) {
      return renderBaseUrl;
    }
    return localBaseUrl;
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
