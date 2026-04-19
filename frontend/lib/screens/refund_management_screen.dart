import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/app_settings_provider.dart';
import '../services/api_service.dart';
import '../utils/api_config.dart';

class RefundManagementScreen extends StatefulWidget {
  const RefundManagementScreen({super.key});

  @override
  State<RefundManagementScreen> createState() => _RefundManagementScreenState();
}

class _RefundManagementScreenState extends State<RefundManagementScreen> {
  List<dynamic> _refunds = [];
  List<dynamic> _filteredRefunds = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();
  String _statusFilter = 'all';
  String _typeFilter = 'all';
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _loadRefunds();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRefunds() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get(ApiConfig.refundsEndpoint);
      if (response['success']) {
        setState(() {
          _refunds = response['data'];
          _filteredRefunds = response['data'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredRefunds = _refunds.where((refund) {
        final matchesSearch = _searchController.text.isEmpty ||
            refund['order_number']
                .toString()
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()) ||
            (refund['reason'] ?? '')
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()) ||
            (refund['processed_by'] ?? '')
                .toLowerCase()
                .contains(_searchController.text.toLowerCase());

        final matchesStatus =
            _statusFilter == 'all' || refund['status'] == _statusFilter;
        final matchesType =
            _typeFilter == 'all' || refund['type'] == _typeFilter;

        final matchesDate = _dateRange == null ||
            (DateTime.parse(refund['created_at']).isAfter(
                    _dateRange!.start.subtract(const Duration(days: 1))) &&
                DateTime.parse(refund['created_at'])
                    .isBefore(_dateRange!.end.add(const Duration(days: 1))));

        return matchesSearch && matchesStatus && matchesType && matchesDate;
      }).toList();
    });
  }

  Map<String, dynamic> _calculateStats() {
    final total = _refunds.length;
    final approved = _refunds.where((r) => r['status'] == 'approved').length;
    final pending = _refunds.where((r) => r['status'] == 'pending').length;
    final rejected = _refunds.where((r) => r['status'] == 'rejected').length;
    final totalAmount = _refunds.fold<double>(
        0, (sum, r) => sum + double.parse(r['amount'].toString()));

    return {
      'total': total,
      'approved': approved,
      'pending': pending,
      'rejected': rejected,
      'totalAmount': totalAmount,
    };
  }

  void _processRefund() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _RefundPage(
          onSaved: _loadRefunds,
        ),
      ),
    );
  }

  void _editRefund(Map<String, dynamic> refund) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _RefundPage(
          refund: refund,
          onSaved: _loadRefunds,
        ),
      ),
    );
  }

  Future<void> _deleteRefund(Map<String, dynamic> refund) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Refund'),
        content: Text(
            'Delete refund for Order #${refund['order_number']}?\n\nThis will restore the stock and revert the order status.'),
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

    if (confirm != true) return;

    try {
      final response = await ApiService.delete(
          '${ApiConfig.refundsEndpoint}?id=${refund['id']}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Refund deleted'),
            backgroundColor: response['success'] ? Colors.green : Colors.red,
          ),
        );
        if (response['success']) _loadRefunds();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final stats = _calculateStats();
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            expandedHeight: 120,
            automaticallyImplyLeading: false,
            title: const Row(
              children: [
                Icon(Icons.assignment_return, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Refund & Returns',
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
                    colors: [Colors.red.shade600, Colors.red.shade800],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          _applyFilters();
                        },
                        decoration: InputDecoration(
                          hintText: 'Search refunds...',
                          prefixIcon:
                              const Icon(Icons.search, color: Colors.white70),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear,
                                      color: Colors.white70, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    _applyFilters();
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.15),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          hintStyle: const TextStyle(color: Colors.white70),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
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
                  icon:
                      const Icon(Icons.refresh, color: Colors.white, size: 20),
                  onPressed: _loadRefunds,
                  tooltip: 'Refresh'),
              IconButton(
                  icon: const Icon(Icons.add_circle,
                      color: Colors.white, size: 20),
                  onPressed: _processRefund,
                  tooltip: 'Process Refund'),
            ],
          ),
          SliverPadding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Statistics Cards
                if (isSmallScreen)
                  GridView.count(
                    crossAxisCount: 1,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    childAspectRatio: 4,
                    children: [
                      _buildStatCard(
                          'Total Refunds',
                          stats['total'].toString(),
                          Icons.receipt_long,
                          colorScheme.primary,
                          isSmallScreen),
                      _buildStatCard('Approved', stats['approved'].toString(),
                          Icons.check_circle, Colors.green, isSmallScreen),
                      _buildStatCard('Pending', stats['pending'].toString(),
                          Icons.pending, Colors.orange, isSmallScreen),
                      _buildStatCard('Rejected', stats['rejected'].toString(),
                          Icons.cancel, Colors.red, isSmallScreen),
                      _buildStatCard(
                          'Total Amount',
                          '${stats['totalAmount'].toStringAsFixed(2)} ${context.watch<AppSettingsProvider>().currencySymbol}',
                          Icons.attach_money,
                          colorScheme.secondary,
                          isSmallScreen),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                          child: _buildStatCard(
                              'Total Refunds',
                              stats['total'].toString(),
                              Icons.receipt_long,
                              colorScheme.primary,
                              isSmallScreen)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _buildStatCard(
                              'Approved',
                              stats['approved'].toString(),
                              Icons.check_circle,
                              Colors.green,
                              isSmallScreen)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _buildStatCard(
                              'Pending',
                              stats['pending'].toString(),
                              Icons.pending,
                              Colors.orange,
                              isSmallScreen)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _buildStatCard(
                              'Rejected',
                              stats['rejected'].toString(),
                              Icons.cancel,
                              Colors.red,
                              isSmallScreen)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _buildStatCard(
                              'Total Amount',
                              '${stats['totalAmount'].toStringAsFixed(2)} ${context.watch<AppSettingsProvider>().currencySymbol}',
                              Icons.attach_money,
                              colorScheme.secondary,
                              isSmallScreen)),
                    ],
                  ),
                const SizedBox(height: 12),

                // Filters
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                    child: isSmallScreen
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DropdownButtonFormField<String>(
                                initialValue: _statusFilter,
                                decoration: InputDecoration(
                                  labelText: 'Status',
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'all', child: Text('All Status')),
                                  DropdownMenuItem(
                                      value: 'approved',
                                      child: Text('Approved')),
                                  DropdownMenuItem(
                                      value: 'pending', child: Text('Pending')),
                                  DropdownMenuItem(
                                      value: 'rejected',
                                      child: Text('Rejected')),
                                ],
                                onChanged: (value) {
                                  setState(() => _statusFilter = value!);
                                  _applyFilters();
                                },
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                initialValue: _typeFilter,
                                decoration: InputDecoration(
                                  labelText: 'Type',
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'all', child: Text('All Types')),
                                  DropdownMenuItem(
                                      value: 'full', child: Text('Full')),
                                  DropdownMenuItem(
                                      value: 'partial', child: Text('Partial')),
                                ],
                                onChanged: (value) {
                                  setState(() => _typeFilter = value!);
                                  _applyFilters();
                                },
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () async {
                                        final picked =
                                            await showDateRangePicker(
                                          context: context,
                                          firstDate: DateTime(2020),
                                          lastDate: DateTime.now(),
                                          initialDateRange: _dateRange,
                                        );
                                        if (picked != null) {
                                          setState(() => _dateRange = picked);
                                          _applyFilters();
                                        }
                                      },
                                      icon: const Icon(Icons.date_range),
                                      label: Text(_dateRange == null
                                          ? 'Date Range'
                                          : 'Filtered'),
                                    ),
                                  ),
                                  if (_dateRange != null ||
                                      _searchController.text.isNotEmpty ||
                                      _statusFilter != 'all' ||
                                      _typeFilter != 'all')
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _searchController.clear();
                                          _statusFilter = 'all';
                                          _typeFilter = 'all';
                                          _dateRange = null;
                                        });
                                        _applyFilters();
                                      },
                                      icon: const Icon(Icons.clear),
                                      tooltip: 'Clear Filters',
                                    ),
                                ],
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: _statusFilter,
                                  decoration: InputDecoration(
                                    labelText: 'Status',
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                        value: 'all',
                                        child: Text('All Status')),
                                    DropdownMenuItem(
                                        value: 'approved',
                                        child: Text('Approved')),
                                    DropdownMenuItem(
                                        value: 'pending',
                                        child: Text('Pending')),
                                    DropdownMenuItem(
                                        value: 'rejected',
                                        child: Text('Rejected')),
                                  ],
                                  onChanged: (value) {
                                    setState(() => _statusFilter = value!);
                                    _applyFilters();
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: _typeFilter,
                                  decoration: InputDecoration(
                                    labelText: 'Type',
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                        value: 'all', child: Text('All Types')),
                                    DropdownMenuItem(
                                        value: 'full', child: Text('Full')),
                                    DropdownMenuItem(
                                        value: 'partial',
                                        child: Text('Partial')),
                                  ],
                                  onChanged: (value) {
                                    setState(() => _typeFilter = value!);
                                    _applyFilters();
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              OutlinedButton.icon(
                                onPressed: () async {
                                  final picked = await showDateRangePicker(
                                    context: context,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now(),
                                    initialDateRange: _dateRange,
                                  );
                                  if (picked != null) {
                                    setState(() => _dateRange = picked);
                                    _applyFilters();
                                  }
                                },
                                icon: const Icon(Icons.date_range),
                                label: Text(_dateRange == null
                                    ? 'Date Range'
                                    : 'Filtered'),
                              ),
                              if (_dateRange != null ||
                                  _searchController.text.isNotEmpty ||
                                  _statusFilter != 'all' ||
                                  _typeFilter != 'all')
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _statusFilter = 'all';
                                      _typeFilter = 'all';
                                      _dateRange = null;
                                    });
                                    _applyFilters();
                                  },
                                  icon: const Icon(Icons.clear),
                                  tooltip: 'Clear Filters',
                                ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 10),
              ]),
            ),
          ),
          // Data Table Section
          if (_filteredRefunds.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off,
                        size: isSmallScreen ? 48 : 64, color: Colors.grey[400]),
                    SizedBox(height: isSmallScreen ? 12 : 16),
                    Text('No refunds found',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                                color: Colors.grey,
                                fontSize: isSmallScreen ? 14 : null)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding:
                  EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Data table header
                  Card(
                    elevation: 2,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 12 : 16,
                          vertical: isSmallScreen ? 8 : 10),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.05),
                        border: Border(
                            bottom: BorderSide(
                                color: colorScheme.outline
                                    .withValues(alpha: 0.2))),
                      ),
                      child: isSmallScreen
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Showing ${_filteredRefunds.length} of ${_refunds.length}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.primary,
                                        fontSize: 12,
                                      ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    '${stats['totalAmount'].toStringAsFixed(2)} ${context.watch<AppSettingsProvider>().currencySymbol}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Showing ${_filteredRefunds.length} of ${_refunds.length} refunds',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.primary,
                                      ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Total: ${stats['totalAmount'].toStringAsFixed(2)} ${context.watch<AppSettingsProvider>().currencySymbol}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ]),
              ),
            ),
          // Refund items list
          if (_filteredRefunds.isNotEmpty)
            SliverPadding(
              padding:
                  EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final refund = _filteredRefunds[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: colorScheme.outline.withValues(alpha: 0.2)),
                        borderRadius: BorderRadius.circular(12),
                        color: colorScheme.surface,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _editRefund(refund),
                          child: Padding(
                            padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (isSmallScreen)
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(
                                                      refund['status'])
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              _getStatusIcon(refund['status']),
                                              color: _getStatusColor(
                                                  refund['status']),
                                              size: 18,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Order #${refund['order_number']}',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  DateFormat('MMM dd • hh:mm')
                                                      .format(DateTime.parse(
                                                          refund[
                                                              'created_at'])),
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${double.parse(refund['amount'].toString()).toStringAsFixed(2)} ${context.watch<AppSettingsProvider>().currencySymbol}',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: colorScheme.primary,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: refund['type'] ==
                                                          'full'
                                                      ? Colors.blue.withValues(
                                                          alpha: 0.1)
                                                      : Colors.purple
                                                          .withValues(
                                                              alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  refund['type']
                                                      .toString()
                                                      .toUpperCase(),
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w600,
                                                    color: refund['type'] ==
                                                            'full'
                                                        ? Colors.blue[700]
                                                        : Colors.purple[700],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(
                                                      refund['status'])
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  _getStatusIcon(
                                                      refund['status']),
                                                  size: 10,
                                                  color: _getStatusColor(
                                                      refund['status']),
                                                ),
                                                const SizedBox(width: 3),
                                                Text(
                                                  refund['status']
                                                      .toString()
                                                      .toUpperCase(),
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w600,
                                                    color: _getStatusColor(
                                                        refund['status']),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  )
                                else
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color:
                                              _getStatusColor(refund['status'])
                                                  .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          _getStatusIcon(refund['status']),
                                          color:
                                              _getStatusColor(refund['status']),
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  'Order #${refund['order_number']}',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        refund['type'] == 'full'
                                                            ? Colors.blue
                                                                .withValues(
                                                                    alpha: 0.1)
                                                            : Colors.purple
                                                                .withValues(
                                                                    alpha: 0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6),
                                                  ),
                                                  child: Text(
                                                    refund['type']
                                                        .toString()
                                                        .toUpperCase(),
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: refund['type'] ==
                                                              'full'
                                                          ? Colors.blue[700]
                                                          : Colors.purple[700],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              DateFormat(
                                                      'MMM dd, yyyy • hh:mm a')
                                                  .format(DateTime.parse(
                                                      refund['created_at'])),
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${double.parse(refund['amount'].toString()).toStringAsFixed(2)} ${context.watch<AppSettingsProvider>().currencySymbol}',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.primary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(
                                                      refund['status'])
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  _getStatusIcon(
                                                      refund['status']),
                                                  size: 12,
                                                  color: _getStatusColor(
                                                      refund['status']),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  refund['status']
                                                      .toString()
                                                      .toUpperCase(),
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: _getStatusColor(
                                                        refund['status']),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest
                                        .withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.info_outline,
                                          size: isSmallScreen ? 14 : 16,
                                          color: Colors.grey[600]),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          refund['reason'] ??
                                              'No reason provided',
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 12 : 13,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (isSmallScreen)
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.person_outline,
                                              size: 12,
                                              color: Colors.grey[600]),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              'By: ${refund['processed_by'] ?? 'N/A'}',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey[600],
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          SizedBox(
                                            height: 36,
                                            width: 36,
                                            child: IconButton(
                                              icon: Icon(Icons.edit_outlined,
                                                  size: 16,
                                                  color: colorScheme.primary),
                                              onPressed: () =>
                                                  _editRefund(refund),
                                              tooltip: 'Edit',
                                              style: IconButton.styleFrom(
                                                padding: EdgeInsets.zero,
                                                backgroundColor: colorScheme
                                                    .primary
                                                    .withValues(alpha: 0.1),
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6)),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          SizedBox(
                                            height: 36,
                                            width: 36,
                                            child: IconButton(
                                              icon: const Icon(
                                                  Icons.delete_outline,
                                                  size: 16,
                                                  color: Colors.red),
                                              onPressed: () =>
                                                  _deleteRefund(refund),
                                              tooltip: 'Delete',
                                              style: IconButton.styleFrom(
                                                padding: EdgeInsets.zero,
                                                backgroundColor: Colors.red
                                                    .withValues(alpha: 0.1),
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6)),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  )
                                else
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.person_outline,
                                              size: 16,
                                              color: Colors.grey[600]),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Processed by: ${refund['processed_by'] ?? 'N/A'}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(Icons.edit_outlined,
                                                size: 20,
                                                color: colorScheme.primary),
                                            onPressed: () =>
                                                _editRefund(refund),
                                            tooltip: 'Edit Refund',
                                            style: IconButton.styleFrom(
                                              backgroundColor: colorScheme
                                                  .primary
                                                  .withValues(alpha: 0.1),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8)),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(
                                                Icons.delete_outline,
                                                size: 20,
                                                color: Colors.red),
                                            onPressed: () =>
                                                _deleteRefund(refund),
                                            tooltip: 'Delete Refund',
                                            style: IconButton.styleFrom(
                                              backgroundColor: Colors.red
                                                  .withValues(alpha: 0.1),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: _filteredRefunds.length,
                ),
              ),
            ),
          // Bottom padding
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color,
      bool isSmallScreen) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: isSmallScreen ? 18 : 22),
            ),
            SizedBox(width: isSmallScreen ? 10 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 13,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 15 : 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Icons.check_circle;
      case 'pending':
        return Icons.pending;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class _RefundPage extends StatefulWidget {
  final VoidCallback onSaved;
  final Map<String, dynamic>? refund;

  const _RefundPage({required this.onSaved, this.refund});

  @override
  State<_RefundPage> createState() => _RefundPageState();
}

class _RefundPageState extends State<_RefundPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  String _refundType = 'full';
  String _selectedStatus = 'approved';
  bool _isLoading = false;
  List<dynamic> _orders = [];
  String? _selectedOrderNumber;
  bool _loadingOrders = true;

  @override
  void initState() {
    super.initState();
    if (widget.refund != null) {
      _amountController.text = widget.refund!['amount'].toString();
      _reasonController.text = widget.refund!['reason'] ?? '';
      _refundType = widget.refund!['type'] ?? 'full';
      _selectedOrderNumber = widget.refund!['order_id']?.toString();
      _selectedStatus = widget.refund!['status'] ?? 'approved';
    }
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final response = await ApiService.get(ApiConfig.ordersEndpoint);
      if (response['success'] && mounted) {
        setState(() {
          _orders = response['data'];
          _loadingOrders = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingOrders = false);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.refund == null ? 'Process Refund' : 'Edit Refund'),
        elevation: 0,
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _loadingOrders
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : DropdownButtonFormField<String>(
                        initialValue: _selectedOrderNumber,
                        decoration: const InputDecoration(
                          labelText: 'Order Number',
                          border: OutlineInputBorder(),
                        ),
                        items: _orders.map((order) {
                          return DropdownMenuItem<String>(
                            value: order['id'].toString(),
                            child: Text(
                              'Order #${order['order_number']} - ${order['total']} ${context.read<AppSettingsProvider>().currencySymbol} (${order['status']})',
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedOrderNumber = value);
                        },
                        validator: (v) => v == null ? 'Required' : null,
                      ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'approved', child: Text('Approved')),
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(
                        value: 'rejected', child: Text('Rejected')),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedStatus = value!);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _refundType,
                  decoration: const InputDecoration(
                    labelText: 'Refund Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'full', child: Text('Full Refund')),
                    DropdownMenuItem(
                        value: 'partial', child: Text('Partial Refund')),
                  ],
                  onChanged: (value) {
                    setState(() => _refundType = value!);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Refund Amount',
                    border: OutlineInputBorder(),
                    prefixText: '\$',
                  ),
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _reasonController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Reason for Refund',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading || _loadingOrders ? null : _submitRefund,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Colors.red.shade600,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Process',
                        style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitRefund() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final selectedOrder =
        _orders.firstWhere((o) => o['id'].toString() == _selectedOrderNumber);

    final data = {
      'order_number': selectedOrder['order_number'],
      'amount': double.parse(_amountController.text),
      'reason': _reasonController.text,
      'type': _refundType,
      'status': _selectedStatus,
    };

    try {
      final response = widget.refund == null
          ? await ApiService.post(ApiConfig.refundsEndpoint, data)
          : await ApiService.put(
              '${ApiConfig.refundsEndpoint}?id=${widget.refund!['id']}', data);

      if (response['success'] && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(response['message'] ?? 'Success'),
              backgroundColor: Colors.green),
        );
        widget.onSaved();
        Navigator.pop(context);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text(response['message'] ?? 'Failed to process refund'),
                backgroundColor: Colors.red),
          );
        }
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
}
