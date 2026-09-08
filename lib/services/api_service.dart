import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class ApiException implements Exception {
  final String message;
  final int statusCode;
  final dynamic details;

  ApiException(this.message, {this.statusCode = 500, this.details});

  @override
  String toString() => message;
}

class ApiService {
  /// Execute HTTP GET request
  static Future<dynamic> get(String endpoint) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    try {
      final response = await http.get(uri, headers: ApiConfig.headers);
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network connection error. Is NestJS running at ${ApiConfig.baseUrl}?');
    }
  }

  /// Execute HTTP POST request
  static Future<dynamic> post(String endpoint, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    try {
      final response = await http.post(
        uri,
        headers: ApiConfig.headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network connection error. Is NestJS running at ${ApiConfig.baseUrl}?');
    }
  }

  /// Execute HTTP PATCH request
  static Future<dynamic> patch(String endpoint, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    try {
      final response = await http.patch(
        uri,
        headers: ApiConfig.headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network connection error. Is NestJS running at ${ApiConfig.baseUrl}?');
    }
  }

  /// Handle HTTP Response status codes and decode JSON
  static dynamic _handleResponse(http.Response response) {
    dynamic body;
    try {
      if (response.body.isNotEmpty) {
        body = jsonDecode(response.body);
      }
    } catch (_) {
      body = response.body;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    String errorMessage = 'An error occurred (Status ${response.statusCode})';
    if (body is Map && body.containsKey('message')) {
      final msg = body['message'];
      if (msg is List) {
        errorMessage = msg.join(', ');
      } else {
        errorMessage = msg.toString();
      }
    }

    if (response.statusCode == 401) {
      ApiConfig.clearAuthToken();
      throw ApiException('Session expired. Please sign in again.', statusCode: 401, details: body);
    }

    throw ApiException(errorMessage, statusCode: response.statusCode, details: body);
  }
}
