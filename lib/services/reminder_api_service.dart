import 'api_service.dart';

class ReminderApiService {
  /// Get current authenticated user's contribution reminders
  static Future<List<Map<String, dynamic>>> getUserReminders() async {
    final data = await ApiService.get('/reminders/me');
    if (data is List) {
      return List<Map<String, dynamic>>.from(data);
    }
    return [];
  }
}
