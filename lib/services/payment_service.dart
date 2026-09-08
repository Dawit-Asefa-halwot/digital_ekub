import 'dart:math';
import '../models/payment_method_enum.dart';
import '../models/transaction_model.dart';
import '../services/ekub_state_service.dart';
import '../services/reminder_service.dart';

/// Payment Result container for simulated payments.
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

/// Service connecting Flutter payment UI to NestJS REST API Payment System
class PaymentService {
  static final PaymentService instance = PaymentService._internal();
  PaymentService._internal();

  /// Process payment via NestJS REST API (`POST /ekubs/:id/contributions` & `POST /payments`)
  Future<PaymentResult> processSimulatedPayment({
    required String userId,
    required String ekubId,
    required String ekubName,
    required int roundNumber,
    required double amount,
    required PaymentMethod method,
    bool simulateFailure = false,
  }) async {
    try {
      final success = await EkubStateService.instance.processContributionAndPayment(
        ekubId: ekubId,
        amount: amount,
        paymentMethodStr: method.displayName,
      );

      if (success) {
        ReminderService.instance.markReminderPaid(ekubId, roundNumber);
        return PaymentResult(
          isSuccess: true,
          referenceId: 'TXN-${method.shortCode}-${Random().nextInt(89999) + 10000}',
          transactionId: 'TXN-${DateTime.now().millisecondsSinceEpoch}',
          message: 'Payment of ${amount.toStringAsFixed(0)} ETB successfully processed via ${method.displayName}!',
        );
      } else {
        return PaymentResult(
          isSuccess: false,
          referenceId: 'TXN-${method.shortCode}-FAILED',
          transactionId: 'TXN-FAILED',
          message: EkubStateService.instance.errorMessage ?? 'Payment simulation failed!',
        );
      }
    } catch (e) {
      return PaymentResult(
        isSuccess: false,
        referenceId: 'TXN-ERR',
        transactionId: 'TXN-ERR',
        message: 'Payment error: ${e.toString()}',
      );
    }
  }
}
