/// Schedule entry model for Ekub lottery draws.
class ScheduleEntryModel {
  final int roundNumber;
  final DateTime date;
  final String recipientName;
  final String status; // 'Completed', 'Current', 'Scheduled'

  ScheduleEntryModel({
    required this.roundNumber,
    required this.date,
    required this.recipientName,
    required this.status,
  });
}
