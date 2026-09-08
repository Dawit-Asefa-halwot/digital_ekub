import 'package:flutter/material.dart';
import '../models/ekub_model.dart';
import '../services/ekub_state_service.dart';
import '../services/auth_service.dart';
import 'simulated_payment_modal.dart';

/// Interactive Contribution Dialog with Duplicate Payment Prevention.
class ContributeDialog extends StatefulWidget {
  const ContributeDialog({super.key});

  @override
  State<ContributeDialog> createState() => _ContributeDialogState();
}

class _ContributeDialogState extends State<ContributeDialog> {
  EkubModel? _selectedEkub;

  @override
  void initState() {
    super.initState();
    final joined = EkubStateService.instance.joinedEkubs;
    if (joined.isNotEmpty) {
      _selectedEkub = joined.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final joinedEkubs = EkubStateService.instance.joinedEkubs;
    final currentUser = AuthService.instance.currentUser;
    final userId = currentUser?.id ?? 'user_101';

    final bool isPaid = _selectedEkub != null &&
        EkubStateService.instance.isAlreadyPaid(
          userId,
          _selectedEkub!.id,
          _selectedEkub!.currentRound,
        );

    final bool isClosed = _selectedEkub != null && (_selectedEkub!.isClosed || _selectedEkub!.isCompleted);

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.add_card_rounded, color: Color(0xFF006C4C)),
          SizedBox(width: 8),
          Text('Record Contribution'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (joinedEkubs.isEmpty)
              const Text('You have not joined any active Ekub yet. Discover or join an Ekub first!')
            else ...[
              const Text('Select Ekub:'),
              const SizedBox(height: 6),
              DropdownButtonFormField<EkubModel>(
                value: _selectedEkub,
                isExpanded: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: joinedEkubs.map((ekub) {
                  return DropdownMenuItem<EkubModel>(
                    value: ekub,
                    child: Text(ekub.name),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedEkub = val;
                  });
                },
              ),
              const SizedBox(height: 16),

              if (_selectedEkub != null) ...[
                Card(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Current Round: Round ${_selectedEkub!.currentRound}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('Amount Due: ${_selectedEkub!.contributionAmount.toStringAsFixed(0)} ETB'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // DUPLICATE PAYMENT SAFEGUARD WARNING
              if (isPaid) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '⚠️ Already Paid: You have already contributed for Round 4 of this Ekub. Financial rules prevent duplicate contributions.',
                          style: TextStyle(fontSize: 12, color: Colors.brown, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              if (isClosed) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: const Text(
                    '🔒 Ekub Closed: This Ekub has completed all rounds and no longer accepts contributions.',
                    style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        if (joinedEkubs.isNotEmpty && _selectedEkub != null)
          ElevatedButton.icon(
            icon: const Icon(Icons.payment_rounded),
            label: Text(isPaid ? 'Already Paid' : 'Proceed to Payment'),
            onPressed: (isPaid || isClosed)
                ? null
                : () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) => SimulatedPaymentModal(ekub: _selectedEkub!),
                    );
                  },
          ),
      ],
    );
  }
}
