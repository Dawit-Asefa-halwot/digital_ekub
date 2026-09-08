import 'payment_method_enum.dart';

/// Transaction model representing ETB financial activities.
class TransactionModel {
  final String id;
  final String referenceId;
  final String userId;
  final String ekubId;
  final String ekubName;
  final String type; // 'Contribution Deposit', 'Pot Payout Received', 'Ekub Creation Fee'
  final PaymentMethod paymentMethod;
  final double amount;
  final DateTime date;
  final String status; // 'successful', 'pending', 'failed'
  final String description;

  TransactionModel({
    required this.id,
    required this.referenceId,
    required this.userId,
    required this.ekubId,
    required this.ekubName,
    required this.type,
    this.paymentMethod = PaymentMethod.telebirr,
    required this.amount,
    required this.date,
    this.status = 'successful',
    required this.description,
  });
}
