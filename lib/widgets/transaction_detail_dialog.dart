import 'package:flutter/material.dart';
import '../models/transaction_model.dart';

/// Modal bottom sheet displaying detailed breakdown of a selected transaction.
class TransactionDetailDialog extends StatelessWidget {
  final TransactionModel transaction;

  const TransactionDetailDialog({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPayout = transaction.amount > 0;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Transaction Details',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  transaction.status,
                  style: TextStyle(
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: isPayout ? Colors.green.shade100 : theme.colorScheme.surfaceContainerHighest,
                  child: Icon(
                    isPayout ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                    size: 32,
                    color: isPayout ? Colors.green.shade800 : Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${isPayout ? "+" : ""}${transaction.amount.toStringAsFixed(0)} ETB',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isPayout ? Colors.green.shade800 : theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  transaction.type,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          _buildDetailRow('Transaction ID', transaction.id),
          _buildDetailRow('Ekub Name', transaction.ekubName),
          _buildDetailRow(
            'Date & Time',
            '${transaction.date.day}/${transaction.date.month}/${transaction.date.year} at ${transaction.date.hour.toString().padLeft(2, "0")}:${transaction.date.minute.toString().padLeft(2, "0")}',
          ),
          _buildDetailRow('Description', transaction.description),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Local Prototype Ledger: Transaction generated and recorded in client memory state.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
