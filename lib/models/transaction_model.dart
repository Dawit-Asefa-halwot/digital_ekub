/// Transaction model representing ETB financial activities.
class TransactionModel {
  final String id;
  final String ekubId;
  final String ekubName;
  final String type; // 'Contribution Deposit', 'Pot Payout Received', 'Ekub Creation Fee'
  final double amount;
  final DateTime date;
  final String status; // 'Successful', 'Pending', 'Failed'
  final String description;

  TransactionModel({
    required this.id,
    required this.ekubId,
    required this.ekubName,
    required this.type,
    required this.amount,
    required this.date,
    this.status = 'Successful',
    required this.description,
  });
}
