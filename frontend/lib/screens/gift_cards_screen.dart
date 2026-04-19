import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_settings_provider.dart';
import '../services/api_service.dart';
import '../utils/api_config.dart';

class GiftCardsScreen extends StatefulWidget {
  const GiftCardsScreen({super.key});

  @override
  State<GiftCardsScreen> createState() => _GiftCardsScreenState();
}

class _GiftCardsScreenState extends State<GiftCardsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _giftCards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadGiftCards();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGiftCards() async {
    setState(() => _isLoading = true);
    try {
      final response =
          await ApiService.get('${ApiConfig.baseUrl}/gift_cards.php');
      if (response['success']) {
        setState(() {
          _giftCards = response['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showIssueDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _IssueGiftCardPage(
          onSaved: _loadGiftCards,
        ),
      ),
    );
  }

  void _showCheckBalanceDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Check Gift Card Balance'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Card Number',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final response = await ApiService.get(
                  '${ApiConfig.baseUrl}/gift_cards.php?card_number=${controller.text}');
              if (!context.mounted) return;
              Navigator.pop(context);
              if (response['success'] && response['data'] != null) {
                final card = response['data'];
                if (!context.mounted) return;
                final sym = context.read<AppSettingsProvider>().currencySymbol;
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Gift Card Balance'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Card: ${card['card_number']}'),
                        Text(
                          'Balance: ${card['current_balance']} $sym',
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        Text('Status: ${card['status']}'),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Gift card not found')),
                );
              }
            },
            child: const Text('Check'),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'used':
        return Colors.grey;
      case 'expired':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sym = context.watch<AppSettingsProvider>().currencySymbol;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            expandedHeight: 0,
            title: const Row(
              children: [
                Icon(Icons.card_giftcard, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Gift Cards',
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
                    colors: [Colors.pink.shade600, Colors.pink.shade800],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: _showCheckBalanceDialog,
                tooltip: 'Check Balance',
              ),
              IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: _showIssueDialog,
                tooltip: 'Issue Gift Card',
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _loadGiftCards,
                tooltip: 'Refresh',
              ),
            ],
          ),
          if (_isLoading)
            const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()))
          else if (_giftCards.isEmpty)
            const SliverFillRemaining(
                child: Center(child: Text('No gift cards issued yet')))
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final card = _giftCards[index];
                    final status = card['status'] ?? 'active';
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(card['card_number'],
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'monospace')),
                                Chip(
                                  label: Text(status.toUpperCase(),
                                      style: const TextStyle(
                                          fontSize: 10, color: Colors.white)),
                                  backgroundColor: _statusColor(status),
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Initial',
                                        style: TextStyle(
                                            fontSize: 10, color: Colors.grey)),
                                    Text('${card['initial_balance']} $sym',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Balance',
                                        style: TextStyle(
                                            fontSize: 10, color: Colors.grey)),
                                    Text('${card['current_balance']} $sym',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green)),
                                  ],
                                ),
                                if (card['expiry_date'] != null)
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('Expires',
                                          style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey)),
                                      Text(card['expiry_date'],
                                          style: const TextStyle(fontSize: 12)),
                                    ],
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: _giftCards.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _IssueGiftCardPage extends StatefulWidget {
  final VoidCallback onSaved;
  const _IssueGiftCardPage({required this.onSaved});

  @override
  State<_IssueGiftCardPage> createState() => _IssueGiftCardPageState();
}

class _IssueGiftCardPageState extends State<_IssueGiftCardPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _expiryController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _expiryController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final response =
          await ApiService.post('${ApiConfig.baseUrl}/gift_cards.php', {
        'initial_balance': double.parse(_amountController.text),
        'expiry_date':
            _expiryController.text.isEmpty ? null : _expiryController.text,
        'issued_by': 1,
      });

      if (!mounted) return;

      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gift card issued: ${response['card_number']}')),
        );
        widget.onSaved();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sym = context.watch<AppSettingsProvider>().currencySymbol;
    final width = MediaQuery.of(context).size.width;
    final isPhone = width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Issue Gift Card',
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
                label: const Text('Issue'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blueGrey.shade700,
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
                              Icons.card_giftcard_rounded,
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
                                  'Issue Gift Card',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blueGrey.shade800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Create a new gift card with initial balance',
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
                      'Amount',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        labelText: 'Amount ($sym)',
                        border: const OutlineInputBorder(),
                        suffixText: sym,
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v?.isEmpty ?? true) return 'Required';
                        if (double.tryParse(v!) == null) {
                          return 'Invalid amount';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Expiry Date',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _expiryController,
                      decoration: const InputDecoration(
                        labelText: 'Expiry Date (optional)',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate:
                              DateTime.now().add(const Duration(days: 365)),
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 3650)),
                        );
                        if (date != null) {
                          _expiryController.text =
                              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                        }
                      },
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
                            label: const Text('Issue Card'),
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
      ),
    );
  }
}
