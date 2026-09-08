/// Contribution record model.
class ContributionModel {
  final String id;
  final String ekubId;
  final String ekubName;
  final int roundNumber;
  final double amount;
  final DateTime date;
  final String status; // 'Paid' or 'Pending'
  final String transactionId;

  ContributionModel({
    required this.id,
    required this.ekubId,
    required this.ekubName,
    required this.roundNumber,
    required this.amount,
    required this.date,
    this.status = 'Paid',
    required this.transactionId,
  });
}
