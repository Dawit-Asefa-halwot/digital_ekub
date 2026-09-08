import 'package:flutter/material.dart';
import '../models/reminder_model.dart';

/// Payment Reminder Service managing local in-app notification alerts for unpaid contributions.
class ReminderService extends ChangeNotifier {
  static final ReminderService instance = ReminderService._internal();
  ReminderService._internal() {
    _initDefaultReminders();
  }

  final List<ReminderModel> _reminders = [];

  void _initDefaultReminders() {
    _reminders.addAll([
      ReminderModel(
        id: 'rem_01',
        userId: 'user_101',
        ekubId: 'ekub_01',
        ekubName: 'Family & Friends Ekub',
        roundNumber: 4,
        amount: 5000,
        dueDate: DateTime.now().add(const Duration(days: 2)),
        status: 'due',
      ),
      ReminderModel(
        id: 'rem_02',
        userId: 'user_101',
        ekubId: 'ekub_02',
        ekubName: 'Bole Tech Entrepreneurs',
        roundNumber: 8,
        amount: 10000,
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
        status: 'overdue',
      ),
      ReminderModel(
        id: 'rem_03',
        userId: 'user_101',
        ekubId: 'ekub_01',
        ekubName: 'Family & Friends Ekub',
        roundNumber: 3,
        amount: 5000,
        dueDate: DateTime.now().subtract(const Duration(days: 7)),
        status: 'paid',
      ),
    ]);
  }

  /// Returns active reminders for specified user
  List<ReminderModel> getRemindersForUser(String userId) {
    return List.unmodifiable(_reminders.where((r) => r.userId == userId).toList());
  }

  /// Unpaid reminders count getter
  int getUnpaidCount(String userId) {
    return _reminders.where((r) => r.userId == userId && r.status != 'paid').length;
  }

  /// Resolves reminder when payment is completed
  void markReminderPaid(String ekubId, int roundNumber) {
    for (var r in _reminders) {
      if (r.ekubId == ekubId && r.roundNumber == roundNumber && r.status != 'paid') {
        r.status = 'paid';
      }
    }
    notifyListeners();
  }
}
