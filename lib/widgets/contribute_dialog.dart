import 'package:flutter/material.dart';
import '../models/ekub_model.dart';
import '../services/ekub_state_service.dart';

/// Interactive Contribution Form Dialog.
class ContributeDialog extends StatefulWidget {
  const ContributeDialog({super.key});

  @override
  State<ContributeDialog> createState() => _ContributeDialogState();
}

class _ContributeDialogState extends State<ContributeDialog> {
  final _formKey = GlobalKey<FormState>();
  EkubModel? _selectedEkub;
  final TextEditingController _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final joined = EkubStateService.instance.joinedEkubs;
    if (joined.isNotEmpty) {
      _selectedEkub = joined.first;
      _amountController.text = _selectedEkub!.contributionAmount.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _submitContribution() {
    if (_formKey.currentState!.validate() && _selectedEkub != null) {
      final amount = double.tryParse(_amountController.text) ?? 0.0;

      final success = EkubStateService.instance.recordContribution(
        ekubId: _selectedEkub!.id,
        amount: amount,
      );

      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Successfully recorded contribution of ${amount.toStringAsFixed(0)} ETB for ${_selectedEkub!.name}!'),
            backgroundColor: Colors.green.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final joinedEkubs = EkubStateService.instance.joinedEkubs;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.add_card_rounded, color: Color(0xFF006C4C)),
          SizedBox(width: 8),
          Text('Record Contribution'),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (joinedEkubs.isEmpty)
                const Text('You have not joined any Ekub yet. Join or create an Ekub first!')
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
                      if (val != null) {
                        _amountController.text = val.contributionAmount.toStringAsFixed(0);
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
                const Text('Contribution Amount (ETB):'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    prefixText: 'ETB ',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter contribution amount';
                    }
                    final amount = double.tryParse(val);
                    if (amount == null || amount <= 0) {
                      return 'Amount must be greater than 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: Colors.blue),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Local Simulation: Confirmed contribution updates the current pot & generates a local transaction.',
                          style: TextStyle(fontSize: 12, color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        if (joinedEkubs.isNotEmpty)
          ElevatedButton(
            onPressed: _submitContribution,
            child: const Text('Confirm Contribution'),
          ),
      ],
    );
  }
}
