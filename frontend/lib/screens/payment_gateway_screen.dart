import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_settings_provider.dart';
import '../services/api_service.dart';
import '../utils/api_config.dart';

class PaymentGatewayScreen extends StatefulWidget {
  const PaymentGatewayScreen({super.key});

  @override
  State<PaymentGatewayScreen> createState() => _PaymentGatewayScreenState();
}

class _PaymentGatewayScreenState extends State<PaymentGatewayScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _gatewaySearchController = TextEditingController();
  final _transactionSearchController = TextEditingController();
  final _gatewayRefreshKey = GlobalKey<RefreshIndicatorState>();
  final _transactionRefreshKey = GlobalKey<RefreshIndicatorState>();

  List<dynamic> gateways = [];
  List<dynamic> filteredGateways = [];
  List<dynamic> transactions = [];
  List<dynamic> filteredTransactions = [];

  bool isLoading = true;
  String transactionStatusFilter = 'all';
  String? lastError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _gatewaySearchController.addListener(_updateGatewayFilter);
    _transactionSearchController.addListener(_updateTransactionFilter);
    loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _gatewaySearchController.dispose();
    _transactionSearchController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    setState(() {
      isLoading = true;
      lastError = null;
    });

    await Future.wait([loadGateways(), loadTransactions()]);

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> loadGateways() async {
    final response = await ApiService.get('${ApiConfig.paymentGatewayEndpoint}?gateways=1');

    if (response is List) {
      if (mounted) {
        setState(() {
          gateways = List<dynamic>.from(response as Iterable);
          filteredGateways = List<dynamic>.from(response as Iterable);
        });
      }
      _updateGatewayFilter();
    } else {
      final error = _extractErrorMessage(response, 'Unable to load gateways');
      _showError(error);
    }
  }

  Future<void> loadTransactions() async {
    final response = await ApiService.get('${ApiConfig.paymentGatewayEndpoint}?transactions=1');

    if (response is List) {
      if (mounted) {
        setState(() {
          transactions = List<dynamic>.from(response as Iterable);
          filteredTransactions = List<dynamic>.from(response as Iterable);
        });
      }
      _updateTransactionFilter();
    } else {
      final error = _extractErrorMessage(response, 'Unable to load transactions');
      _showError(error);
    }
  }

  String _extractErrorMessage(dynamic response, String fallback) {
    if (response is Map) {
      if (response['message'] != null) return response['message'].toString();
      if (response['error'] != null) return response['error'].toString();
    }
    return fallback;
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() {
      lastError = message;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  void _updateGatewayFilter() {
    final query = _gatewaySearchController.text.toLowerCase().trim();
    if (query.isEmpty) {
      setState(() => filteredGateways = gateways);
      return;
    }

    setState(() {
      filteredGateways = gateways.where((gateway) {
        final name = gateway['name']?.toString().toLowerCase() ?? '';
        final type = gateway['gateway_type']?.toString().toLowerCase() ?? '';
        return name.contains(query) || type.contains(query);
      }).toList();
    });
  }

  void _updateTransactionFilter() {
    final query = _transactionSearchController.text.toLowerCase().trim();
    final status = transactionStatusFilter;

    setState(() {
      filteredTransactions = transactions.where((txn) {
        final matchesStatus = status == 'all' || txn['status'] == status;
        if (!matchesStatus) {
          return false;
        }

        if (query.isEmpty) {
          return true;
        }

        final orderNumber = txn['order_number']?.toString().toLowerCase() ?? '';
        final transactionId = txn['transaction_id']?.toString().toLowerCase() ?? '';
        final gatewayName = txn['gateway_name']?.toString().toLowerCase() ?? '';
        final customer = txn['customer_name']?.toString().toLowerCase() ?? '';
        return orderNumber.contains(query) || transactionId.contains(query) || gatewayName.contains(query) || customer.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol = context.select((AppSettingsProvider settings) => settings.currencySymbol);

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo.shade600, Colors.indigo.shade800],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Row(
          children: [
            Icon(Icons.payment, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'Payment Gateway',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.payment), text: 'Gateways'),
            Tab(icon: Icon(Icons.receipt_long), text: 'Transactions'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildGatewaysTab(),
                _buildTransactionsTab(currencySymbol),
              ],
            ),
    );
  }

  Widget _buildGatewaysTab() {
    return RefreshIndicator(
      key: _gatewayRefreshKey,
      onRefresh: loadGateways,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _gatewaySearchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search gateways',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (lastError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(lastError!, style: const TextStyle(color: Colors.red)),
              ),
            if (filteredGateways.isEmpty)
              const Expanded(
                child: Center(child: Text('No gateways configured yet.')),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: filteredGateways.length,
                  itemBuilder: (context, index) {
                    final gateway = filteredGateways[index];
                    return _buildGatewayCard(gateway);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGatewayCard(Map<String, dynamic> gateway) {
    final isActive = gateway['is_active'] == 1 || gateway['is_active'] == true;
    final isTestMode = gateway['is_test_mode'] == 1 || gateway['is_test_mode'] == true;
    final gatewayType = gateway['gateway_type']?.toString().toLowerCase() ?? '';
    final iconData = _gatewayIcon(gatewayType);
    final color = _gatewayColor(gatewayType);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(iconData, color: Colors.white),
        ),
        title: Text(gateway['name']?.toString() ?? 'Unnamed Gateway', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Row(
          children: [
            Chip(
              label: Text(isActive ? 'Active' : 'Inactive'),
              backgroundColor: isActive ? Colors.green : Colors.grey,
              labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            const SizedBox(width: 8),
            if (isTestMode)
              const Chip(
                label: Text('Test Mode'),
                backgroundColor: Colors.orange,
                labelStyle: TextStyle(color: Colors.white, fontSize: 12),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () => _showGatewayConfigDialog(gateway),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Gateway Type', gateway['gateway_type']?.toString().toUpperCase() ?? 'N/A'),
                _buildInfoRow('Status', isActive ? 'Active' : 'Inactive'),
                _buildInfoRow('Mode', isTestMode ? 'Test Mode' : 'Production'),
                _buildInfoRow('Created', gateway['created_at'] ?? 'N/A'),
                _buildInfoRow('Updated', gateway['updated_at'] ?? 'N/A'),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _testGateway(gateway),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Test Connection'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _showGatewayConfigDialog(gateway),
                      icon: const Icon(Icons.edit),
                      label: const Text('Configure'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _gatewayIcon(String type) {
    switch (type) {
      case 'stripe':
        return Icons.credit_card;
      case 'paypal':
        return Icons.account_balance;
      case 'square':
        return Icons.square;
      default:
        return Icons.payment;
    }
  }

  Color _gatewayColor(String type) {
    switch (type) {
      case 'stripe':
        return Colors.purple;
      case 'paypal':
        return Colors.blue;
      case 'square':
        return Colors.black;
      default:
        return Colors.grey;
    }
  }

  Widget _buildTransactionsTab(String currencySymbol) {
    return RefreshIndicator(
      key: _transactionRefreshKey,
      onRefresh: loadTransactions,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _transactionSearchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search order, transaction or gateway',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            _buildStatusChips(),
            const SizedBox(height: 16),
            if (lastError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(lastError!, style: const TextStyle(color: Colors.red)),
              ),
            if (filteredTransactions.isEmpty)
              const Expanded(
                child: Center(child: Text('No transactions match your search or filters.')),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: filteredTransactions.length,
                  itemBuilder: (context, index) {
                    final txn = filteredTransactions[index];
                    return _buildTransactionCard(txn, currencySymbol);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChips() {
    const statuses = [
      {'value': 'all', 'label': 'All'},
      {'value': 'completed', 'label': 'Completed'},
      {'value': 'pending', 'label': 'Pending'},
      {'value': 'failed', 'label': 'Failed'},
      {'value': 'refunded', 'label': 'Refunded'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: statuses.map((status) {
          final value = status['value'] as String;
          final label = status['label'] as String;
          final selected = transactionStatusFilter == value;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(label),
              selected: selected,
              onSelected: (_) {
                setState(() {
                  transactionStatusFilter = value;
                });
                _updateTransactionFilter();
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> txn, String currencySymbol) {
    final status = txn['status']?.toString().toLowerCase() ?? 'unknown';
    final statusData = _transactionStatusData(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusData.color,
          child: Icon(statusData.icon, color: Colors.white),
        ),
        title: Text('Order #${txn['order_number'] ?? 'N/A'}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Gateway: ${txn['gateway_name'] ?? 'N/A'}'),
            Text('Transaction ID: ${txn['transaction_id'] ?? 'N/A'}'),
            Text('Date: ${txn['created_at'] ?? 'N/A'}'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${double.parse(txn['amount'].toString()).toStringAsFixed(2)} $currencySymbol',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              status.toUpperCase(),
              style: TextStyle(color: statusData.color, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        onTap: () => _showTransactionDetails(txn),
      ),
    );
  }

  _TransactionStatusData _transactionStatusData(String status) {
    switch (status) {
      case 'completed':
        return _TransactionStatusData(Colors.green, Icons.check_circle);
      case 'failed':
        return _TransactionStatusData(Colors.red, Icons.error);
      case 'pending':
        return _TransactionStatusData(Colors.orange, Icons.pending);
      case 'refunded':
        return _TransactionStatusData(Colors.blue, Icons.undo);
      default:
        return _TransactionStatusData(Colors.grey, Icons.help);
    }
  }

  void _showGatewayConfigDialog(Map<String, dynamic> gateway) {
    final apiKeyController = TextEditingController(text: gateway['api_key']?.toString() ?? '');
    final apiSecretController = TextEditingController(text: gateway['api_secret']?.toString() ?? '');
    final webhookSecretController = TextEditingController(text: gateway['webhook_secret']?.toString() ?? '');
    bool isActive = gateway['is_active'] == 1 || gateway['is_active'] == true;
    bool isTestMode = gateway['is_test_mode'] == 1 || gateway['is_test_mode'] == true;
    final formKey = GlobalKey<FormState>();
    bool dialogSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, dialogSetState) => AlertDialog(
          title: Text('Configure ${gateway['name']}'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: apiKeyController,
                    decoration: const InputDecoration(
                      labelText: 'API Key',
                      hintText: 'Enter your API key',
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'API key is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: apiSecretController,
                    decoration: const InputDecoration(
                      labelText: 'API Secret',
                      hintText: 'Enter your API secret',
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'API secret is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: webhookSecretController,
                    decoration: const InputDecoration(
                      labelText: 'Webhook Secret',
                      hintText: 'Enter webhook secret (optional)',
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Enable Gateway'),
                    value: isActive,
                    onChanged: (value) => dialogSetState(() => isActive = value),
                  ),
                  SwitchListTile(
                    title: const Text('Test Mode'),
                    subtitle: const Text('Use test credentials'),
                    value: isTestMode,
                    onChanged: (value) => dialogSetState(() => isTestMode = value),
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
              onPressed: dialogSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) {
                        return;
                      }

                      dialogSetState(() {
                        dialogSaving = true;
                      });

                      final data = {
                        'api_key': apiKeyController.text.trim(),
                        'api_secret': apiSecretController.text.trim(),
                        'webhook_secret': webhookSecretController.text.trim(),
                        'is_active': isActive ? 1 : 0,
                        'is_test_mode': isTestMode ? 1 : 0,
                      };

                      final response = await ApiService.put(
                        '${ApiConfig.paymentGatewayEndpoint}?gateway_id=${gateway['id']}',
                        data,
                      );

                      dialogSetState(() {
                        dialogSaving = false;
                      });

                      if (response['success'] == true) {
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Gateway configured successfully')),
                          );
                          await loadGateways();
                        }
                      } else {
                        final error = _extractErrorMessage(response, 'Failed to save gateway settings');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error)),
                          );
                        }
                      }
                    },
              child: dialogSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _testGateway(Map<String, dynamic> gateway) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Test Gateway'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Gateway: ${gateway['name']}'),
            const SizedBox(height: 12),
            Text(
              gateway['is_active'] == 1 || gateway['is_active'] == true
                  ? 'This gateway is active. Ensure credentials are valid before processing live payments.'
                  : 'This gateway is inactive. Enable it before you perform any test payments.',
            ),
            const SizedBox(height: 12),
            const Text(
              'Note: Live gateway validation is not available from the client. Update credentials and save to persist configuration.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
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
  }

  void _showTransactionDetails(Map<String, dynamic> txn) {
    final currencySymbol = context.watch<AppSettingsProvider>().currencySymbol;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Transaction Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('Transaction ID', txn['transaction_id'] ?? 'N/A'),
              _buildInfoRow('Order Number', txn['order_number'] ?? 'N/A'),
              _buildInfoRow('Gateway', txn['gateway_name'] ?? 'N/A'),
              _buildInfoRow('Amount', '${double.parse(txn['amount'].toString()).toStringAsFixed(2)} $currencySymbol'),
              _buildInfoRow('Currency', txn['currency'] ?? 'USD'),
              _buildInfoRow('Status', txn['status'] ?? 'N/A'),
              _buildInfoRow('Payment Method', txn['payment_method'] ?? 'N/A'),
              _buildInfoRow('Customer', txn['customer_name'] ?? 'N/A'),
              _buildInfoRow('Email', txn['customer_email'] ?? 'N/A'),
              _buildInfoRow('Date', txn['created_at'] ?? 'N/A'),
            ],
          ),
        ),
        actions: [
          if (txn['status'] == 'completed')
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _processRefund(txn);
              },
              child: const Text('Refund'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _processRefund(Map<String, dynamic> txn) {
    final amountController = TextEditingController(text: txn['amount']?.toString() ?? '0');
    final reasonController = TextEditingController();
    final refundFormKey = GlobalKey<FormState>();
    final originalAmount = double.tryParse(txn['amount']?.toString() ?? '0') ?? 0.0;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, dialogSetState) => AlertDialog(
          title: const Text('Process Refund'),
          content: Form(
            key: refundFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: amountController,
                  decoration: const InputDecoration(labelText: 'Refund Amount'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    final amount = double.tryParse(value?.trim() ?? '');
                    if (amount == null || amount <= 0) {
                      return 'Enter a valid amount';
                    }
                    if (amount > originalAmount) {
                      return 'Refund cannot exceed original amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: reasonController,
                  decoration: const InputDecoration(labelText: 'Reason'),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please provide a reason';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (!refundFormKey.currentState!.validate()) {
                        return;
                      }

                      final amount = double.tryParse(amountController.text.trim()) ?? 0.0;
                      final data = {
                        'transaction_id': txn['id'],
                        'amount': amount,
                        'reason': reasonController.text.trim(),
                      };

                      dialogSetState(() {
                        isSubmitting = true;
                      });

                      final response = await ApiService.post(
                        '${ApiConfig.paymentGatewayEndpoint}?refund=1',
                        data,
                      );

                      dialogSetState(() {
                        isSubmitting = false;
                      });

                      if (response['success'] == true) {
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Refund processed successfully')),
                          );
                          await loadTransactions();
                        }
                      } else {
                        final error = _extractErrorMessage(response, 'Refund failed');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error)),
                          );
                        }
                      }
                    },
              child: isSubmitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Process Refund'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionStatusData {
  final Color color;
  final IconData icon;

  _TransactionStatusData(this.color, this.icon);
}
