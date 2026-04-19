import 'package:flutter/material.dart';
import '../utils/api_config.dart';
import '../services/api_service.dart';

class MultiStoreScreen extends StatefulWidget {
  const MultiStoreScreen({super.key});

  @override
  State<MultiStoreScreen> createState() => _MultiStoreScreenState();
}

class _MultiStoreScreenState extends State<MultiStoreScreen> {
  List<dynamic> stores = [];
  List<dynamic> filteredStores = [];
  bool isLoading = true;
  String? selectedStoreId;
  String searchQuery = '';
  String selectedFilter = 'All'; // All, Active, Inactive
  int displayedCount = 10;
  static const int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    loadStores();
  }

  Future<void> loadStores() async {
    setState(() => isLoading = true);
    try {
      final response = await ApiService.get('${ApiConfig.baseUrl}/stores.php');
      if (response is List) {
        setState(() {
          stores = response;
          _applyFilters();
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(response['error'] ??
                    response['message'] ??
                    'Failed to load stores')),
          );
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Connection error: $e')));
      }
    }
  }

  void _applyFilters() {
    setState(() {
      filteredStores = stores.where((store) {
        final matchesSearch = searchQuery.isEmpty ||
            store['name']
                .toString()
                .toLowerCase()
                .contains(searchQuery.toLowerCase()) ||
            store['code']
                .toString()
                .toLowerCase()
                .contains(searchQuery.toLowerCase()) ||
            (store['manager_name']
                    ?.toString()
                    .toLowerCase()
                    .contains(searchQuery.toLowerCase()) ??
                false);

        final matchesFilter = selectedFilter == 'All' ||
            (selectedFilter == 'Active' &&
                (store['is_active'] == 1 || store['is_active'] == true)) ||
            (selectedFilter == 'Inactive' &&
                (store['is_active'] != 1 && store['is_active'] != true));

        return matchesSearch && matchesFilter;
      }).toList();
      displayedCount = _itemsPerPage; // Reset pagination when filtering
    });
  }

  void _loadMore() {
    setState(() {
      displayedCount += _itemsPerPage;
    });
  }

  int get _totalStores => stores.length;
  int get _activeStores =>
      stores.where((s) => s['is_active'] == 1 || s['is_active'] == true).length;
  int get _totalEmployees => stores.fold<int>(
      0,
      (sum, s) =>
          sum + (int.tryParse(s['total_employees']?.toString() ?? '0') ?? 0));
  int get _totalOrders => stores.fold<int>(
      0,
      (sum, s) =>
          sum + (int.tryParse(s['total_orders']?.toString() ?? '0') ?? 0));

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade600, Colors.blue.shade800],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
                child: Row(
                  children: [
                    const Icon(Icons.store_rounded,
                        color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Multi-Store',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20)),
                          Text('Manage your store locations',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                        icon: const Icon(Icons.add, color: Colors.white),
                        onPressed: () => _showStoreDialog(),
                        tooltip: 'Add Store'),
                    IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: loadStores,
                        tooltip: 'Refresh'),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  onChanged: (value) {
                    searchQuery = value;
                    _applyFilters();
                  },
                  decoration: InputDecoration(
                    hintText: 'Search stores by name, code, or manager...',
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.15),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    hintStyle: const TextStyle(color: Colors.white70),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Metric Cards
                      Row(
                        children: [
                          Expanded(
                              child: _GradientMetricCard(
                                  label: 'Total Stores',
                                  value: _totalStores.toString(),
                                  icon: Icons.store_rounded,
                                  gradient: [
                                Colors.blue.shade400,
                                Colors.blue.shade600
                              ])),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _GradientMetricCard(
                                  label: 'Active Stores',
                                  value: _activeStores.toString(),
                                  icon: Icons.check_circle_rounded,
                                  gradient: [
                                Colors.green.shade400,
                                Colors.green.shade600
                              ])),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _GradientMetricCard(
                                  label: 'Total Employees',
                                  value: _totalEmployees.toString(),
                                  icon: Icons.people_rounded,
                                  gradient: [
                                Colors.orange.shade400,
                                Colors.orange.shade600
                              ])),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _GradientMetricCard(
                                  label: 'Total Orders',
                                  value: _totalOrders.toString(),
                                  icon: Icons.shopping_cart_rounded,
                                  gradient: [
                                Colors.purple.shade400,
                                Colors.purple.shade600
                              ])),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Filter Tabs
                      Row(
                        children: [
                          _FilterTab(
                              label: 'All',
                              isSelected: selectedFilter == 'All',
                              onTap: () {
                                selectedFilter = 'All';
                                _applyFilters();
                              }),
                          const SizedBox(width: 8),
                          _FilterTab(
                              label: 'Active',
                              isSelected: selectedFilter == 'Active',
                              onTap: () {
                                selectedFilter = 'Active';
                                _applyFilters();
                              }),
                          const SizedBox(width: 8),
                          _FilterTab(
                              label: 'Inactive',
                              isSelected: selectedFilter == 'Inactive',
                              onTap: () {
                                selectedFilter = 'Inactive';
                                _applyFilters();
                              }),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Stores Panel
                      _StoresPanel(
                        stores: filteredStores,
                        displayedCount: displayedCount,
                        onLoadMore: _loadMore,
                        onSelectStore: (storeId) =>
                            setState(() => selectedStoreId = storeId),
                        onEditStore: (store) => _showStoreDialog(store: store),
                        onDeleteStore: (storeId) => _deleteStore(storeId),
                        onViewInventory: (storeId) =>
                            _showInventoryDialog(storeId),
                        onTransferStock: (storeId) =>
                            _showTransferDialog(storeId),
                      ),

                      // Store Details Panel
                      if (selectedStoreId != null) ...[
                        const SizedBox(height: 16),
                        _StoreDetailsPanel(
                          store: stores.firstWhere(
                              (s) => s['id'].toString() == selectedStoreId),
                          onClose: () => setState(() => selectedStoreId = null),
                          onViewInventory: () =>
                              _showInventoryDialog(selectedStoreId!),
                          onTransferStock: () =>
                              _showTransferDialog(selectedStoreId!),
                        ),
                      ],
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  void _showStoreDialog({Map<String, dynamic>? store}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _StorePage(
          store: store,
          onSaved: () {
            loadStores();
          },
        ),
      ),
    );
  }

  void _showInventoryDialog(String storeId) {
    final storeName = stores.firstWhere((s) => s['id'].toString() == storeId,
        orElse: () => {'name': 'Store'})['name'];
    showDialog(
      context: context,
      builder: (context) =>
          _InventoryDialog(storeId: storeId, storeName: storeName),
    );
  }

  void _showTransferDialog(String storeId) {
    if (stores.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('You need at least 2 stores to transfer stock')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) => _TransferDialog(
        fromStoreId: storeId,
        stores: stores,
        onTransferred: loadStores,
      ),
    );
  }

  Future<void> _deleteStore(String storeId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this store?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final response =
        await ApiService.delete('${ApiConfig.baseUrl}/stores.php?id=$storeId');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(response['message'] ??
            (response['success'] == true ? 'Deleted' : 'Failed')),
        backgroundColor:
            response['success'] == true ? Colors.green : Colors.red,
      ));
      if (response['success'] == true) loadStores();
    }
  }
}

// ── Gradient Metric Card ───────────────────────────────────────────────────
class _GradientMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final List<Color> gradient;

  const _GradientMetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.white),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Filter Tab ─────────────────────────────────────────────────────────────
class _FilterTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? cs.primaryContainer : cs.surface,
          border: Border.all(
              color:
                  isSelected ? cs.primary : cs.outline.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? cs.primary : cs.onSurface,
          ),
        ),
      ),
    );
  }
}

// ── Stores Panel ───────────────────────────────────────────────────────────
class _StoresPanel extends StatelessWidget {
  final List<dynamic> stores;
  final int displayedCount;
  final VoidCallback onLoadMore;
  final Function(String) onSelectStore;
  final Function(Map<String, dynamic>) onEditStore;
  final Function(String) onDeleteStore;
  final Function(String) onViewInventory;
  final Function(String) onTransferStock;

  const _StoresPanel({
    required this.stores,
    required this.displayedCount,
    required this.onLoadMore,
    required this.onSelectStore,
    required this.onEditStore,
    required this.onDeleteStore,
    required this.onViewInventory,
    required this.onTransferStock,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final displayedStores = stores.take(displayedCount).toList();
    final hasMore = stores.length > displayedCount;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(Icons.store_mall_directory_rounded,
                    size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Text('Stores',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface)),
                const Spacer(),
                Text('${displayedStores.length}/${stores.length} stores',
                    style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.5))),
              ],
            ),
          ),
          const Divider(height: 1),
          if (stores.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                  child: Text('No stores found',
                      style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.4)))),
            )
          else
            Column(
              children: [
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayedStores.length,
                  separatorBuilder: (_, __) => Divider(
                      height: 1, color: cs.outline.withValues(alpha: 0.08)),
                  itemBuilder: (context, index) {
                    final store =
                        displayedStores[index] as Map<String, dynamic>;
                    final isMain =
                        store['is_main'] == 1 || store['is_main'] == true;
                    final isActive =
                        store['is_active'] == 1 || store['is_active'] == true;
                    final totalOrders = int.tryParse(
                            store['total_orders']?.toString() ?? '0') ??
                        0;
                    final totalEmployees = int.tryParse(
                            store['total_employees']?.toString() ?? '0') ??
                        0;

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isMain
                                  ? Colors.amber.withValues(alpha: 0.1)
                                  : isActive
                                      ? Colors.green.withValues(alpha: 0.1)
                                      : Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                                isMain
                                    ? Icons.star_rounded
                                    : Icons.store_rounded,
                                size: 20,
                                color: isMain
                                    ? Colors.amber
                                    : isActive
                                        ? Colors.green
                                        : Colors.grey),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(store['name'],
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14),
                                        overflow: TextOverflow.ellipsis),
                                    const SizedBox(width: 8),
                                    if (isMain)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.amber
                                              .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text('Main',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.amber.shade700,
                                                fontWeight: FontWeight.w600)),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text('Code: ${store['code']}',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: cs.onSurface
                                            .withValues(alpha: 0.6))),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(Icons.person,
                                        size: 12,
                                        color: cs.onSurface
                                            .withValues(alpha: 0.5)),
                                    const SizedBox(width: 4),
                                    Text(store['manager_name'] ?? 'No manager',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: cs.onSurface
                                                .withValues(alpha: 0.6))),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? Colors.green
                                                .withValues(alpha: 0.1)
                                            : Colors.red.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                          isActive ? 'Active' : 'Inactive',
                                          style: TextStyle(
                                              fontSize: 10,
                                              color: isActive
                                                  ? Colors.green
                                                  : Colors.red,
                                              fontWeight: FontWeight.w600)),
                                    ),
                                    const SizedBox(width: 12),
                                    Text('$totalOrders orders',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: cs.onSurface
                                                .withValues(alpha: 0.5))),
                                    Text('  ·  ',
                                        style: TextStyle(
                                            color: cs.onSurface
                                                .withValues(alpha: 0.3))),
                                    Text('$totalEmployees employees',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: cs.onSurface
                                                .withValues(alpha: 0.5))),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              switch (value) {
                                case 'view':
                                  onSelectStore(store['id'].toString());
                                  break;
                                case 'edit':
                                  onEditStore(store);
                                  break;
                                case 'inventory':
                                  onViewInventory(store['id'].toString());
                                  break;
                                case 'transfer':
                                  onTransferStock(store['id'].toString());
                                  break;
                                case 'delete':
                                  onDeleteStore(store['id'].toString());
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'view',
                                child: Row(
                                  children: [
                                    Icon(Icons.visibility_rounded, size: 18),
                                    SizedBox(width: 8),
                                    Text('View Details'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_rounded, size: 18),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'inventory',
                                child: Row(
                                  children: [
                                    Icon(Icons.inventory_rounded, size: 18),
                                    SizedBox(width: 8),
                                    Text('View Inventory'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'transfer',
                                child: Row(
                                  children: [
                                    Icon(Icons.swap_horiz_rounded, size: 18),
                                    SizedBox(width: 8),
                                    Text('Transfer Stock'),
                                  ],
                                ),
                              ),
                              if (!isMain)
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_rounded,
                                          size: 18, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Delete',
                                          style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                            ],
                            icon: Icon(Icons.more_vert_rounded,
                                size: 18,
                                color: cs.onSurface.withValues(alpha: 0.5)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                if (hasMore)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: onLoadMore,
                        icon: const Icon(Icons.expand_more_rounded),
                        label: Text(
                            'Load More (${stores.length - displayedCount} remaining)'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

// ── Store Details Panel ────────────────────────────────────────────────────
class _StoreDetailsPanel extends StatelessWidget {
  final Map<String, dynamic> store;
  final VoidCallback onClose;
  final VoidCallback onViewInventory;
  final VoidCallback onTransferStock;

  const _StoreDetailsPanel({
    required this.store,
    required this.onClose,
    required this.onViewInventory,
    required this.onTransferStock,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isMain = store['is_main'] == 1 || store['is_main'] == true;
    final isActive = store['is_active'] == 1 || store['is_active'] == true;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isMain
                        ? Colors.amber.withValues(alpha: 0.1)
                        : isActive
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(isMain ? Icons.star_rounded : Icons.store_rounded,
                      size: 16,
                      color: isMain
                          ? Colors.amber
                          : isActive
                              ? Colors.green
                              : Colors.grey),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(store['name'],
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _DetailRow(label: 'Store Code', value: store['code']),
                _DetailRow(
                    label: 'Address',
                    value: store['address'] ?? 'Not provided'),
                _DetailRow(
                    label: 'Phone', value: store['phone'] ?? 'Not provided'),
                _DetailRow(
                    label: 'Email', value: store['email'] ?? 'Not provided'),
                _DetailRow(
                    label: 'Manager',
                    value: store['manager_name'] ?? 'Not assigned'),
                _DetailRow(
                    label: 'Status',
                    value: isActive ? 'Active' : 'Inactive',
                    valueColor: isActive ? Colors.green : Colors.red),
                _DetailRow(
                    label: 'Total Orders',
                    value: (int.tryParse(
                                store['total_orders']?.toString() ?? '0') ??
                            0)
                        .toString()),
                _DetailRow(
                    label: 'Total Employees',
                    value: (int.tryParse(
                                store['total_employees']?.toString() ?? '0') ??
                            0)
                        .toString()),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onViewInventory,
                        icon: const Icon(Icons.inventory_rounded),
                        label: const Text('View Inventory'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onTransferStock,
                        icon: const Icon(Icons.swap_horiz_rounded),
                        label: const Text('Transfer Stock'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
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
}

// ── Detail Row ─────────────────────────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: cs.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: valueColor ?? cs.onSurface,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Store Dialog ───────────────────────────────────────────────────────────
class _StorePage extends StatefulWidget {
  final Map<String, dynamic>? store;
  final VoidCallback onSaved;

  const _StorePage({
    this.store,
    required this.onSaved,
  });

  @override
  State<_StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<_StorePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _code;
  late final TextEditingController _address;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late bool _isActive;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.store?['name']);
    _code = TextEditingController(text: widget.store?['code']);
    _address = TextEditingController(text: widget.store?['address']);
    _phone = TextEditingController(text: widget.store?['phone']);
    _email = TextEditingController(text: widget.store?['email']);
    _isActive = widget.store?['is_active'] == 1 ||
        widget.store?['is_active'] == true ||
        widget.store == null;
  }

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _address.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final data = {
      'name': _name.text.trim(),
      'code': _code.text.trim(),
      'address': _address.text.trim(),
      'phone': _phone.text.trim(),
      'email': _email.text.trim(),
      'is_active': _isActive,
    };

    final response = widget.store == null
        ? await ApiService.post('${ApiConfig.baseUrl}/stores.php', data)
        : await ApiService.put(
            '${ApiConfig.baseUrl}/stores.php?id=${widget.store!['id']}', data);

    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(response['message'] ??
          (response['success'] == true ? 'Saved' : 'Failed')),
      backgroundColor: response['success'] == true ? Colors.green : Colors.red,
    ));

    if (response['success'] == true) {
      Navigator.pop(context);
      widget.onSaved();
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isPhone = width < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.store == null ? 'Add Store' : 'Edit Store',
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueGrey.shade700,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
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
                            child: Icon(
                              widget.store == null
                                  ? Icons.add_business
                                  : Icons.edit_rounded,
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
                                  widget.store == null
                                      ? 'Add New Store'
                                      : 'Edit Store Details',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blueGrey.shade800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Configure store information and settings',
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
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _name,
                        decoration: const InputDecoration(
                          labelText: 'Store Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.store),
                        ),
                        validator: (v) =>
                            v?.isEmpty == true ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _code,
                        decoration: const InputDecoration(
                          labelText: 'Store Code',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.tag),
                        ),
                        textCapitalization: TextCapitalization.characters,
                        validator: (v) =>
                            v?.isEmpty == true ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _address,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _email,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Active Store'),
                  subtitle: const Text('Inactive stores cannot process orders'),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isLoading ? null : _save,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: const Text('Save Store'),
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
          ),
        ),
      ),
    );
  }
}

// ── Inventory Dialog ───────────────────────────────────────────────────────
class _InventoryDialog extends StatefulWidget {
  final String storeId;
  final String storeName;
  const _InventoryDialog({required this.storeId, required this.storeName});

  @override
  State<_InventoryDialog> createState() => _InventoryDialogState();
}

class _InventoryDialogState extends State<_InventoryDialog> {
  List<dynamic> _inventory = [];
  bool _isLoading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final response = await ApiService.get(
        '${ApiConfig.baseUrl}/stores.php?inventory=1&store_id=${widget.storeId}');
    setState(() {
      _inventory = response is List ? response : [];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _search.isEmpty
        ? _inventory
        : _inventory
            .where((i) =>
                (i['product_name'] ?? '')
                    .toLowerCase()
                    .contains(_search.toLowerCase()) ||
                (i['barcode'] ?? '')
                    .toLowerCase()
                    .contains(_search.toLowerCase()))
            .toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 600,
        height: 520,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [Colors.blue.shade500, Colors.blue.shade700]),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.inventory_rounded, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('${widget.storeName} — Inventory',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                  ),
                  IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: _load,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints()),
                  const SizedBox(width: 8),
                  IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints()),
                ],
              ),
            ),
            // Search
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  isDense: true,
                ),
              ),
            ),
            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2_outlined,
                                  size: 48, color: Colors.grey[300]),
                              const SizedBox(height: 8),
                              Text(
                                  _search.isEmpty
                                      ? 'No inventory for this store'
                                      : 'No results',
                                  style: TextStyle(color: Colors.grey[500])),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final item = filtered[i] as Map<String, dynamic>;
                            final qty = int.tryParse(
                                    item['quantity']?.toString() ?? '0') ??
                                0;
                            final isLow = qty <= 5;
                            return ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 18,
                                backgroundColor: isLow
                                    ? Colors.red.withValues(alpha: 0.1)
                                    : Colors.blue.withValues(alpha: 0.1),
                                child: Icon(Icons.inventory_2_rounded,
                                    size: 16,
                                    color: isLow ? Colors.red : Colors.blue),
                              ),
                              title: Text(item['product_name'] ?? '',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                              subtitle: Text(item['barcode'] ?? '',
                                  style: const TextStyle(fontSize: 11)),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isLow
                                      ? Colors.red.withValues(alpha: 0.1)
                                      : Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('$qty units',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color:
                                            isLow ? Colors.red : Colors.green)),
                              ),
                            );
                          },
                        ),
            ),
            // Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Text('${filtered.length} products',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  const Spacer(),
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Transfer Dialog ────────────────────────────────────────────────────────
class _TransferDialog extends StatefulWidget {
  final String fromStoreId;
  final List<dynamic> stores;
  final VoidCallback onTransferred;
  const _TransferDialog(
      {required this.fromStoreId,
      required this.stores,
      required this.onTransferred});

  @override
  State<_TransferDialog> createState() => _TransferDialogState();
}

class _TransferDialogState extends State<_TransferDialog> {
  List<dynamic> _inventory = [];
  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic>? _selectedProduct;
  String? _toStoreId;
  final _qtyController = TextEditingController(text: '1');
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _toStoreId = widget.stores
        .firstWhere((s) => s['id'].toString() != widget.fromStoreId,
            orElse: () => widget.stores.first)['id']
        .toString();
    _loadInventory();
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadInventory() async {
    setState(() => _isLoading = true);
    final response = await ApiService.get(
        '${ApiConfig.baseUrl}/stores.php?inventory=1&store_id=${widget.fromStoreId}');
    setState(() {
      _inventory = response is List ? response : [];
      _isLoading = false;
    });
  }

  Future<void> _submit() async {
    if (_selectedProduct == null || _toStoreId == null) return;
    final qty = int.tryParse(_qtyController.text.trim()) ?? 0;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid quantity')));
      return;
    }
    setState(() => _isSaving = true);
    final response = await ApiService.post(
      '${ApiConfig.baseUrl}/stores.php?transfer=1',
      {
        'from_store_id': widget.fromStoreId,
        'to_store_id': _toStoreId,
        'product_id': _selectedProduct!['product_id'],
        'quantity': qty,
        'notes': _notesController.text.trim(),
      },
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(response['message'] ??
          (response['success'] == true ? 'Transfer created' : 'Failed')),
      backgroundColor: response['success'] == true ? Colors.green : Colors.red,
    ));
    if (response['success'] == true) {
      Navigator.pop(context);
      widget.onTransferred();
    }
  }

  @override
  Widget build(BuildContext context) {
    final fromStore = widget.stores.firstWhere(
        (s) => s['id'].toString() == widget.fromStoreId,
        orElse: () => {'name': 'Store'});
    final otherStores = widget.stores
        .where((s) => s['id'].toString() != widget.fromStoreId)
        .toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [Colors.orange.shade500, Colors.orange.shade700]),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.swap_horiz_rounded, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Transfer Stock from ${fromStore['name']}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                  ),
                  IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints()),
                ],
              ),
            ),
            // Form
            Padding(
              padding: const EdgeInsets.all(16),
              child: _isLoading
                  ? const Center(
                      child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator()))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product picker
                        DropdownButtonFormField<Map<String, dynamic>>(
                          initialValue: _selectedProduct,
                          decoration: const InputDecoration(
                              labelText: 'Product',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.inventory_2_rounded)),
                          hint: const Text('Select product'),
                          items: _inventory.map((item) {
                            final qty = int.tryParse(
                                    item['quantity']?.toString() ?? '0') ??
                                0;
                            return DropdownMenuItem<Map<String, dynamic>>(
                              value: item as Map<String, dynamic>,
                              child: Text(
                                  '${item['product_name']} ($qty in stock)',
                                  overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (v) =>
                              setState(() => _selectedProduct = v),
                        ),
                        const SizedBox(height: 12),
                        // Destination store
                        DropdownButtonFormField<String>(
                          initialValue: _toStoreId,
                          decoration: const InputDecoration(
                              labelText: 'Destination Store',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.store_rounded)),
                          items: otherStores
                              .map((s) => DropdownMenuItem<String>(
                                    value: s['id'].toString(),
                                    child: Text(s['name']),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _toStoreId = v),
                        ),
                        const SizedBox(height: 12),
                        // Quantity
                        TextField(
                          controller: _qtyController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              labelText: 'Quantity',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.numbers_rounded)),
                        ),
                        const SizedBox(height: 12),
                        // Notes
                        TextField(
                          controller: _notesController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                              labelText: 'Notes (optional)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.notes_rounded)),
                        ),
                      ],
                    ),
            ),
            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel')),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed:
                        _isSaving || _selectedProduct == null ? null : _submit,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send_rounded),
                    label: const Text('Transfer'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
