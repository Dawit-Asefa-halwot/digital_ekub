import 'api_service.dart';

class NotificationApiService {
  /// Get current user's in-app notifications
  static Future<List<Map<String, dynamic>>> getUserNotifications() async {
    final data = await ApiService.get('/notifications/me');
    if (data is List) {
      return List<Map<String, dynamic>>.from(data);
    }
    return [];
  }

  /// Mark single notification as read
  static Future<Map<String, dynamic>> markAsRead(String notificationId) async {
    final data = await ApiService.patch('/notifications/$notificationId/read');
    return data as Map<String, dynamic>;
  }

  /// Mark all notifications as read
  static Future<Map<String, dynamic>> markAllAsRead() async {
    final data = await ApiService.patch('/notifications/read-all');
    return data as Map<String, dynamic>;
  }
}
