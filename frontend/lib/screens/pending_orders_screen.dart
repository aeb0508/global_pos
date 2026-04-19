import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/receipt.dart';
import '../providers/app_settings_provider.dart';
import '../services/api_service.dart';
import '../services/receipt_service.dart';
import '../utils/api_config.dart';
import 'home_screen.dart';

enum _SortField { date, total, customer }

enum _SortDir { asc, desc }

class PendingOrdersScreen extends StatefulWidget {
  final String? initialSearch;
  const PendingOrdersScreen({super.key, this.initialSearch});

  @override
  State<PendingOrdersScreen> createState() => _PendingOrdersScreenState();
}

class _PendingOrdersScreenState extends State<PendingOrdersScreen>
    with AutomaticKeepAliveClientMixin {
  List<dynamic> _all = [];
  List<dynamic> _filtered = [];
  List<dynamic> _displayed = [];
  bool _isLoading = true;
  String _searchQuery = '';
  late final TextEditingController _searchCtrl;
  _SortField _sortField = _SortField.date;
  _SortDir _sortDir = _SortDir.desc;
  DateTime? _startDate;
  DateTime? _endDate;
  final ScrollController _scrollController = ScrollController();
  static const int _pageSize = 10;
  int _currentPage = 1;
  bool _hasMore = false;

  @override
  bool get wantKeepAlive => false;

  @override
  void initState() {
    super.initState();
    _searchQuery = widget.initialSearch ?? '';
    _searchCtrl = TextEditingController(text: _searchQuery);
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load({bool clearSearch = false}) async {
    if (clearSearch) {
      _searchQuery = '';
      _searchCtrl.clear();
    }
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.get(ApiConfig.ordersEndpoint);
      if (res['success'] == true && res['data'] != null) {
        final data = res['data'] as List? ?? [];
        setState(() {
          _all = data.where((o) => o['status'] == 'pending').toList();
          _isLoading = false;
        });
        _applyFilters();
      } else {
        setState(() {
          _all = [];
          _filtered = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _all = [];
        _filtered = [];
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _applySearch(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void _applyFilters() {
    var list = List<dynamic>.from(_all);

    // Search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((o) {
        return (o['order_number'] ?? '').toString().toLowerCase().contains(q) ||
            (o['customer_name'] ?? '').toString().toLowerCase().contains(q) ||
            (o['cashier_name'] ?? '').toString().toLowerCase().contains(q);
      }).toList();
    }

    // Date range
    if (_startDate != null || _endDate != null) {
      list = list.where((o) {
        final d = DateTime.parse(o['created_at']);
        if (_startDate != null && d.isBefore(_startDate!)) return false;
        if (_endDate != null &&
            d.isAfter(_endDate!.add(const Duration(days: 1)))) {
          return false;
        }
        return true;
      }).toList();
    }

    // Sort
    list.sort((a, b) {
      int cmp;
      switch (_sortField) {
        case _SortField.total:
          cmp = (double.tryParse(a['total'].toString()) ?? 0)
              .compareTo(double.tryParse(b['total'].toString()) ?? 0);
        case _SortField.customer:
          cmp = (a['customer_name'] ?? '')
              .toString()
              .compareTo((b['customer_name'] ?? '').toString());
        case _SortField.date:
          cmp = DateTime.parse(a['created_at'])
              .compareTo(DateTime.parse(b['created_at']));
      }
      return _sortDir == _SortDir.asc ? cmp : -cmp;
    });

    setState(() => _filtered = list);
    _resetPagination();
  }

  void _resetPagination() {
    _currentPage = 1;
    _displayed = _filtered.take(_pageSize).toList();
    _hasMore = _filtered.length > _pageSize;
    if (mounted) setState(() {});
  }

  void _onScroll() {
    if (!_hasMore) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      setState(() {
        _currentPage++;
        _displayed = _filtered.take(_currentPage * _pageSize).toList();
        _hasMore = _displayed.length < _filtered.length;
      });
    }
  }

  Future<void> _completeOrder(dynamic order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete Order'),
        content: Text('Mark Order #${order['order_number']} as completed?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Complete')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final res = await ApiService.put(
          '${ApiConfig.ordersEndpoint}?id=${order['id']}',
          {'status': 'completed'});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res['message'] ?? 'Done'),
          backgroundColor: res['success'] == true ? Colors.green : Colors.red,
        ));
        if (res['success'] == true) _load(clearSearch: false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _editOrder(dynamic order) async {
    try {
      final response =
          await ApiService.get('${ApiConfig.ordersEndpoint}?id=${order['id']}');
      if (response['success'] == true && response['data'] != null && mounted) {
        final orderDetails = response['data'];
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              initialIndex: 1,
              orderToEdit: orderDetails,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading order: $e')),
        );
      }
    }
  }

  Future<void> _viewOrderDetails(dynamic order) async {
    try {
      final res =
          await ApiService.get('${ApiConfig.ordersEndpoint}?id=${order['id']}');
      if (res['success'] == true && res['data'] != null && mounted) {
        final orderDetails = res['data'];
        showDialog(
          context: context,
          builder: (context) => _OrderDetailsDialog(order: orderDetails),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading order details: $e')),
        );
      }
    }
  }

  Future<void> _deleteOrder(dynamic order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Order'),
        content: Text('Delete Order #${order['order_number']}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final res = await ApiService.delete(
          '${ApiConfig.ordersEndpoint}?id=${order['id']}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res['message'] ?? 'Done'),
          backgroundColor: res['success'] == true ? Colors.green : Colors.red,
        ));
        if (res['success'] == true) _load(clearSearch: false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _printReceipt(dynamic order) async {
    try {
      final res =
          await ApiService.get('${ApiConfig.ordersEndpoint}?id=${order['id']}');
      if (res['success'] == true && res['data'] != null) {
        final details = res['data'];
        final items = (details['items'] as List)
            .map((i) => ReceiptItem(
                  name: i['product_name'],
                  quantity: int.parse(i['quantity'].toString()),
                  price: double.parse(i['unit_price'].toString()),
                  total: double.parse(i['total_price'].toString()),
                ))
            .toList();
        final receipt = Receipt(
          orderId: order['id'].toString(),
          orderNumber: order['order_number'],
          date: DateTime.parse(order['created_at']),
          items: items,
          subtotal: double.parse((order['subtotal'] ?? 0).toString()),
          tax: double.parse((order['tax'] ?? 0).toString()),
          total: double.parse(order['total'].toString()),
          paymentMethod: 'N/A',
          amountPaid: double.parse(order['total'].toString()),
          change: 0.0,
          cashierName: order['cashier_name'] ?? 'Cashier',
          customerName: order['customer_name'],
        );
        if (!mounted) return;
        await ReceiptService.printReceipt(receipt, context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  double get _totalRevenue =>
      _all.fold(0.0, (s, o) => s + double.parse(o['total'].toString()));

  double get _avgOrder => _all.isEmpty ? 0.0 : _totalRevenue / _all.length;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
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
                      Icon(Icons.schedule, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('Pending Orders',
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
                          colors: [
                            Colors.orange.shade600,
                            Colors.orange.shade800,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(
                            left: 16, right: 16, bottom: 16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // const Text(
                            //   'Pending Orders',
                            //   style: TextStyle(
                            //     fontSize: 24,
                            //     fontWeight: FontWeight.bold,
                            //     color: Colors.white,
                            //   ),
                            // ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _searchCtrl,
                              onChanged: _applySearch,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.search,
                                    color: Colors.white70),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear,
                                            color: Colors.white70, size: 18),
                                        onPressed: () {
                                          _searchCtrl.clear();
                                          _applySearch('');
                                        },
                                      )
                                    : null,
                                hintText: 'Search pending orders...',
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.15),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                hintStyle:
                                    const TextStyle(color: Colors.white70),
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
                      onPressed: () => _load(clearSearch: true),
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
                        // Stat cards
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth < 600) {
                              // Mobile: Stack vertically
                              return Column(
                                children: [
                                  _StatCard(
                                    label: 'Pending Orders',
                                    value: '${_all.length}',
                                    icon: Icons.schedule_rounded,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(height: 12),
                                  _StatCard(
                                    label: 'Total Value',
                                    value:
                                        '${_totalRevenue.toStringAsFixed(2)} ${context.watch<AppSettingsProvider>().currencySymbol}',
                                    icon: Icons.attach_money,
                                    color: Colors.blue,
                                  ),
                                  const SizedBox(height: 12),
                                  _StatCard(
                                    label: 'Avg Order Value',
                                    value:
                                        '${_avgOrder.toStringAsFixed(2)} ${context.watch<AppSettingsProvider>().currencySymbol}',
                                    icon: Icons.trending_up,
                                    color: Colors.purple,
                                  ),
                                ],
                              );
                            }
                            // Desktop: Row
                            return Row(
                              children: [
                                Expanded(
                                  child: _StatCard(
                                    label: 'Pending Orders',
                                    value: '${_all.length}',
                                    icon: Icons.schedule_rounded,
                                    color: Colors.orange,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _StatCard(
                                    label: 'Total Value',
                                    value:
                                        '${_totalRevenue.toStringAsFixed(2)} ${context.watch<AppSettingsProvider>().currencySymbol}',
                                    icon: Icons.attach_money,
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _StatCard(
                                    label: 'Avg Order Value',
                                    value:
                                        '${_avgOrder.toStringAsFixed(2)} ${context.watch<AppSettingsProvider>().currencySymbol}',
                                    icon: Icons.trending_up,
                                    color: Colors.purple,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        // Filters row
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isMobile = constraints.maxWidth < 600;
                            
                            if (isMobile) {
                              // Mobile layout
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: DropdownButtonFormField<_SortField>(
                                          isExpanded: true,
                                          initialValue: _sortField,
                                          decoration: const InputDecoration(
                                            labelText: 'Sort by',
                                            border: OutlineInputBorder(),
                                            isDense: true,
                                          ),
                                          items: const [
                                            DropdownMenuItem(
                                                value: _SortField.date,
                                                child: Text('Date')),
                                            DropdownMenuItem(
                                                value: _SortField.total,
                                                child: Text('Total')),
                                            DropdownMenuItem(
                                                value: _SortField.customer,
                                                child: Text('Customer')),
                                          ],
                                          onChanged: (v) {
                                            if (v != null) {
                                              setState(() => _sortField = v);
                                            }
                                            _applyFilters();
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        height: 48,
                                        width: 48,
                                        child: IconButton(
                                          icon: Icon(
                                            _sortDir == _SortDir.asc
                                                ? Icons.arrow_upward
                                                : Icons.arrow_downward,
                                          ),
                                          tooltip: 'Toggle sort order',
                                          onPressed: () {
                                            setState(() => _sortDir =
                                                _sortDir == _SortDir.asc
                                                    ? _SortDir.desc
                                                    : _SortDir.asc);
                                            _applyFilters();
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  FilledButton.tonal(
                                    onPressed: () async {
                                      final d = await showDatePicker(
                                        context: context,
                                        initialDate: _startDate ?? DateTime.now(),
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime.now(),
                                      );
                                      if (d != null) {
                                        setState(() => _startDate = d);
                                        _applyFilters();
                                      }
                                    },
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.date_range, size: 16),
                                        const SizedBox(width: 6),
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
                                      final d = await showDatePicker(
                                        context: context,
                                        initialDate: _endDate ?? DateTime.now(),
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime.now(),
                                      );
                                      if (d != null) {
                                        setState(() => _endDate = d);
                                        _applyFilters();
                                      }
                                    },
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.date_range, size: 16),
                                        const SizedBox(width: 6),
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
                                        _applyFilters();
                                      },
                                      child: const Text('Clear Dates'),
                                    ),
                                  ],
                                ],
                              );
                            }
                            
                            // Desktop layout
                            return Column(
                              children: [
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 160,
                                      child: DropdownButtonFormField<_SortField>(
                                        isExpanded: true,
                                        initialValue: _sortField,
                                        decoration: const InputDecoration(
                                          labelText: 'Sort by',
                                          border: OutlineInputBorder(),
                                          isDense: true,
                                        ),
                                        items: const [
                                          DropdownMenuItem(
                                              value: _SortField.date,
                                              child: Text('Date')),
                                          DropdownMenuItem(
                                              value: _SortField.total,
                                              child: Text('Total')),
                                          DropdownMenuItem(
                                              value: _SortField.customer,
                                              child: Text('Customer')),
                                        ],
                                        onChanged: (v) {
                                          if (v != null) {
                                            setState(() => _sortField = v);
                                          }
                                          _applyFilters();
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: Icon(
                                        _sortDir == _SortDir.asc
                                            ? Icons.arrow_upward
                                            : Icons.arrow_downward,
                                      ),
                                      tooltip: 'Toggle sort order',
                                      onPressed: () {
                                        setState(() => _sortDir =
                                            _sortDir == _SortDir.asc
                                                ? _SortDir.desc
                                                : _SortDir.asc);
                                        _applyFilters();
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: FilledButton.tonal(
                                        onPressed: () async {
                                          final d = await showDatePicker(
                                            context: context,
                                            initialDate: _startDate ?? DateTime.now(),
                                            firstDate: DateTime(2020),
                                            lastDate: DateTime.now(),
                                          );
                                          if (d != null) {
                                            setState(() => _startDate = d);
                                            _applyFilters();
                                          }
                                        },
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.date_range, size: 16),
                                            const SizedBox(width: 6),
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
                                          final d = await showDatePicker(
                                            context: context,
                                            initialDate: _endDate ?? DateTime.now(),
                                            firstDate: DateTime(2020),
                                            lastDate: DateTime.now(),
                                          );
                                          if (d != null) {
                                            setState(() => _endDate = d);
                                            _applyFilters();
                                          }
                                        },
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.date_range, size: 16),
                                            const SizedBox(width: 6),
                                            Text(_endDate == null
                                                ? 'End Date'
                                                : DateFormat('MMM dd, yyyy')
                                                    .format(_endDate!)),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (_startDate != null || _endDate != null) ...[
                                      const SizedBox(width: 12),
                                      OutlinedButton(
                                        onPressed: () {
                                          setState(() {
                                            _startDate = null;
                                            _endDate = null;
                                          });
                                          _applyFilters();
                                        },
                                        child: const Text('Clear'),
                                      ),
                                    ],
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
                if (_filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.schedule_outlined,
                              size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text('No pending orders',
                              style: Theme.of(context).textTheme.titleMedium),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => _PendingOrderCard(
                          order: _displayed[i],
                          onComplete: () => _completeOrder(_displayed[i]),
                          onEdit: () => _editOrder(_displayed[i]),
                          onDelete: () => _deleteOrder(_displayed[i]),
                          onPrint: () => _printReceipt(_displayed[i]),
                          onTap: () => _viewOrderDetails(_displayed[i]),
                        ),
                        childCount: _displayed.length,
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
            ),
    );
  }
}

// ── Stat card (same style as orders screen) ──────────────────────────────────

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

// ── Compact pending order card ────────────────────────────────────────────────

class _PendingOrderCard extends StatelessWidget {
  final dynamic order;
  final VoidCallback onComplete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPrint;
  final VoidCallback onTap;

  const _PendingOrderCard({
    required this.order,
    required this.onComplete,
    required this.onEdit,
    required this.onDelete,
    required this.onPrint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final date = DateTime.parse(order['created_at']);
    final total = double.tryParse(order['total']?.toString() ?? '0') ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
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
          onTap: onTap,
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
                          const Icon(Icons.schedule, color: Colors.orange, size: 20),
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                            ),
                            child: const Text(
                              'Pending',
                              style: TextStyle(
                                  color: Colors.orange,
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
                            fontSize: 12, color: cs.onSurface.withValues(alpha: 0.7)),
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
                                  color: Colors.orange.shade700),
                            ),
                          ),
                          IconButton(
                            onPressed: onComplete,
                            icon: const Icon(Icons.check_circle_outline, size: 18),
                            tooltip: 'Complete',
                            visualDensity: VisualDensity.compact,
                            color: Colors.green,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                          ),
                          IconButton(
                            onPressed: onEdit,
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
                            onPressed: onDelete,
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
                            onPressed: onPrint,
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
                    const Icon(Icons.schedule, color: Colors.orange, size: 20),
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
                                fontSize: 11, color: cs.onSurface.withValues(alpha: 0.5)),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        order['customer_name'] ?? 'Walk-in',
                        style: TextStyle(
                            fontSize: 12, color: cs.onSurface.withValues(alpha: 0.7)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                      ),
                      child: const Text(
                        'Pending',
                        style: TextStyle(
                            color: Colors.orange,
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
                          color: Colors.orange.shade700),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {},
                      child: IconButton(
                        onPressed: onComplete,
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        tooltip: 'Complete',
                        visualDensity: VisualDensity.compact,
                        color: Colors.green,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: IconButton(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        tooltip: 'Edit',
                        visualDensity: VisualDensity.compact,
                        color: Colors.blue,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: IconButton(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline, size: 18),
                        tooltip: 'Delete',
                        visualDensity: VisualDensity.compact,
                        color: Colors.red,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: IconButton(
                        onPressed: onPrint,
                        icon: const Icon(Icons.print_outlined, size: 18),
                        tooltip: 'Print',
                        visualDensity: VisualDensity.compact,
                        color: cs.primary,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ── Order Details Dialog ──────────────────────────────────────────────────────

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
                color: Colors.orange.withValues(alpha: 0.15),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule, color: Colors.orange, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pending Order #${order['order_number']}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        Text(
                          DateFormat('MMM dd, yyyy • HH:mm').format(date),
                          style: TextStyle(
                            fontSize: 13,
                            color: cs.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    color: cs.onSurface,
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
                        const Expanded(
                          child: _InfoCard(
                            label: 'Status',
                            value: 'PENDING',
                            icon: Icons.schedule,
                            valueColor: Colors.orange,
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
                        border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color:
                                  cs.surfaceContainerHighest.withValues(alpha: 0.5),
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
                                            color:
                                                cs.outline.withValues(alpha: 0.1))),
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
                        color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
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
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange),
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
  final Color? valueColor;

  const _InfoCard(
      {required this.label,
      required this.value,
      required this.icon,
      this.valueColor});

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
          Icon(icon, size: 20, color: valueColor ?? cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11, color: cs.onSurface.withValues(alpha: 0.6))),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: valueColor),
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
