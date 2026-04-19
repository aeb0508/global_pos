import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_settings_provider.dart';
import '../services/api_service.dart';
import '../utils/api_config.dart';

class LayawayScreen extends StatefulWidget {
  const LayawayScreen({super.key});

  @override
  State<LayawayScreen> createState() => _LayawayScreenState();
}

class _LayawayScreenState extends State<LayawayScreen> {
  List<dynamic> _layaways = [];
  bool _isLoading = true;
  String _filter = 'active';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final res = await ApiService.get('${ApiConfig.baseUrl}/layaway.php');
    setState(() {
      _layaways = res['success'] ? (res['data'] ?? []) : [];
      _isLoading = false;
    });
  }

  List<dynamic> get _filtered {
    if (_filter == 'all') return _layaways;
    return _layaways.where((l) => l['status'] == _filter).toList();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'expired':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _showDetail(dynamic layaway) async {
    final res = await ApiService.get(
        '${ApiConfig.baseUrl}/layaway.php?id=${layaway['id']}');
    if (!mounted) return;
    if (res['success']) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _LayawayDetailPage(
            layaway: res['data'],
            onPaymentAdded: _load,
            onCancelled: _load,
          ),
        ),
      );
    }
  }

  void _showCreateDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _CreateLayawayPage(onCreated: _load),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            expandedHeight: 0,
            title: const Row(
              children: [
                Icon(Icons.layers, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Layaway / Hold',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18)),
              ],
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.cyan.shade600, Colors.cyan.shade800],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                  icon: const Icon(Icons.add, color: Colors.white),
                  onPressed: _showCreateDialog,
                  tooltip: 'New Layaway'),
              IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _load,
                  tooltip: 'Refresh'),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            sliver: SliverToBoxAdapter(
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'active', label: Text('Active')),
                  ButtonSegment(value: 'completed', label: Text('Completed')),
                  ButtonSegment(value: 'cancelled', label: Text('Cancelled')),
                  ButtonSegment(value: 'all', label: Text('All')),
                ],
                selected: {_filter},
                onSelectionChanged: (s) => setState(() => _filter = s.first),
              ),
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()))
          else if (_filtered.isEmpty)
            SliverFillRemaining(
                child: Center(child: Text('No $_filter layaways')))
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final l = _filtered[index];
                    final total =
                        double.tryParse(l['total_amount'].toString()) ?? 0;
                    final paid =
                        double.tryParse(l['deposit_paid'].toString()) ?? 0;
                    final balance =
                        double.tryParse(l['balance_due'].toString()) ?? 0;
                    final progress = total > 0 ? paid / total : 0.0;
                    return Card(
                      child: InkWell(
                        onTap: () => _showDetail(l),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(l['layaway_number'],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                  Chip(
                                    label: Text(
                                        (l['status'] as String).toUpperCase(),
                                        style: const TextStyle(
                                            fontSize: 10, color: Colors.white)),
                                    backgroundColor: _statusColor(l['status']),
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ],
                              ),
                              if (l['customer_name'] != null)
                                Text('Customer: ${l['customer_name']}',
                                    style: const TextStyle(color: Colors.grey)),
                              const SizedBox(height: 8),
                              Builder(builder: (ctx) {
                                final sym = ctx
                                    .watch<AppSettingsProvider>()
                                    .currencySymbol;
                                return Row(children: [
                                  Text(
                                      'Total: ${total.toStringAsFixed(2)} $sym'),
                                  const SizedBox(width: 16),
                                  Text('Paid: ${paid.toStringAsFixed(2)} $sym',
                                      style:
                                          const TextStyle(color: Colors.green)),
                                  const SizedBox(width: 16),
                                  Text(
                                      'Balance: ${balance.toStringAsFixed(2)} $sym',
                                      style: TextStyle(
                                          color: balance > 0
                                              ? Colors.red
                                              : Colors.green,
                                          fontWeight: FontWeight.bold)),
                                ]);
                              }),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: progress.clamp(0.0, 1.0),
                                backgroundColor: Colors.grey[200],
                                color: progress >= 1.0
                                    ? Colors.green
                                    : Colors.blue,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                  '${(progress * 100).toStringAsFixed(0)}% paid',
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: _filtered.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LayawayDetailPage extends StatefulWidget {
  final Map<String, dynamic> layaway;
  final VoidCallback onPaymentAdded;
  final VoidCallback onCancelled;
  const _LayawayDetailPage({
    required this.layaway,
    required this.onPaymentAdded,
    required this.onCancelled,
  });

  @override
  State<_LayawayDetailPage> createState() => _LayawayDetailPageState();
}

class _LayawayDetailPageState extends State<_LayawayDetailPage> {
  final _paymentController = TextEditingController();
  String _paymentMethod = 'cash';

  @override
  void dispose() {
    _paymentController.dispose();
    super.dispose();
  }

  Future<void> _addPayment() async {
    final amount = double.tryParse(_paymentController.text);
    if (amount == null || amount <= 0) return;
    final res = await ApiService.post('${ApiConfig.baseUrl}/layaway.php', {
      'add_payment': true,
      'layaway_id': widget.layaway['id'],
      'amount': amount,
      'payment_method': _paymentMethod,
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res['message'] ?? 'Done'),
        backgroundColor: res['success'] == true ? Colors.green : Colors.red,
      ),
    );
    if (res['success'] == true) {
      widget.onPaymentAdded();
      Navigator.pop(context);
    }
  }

  Future<void> _cancel() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Layaway'),
        content: const Text('Are you sure you want to cancel this layaway?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes, Cancel')),
        ],
      ),
    );
    if (confirm == true) {
      await ApiService.delete(
          '${ApiConfig.baseUrl}/layaway.php?id=${widget.layaway['id']}');
      if (!mounted) return;
      widget.onCancelled();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.layaway;
    final items = l['items'] as List? ?? [];
    final payments = l['payments'] as List? ?? [];
    final balance = double.tryParse(l['balance_due'].toString()) ?? 0;
    final isActive = l['status'] == 'active';
    final width = MediaQuery.of(context).size.width;
    final isPhone = width < 600;
    final sym = context.watch<AppSettingsProvider>().currencySymbol;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Layaway: ${l['layaway_number']}',
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueGrey.shade700,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (isActive)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton.icon(
                onPressed: _cancel,
                icon: const Icon(Icons.cancel, color: Colors.red),
                label:
                    const Text('Cancel', style: TextStyle(color: Colors.red)),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isPhone ? 16.0 : 24.0,
            vertical: isPhone ? 20.0 : 30.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blueGrey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.receipt_long_rounded,
                            color: Colors.blueGrey,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Layaway Details',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blueGrey.shade800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'View items, payments, and manage layaway',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blueGrey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (l['customer_name'] != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('Customer: ${l['customer_name']}',
                            style:
                                const TextStyle(fontWeight: FontWeight.w500)),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('Status: ${l['status']}',
                          style: TextStyle(
                              color: isActive ? Colors.green : Colors.grey,
                              fontWeight: FontWeight.w500)),
                    ),
                    if (l['expiry_date'] != null)
                      Text('Expires: ${l['expiry_date']}',
                          style: TextStyle(color: Colors.orange.shade700)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Items',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...items.map((item) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(item['product_name'],
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500)),
                        ),
                        Text(
                            '${item['quantity']} x ${item['unit_price']} $sym = ${item['total_price']} $sym',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('${l['total_amount']} $sym',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Paid:',
                            style: TextStyle(color: Colors.green)),
                        Text('${l['deposit_paid']} $sym',
                            style: const TextStyle(color: Colors.green)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Balance:',
                            style: TextStyle(
                                color: balance > 0 ? Colors.red : Colors.green,
                                fontWeight: FontWeight.bold)),
                        Text('${l['balance_due']} $sym',
                            style: TextStyle(
                                color: balance > 0 ? Colors.red : Colors.green,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              if (payments.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Payment History',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ...payments.map((p) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                                '${p['amount']} $sym (${p['payment_method']})',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500)),
                          ),
                          Text(p['created_at'] ?? '',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    )),
              ],
              if (isActive && balance > 0) ...[
                const SizedBox(height: 24),
                Text(
                  'Add Payment',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _paymentController,
                        decoration: InputDecoration(
                          labelText: 'Amount ($sym)',
                          border: const OutlineInputBorder(),
                          prefixText: sym,
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<String>(
                      value: _paymentMethod,
                      items: const [
                        DropdownMenuItem(value: 'cash', child: Text('Cash')),
                        DropdownMenuItem(value: 'card', child: Text('Card')),
                      ],
                      onChanged: (v) => setState(() => _paymentMethod = v!),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _addPayment,
                    icon: const Icon(Icons.payment),
                    label: const Text('Add Payment'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.blueGrey.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateLayawayPage extends StatefulWidget {
  final VoidCallback onCreated;
  const _CreateLayawayPage({required this.onCreated});

  @override
  State<_CreateLayawayPage> createState() => _CreateLayawayPageState();
}

class _CreateLayawayPageState extends State<_CreateLayawayPage> {
  final _formKey = GlobalKey<FormState>();
  final _depositController = TextEditingController();
  final _expiryController = TextEditingController();
  final _notesController = TextEditingController();
  List<dynamic> _products = [];
  final List<Map<String, dynamic>> _items = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _depositController.dispose();
    _expiryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    final res = await ApiService.get(ApiConfig.productsEndpoint);
    if (res['success'] && mounted) {
      setState(() => _products = res['data'] ?? []);
    }
  }

  void _addItem(dynamic product) {
    setState(() {
      final existing = _items.indexWhere(
          (i) => i['product_id'].toString() == product['id'].toString());
      if (existing >= 0) {
        _items[existing]['quantity']++;
        _items[existing]['total_price'] = _items[existing]['quantity'] *
            double.parse(product['selling_price'].toString());
      } else {
        _items.add({
          'product_id': product['id'],
          'product_name': product['name'],
          'quantity': 1,
          'unit_price': double.parse(product['selling_price'].toString()),
          'total_price': double.parse(product['selling_price'].toString()),
        });
      }
    });
  }

  double get _total =>
      _items.fold(0, (sum, i) => sum + (i['total_price'] as double));

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one item')),
      );
      return;
    }
    setState(() => _isLoading = true);
    final res = await ApiService.post('${ApiConfig.baseUrl}/layaway.php', {
      'user_id': 1,
      'total_amount': _total,
      'deposit_paid': double.tryParse(_depositController.text) ?? 0,
      'expiry_date':
          _expiryController.text.isEmpty ? null : _expiryController.text,
      'notes': _notesController.text,
      'items': _items,
    });
    if (!mounted) return;
    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Layaway created: ${res['data']?['layaway_number'] ?? ''}'),
            backgroundColor: Colors.green),
      );
      widget.onCreated();
      Navigator.pop(context);
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(res['message'] ?? 'Error'),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isPhone = width < 600;
    final sym = context.watch<AppSettingsProvider>().currencySymbol;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'New Layaway',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueGrey.shade700,
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
                icon: const Icon(Icons.save, size: 18),
                label: const Text('Create'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blueGrey.shade700,
                ),
              ),
            ),
          ),
        ],
      ),
      body: isPhone ? _buildPhoneLayout(sym) : _buildDesktopLayout(sym),
    );
  }

  Widget _buildPhoneLayout(String sym) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blueGrey.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.shopping_cart_rounded,
                        color: Colors.blueGrey,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create Layaway',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.blueGrey.shade800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Select products and set terms',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blueGrey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Products',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final p = _products[index];
                    return ListTile(
                      dense: true,
                      title: Text(p['name']),
                      subtitle: Text('${p['selling_price']} $sym'),
                      trailing: IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.blue),
                        onPressed: () => _addItem(p),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Selected Items',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              if (_items.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('No items added',
                      style: TextStyle(color: Colors.grey)),
                )
              else
                ..._items.map((item) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['product_name'],
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500)),
                                Text('Qty: ${item['quantity']}',
                                    style:
                                        TextStyle(color: Colors.grey.shade600)),
                              ],
                            ),
                          ),
                          Text(
                              '${(item['total_price'] as double).toStringAsFixed(2)} $sym',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )),
              if (_items.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('${_total.toStringAsFixed(2)} $sym',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _depositController,
                decoration: InputDecoration(
                  labelText: 'Initial Deposit ($sym)',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _expiryController,
                decoration: const InputDecoration(
                  labelText: 'Expiry Date (YYYY-MM-DD)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.close),
                      label: const Text('Cancel'),
                      onPressed:
                          _isLoading ? null : () => Navigator.pop(context),
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
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Icon(Icons.save),
                      label: const Text('Create Layaway'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.blueGrey.shade700,
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
    );
  }

  Widget _buildDesktopLayout(String sym) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product list
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Products',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      itemCount: _products.length,
                      itemBuilder: (context, index) {
                        final p = _products[index];
                        return ListTile(
                          dense: true,
                          title: Text(p['name']),
                          subtitle: Text('${p['selling_price']} $sym'),
                          trailing: IconButton(
                            icon: const Icon(Icons.add_circle,
                                color: Colors.blue),
                            onPressed: () => _addItem(p),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const VerticalDivider(),
        // Cart & details
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected Items',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    if (_items.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('No items added',
                            style: TextStyle(color: Colors.grey)),
                      )
                    else
                      ..._items.map((item) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(item['product_name'],
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w500)),
                                      Text('Qty: ${item['quantity']}',
                                          style: TextStyle(
                                              color: Colors.grey.shade600)),
                                    ],
                                  ),
                                ),
                                Text(
                                    '${(item['total_price'] as double).toStringAsFixed(2)} $sym',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          )),
                    if (_items.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total:',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('${_total.toStringAsFixed(2)} $sym',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _depositController,
                      decoration: InputDecoration(
                        labelText: 'Initial Deposit ($sym)',
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _expiryController,
                      decoration: const InputDecoration(
                        labelText: 'Expiry Date (YYYY-MM-DD)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.close),
                            label: const Text('Cancel'),
                            onPressed: _isLoading
                                ? null
                                : () => Navigator.pop(context),
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
                                      valueColor:
                                          AlwaysStoppedAnimation(Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.save),
                            label: const Text('Create Layaway'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.blueGrey.shade700,
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
      ],
    );
  }
}
