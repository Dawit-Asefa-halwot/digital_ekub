import 'package:flutter/material.dart';
import '../services/ekub_state_service.dart';

/// Interactive Create Ekub Form Dialog with input validation.
class CreateEkubDialog extends StatefulWidget {
  const CreateEkubDialog({super.key});

  @override
  State<CreateEkubDialog> createState() => _CreateEkubDialogState();
}

class _CreateEkubDialogState extends State<CreateEkubDialog> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _membersController = TextEditingController(text: '10');
  final _descriptionController = TextEditingController();

  // In-Kind specific controllers
  final _productNameController = TextEditingController();
  final _productValueController = TextEditingController();

  String _category = 'Group';
  String _frequency = 'Monthly';
  String _productIcon = 'tv';

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _membersController.dispose();
    _descriptionController.dispose();
    _productNameController.dispose();
    _productValueController.dispose();
    super.dispose();
  }

  Future<void> _submitCreateEkub() async {
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text.trim());
      final members = int.parse(_membersController.text.trim());
      final productVal = _productValueController.text.trim().isNotEmpty
          ? double.tryParse(_productValueController.text.trim())
          : null;

      final createdEkub = await EkubStateService.instance.createEkub(
        name: _nameController.text.trim(),
        category: _category,
        contributionAmount: amount,
        frequency: _frequency,
        maxMembers: members,
        description: _descriptionController.text.trim(),
        productName: _category == 'In-kind' ? _productNameController.text.trim() : null,
        productValue: productVal,
        productIcon: _category == 'In-kind' ? _productIcon : null,
      );

      if (mounted) {
        Navigator.pop(context);

        // Switch to My Ekubs tab
        EkubStateService.instance.setTabIndex(2);

        final nameStr = createdEkub?.name ?? _nameController.text.trim();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Successfully created "$nameStr" and added to My Ekubs!'),
            backgroundColor: Colors.green.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isInKind = _category == 'In-kind';

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.create_new_folder_rounded, color: Color(0xFF006C4C)),
          SizedBox(width: 8),
          Text('Create New Ekub'),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ekub Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Ekub Name *',
                  hintText: 'e.g. Bole Merchant Savings',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Ekub name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Ekub Type / Category Dropdown
              const Text('Category / Type:'),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'Popular', child: Text('Popular Cash Ekub')),
                  DropdownMenuItem(value: 'Group', child: Text('Group Ekub')),
                  DropdownMenuItem(value: 'Corporate', child: Text('Corporate Ekub')),
                  DropdownMenuItem(value: 'In-kind', child: Text('In-kind Product Ekub 🎁')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _category = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),

              // Dynamic In-Kind Section
              if (isInKind) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'In-Kind Product Details',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _productNameController,
                        decoration: const InputDecoration(
                          labelText: 'Product Name *',
                          hintText: 'e.g. Samsung 55" Smart TV',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (isInKind && (val == null || val.trim().isEmpty)) {
                            return 'Product name is required for In-kind Ekub';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _productValueController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Product Retail Value (ETB) *',
                          prefixText: 'ETB ',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (isInKind) {
                            if (val == null || val.trim().isEmpty) return 'Product value is required';
                            final v = double.tryParse(val);
                            if (v == null || v <= 0) return 'Enter a valid positive value';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      const Text('Product Icon:'),
                      DropdownButtonFormField<String>(
                        value: _productIcon,
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'tv', child: Text('📺 Smart TV')),
                          DropdownMenuItem(value: 'refrigerator', child: Text('🧊 Refrigerator')),
                          DropdownMenuItem(value: 'washing_machine', child: Text('🧺 Washing Machine')),
                          DropdownMenuItem(value: 'oven', child: Text('🍳 Electric Oven')),
                          DropdownMenuItem(value: 'smartphone', child: Text('📱 Smartphone')),
                          DropdownMenuItem(value: 'laptop', child: Text('💻 Laptop')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _productIcon = val);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Contribution Amount
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Contribution Amount (ETB) *',
                  prefixText: 'ETB ',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Contribution amount is required';
                  }
                  final v = double.tryParse(val.trim());
                  if (v == null || v <= 0) {
                    return 'Contribution must be greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Frequency & Max Members Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Frequency:'),
                        DropdownButtonFormField<String>(
                          value: _frequency,
                          decoration: const InputDecoration(border: OutlineInputBorder()),
                          items: const [
                            DropdownMenuItem(value: 'Daily', child: Text('Daily')),
                            DropdownMenuItem(value: 'Weekly', child: Text('Weekly')),
                            DropdownMenuItem(value: 'Monthly', child: Text('Monthly')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _frequency = val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Members:'),
                        TextFormField(
                          controller: _membersController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(border: OutlineInputBorder()),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Required';
                            final m = int.tryParse(val.trim());
                            if (m == null || m <= 1) return 'Must be > 1';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Ekub Description *',
                  hintText: 'Brief rules or promo description...',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Description is required';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submitCreateEkub,
          child: const Text('Create Ekub'),
        ),
      ],
    );
  }
}
