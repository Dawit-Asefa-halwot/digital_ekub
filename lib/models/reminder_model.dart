/// Payment Reminder model for Digital Ekub.
class ReminderModel {
  final String id;
  final String userId;
  final String ekubId;
  final String ekubName;
  final int roundNumber;
  final double amount;
  final DateTime dueDate;
  String status; // 'upcoming', 'due', 'overdue', 'paid'

  ReminderModel({
    required this.id,
    required this.userId,
    required this.ekubId,
    required this.ekubName,
    required this.roundNumber,
    required this.amount,
    required this.dueDate,
    this.status = 'due',
  });
}
