import 'package:flutter/material.dart';
import '../services/ekub_state_service.dart';
import '../widgets/transaction_detail_dialog.dart';
import '../widgets/empty_state_widget.dart';

/// Interactive Transaction History Screen.
class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: EkubStateService.instance,
      builder: (context, child) {
        final txns = EkubStateService.instance.transactions;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Transaction History'),
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline),
                tooltip: 'Transaction Info',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('ℹ️ Showing real-time local ledger transactions in Ethiopian Birr (ETB).'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
          body: txns.isNotEmpty
              ? ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: txns.length,
                  itemBuilder: (context, index) {
                    final txn = txns[index];
                    final isPayout = txn.amount > 0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isPayout
                              ? Colors.green.shade100
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: Icon(
                            isPayout ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                            color: isPayout ? Colors.green.shade800 : Colors.grey.shade800,
                          ),
                        ),
                        title: Text(
                          txn.type,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('${txn.ekubName} • ${txn.date.day}/${txn.date.month}/${txn.date.year}\nID: ${txn.id}'),
                        isThreeLine: true,
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${isPayout ? "+" : ""}${txn.amount.toStringAsFixed(0)} ETB',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: isPayout ? Colors.green.shade700 : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                txn.status,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.green.shade800,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (context) => TransactionDetailDialog(transaction: txn),
                          );
                        },
                      ),
                    );
                  },
                )
              : const EmptyStateWidget(
                  icon: Icons.receipt_long_outlined,
                  title: 'No Transactions Found',
                  description: 'Your financial transaction records will appear here as you join Ekubs or make contribution deposits.',
                ),
        );
      },
    );
  }
}
