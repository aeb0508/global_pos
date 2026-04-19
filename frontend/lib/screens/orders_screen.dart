import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/receipt.dart';
import '../providers/app_settings_provider.dart';
import '../services/api_service.dart';
import '../services/receipt_service.dart';
import '../utils/api_config.dart';
import 'home_screen.dart';

enum _OrderStatus { all, completed, cancelled, refunded }

enum _OrderSortField { date, total, customer }

enum _SortDirection { asc, desc }

class OrdersScreen extends StatefulWidget {
  final String? initialSearch;
  const OrdersScreen({super.key, this.initialSearch});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with AutomaticKeepAliveClientMixin {
  List<dynamic> _orders = [];
  List<dynamic> _filteredOrders = [];
  bool _isLoading = true;
  String _searchQuery = '';
  late final TextEditingController _searchCtrl;
  _OrderStatus _selectedStatus = _OrderStatus.all;
  _OrderSortField _sortField = _OrderSortField.date;
  _SortDirection _sortDirection = _SortDirection.desc;
  DateTime? _startDate;
  DateTime? _endDate;
  late final ScrollController _scrollController;

  final int _pageSize = 10;
  int _currentPage = 1;
  List<dynamic> _displayedOrders = [];
  bool _hasMore = false;

  @override
  bool get wantKeepAlive => false; // Don't keep alive, always refresh

  @override
  void initState() {
    super.initState();
    _searchQuery = widget.initialSearch ?? '';
    _searchCtrl = TextEditingController(text: _searchQuery);
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _loadOrders();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreOrders();
    }
  }

  void _resetPagination() {
    _currentPage = 1;
    final end = _pageSize.clamp(0, _filteredOrders.length);
    _displayedOrders = _filteredOrders.take(end).toList();
    _hasMore = _filteredOrders.length > end;
  }

  void _loadMoreOrders() {
    if (!_hasMore) return;
    setState(() {
      _currentPage++;
      final end = (_currentPage * _pageSize).clamp(0, _filteredOrders.length);
      _displayedOrders = _filteredOrders.take(end).toList();
      _hasMore = _displayedOrders.length < _filteredOrders.length;
    });
  }

  Future<void> _loadOrders({bool clearSearch = false}) async {
    if (clearSearch) {
      _searchQuery = '';
      _searchCtrl.clear();
    }
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get(ApiConfig.ordersEndpoint);

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        setState(() {
          _orders = (data is List)
              ? data.where((order) => order['status'] != 'pending').toList()
              : [];
          _filteredOrders = List.from(_orders);
          _isLoading = false;
        });
        _resetPagination();
        if (_searchQuery.isNotEmpty) _applyFiltersAndSort();
      } else {
        setState(() {
          _orders = [];
          _filteredOrders = [];
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading orders: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        _orders = [];
        _filteredOrders = [];
        _isLoading = false;
      });
    }
  }

  void _applyFiltersAndSort() {
    if (_orders.isEmpty) {
      setState(() => _filteredOrders = []);
      return;
    }

    List<dynamic> filtered = List.from(_orders);

    // Apply status filter
    if (_selectedStatus != _OrderStatus.all) {
      final statusStr = _selectedStatus.toString().split('.').last;
      filtered = filtered
          .where((order) =>
              (order['status'] ?? '').toString().toLowerCase() == statusStr)
          .toList();
    }

    // Apply date range filter
    if (_startDate != null || _endDate != null) {
      filtered = filtered.where((order) {
        final orderDate = DateTime.parse(order['created_at']);
        if (_startDate != null && orderDate.isBefore(_startDate!)) return false;
        if (_endDate != null &&
            orderDate.isAfter(_endDate!.add(const Duration(days: 1)))) {
          return false;
        }
        return true;
      }).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((order) {
        final orderNumber =
            (order['order_number'] ?? '').toString().toLowerCase();
        final customer =
            (order['customer_name'] ?? '').toString().toLowerCase();
        final cashier = (order['cashier_name'] ?? '').toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        return orderNumber.contains(query) ||
            customer.contains(query) ||
            cashier.contains(query);
      }).toList();
    }

    // Apply sorting
    _applySorting(filtered);

    setState(() {
      _filteredOrders = filtered;
    });
    _resetPagination();
  }

  void _applySorting(List<dynamic> orders) {
    if (orders.isEmpty) {
      debugPrint('Sorting skipped: orders list is empty');
      return;
    }

    try {
      orders.sort((a, b) {
        if (a == null || b == null) return 0;

        dynamic aValue, bValue;

        switch (_sortField) {
          case _OrderSortField.date:
            try {
              aValue = DateTime.parse(a['created_at'] ?? '');
              bValue = DateTime.parse(b['created_at'] ?? '');
            } catch (e) {
              return 0;
            }
            break;
          case _OrderSortField.total:
            aValue = double.tryParse(a['total']?.toString() ?? '0') ?? 0;
            bValue = double.tryParse(b['total']?.toString() ?? '0') ?? 0;
            break;
          case _OrderSortField.customer:
            aValue = (a['customer_name'] ?? '').toString().toLowerCase();
            bValue = (b['customer_name'] ?? '').toString().toLowerCase();
            break;
        }

        int comparison = 0;
        if (aValue is DateTime && bValue is DateTime) {
          comparison = aValue.compareTo(bValue);
        } else if (aValue is num && bValue is num) {
          comparison = aValue.compareTo(bValue);
        } else if (aValue is String && bValue is String) {
          comparison = aValue.compareTo(bValue);
        }

        return _sortDirection == _SortDirection.asc ? comparison : -comparison;
      });
    } catch (e) {
      debugPrint('Error sorting orders: $e');
    }
  }

  Future<void> _deleteOrder(dynamic order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Order'),
        content: Text(
            'Are you sure you want to delete Order #${order['order_number']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final response = await ApiService.delete(
            '${ApiConfig.ordersEndpoint}?id=${order['id']}');
        if (response['success'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Order deleted successfully')),
            );
          }
          _loadOrders();
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      Text(response['message'] ?? 'Failed to delete order')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _editOrder(dynamic order) async {
    try {
      debugPrint('Editing order: ${order['id']}');
      final response =
          await ApiService.get('${ApiConfig.ordersEndpoint}?id=${order['id']}');
      debugPrint('Edit order response: $response');
      if (response['success'] == true && response['data'] != null && mounted) {
        final orderDetails = response['data'];
        debugPrint(
            'Navigating to POS with order: ${orderDetails['order_number']}');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              initialIndex: 1,
              orderToEdit: orderDetails,
            ),
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(response['message'] ?? 'Failed to load order')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error editing order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading order: $e')),
        );
      }
    }
  }

  Future<void> _viewOrderDetails(dynamic order) async {
    try {
      debugPrint('Viewing order details: ${order['id']}');
      final response =
          await ApiService.get('${ApiConfig.ordersEndpoint}?id=${order['id']}');
      debugPrint('View details response: $response');
      if (response['success'] == true && response['data'] != null && mounted) {
        final orderDetails = response['data'];
        showDialog(
          context: context,
          builder: (context) => _OrderDetailsDialog(order: orderDetails),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    response['message'] ?? 'Failed to load order details')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error viewing order details: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading order details: $e')),
        );
      }
    }
  }

  Future<void> _printReceipt(dynamic order) async {
    try {
      debugPrint('Printing receipt for order: ${order['id']}');
      final response =
          await ApiService.get('${ApiConfig.ordersEndpoint}?id=${order['id']}');
      debugPrint('Print receipt response: $response');
      if (response['success'] == true && response['data'] != null) {
        final orderDetails = response['data'];
        final itemsList = orderDetails['items'];
        debugPrint('Order items: $itemsList');

        if (itemsList == null || itemsList is! List || itemsList.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No items found in order')),
            );
          }
          return;
        }

        final items = itemsList
            .map((item) => ReceiptItem(
                  name: item['product_name'] ?? 'Unknown',
                  quantity:
                      int.tryParse(item['quantity']?.toString() ?? '0') ?? 0,
                  price:
                      double.tryParse(item['unit_price']?.toString() ?? '0') ??
                          0.0,
                  total:
                      double.tryParse(item['total_price']?.toString() ?? '0') ??
                          0.0,
                ))
            .toList();

        final receipt = Receipt(
          orderId: order['id'].toString(),
          orderNumber: order['order_number'] ?? 'N/A',
          date: DateTime.tryParse(order['created_at'] ?? '') ?? DateTime.now(),
          items: items,
          subtotal: double.tryParse((order['subtotal'] ?? 0).toString()) ?? 0.0,
          tax: double.tryParse((order['tax'] ?? 0).toString()) ?? 0.0,
          total: double.tryParse(order['total']?.toString() ?? '0') ?? 0.0,
          paymentMethod: order['payment_method'] ?? 'N/A',
          amountPaid: double.tryParse(order['total']?.toString() ?? '0') ?? 0.0,
          change: 0.0,
          cashierName: order['cashier_name'] ?? 'Cashier',
          customerName: order['customer_name'],
        );

        debugPrint('Receipt created, printing...');
        if (!mounted) return;
        await ReceiptService.printReceipt(receipt, context);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(response['message'] ?? 'Failed to load order')),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error printing receipt: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    return CustomScrollView(
      controller: _scrollController,
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverAppBar(
          floating: true,
          pinned: true,
          expandedHeight: 120,
          automaticallyImplyLeading: false,
          title: const Row(
            children: [
              Icon(Icons.receipt_long, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Orders',
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
                  colors: [Colors.indigo.shade600, Colors.indigo.shade800],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    TextField(
                      controller: _searchCtrl,
                      onChanged: (value) {
                        _searchQuery = value;
                        _applyFiltersAndSort();
                      },
                      decoration: InputDecoration(
                        prefixIcon:
                            const Icon(Icons.search, color: Colors.white70),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear,
                                    color: Colors.white70, size: 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  _searchQuery = '';
                                  _applyFiltersAndSort();
                                },
                              )
                            : null,
                        hintText: 'Search orders by number...',
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.15),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        hintStyle: const TextStyle(color: Colors.white70),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () =>
                  _loadOrders(clearSearch: widget.initialSearch != null),
              tooltip: 'Refresh',
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats Row - Responsive
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 600) {
                      // Mobile: Stack vertically
                      return Column(
                        children: [
                          _StatCard(
                            label: 'Total Orders',
                            value: '${_orders.length}',
                            icon: Icons.receipt_rounded,
                            color: Colors.blue,
                          ),
                          const SizedBox(height: 12),
                          _StatCard(
                            label: 'Total Revenue',
                            value:
                                '${_calculateTotalRevenue().toStringAsFixed(2)} ${context.watch<AppSettingsProvider>().currencySymbol}',
                            icon: Icons.attach_money,
                            color: Colors.green,
                          ),
                          const SizedBox(height: 12),
                          _StatCard(
                            label: 'Avg Order Value',
                            value:
                                '${_calculateAverageOrder().toStringAsFixed(2)} ${context.watch<AppSettingsProvider>().currencySymbol}',
                            icon: Icons.trending_up,
                            color: Colors.orange,
                          ),
                        ],
                      );
                    }
                    // Desktop: Row
                    return Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Total Orders',
                            value: '${_orders.length}',
                            icon: Icons.receipt_rounded,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: 'Total Revenue',
                            value:
                                '${_calculateTotalRevenue().toStringAsFixed(2)} ${context.watch<AppSettingsProvider>().currencySymbol}',
                            icon: Icons.attach_money,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: 'Avg Order Value',
                            value:
                                '${_calculateAverageOrder().toStringAsFixed(2)} ${context.watch<AppSettingsProvider>().currencySymbol}',
                            icon: Icons.trending_up,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                // Filters Row
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 600;

                    if (isMobile) {
                      // Mobile layout: Stack vertically
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DropdownButtonFormField<_OrderStatus>(
                            isExpanded: true,
                            initialValue: _selectedStatus,
                            decoration: const InputDecoration(
                              labelText: 'Status',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: _OrderStatus.all,
                                  child: Text('All Status')),
                              DropdownMenuItem(
                                  value: _OrderStatus.completed,
                                  child: Text('Completed')),
                              DropdownMenuItem(
                                  value: _OrderStatus.cancelled,
                                  child: Text('Cancelled')),
                              DropdownMenuItem(
                                  value: _OrderStatus.refunded,
                                  child: Text('Refunded')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedStatus = value;
                                });
                                _applyFiltersAndSort();
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<_OrderSortField>(
                                  isExpanded: true,
                                  initialValue: _sortField,
                                  decoration: const InputDecoration(
                                    labelText: 'Sort by',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                        value: _OrderSortField.date,
                                        child: Text('Date')),
                                    DropdownMenuItem(
                                        value: _OrderSortField.total,
                                        child: Text('Total')),
                                    DropdownMenuItem(
                                        value: _OrderSortField.customer,
                                        child: Text('Customer')),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _sortField = value;
                                      });
                                      _applyFiltersAndSort();
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                height: 48,
                                width: 48,
                                child: IconButton(
                                  icon: Icon(
                                    _sortDirection == _SortDirection.asc
                                        ? Icons.arrow_upward
                                        : Icons.arrow_downward,
                                  ),
                                  tooltip: 'Toggle sort order',
                                  onPressed: () {
                                    setState(() {
                                      _sortDirection =
                                          _sortDirection == _SortDirection.asc
                                              ? _SortDirection.desc
                                              : _SortDirection.asc;
                                    });
                                    _applyFiltersAndSort();
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          FilledButton.tonal(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _startDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) {
                                setState(() => _startDate = date);
                                _applyFiltersAndSort();
                              }
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.date_range, size: 18),
                                const SizedBox(width: 8),
                                Text(_startDate == null
                                    ? 'Start Date'
                                    : DateFormat('MMM dd, yyyy')
                                        .format(_startDate!)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.tonal(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _endDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) {
                                setState(() => _endDate = date);
                                _applyFiltersAndSort();
                              }
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.date_range, size: 18),
                                const SizedBox(width: 8),
                                Text(_endDate == null
                                    ? 'End Date'
                                    : DateFormat('MMM dd, yyyy')
                                        .format(_endDate!)),
                              ],
                            ),
                          ),
                          if (_startDate != null || _endDate != null) ...[
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _startDate = null;
                                  _endDate = null;
                                });
                                _applyFiltersAndSort();
                              },
                              child: const Text('Clear Dates'),
                            ),
                          ],
                        ],
                      );
                    }

                    // Desktop layout
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 180,
                              child: DropdownButtonFormField<_OrderStatus>(
                                isExpanded: true,
                                initialValue: _selectedStatus,
                                decoration: const InputDecoration(
                                  labelText: 'Status',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                items: const [
                                  DropdownMenuItem(
                                      value: _OrderStatus.all,
                                      child: Text('All Status')),
                                  DropdownMenuItem(
                                      value: _OrderStatus.completed,
                                      child: Text('Completed')),
                                  DropdownMenuItem(
                                      value: _OrderStatus.cancelled,
                                      child: Text('Cancelled')),
                                  DropdownMenuItem(
                                      value: _OrderStatus.refunded,
                                      child: Text('Refunded')),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _selectedStatus = value;
                                    });
                                    _applyFiltersAndSort();
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 180,
                              child: DropdownButtonFormField<_OrderSortField>(
                                isExpanded: true,
                                initialValue: _sortField,
                                decoration: const InputDecoration(
                                  labelText: 'Sort by',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                items: const [
                                  DropdownMenuItem(
                                      value: _OrderSortField.date,
                                      child: Text('Date')),
                                  DropdownMenuItem(
                                      value: _OrderSortField.total,
                                      child: Text('Total')),
                                  DropdownMenuItem(
                                      value: _OrderSortField.customer,
                                      child: Text('Customer')),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _sortField = value;
                                    });
                                    _applyFiltersAndSort();
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 46,
                              child: IconButton(
                                icon: Icon(
                                  _sortDirection == _SortDirection.asc
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward,
                                ),
                                tooltip: 'Toggle sort order',
                                onPressed: () {
                                  setState(() {
                                    _sortDirection =
                                        _sortDirection == _SortDirection.asc
                                            ? _SortDirection.desc
                                            : _SortDirection.asc;
                                  });
                                  _applyFiltersAndSort();
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.tonal(
                                onPressed: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: _startDate ?? DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now(),
                                  );
                                  if (date != null) {
                                    setState(() => _startDate = date);
                                    _applyFiltersAndSort();
                                  }
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.date_range, size: 18),
                                    const SizedBox(width: 8),
                                    Text(_startDate == null
                                        ? 'Start Date'
                                        : DateFormat('MMM dd, yyyy')
                                            .format(_startDate!)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.tonal(
                                onPressed: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: _endDate ?? DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now(),
                                  );
                                  if (date != null) {
                                    setState(() => _endDate = date);
                                    _applyFiltersAndSort();
                                  }
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.date_range, size: 18),
                                    const SizedBox(width: 8),
                                    Text(_endDate == null
                                        ? 'End Date'
                                        : DateFormat('MMM dd, yyyy')
                                            .format(_endDate!)),
                                  ],
                                ),
                              ),
                            ),
                            if (_startDate != null || _endDate != null)
                              const SizedBox(width: 12),
                            if (_startDate != null || _endDate != null)
                              SizedBox(
                                height: 40,
                                child: OutlinedButton(
                                  onPressed: () {
                                    setState(() {
                                      _startDate = null;
                                      _endDate = null;
                                    });
                                    _applyFiltersAndSort();
                                  },
                                  child: const Text('Clear Dates'),
                                ),
                              ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        // Orders list
        if (_filteredOrders.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No orders found',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index >= _displayedOrders.length) {
                    return const SizedBox.shrink();
                  }
                  final order = _displayedOrders[index];
                  if (order == null) return const SizedBox.shrink();
                  return _OrderCard(
                    order: order,
                    onPrint: () => _printReceipt(order),
                    onEdit: () => _editOrder(order),
                    onDelete: () => _deleteOrder(order),
                    onTap: () => _viewOrderDetails(order),
                  );
                },
                childCount: _displayedOrders.length,
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: _hasMore
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                )
              : const SizedBox(height: 16),
        ),
      ],
    );
  }

  double _calculateTotalRevenue() {
    return _orders.fold(0.0, (sum, order) {
      return sum + double.parse(order['total'].toString());
    });
  }

  double _calculateAverageOrder() {
    if (_orders.isEmpty) return 0.0;
    return _calculateTotalRevenue() / _orders.length;
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.color = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatefulWidget {
  final dynamic order;
  final VoidCallback onPrint;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _OrderCard({
    required this.order,
    required this.onPrint,
    required this.onEdit,
    required this.onDelete,
    required this.onTap,
  });

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Color _getStatusColor(String status) {
    final statusLower = status.toLowerCase();
    if (statusLower.contains('completed')) return Colors.green;
    if (statusLower.contains('pending')) return Colors.orange;
    if (statusLower.contains('cancelled')) return Colors.red;
    if (statusLower.contains('refunded')) return Colors.purple;
    return Colors.grey;
  }

  IconData _getStatusIcon(String status) {
    final statusLower = status.toLowerCase();
    if (statusLower.contains('completed')) return Icons.check_circle;
    if (statusLower.contains('pending')) return Icons.schedule;
    if (statusLower.contains('cancelled')) return Icons.cancel;
    if (statusLower.contains('refunded')) return Icons.assignment_return;
    return Icons.info;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final order = widget.order;
    final cs = Theme.of(context).colorScheme;
    if (order == null) return const SizedBox.shrink();

    try {
      final date = DateTime.parse(
          order['created_at'] ?? DateTime.now().toIso8601String());
      final status = (order['status'] ?? 'completed').toString();
      if (status.isEmpty) throw Exception('Empty status field');
      final statusColor = _getStatusColor(status);
      final total = double.tryParse(order['total']?.toString() ?? '0') ?? 0.0;

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 600;

                  if (isMobile) {
                    // Mobile layout: Stack vertically
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(_getStatusIcon(status),
                                color: statusColor, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '#${order['order_number']}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: statusColor.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                status[0].toUpperCase() + status.substring(1),
                                style: TextStyle(
                                    color: statusColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat('MMM dd, yyyy • HH:mm').format(date),
                          style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurface.withValues(alpha: 0.5)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order['customer_name'] ?? 'Walk-in',
                          style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurface.withValues(alpha: 0.7)),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${total.toStringAsFixed(2)} ${context.watch<AppSettingsProvider>().currencySymbol}',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade600),
                              ),
                            ),
                            IconButton(
                              onPressed: widget.onEdit,
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              tooltip: 'Edit',
                              visualDensity: VisualDensity.compact,
                              color: Colors.blue,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                            ),
                            IconButton(
                              onPressed: widget.onDelete,
                              icon: const Icon(Icons.delete_outline, size: 18),
                              tooltip: 'Delete',
                              visualDensity: VisualDensity.compact,
                              color: Colors.red,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                            ),
                            IconButton(
                              onPressed: widget.onPrint,
                              icon: const Icon(Icons.print_outlined, size: 18),
                              tooltip: 'Print',
                              visualDensity: VisualDensity.compact,
                              color: cs.primary,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }

                  // Desktop layout: Horizontal
                  return Row(
                    children: [
                      Icon(_getStatusIcon(status),
                          color: statusColor, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '#${order['order_number']}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              DateFormat('MMM dd, yyyy • HH:mm').format(date),
                              style: TextStyle(
                                  fontSize: 11,
                                  color: cs.onSurface.withValues(alpha: 0.5)),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          order['customer_name'] ?? 'Walk-in',
                          style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurface.withValues(alpha: 0.7)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: statusColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          status[0].toUpperCase() + status.substring(1),
                          style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${total.toStringAsFixed(2)} ${context.watch<AppSettingsProvider>().currencySymbol}',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade600),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: widget.onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        tooltip: 'Edit',
                        visualDensity: VisualDensity.compact,
                        color: Colors.blue,
                      ),
                      IconButton(
                        onPressed: widget.onDelete,
                        icon: const Icon(Icons.delete_outline, size: 18),
                        tooltip: 'Delete',
                        visualDensity: VisualDensity.compact,
                        color: Colors.red,
                      ),
                      IconButton(
                        onPressed: widget.onPrint,
                        icon: const Icon(Icons.print_outlined, size: 18),
                        tooltip: 'Print',
                        visualDensity: VisualDensity.compact,
                        color: cs.primary,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error rendering order card: $e');
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
              'Error: ${widget.order['order_number'] ?? 'Unknown'} — $e',
              style: TextStyle(fontSize: 12, color: Colors.red.shade700)),
        ),
      );
    }
  }
}

class _OrderDetailsDialog extends StatelessWidget {
  final dynamic order;

  const _OrderDetailsDialog({required this.order});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = (order['items'] as List?) ?? [];
    final subtotal =
        double.tryParse(order['subtotal']?.toString() ?? '0') ?? 0.0;
    final tax = double.tryParse(order['tax']?.toString() ?? '0') ?? 0.0;
    final discount =
        double.tryParse(order['discount']?.toString() ?? '0') ?? 0.0;
    final total = double.tryParse(order['total']?.toString() ?? '0') ?? 0.0;
    final date =
        DateTime.parse(order['created_at'] ?? DateTime.now().toIso8601String());

    return Dialog(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Row(
                children: [
                  Icon(Icons.receipt_long, color: cs.primary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${order['order_number']}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: cs.onPrimaryContainer,
                          ),
                        ),
                        Text(
                          DateFormat('MMM dd, yyyy • HH:mm').format(date),
                          style: TextStyle(
                            fontSize: 13,
                            color: cs.onPrimaryContainer.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    color: cs.onPrimaryContainer,
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order Info
                    Row(
                      children: [
                        Expanded(
                          child: _InfoCard(
                            label: 'Customer',
                            value: order['customer_name'] ?? 'Walk-in',
                            icon: Icons.person,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _InfoCard(
                            label: 'Cashier',
                            value: order['cashier_name'] ?? 'N/A',
                            icon: Icons.badge,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _InfoCard(
                            label: 'Payment',
                            value: (order['payment_method'] ?? 'cash')
                                .toString()
                                .toUpperCase(),
                            icon: Icons.payment,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _InfoCard(
                            label: 'Status',
                            value: (order['status'] ?? 'completed')
                                .toString()
                                .toUpperCase(),
                            icon: Icons.info,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Items
                    Text(
                      'Order Items',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: cs.outline.withValues(alpha: 0.2)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest
                                  .withValues(alpha: 0.5),
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12)),
                            ),
                            child: const Row(
                              children: [
                                Expanded(
                                    flex: 3,
                                    child: Text('Product',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13))),
                                Expanded(
                                    child: Text('Qty',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13))),
                                Expanded(
                                    child: Text('Price',
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13))),
                                Expanded(
                                    child: Text('Total',
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13))),
                              ],
                            ),
                          ),
                          // Items
                          ...items.asMap().entries.map((entry) {
                            final index = entry.key;
                            final item = entry.value;
                            final isLast = index == items.length - 1;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                border: isLast
                                    ? null
                                    : Border(
                                        bottom: BorderSide(
                                            color: cs.outline
                                                .withValues(alpha: 0.1))),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      item['product_name'] ?? 'Unknown',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      item['quantity']?.toString() ?? '0',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '${double.tryParse(item['unit_price']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0.00'} ${context.watch<AppSettingsProvider>().currencySymbol}',
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '${double.tryParse(item['total_price']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0.00'} ${context.watch<AppSettingsProvider>().currencySymbol}',
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Summary
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                            cs.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: cs.outline.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        children: [
                          _SummaryRow(
                              label: 'Subtotal',
                              value:
                                  '${subtotal.toStringAsFixed(2)} ${context.watch<AppSettingsProvider>().currencySymbol}'),
                          if (discount > 0) ...[
                            const SizedBox(height: 8),
                            _SummaryRow(
                                label: 'Discount',
                                value:
                                    '-${discount.toStringAsFixed(2)} ${context.watch<AppSettingsProvider>().currencySymbol}',
                                valueColor: Colors.red)
                          ],
                          const SizedBox(height: 8),
                          _SummaryRow(
                              label: 'Tax',
                              value:
                                  '${tax.toStringAsFixed(2)} ${context.watch<AppSettingsProvider>().currencySymbol}'),
                          const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Divider(height: 1)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              Text(
                                '${total.toStringAsFixed(2)} ${context.watch<AppSettingsProvider>().currencySymbol}',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: cs.primary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoCard(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurface.withValues(alpha: 0.6))),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryRow(
      {required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        Text(value,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: valueColor)),
      ],
    );
  }
}
