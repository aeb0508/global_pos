import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../services/api_service.dart';
import '../utils/api_config.dart';

class CustomerFormDialog extends StatefulWidget {
  final Customer? customer;
  final Function(Customer?) onSaved;

  const CustomerFormDialog({super.key, this.customer, required this.onSaved});

  @override
  State<CustomerFormDialog> createState() => _CustomerFormDialogState();
}

class _CustomerFormDialogState extends State<CustomerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(text: widget.customer?.name ?? '');
  late final TextEditingController _email = TextEditingController(text: widget.customer?.email ?? '');
  late final TextEditingController _phone = TextEditingController(text: widget.customer?.phone ?? '');
  late final TextEditingController _address = TextEditingController(text: widget.customer?.address ?? '');
  bool _isLoading = false;

  @override
  void dispose() {
    _name.dispose(); _email.dispose(); _phone.dispose(); _address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final data = {
      'name': _name.text.trim(),
      'email': _email.text.trim().isEmpty ? null : _email.text.trim(),
      'phone': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      'address': _address.text.trim().isEmpty ? null : _address.text.trim(),
      if (widget.customer != null) 'id': widget.customer!.id,
    };

    try {
      final res = widget.customer == null
          ? await ApiService.post(ApiConfig.customersEndpoint, data)
          : await ApiService.put(ApiConfig.customersEndpoint, data);

      if (mounted) {
        if (res['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(widget.customer == null ? 'Customer added' : 'Customer updated'),
            backgroundColor: Colors.green,
          ));
          widget.onSaved(res['data'] != null ? Customer.fromJson(res['data']) : null);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(res['message'] ?? 'Failed'),
            backgroundColor: Colors.red,
          ));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEdit = widget.customer != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(10)),
                    child: Icon(isEdit ? Icons.edit_rounded : Icons.person_add_rounded, color: cs.onPrimary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(isEdit ? 'Edit Customer' : 'New Customer',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Text(isEdit ? 'Update customer information' : 'Add a new customer to your database',
                          style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
                    ]),
                  ),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 24),

              // Name
              TextFormField(
                controller: _name,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: _dec('Full Name', Icons.person_outline, cs),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),

              // Email & Phone
              Row(children: [
                Expanded(child: TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _dec('Email', Icons.email_outlined, cs),
                )),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: _dec('Phone', Icons.phone_outlined, cs),
                )),
              ]),
              const SizedBox(height: 16),

              // Address
              TextFormField(
                controller: _address,
                maxLines: 2,
                textCapitalization: TextCapitalization.words,
                decoration: _dec('Address', Icons.location_on_outlined, cs),
              ),
              const SizedBox(height: 24),

              // Actions
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(onPressed: _isLoading ? null : () => Navigator.pop(context), child: const Text('Cancel')),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _isLoading ? null : _save,
                  icon: _isLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Icon(isEdit ? Icons.check_rounded : Icons.add_rounded, size: 18),
                  label: Text(isEdit ? 'Update Customer' : 'Add Customer'),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _dec(String label, IconData icon, ColorScheme cs) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: cs.primary, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
        isDense: true,
      );
}
