import 'dart:math';
import '../models/payment_method_enum.dart';
import '../models/transaction_model.dart';
import '../services/ekub_state_service.dart';
import '../services/reminder_service.dart';

/// Payment Result container for simulated local payments.
class PaymentResult {
  final bool isSuccess;
  final String referenceId;
  final String transactionId;
  final String message;
  final TransactionModel? transaction;

  PaymentResult({
    required this.isSuccess,
    required this.referenceId,
    required this.transactionId,
    required this.message,
    this.transaction,
  });
}

/// Service simulating local payment gateways (Telebirr, CBE Birr, Bank Transfer).
class PaymentService {
  static final PaymentService instance = PaymentService._internal();
  PaymentService._internal();

  /// Simulates payment processing delay & executes transaction logic locally.
  Future<PaymentResult> processSimulatedPayment({
    required String userId,
    required String ekubId,
    required String ekubName,
    required int roundNumber,
    required double amount,
    required PaymentMethod method,
    bool simulateFailure = false,
  }) async {
    // Simulate gateway network processing time (1.2 seconds)
    await Future.delayed(const Duration(milliseconds: 1200));

    final randomSuffix = Random().nextInt(89999) + 10000;
    final referenceId = 'TXN-${method.shortCode}-$randomSuffix';
    final transactionId = 'TXN-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';

    if (simulateFailure) {
      // Record Failed Transaction
      final failedTxn = TransactionModel(
        id: transactionId,
        referenceId: referenceId,
        userId: userId,
        ekubId: ekubId,
        ekubName: ekubName,
        type: 'Contribution Deposit (Failed)',
        paymentMethod: method,
        amount: -amount,
        date: DateTime.now(),
        status: 'failed',
        description: 'Simulated payment processing failure via ${method.displayName}. Reference: $referenceId',
      );

      EkubStateService.instance.addTransaction(failedTxn);

      return PaymentResult(
        isSuccess: false,
        referenceId: referenceId,
        transactionId: transactionId,
        message: 'Payment simulation failed! Gateway rejected transaction ref $referenceId.',
        transaction: failedTxn,
      );
    }

    // Execute Successful Payment Logic
    final successTxn = TransactionModel(
      id: transactionId,
      referenceId: referenceId,
      userId: userId,
      ekubId: ekubId,
      ekubName: ekubName,
      type: 'Contribution Deposit',
      paymentMethod: method,
      amount: -amount,
      date: DateTime.now(),
      status: 'successful',
      description: 'Successful contribution deposit via ${method.displayName}. Reference: $referenceId',
    );

    // Update Ekub State & Contribution History
    EkubStateService.instance.recordContributionWithTxn(
      ekubId: ekubId,
      amount: amount,
      transaction: successTxn,
    );

    // Resolve Reminder in ReminderService
    ReminderService.instance.markReminderPaid(ekubId, roundNumber);

    return PaymentResult(
      isSuccess: true,
      referenceId: referenceId,
      transactionId: transactionId,
      message: 'Payment of ${amount.toStringAsFixed(0)} ETB successfully processed via ${method.displayName}!',
      transaction: successTxn,
    );
  }
}
