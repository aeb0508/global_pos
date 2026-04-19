import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/customer.dart';
import '../providers/app_settings_provider.dart';
import '../services/api_service.dart';
import '../utils/api_config.dart';
import '../utils/snackbar_helper.dart';
import 'home_screen.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen>
    with AutomaticKeepAliveClientMixin {
  List<Customer> _all = [];
  List<Customer> _filtered = [];
  List<Customer> _displayed = [];
  Customer? _selected;
  List<dynamic> _selectedOrders = [];
  bool _isLoading = true;
  bool _historyLoading = false;
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  static const int _pageSize = 10;
  int _currentPage = 1;
  bool _hasMore = false;

  @override
  bool get wantKeepAlive => false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.get(ApiConfig.customersEndpoint);
      if (res['success'] == true && res['data'] != null) {
        final list =
            (res['data'] as List).map((j) => Customer.fromJson(j)).toList();
        setState(() {
          _all = list;
          _filtered = List.from(list);
          _displayed = _filtered.take(_pageSize).toList();
          _hasMore = _filtered.length > _pageSize;
          _isLoading = false;
          // keep selection valid
          if (_selected != null) {
            _selected = list.where((c) => c.id == _selected!.id).firstOrNull;
          }
        });
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
        SnackBarHelper.showError(context, 'Error: $e');
      }
    }
  }

  Future<void> _selectCustomer(Customer c) async {
    setState(() {
      _selected = c;
      _historyLoading = true;
      _selectedOrders = [];
    });
    try {
      final res = await ApiService.get(
          '${ApiConfig.customersEndpoint}?id=${c.id}&history=1');
      if (mounted) {
        setState(() {
          _selectedOrders =
              res['success'] == true ? (res['data'] as List? ?? []) : [];
          _historyLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _historyLoading = false);
    }
  }

  void _applySearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _filtered = List.from(_all);
        _currentPage = 1;
        _displayed = _filtered.take(_pageSize).toList();
        _hasMore = _filtered.length > _pageSize;
      });
      return;
    }
    final q = query.toLowerCase();
    setState(() {
      _filtered = _all.where((c) {
        return c.name.toLowerCase().contains(q) ||
            (c.email ?? '').toLowerCase().contains(q) ||
            (c.phone ?? '').toLowerCase().contains(q);
      }).toList();
      _currentPage = 1;
      _displayed = _filtered.take(_pageSize).toList();
      _hasMore = _filtered.length > _pageSize;
    });
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

  void _showForm([Customer? customer]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _CustomerFormPage(
          customer: customer,
          onSaved: (_) => _load(),
        ),
      ),
    );
  }

  Future<void> _delete(Customer customer) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text('Delete "${customer.name}"?'),
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
          '${ApiConfig.customersEndpoint}?id=${customer.id}');
      if (mounted) {
        if (res['success'] == true) {
          SnackBarHelper.showSuccess(context, res['message'] ?? 'Done');
          if (_selected?.id == customer.id) setState(() => _selected = null);
          _load();
        } else {
          SnackBarHelper.showError(context, res['message'] ?? 'Failed');
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Error: $e');
      }
    }
  }

  int get _withEmail =>
      _all.where((c) => c.email != null && c.email!.isNotEmpty).length;
  int get _withPhone =>
      _all.where((c) => c.phone != null && c.phone!.isNotEmpty).length;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 800;

                if (isMobile) {
                  // Mobile: Single column with tabs or list only
                  return Column(
                    children: [
                      // Header
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.teal.shade600,
                              Colors.teal.shade800,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.people_rounded,
                                    color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Customers',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.refresh,
                                      color: Colors.white, size: 20),
                                  onPressed: _load,
                                  tooltip: 'Refresh',
                                  visualDensity: VisualDensity.compact,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add,
                                      color: Colors.white, size: 20),
                                  onPressed: () => _showForm(),
                                  tooltip: 'Add Customer',
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _searchCtrl,
                              onChanged: _applySearch,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.search,
                                    color: Colors.white70, size: 18),
                                suffixIcon: _searchCtrl.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear,
                                            color: Colors.white70, size: 18),
                                        onPressed: () {
                                          _searchCtrl.clear();
                                          _applySearch('');
                                        },
                                      )
                                    : null,
                                hintText: 'Search customers…',
                                hintStyle: const TextStyle(
                                    color: Colors.white70, fontSize: 13),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.15),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                isDense: true,
                              ),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 13),
                            ),
                          ],
                        ),
                      ),

                      // Stat chips
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        color: cs.surface,
                        child: Row(
                          children: [
                            _StatChip(
                                label: 'Total',
                                value: '${_all.length}',
                                color: cs.primary),
                            const SizedBox(width: 8),
                            _StatChip(
                                label: 'Email',
                                value: '$_withEmail',
                                color: Colors.green),
                            const SizedBox(width: 8),
                            _StatChip(
                                label: 'Phone',
                                value: '$_withPhone',
                                color: Colors.purple),
                          ],
                        ),
                      ),

                      // List
                      Expanded(
                        child: _filtered.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.people_outline,
                                        size: 48,
                                        color: cs.onSurface
                                            .withValues(alpha: 0.25)),
                                    const SizedBox(height: 12),
                                    Text('No customers found',
                                        style: TextStyle(
                                            color: cs.onSurface
                                                .withValues(alpha: 0.45))),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                controller: _scrollController,
                                physics: const ClampingScrollPhysics(),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                itemCount:
                                    _displayed.length + (_hasMore ? 1 : 0),
                                itemBuilder: (ctx, i) {
                                  if (i == _displayed.length) {
                                    return const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 12),
                                      child: Center(
                                          child: CircularProgressIndicator()),
                                    );
                                  }
                                  return _CustomerTile(
                                    customer: _displayed[i],
                                    isSelected:
                                        _selected?.id == _displayed[i].id,
                                    onTap: () {
                                      _selectCustomer(_displayed[i]);
                                      // Show detail in bottom sheet on mobile
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (ctx) =>
                                            DraggableScrollableSheet(
                                          initialChildSize: 0.9,
                                          minChildSize: 0.5,
                                          maxChildSize: 0.95,
                                          builder: (_, scrollCtrl) => Container(
                                            decoration: BoxDecoration(
                                              color: cs.surface,
                                              borderRadius:
                                                  const BorderRadius.vertical(
                                                top: Radius.circular(20),
                                              ),
                                            ),
                                            child: _CustomerDetail(
                                              customer: _displayed[i],
                                              orders: _selectedOrders,
                                              isLoading: _historyLoading,
                                              onEdit: () {
                                                Navigator.pop(ctx);
                                                _showForm(_displayed[i]);
                                              },
                                              onDelete: () {
                                                Navigator.pop(ctx);
                                                _delete(_displayed[i]);
                                              },
                                              cs: cs,
                                              isMobile: true,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                    onEdit: () => _showForm(_displayed[i]),
                                    onDelete: () => _delete(_displayed[i]),
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                }

                // Desktop: Two-panel layout
                return Row(
                  children: [
                    // ── LEFT PANEL ──────────────────────────────────────────────
                    SizedBox(
                      width: 380,
                      child: Column(
                        children: [
                          // Header
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.teal.shade600,
                                  Colors.teal.shade800,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.people_rounded,
                                        color: Colors.white, size: 20),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Text(
                                        'Customers',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.refresh,
                                          color: Colors.white, size: 20),
                                      onPressed: _load,
                                      tooltip: 'Refresh',
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add,
                                          color: Colors.white, size: 20),
                                      onPressed: () => _showForm(),
                                      tooltip: 'Add Customer',
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: _searchCtrl,
                                  onChanged: _applySearch,
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(Icons.search,
                                        color: Colors.white70, size: 18),
                                    suffixIcon: _searchCtrl.text.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.clear,
                                                color: Colors.white70,
                                                size: 18),
                                            onPressed: () {
                                              _searchCtrl.clear();
                                              _applySearch('');
                                            },
                                          )
                                        : null,
                                    hintText: 'Search name, email, phone…',
                                    hintStyle:
                                        const TextStyle(color: Colors.white70),
                                    filled: true,
                                    fillColor:
                                        Colors.white.withValues(alpha: 0.15),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    isDense: true,
                                  ),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),

                          // Stat chips
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            color: cs.surface,
                            child: Row(
                              children: [
                                _StatChip(
                                    label: 'Total',
                                    value: '${_all.length}',
                                    color: cs.primary),
                                const SizedBox(width: 8),
                                _StatChip(
                                    label: 'Email',
                                    value: '$_withEmail',
                                    color: Colors.green),
                                const SizedBox(width: 8),
                                _StatChip(
                                    label: 'Phone',
                                    value: '$_withPhone',
                                    color: Colors.purple),
                              ],
                            ),
                          ),

                          // List
                          Expanded(
                            child: _filtered.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.people_outline,
                                            size: 48,
                                            color: cs.onSurface
                                                .withValues(alpha: 0.25)),
                                        const SizedBox(height: 12),
                                        Text('No customers found',
                                            style: TextStyle(
                                                color: cs.onSurface
                                                    .withValues(alpha: 0.45))),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    controller: _scrollController,
                                    physics: const ClampingScrollPhysics(),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    itemCount:
                                        _displayed.length + (_hasMore ? 1 : 0),
                                    itemBuilder: (ctx, i) {
                                      if (i == _displayed.length) {
                                        return const Padding(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 12),
                                          child: Center(
                                              child:
                                                  CircularProgressIndicator()),
                                        );
                                      }
                                      return _CustomerTile(
                                        customer: _displayed[i],
                                        isSelected:
                                            _selected?.id == _displayed[i].id,
                                        onTap: () =>
                                            _selectCustomer(_displayed[i]),
                                        onEdit: () => _showForm(_displayed[i]),
                                        onDelete: () => _delete(_displayed[i]),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),

                    // Divider
                    VerticalDivider(
                        width: 1, color: cs.outline.withValues(alpha: 0.15)),

                    // ── RIGHT PANEL ─────────────────────────────────────────────
                    Expanded(
                      child: _selected == null
                          ? _EmptyDetail(cs: cs)
                          : _CustomerDetail(
                              customer: _selected!,
                              orders: _selectedOrders,
                              isLoading: _historyLoading,
                              onEdit: () => _showForm(_selected),
                              onDelete: () => _delete(_selected!),
                              cs: cs,
                            ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

// ── Stat chip ──────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13, color: color)),
          const SizedBox(width: 4),
          Text(label,
              style:
                  TextStyle(fontSize: 11, color: color.withValues(alpha: 0.8))),
        ],
      ),
    );
  }
}

// ── Customer list tile ─────────────────────────────────────────────────────────

class _CustomerTile extends StatelessWidget {
  final Customer customer;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CustomerTile({
    required this.customer,
    required this.isSelected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final initials = customer.name
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isSelected ? cs.primary.withValues(alpha: 0.08) : cs.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected
              ? cs.primary.withValues(alpha: 0.4)
              : cs.outline.withValues(alpha: 0.12),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: isSelected
                    ? cs.primary
                    : cs.primary.withValues(alpha: 0.12),
                child: Text(initials,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? cs.onPrimary : cs.primary)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customer.name,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: isSelected ? cs.primary : null),
                        overflow: TextOverflow.ellipsis),
                    if (customer.email != null && customer.email!.isNotEmpty)
                      Text(customer.email!,
                          style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurface.withValues(alpha: 0.5)),
                          overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [
                        Icon(Icons.edit_outlined, size: 16),
                        SizedBox(width: 8),
                        Text('Edit')
                      ])),
                  const PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete_outline, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red))
                      ])),
                ],
                icon: Icon(Icons.more_vert,
                    size: 18, color: cs.onSurface.withValues(alpha: 0.4)),
                tooltip: 'Options',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty detail placeholder ───────────────────────────────────────────────────

class _EmptyDetail extends StatelessWidget {
  final ColorScheme cs;
  const _EmptyDetail({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person_search_rounded,
                size: 52, color: cs.primary.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 20),
          Text('Select a customer',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: cs.onSurface.withValues(alpha: 0.5))),
          const SizedBox(height: 6),
          Text('Click any customer to view details',
              style: TextStyle(
                  fontSize: 13, color: cs.onSurface.withValues(alpha: 0.35))),
        ],
      ),
    );
  }
}

// ── Customer detail panel ──────────────────────────────────────────────────────

class _CustomerDetail extends StatelessWidget {
  final Customer customer;
  final List<dynamic> orders;
  final bool isLoading;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ColorScheme cs;
  final bool isMobile;

  const _CustomerDetail({
    required this.customer,
    required this.orders,
    required this.isLoading,
    required this.onEdit,
    required this.onDelete,
    required this.cs,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final initials = customer.name
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    final orderList = orders.cast<Map<String, dynamic>>();
    final totalSpent = orderList.fold<double>(
        0, (s, o) => s + (double.tryParse(o['total'].toString()) ?? 0));
    final avgOrder = orderList.isEmpty ? 0.0 : totalSpent / orderList.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Profile header ──────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cs.surface,
            border: Border(
                bottom: BorderSide(color: cs.outline.withValues(alpha: 0.12))),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: cs.primary.withValues(alpha: 0.15),
                child: Text(initials,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: cs.primary)),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customer.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    if (customer.email != null && customer.email!.isNotEmpty)
                      _InfoRow(
                          icon: Icons.email_outlined,
                          text: customer.email!,
                          cs: cs),
                    if (customer.phone != null && customer.phone!.isNotEmpty)
                      _InfoRow(
                          icon: Icons.phone_outlined,
                          text: customer.phone!,
                          cs: cs),
                    if (customer.address != null &&
                        customer.address!.isNotEmpty)
                      _InfoRow(
                          icon: Icons.location_on_outlined,
                          text: customer.address!,
                          cs: cs),
                  ],
                ),
              ),
              IconButton.outlined(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                tooltip: 'Edit',
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: Colors.red),
                tooltip: 'Delete',
                style: IconButton.styleFrom(
                    side: const BorderSide(color: Colors.red)),
              ),
            ],
          ),
        ),

        // ── Stats row ───────────────────────────────────────────────────────
        if (!isLoading)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                    child: _DetailStatCard(
                  label: 'Total Orders',
                  value: '${orderList.length}',
                  icon: Icons.receipt_long_outlined,
                  color: cs.primary,
                )),
                const SizedBox(width: 12),
                Expanded(
                    child: _DetailStatCard(
                  label: 'Total Spent',
                  value:
                      '${totalSpent.toStringAsFixed(2)} ${context.watch<AppSettingsProvider>().currencySymbol}',
                  icon: Icons.payments_outlined,
                  color: Colors.green,
                )),
                const SizedBox(width: 12),
                Expanded(
                    child: _DetailStatCard(
                  label: 'Avg Order',
                  value:
                      '${avgOrder.toStringAsFixed(2)} ${context.watch<AppSettingsProvider>().currencySymbol}',
                  icon: Icons.trending_up_rounded,
                  color: Colors.orange,
                )),
              ],
            ),
          ),

        // ── Order history ───────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Text('Purchase History',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ),

        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : orderList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt_outlined,
                              size: 40,
                              color: cs.onSurface.withValues(alpha: 0.25)),
                          const SizedBox(height: 10),
                          Text('No orders yet',
                              style: TextStyle(
                                  color: cs.onSurface.withValues(alpha: 0.4))),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: orderList.length,
                      itemBuilder: (ctx, i) =>
                          _OrderHistoryTile(order: orderList[i], cs: cs),
                    ),
        ),
      ],
    );
  }
}

// ── Small helpers ──────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final ColorScheme cs;

  const _InfoRow({required this.icon, required this.text, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Icon(icon, size: 13, color: cs.onSurface.withValues(alpha: 0.45)),
          const SizedBox(width: 5),
          Flexible(
            child: Text(text,
                style: TextStyle(
                    fontSize: 12, color: cs.onSurface.withValues(alpha: 0.6)),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

class _DetailStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _DetailStatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 10),
          Text(value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: color.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _OrderHistoryTile extends StatelessWidget {
  final Map<String, dynamic> order;
  final ColorScheme cs;

  const _OrderHistoryTile({required this.order, required this.cs});

  @override
  Widget build(BuildContext context) {
    final total =
        double.tryParse(order['total'].toString())?.toStringAsFixed(2) ??
            '0.00';
    final date = order['created_at'] != null
        ? DateTime.tryParse(order['created_at'].toString())
        : null;
    final dateStr =
        date != null ? '${date.day}/${date.month}/${date.year}' : '—';
    final orderNumber = order['order_number']?.toString() ?? '';
    final isPending =
        (order['status'] ?? '').toString().toLowerCase() == 'pending';

    return InkWell(
      onTap: () => Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            initialIndex: isPending ? 4 : 3,
            initialOrderSearch: isPending ? null : orderNumber,
            initialPendingOrderSearch: isPending ? orderNumber : null,
          ),
        ),
      ),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.receipt_outlined, size: 16, color: cs.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(orderNumber.isNotEmpty ? orderNumber : '#—',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(dateStr,
                      style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurface.withValues(alpha: 0.5))),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('\$$total',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                Container(
                  margin: const EdgeInsets.only(top: 3),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: (isPending ? Colors.orange : Colors.green)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    (order['status'] ?? 'completed').toString().toUpperCase(),
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isPending ? Colors.orange : Colors.green),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 12, color: cs.onSurface.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }
}

class _CustomerFormPage extends StatefulWidget {
  final Customer? customer;
  final Function(Customer?) onSaved;

  const _CustomerFormPage({this.customer, required this.onSaved});

  @override
  State<_CustomerFormPage> createState() => _CustomerFormPageState();
}

class _CustomerFormPageState extends State<_CustomerFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name =
      TextEditingController(text: widget.customer?.name ?? '');
  late final TextEditingController _email =
      TextEditingController(text: widget.customer?.email ?? '');
  late final TextEditingController _phone =
      TextEditingController(text: widget.customer?.phone ?? '');
  late final TextEditingController _address =
      TextEditingController(text: widget.customer?.address ?? '');
  bool _isLoading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
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

      if (!mounted) return;

      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              widget.customer == null ? 'Customer added' : 'Customer updated'),
          backgroundColor: Colors.green,
        ));
        widget.onSaved(
            res['data'] != null ? Customer.fromJson(res['data']) : null);
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res['message'] ?? 'Failed'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.customer == null;
    final width = MediaQuery.of(context).size.width;
    final isPhone = width < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isNew ? 'Add Customer' : 'Edit Customer',
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal.shade700,
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
                label: const Text('Save'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.teal.shade700,
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
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.teal.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.teal.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.people_rounded,
                              color: Colors.teal,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isNew ? 'Create Customer' : 'Update Customer',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.teal.shade800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Provide customer details',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.teal.shade600,
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
                      'Full Name',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _name,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Name is required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Email',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Phone',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Address',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _address,
                      maxLines: 2,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on_outlined),
                        alignLabelWithHint: true,
                      ),
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
                            label: const Text('Save Customer'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.teal.shade700,
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
