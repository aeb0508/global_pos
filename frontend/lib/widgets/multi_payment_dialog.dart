import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_settings_provider.dart';

class MultiPaymentDialog extends StatefulWidget {
  final double totalAmount;
  final Function(List<Map<String, dynamic>>) onComplete;

  const MultiPaymentDialog({
    super.key,
    required this.totalAmount,
    required this.onComplete,
  });

  @override
  State<MultiPaymentDialog> createState() => _MultiPaymentDialogState();
}

class _MultiPaymentDialogState extends State<MultiPaymentDialog> {
  final List<Map<String, dynamic>> _payments = [];
  final _amountController = TextEditingController();
  String _selectedMethod = 'cash';
  double _remainingAmount = 0;

  @override
  void initState() {
    super.initState();
    _remainingAmount = widget.totalAmount;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _addPayment() {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    if (amount > _remainingAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amount exceeds remaining balance')),
      );
      return;
    }

    setState(() {
      _payments.add({'method': _selectedMethod, 'amount': amount});
      _remainingAmount -= amount;
      _amountController.clear();
    });
  }

  void _removePayment(int index) {
    setState(() {
      _remainingAmount += _payments[index]['amount'] as double;
      _payments.removeAt(index);
    });
  }

  void _complete() {
    if (_remainingAmount > 0.01) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete the full payment')),
      );
      return;
    }
    widget.onComplete(_payments);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Split Payment'),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total:', style: TextStyle(fontSize: 16)),
                        Text('${widget.totalAmount.toStringAsFixed(2)} ${context.watch<AppSettingsProvider>().currencySymbol}',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Remaining:',
                            style: TextStyle(fontSize: 16)),
                        Text('${_remainingAmount.toStringAsFixed(2)} ${context.watch<AppSettingsProvider>().currencySymbol}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _remainingAmount > 0
                                  ? Colors.red
                                  : Colors.green,
                            )),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_remainingAmount > 0.01) ...[
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedMethod,
                      decoration: const InputDecoration(
                        labelText: 'Method',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'cash', child: Text('Cash')),
                        DropdownMenuItem(value: 'card', child: Text('Card')),
                        DropdownMenuItem(
                            value: 'mobile', child: Text('Mobile')),
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedMethod = value!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        border: const OutlineInputBorder(),
                        suffixText: context.watch<AppSettingsProvider>().currencySymbol,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addPayment,
                    child: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            if (_payments.isNotEmpty) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Payments:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _payments.length,
                  itemBuilder: (context, index) {
                    final payment = _payments[index];
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          payment['method'] == 'cash'
                              ? Icons.money
                              : payment['method'] == 'card'
                                  ? Icons.credit_card
                                  : Icons.phone_android,
                        ),
                        title: Text(payment['method'].toString().toUpperCase()),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${payment['amount'].toStringAsFixed(2)} ${context.watch<AppSettingsProvider>().currencySymbol}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removePayment(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _remainingAmount <= 0.01 ? _complete : null,
          child: const Text('Complete'),
        ),
      ],
    );
  }
}
