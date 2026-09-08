import 'package:flutter/material.dart';
import '../models/ekub_model.dart';
import '../models/payment_method_enum.dart';
import '../services/payment_service.dart';
import '../services/auth_service.dart';

/// Simulated Local Payment Gateway Modal.
/// Supports Telebirr, CBE Birr, Bank Transfer, reference IDs, processing states, and failure testing.
class SimulatedPaymentModal extends StatefulWidget {
  final EkubModel ekub;

  const SimulatedPaymentModal({
    super.key,
    required this.ekub,
  });

  @override
  State<SimulatedPaymentModal> createState() => _SimulatedPaymentModalState();
}

class _SimulatedPaymentModalState extends State<SimulatedPaymentModal> {
  PaymentMethod _selectedMethod = PaymentMethod.telebirr;
  bool _simulateFailure = false;
  bool _isProcessing = false;
  PaymentResult? _paymentResult;

  void _executePayment() async {
    setState(() {
      _isProcessing = true;
      _paymentResult = null;
    });

    final currentUser = AuthService.instance.currentUser;
    final userId = currentUser?.id ?? 'user_101';

    final result = await PaymentService.instance.processSimulatedPayment(
      userId: userId,
      ekubId: widget.ekub.id,
      ekubName: widget.ekub.name,
      roundNumber: widget.ekub.currentRound,
      amount: widget.ekub.contributionAmount,
      method: _selectedMethod,
      simulateFailure: _simulateFailure,
    );

    if (mounted) {
      setState(() {
        _isProcessing = false;
        _paymentResult = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 1. PROCESSING STATE
    if (_isProcessing) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              'Processing ${_selectedMethod.displayName} Payment...',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Connecting to simulated local gateway ledger...',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }

    // 2. PAYMENT RESULT STATE (Success or Failure)
    if (_paymentResult != null) {
      final res = _paymentResult!;
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: res.isSuccess ? Colors.green.shade100 : Colors.red.shade100,
              child: Icon(
                res.isSuccess ? Icons.check_circle_rounded : Icons.cancel_rounded,
                size: 48,
                color: res.isSuccess ? Colors.green.shade800 : Colors.red.shade800,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              res.isSuccess ? 'Payment Successful!' : 'Payment Failed',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: res.isSuccess ? Colors.green.shade800 : Colors.red.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              res.message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Card(
              color: theme.colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    _buildRow('Reference ID', res.referenceId),
                    _buildRow('Transaction ID', res.transactionId),
                    _buildRow('Amount', '${widget.ekub.contributionAmount.toStringAsFixed(0)} ETB'),
                    _buildRow('Payment Provider', _selectedMethod.displayName),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(res.isSuccess ? 'Done' : 'Close'),
              ),
            ),
          ],
        ),
      );
    }

    // 3. INITIAL SELECTION FORM STATE
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Simulated Local Payment',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 8),

          // Ekub Summary Box
          Card(
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.ekub.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      Text(
                        'Round ${widget.ekub.currentRound} Contribution',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${widget.ekub.contributionAmount.toStringAsFixed(0)} ETB',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Payment Method Selector
          Text(
            'Select Simulated Payment Method:',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          RadioListTile<PaymentMethod>(
            value: PaymentMethod.telebirr,
            groupValue: _selectedMethod,
            secondary: const Icon(Icons.phone_android_rounded, color: Colors.blue),
            title: const Text('Telebirr Mobile Money'),
            subtitle: const Text('Ethio Telecom Instant Payment'),
            onChanged: (val) => setState(() => _selectedMethod = val!),
          ),
          RadioListTile<PaymentMethod>(
            value: PaymentMethod.cbeBirr,
            groupValue: _selectedMethod,
            secondary: const Icon(Icons.account_balance_rounded, color: Colors.purple),
            title: const Text('CBE Birr'),
            subtitle: const Text('Commercial Bank of Ethiopia'),
            onChanged: (val) => setState(() => _selectedMethod = val!),
          ),
          RadioListTile<PaymentMethod>(
            value: PaymentMethod.bankTransfer,
            groupValue: _selectedMethod,
            secondary: const Icon(Icons.account_balance_rounded, color: Colors.teal),
            title: const Text('Commercial Bank Direct Transfer'),
            subtitle: const Text('Account to Account Direct Wire'),
            onChanged: (val) => setState(() => _selectedMethod = val!),
          ),
          const SizedBox(height: 12),

          // Failure Testing Switch
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.bug_report_outlined, color: Colors.brown, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Simulate Payment Failure (Testing):',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.brown),
                  ),
                ),
                Switch(
                  value: _simulateFailure,
                  onChanged: (val) => setState(() => _simulateFailure = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Confirm Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.lock_outline),
              label: Text('Confirm ${widget.ekub.contributionAmount.toStringAsFixed(0)} ETB Payment'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _executePayment,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
