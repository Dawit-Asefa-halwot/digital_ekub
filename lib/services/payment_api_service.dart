import 'api_service.dart';

class PaymentApiService {
  /// Process simulated payment for a pending contribution
  static Future<Map<String, dynamic>> processPayment({
    required String contributionId,
    required String paymentMethod,
    String simulateOutcome = 'SUCCESS',
  }) async {
    final data = await ApiService.post('/payments', body: {
      'contributionId': contributionId,
      'paymentMethod': paymentMethod,
      'simulateOutcome': simulateOutcome,
    });
    return data as Map<String, dynamic>;
  }

  /// Get current user's transaction/payment history
  static Future<List<Map<String, dynamic>>> getUserTransactions() async {
    final data = await ApiService.get('/payments/me');
    if (data is List) {
      return List<Map<String, dynamic>>.from(data);
    }
    return [];
  }

  /// Get single transaction details by ID
  static Future<Map<String, dynamic>> getTransactionDetails(String transactionId) async {
    final data = await ApiService.get('/transactions/$transactionId');
    return data as Map<String, dynamic>;
  }

  /// Get supported demo payment methods
  static Future<List<Map<String, dynamic>>> getPaymentMethods() async {
    final data = await ApiService.get('/payments/methods');
    if (data is List) {
      return List<Map<String, dynamic>>.from(data);
    }
    return [];
  }
}
