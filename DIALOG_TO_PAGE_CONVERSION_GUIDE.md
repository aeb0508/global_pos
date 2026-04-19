# Dialog to Responsive Page Conversion Guide

## Completed Conversions
✅ **categories_screen.dart** - DONE
- Converted `_showDialog()` to `_showForm()` with responsive page navigation
- Created `_CategoriesFormPage` StatefulWidget with full responsive layout
- Supports phone, tablet, and desktop layouts
- All methods properly updated

## Pattern to Follow for Remaining Screens

### Step 1: Replace showDialog call with Navigator.push

**Before:**
```dart
void _showDialog({Map<String, dynamic>? item}) {
  showDialog(
    context: context,
    builder: (_) => _ItemDialog(
      item: item,
      onSaved: () {
        Navigator.pop(context);
        _load();
      },
    ),
  );
}
```

**After:**
```dart
void _showForm({Map<String, dynamic>? item}) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => _ItemFormPage(
        item: item,
        onSaved: _load,
      ),
    ),
  );
}
```

### Step 2: Update all calls to _showDialog → _showForm

- `_showDialog()` → `_showForm()`
- `_showDialog(item: item)` → `_showForm(item: item)`
- `onEdit: _showDialog` → `onEdit: _showForm`

### Step 3: Create Responsive Form Page Widget

Replace the dialog class with this template:

```dart
class _ItemFormPage extends StatefulWidget {
  final Map<String, dynamic>? item;
  final VoidCallback onSaved;

  const _ItemFormPage({
    this.item,
    required this.onSaved,
  });

  @override
  State<_ItemFormPage> createState() => _ItemFormPageState();
}

class _ItemFormPageState extends State<_ItemFormPage> {
  late final TextEditingController _field1Ctrl;
  late final TextEditingController _field2Ctrl;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _field1Ctrl = TextEditingController(text: widget.item?['field1'] ?? '');
    _field2Ctrl = TextEditingController(text: widget.item?['field2'] ?? '');
  }

  @override
  void dispose() {
    _field1Ctrl.dispose();
    _field2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final body = {
      'field1': _field1Ctrl.text.trim(),
      'field2': _field2Ctrl.text.trim(),
    };

    try {
      late final Map<String, dynamic> res;
      final isNew = widget.item == null;

      if (isNew) {
        res = await ApiService.post(ApiConfig.endpoint, body);
      } else {
        res = await ApiService.put(
          '${ApiConfig.endpoint}?id=${widget.item!['id']}',
          body,
        );
      }

      if (!mounted) return;

      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isNew ? 'Added successfully' : 'Updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSaved();
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.item == null;
    final width = MediaQuery.of(context).size.width;
    final isPhone = width < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isNew ? 'Add Item' : 'Edit Item',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade600,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Center(
              child: FilledButton.icon(
                onPressed: _isLoading ? null : _save,
                icon: Icon(isNew ? Icons.add : Icons.save, size: 18),
                label: Text(isNew ? 'Add' : 'Save'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue.shade600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isPhone ? 16.0 : 24.0,
                vertical: isPhone ? 20.0 : 30.0,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Info Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.edit_rounded,
                              color: Colors.blue.shade600,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isNew ? 'Create New Item' : 'Edit Item',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Fill in the details below',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Form Fields
                    Text(
                      'Field 1',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _field1Ctrl,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Enter value',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'Field 2',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _field2Ctrl,
                      decoration: InputDecoration(
                        labelText: 'Enter value',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.close),
                            label: const Text('Cancel'),
                            onPressed: _isLoading ? null : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _isLoading ? null : _save,
                            icon: _isLoading
                                ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                                : Icon(isNew ? Icons.add : Icons.save),
                            label: Text(isNew ? 'Add Item' : 'Save Changes'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

## Screens Still Needing Conversion (by priority)

### HIGH PRIORITY (Form Dialogs):
1. **currency_management_screen** - Currency add/edit form - IN PROGRESS
2. **customers_screen** - Customer add/edit form
3. **users_screen** - User add/edit form
4. **gift_cards_screen** - Issue gift card form
5. **layaway_screen** - Create layaway form
6. **loyalty_program_screen** - Edit loyalty, Add points forms (2 dialogs)
7. **multi_store_screen** - Add/Edit store, Inventory management, Stock transfer (3 dialogs)
8. **payment_gateway_screen** - Configure gateway, Process refund (2 dialogs)
9. **price_management_screen** - Update price form
10. **refund_management_screen** - Process refund, Edit refund (2 dialogs)
11. **stock_management_screen** - Adjust stock form
12. **suppliers_screen** - Supplier form (check if already done)
13. **tax_management_screen** - Add/Edit tax rate form

### MEDIUM PRIORITY (Info/Selection Dialogs):
- payment_gateway_screen - Transaction details info
- orders_screen - Order details info
- pending_orders_screen - Order details + completion
- gift_cards_screen - Check balance selection
- Others (mostly confirmation dialogs - can stay as dialogs)

## Quick Conversion Checklist

For each screen:
- [ ] Replace `showDialog` with `Navigator.push`
- [ ] Create `_ScreenFormPage` StatefulWidget
- [ ] Create `_ScreenFormPageState` State class  
- [ ] Update AppBar with theme color matching screen
- [ ] Add responsive constraints (maxWidth: 600)
- [ ] Add support for different screen sizes
- [ ] Test on phone layout < 600
- [ ] Test on tablet layout 600-1024
- [ ] Test on desktop layout > 1024

## Color Codes by Module
- Categories: Orange
- Currencies: Teal
- Customers: Purple/Blue
- Users: Indigo
- Products: Green
- Orders: Amber
- Refunds: Red
- Others: Match existing theme or use Blue as default

## Key Notes
- ALL form pages should be responsive
- Use ConstrainedBox(maxWidth: 600) for content centering
- Support all 3 screen sizes: phone (<600), tablet (600-1024), desktop (>1024)
- Keep confirmation dialogs as AlertDialog (they don't need pages)
- Test each conversion with hot reload to verify functionality
