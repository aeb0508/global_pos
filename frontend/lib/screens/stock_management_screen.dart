import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/api_config.dart';

class StockManagementScreen extends StatefulWidget {
  const StockManagementScreen({super.key});

  @override
  State<StockManagementScreen> createState() => _StockManagementScreenState();
}

class _StockManagementScreenState extends State<StockManagementScreen> {
  List<dynamic> _products = [];
  List<dynamic> _filteredProducts = [];
  List<dynamic> _logs = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _filterType = 'all';
  static const int _itemsPerPage = 10;
  int _displayedCount = _itemsPerPage;
  int _displayedLogsCount = _itemsPerPage;
  final TextEditingController _searchCtrl = TextEditingController();

  int get _lowStockCount => _products.where((p) {
        final stock = int.tryParse(p['stock_quantity'].toString()) ?? 0;
        final threshold =
            int.tryParse(p['low_stock_threshold'].toString()) ?? 0;
        return stock <= threshold;
      }).length;

  int get _outOfStockCount => _products.where((p) {
        return (int.tryParse(p['stock_quantity'].toString()) ?? 0) <= 0;
      }).length;

  int get _totalUnits => _products.fold(0, (sum, p) {
        return sum + (int.tryParse(p['stock_quantity'].toString()) ?? 0);
      });

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.get('${ApiConfig.baseUrl}/products.php'),
        ApiService.get('${ApiConfig.baseUrl}/stock_management.php?logs=1'),
      ]);
      if (results[0]['success'] == true && results[1]['success'] == true) {
        setState(() {
          _products = results[0]['data'] as List;
          _logs = results[1]['data'] as List;
          _applyFilters();
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
    _searchQuery = _searchQuery.toLowerCase();
    _filteredProducts = _products.where((p) {
      final matchesSearch =
          (p['name'] as String).toLowerCase().contains(_searchQuery);
      final stock = int.tryParse(p['stock_quantity'].toString()) ?? 0;
      final threshold = int.tryParse(p['low_stock_threshold'].toString()) ?? 0;
      final matchesFilter = switch (_filterType) {
        'low' => stock > 0 && stock <= threshold,
        'out' => stock <= 0,
        _ => true,
      };
      return matchesSearch && matchesFilter;
    }).toList();
    _displayedCount = _itemsPerPage; // Reset to first page on filter change
  }

  void _showAdjustmentDialog(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (_) => _StockAdjustmentDialog(
        product: product,
        onSaved: () {
          Navigator.pop(context);
          _loadData();
        },
      ),
    );
  }

  void _loadMore() {
    setState(() {
      _displayedCount += _itemsPerPage;
    });
  }

  void _loadMoreLogs() {
    setState(() {
      _displayedLogsCount += _itemsPerPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // ── App Bar with Search ─────────────────────────
                SliverAppBar(
                  floating: true,
                  pinned: true,
                  expandedHeight: 120,
                  title: const Row(
                    children: [
                      Icon(Icons.inventory_2_outlined,
                          color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('Stock Management',
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
                          colors: [Colors.blue.shade600, Colors.blue.shade800],
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
                            //   'Stock Management',
                            //   style: TextStyle(
                            //     fontSize: 24,
                            //     fontWeight: FontWeight.bold,
                            //     color: Colors.white,
                            //   ),
                            // ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _searchCtrl,
                              onChanged: (q) {
                                _searchQuery = q;
                                _applyFilters();
                                setState(() {});
                              },
                              decoration: InputDecoration(
                                hintText: 'Search products by name or code...',
                                prefixIcon: const Icon(Icons.search,
                                    color: Colors.white70),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear,
                                            color: Colors.white70, size: 18),
                                        onPressed: () {
                                          _searchCtrl.clear();
                                          _searchQuery = '';
                                          _applyFilters();
                                          setState(() {});
                                        },
                                      )
                                    : null,
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
                      icon: const Icon(Icons.add, color: Colors.white),
                      onPressed: () {
                        // Add new product
                      },
                      tooltip: 'Add Product',
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: _loadData,
                      tooltip: 'Refresh',
                    ),
                  ],
                ),

                // ── Stats ────────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Expanded(
                            child: _GradientStatCard(
                                label: 'Total Products',
                                value: '${_products.length}',
                                icon: Icons.inventory_2_outlined,
                                gradient: [
                              cs.primary,
                              cs.primary.withValues(alpha: 0.7)
                            ])),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _GradientStatCard(
                                label: 'Total Units',
                                value: '$_totalUnits',
                                icon: Icons.layers_outlined,
                                gradient: [
                              Colors.blue,
                              Colors.blue.withValues(alpha: 0.7)
                            ])),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _GradientStatCard(
                                label: 'Low Stock',
                                value: '$_lowStockCount',
                                icon: Icons.warning_amber_rounded,
                                gradient: [
                              Colors.orange,
                              Colors.orange.withValues(alpha: 0.7)
                            ])),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _GradientStatCard(
                                label: 'Out of Stock',
                                value: '$_outOfStockCount',
                                icon: Icons.remove_shopping_cart_outlined,
                                gradient: [
                              Colors.red,
                              Colors.red.withValues(alpha: 0.7)
                            ])),
                      ],
                    ),
                  ),
                ),

                // ── Filter Tabs ───────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  sliver: SliverToBoxAdapter(
                    child: SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _FilterTab(
                            label: 'All',
                            isSelected: _filterType == 'all',
                            onTap: () {
                              setState(() {
                                _filterType = 'all';
                                _applyFilters();
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          _FilterTab(
                            label: 'Low Stock',
                            isSelected: _filterType == 'low',
                            onTap: () {
                              setState(() {
                                _filterType = 'low';
                                _applyFilters();
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          _FilterTab(
                            label: 'Out of Stock',
                            isSelected: _filterType == 'out',
                            onTap: () {
                              setState(() {
                                _filterType = 'out';
                                _applyFilters();
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Products + Logs side by side ─────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverToBoxAdapter(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isMobile = constraints.maxWidth < 700;
                        if (isMobile) {
                          return Column(
                            children: [
                              _ProductsPanel(
                                  products: _filteredProducts,
                                  displayedCount: _displayedCount,
                                  onAdjust: _showAdjustmentDialog,
                                  onLoadMore: _loadMore),
                              const SizedBox(height: 16),
                              _LogsPanel(
                                logs: _logs,
                                displayedCount: _displayedLogsCount,
                                onLoadMore: _loadMoreLogs,
                              ),
                            ],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: _ProductsPanel(
                                  products: _filteredProducts,
                                  displayedCount: _displayedCount,
                                  onAdjust: _showAdjustmentDialog,
                                  onLoadMore: _loadMore),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: _LogsPanel(
                                logs: _logs,
                                displayedCount: _displayedLogsCount,
                                onLoadMore: _loadMoreLogs,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// ── Gradient Stat Card ────────────────────────────────────────────────────
class _GradientStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final List<Color> gradient;

  const _GradientStatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.gradient});

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

// ── Filter Tab ────────────────────────────────────────────────────────────
class _FilterTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterTab(
      {required this.label, required this.isSelected, required this.onTap});

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
              color: isSelected ? cs.primary : cs.outline.withValues(alpha: 0.3)),
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

// ── Products Panel ─────────────────────────────────────────────────────────────
class _ProductsPanel extends StatelessWidget {
  final List<dynamic> products;
  final int displayedCount;
  final void Function(Map<String, dynamic>) onAdjust;
  final VoidCallback onLoadMore;

  const _ProductsPanel({
    required this.products,
    required this.displayedCount,
    required this.onAdjust,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final displayedProducts = products.take(displayedCount).toList();
    final hasMore = products.length > displayedCount;

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
                Icon(Icons.inventory_2_outlined, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Text('Products',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface)),
                const Spacer(),
                Text('${displayedProducts.length}/${products.length} items',
                    style: TextStyle(
                        fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
              ],
            ),
          ),
          const Divider(height: 1),
          if (products.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                  child: Text('No products found',
                      style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4)))),
            )
          else
            Column(
              children: [
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayedProducts.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: cs.outline.withValues(alpha: 0.08)),
                  itemBuilder: (context, index) {
                    final product =
                        displayedProducts[index] as Map<String, dynamic>;
                    final stock =
                        int.tryParse(product['stock_quantity'].toString()) ?? 0;
                    final threshold = int.tryParse(
                            product['low_stock_threshold'].toString()) ??
                        0;
                    final isOut = stock <= 0;
                    final isLow = !isOut && stock <= threshold;
                    final stockColor = isOut
                        ? Colors.red
                        : isLow
                            ? Colors.orange
                            : Colors.green;
                    final maxStock = threshold * 2;
                    final progress =
                        maxStock > 0 ? (stock / maxStock).clamp(0.0, 1.0) : 0.0;

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: stockColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.inventory_2_outlined,
                                size: 18, color: stockColor),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(product['name'] ?? '',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13),
                                    overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text('$stock units',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: stockColor,
                                            fontWeight: FontWeight.w600)),
                                    if (product['category_name'] != null) ...[
                                      Text('  ·  ',
                                          style: TextStyle(
                                              color: cs.onSurface
                                                  .withValues(alpha: 0.3))),
                                      Flexible(
                                          child: Text(product['category_name'],
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: cs.onSurface
                                                      .withValues(alpha: 0.45)),
                                              overflow: TextOverflow.ellipsis)),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 6),
                                LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: cs.outline.withValues(alpha: 0.2),
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(stockColor),
                                  minHeight: 4,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isOut || isLow)
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: stockColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: stockColor.withValues(alpha: 0.3)),
                              ),
                              child: Text(isOut ? 'Out' : 'Low',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: stockColor,
                                      fontWeight: FontWeight.bold)),
                            ),
                          FilledButton.tonal(
                            onPressed: () => onAdjust(product),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              visualDensity: VisualDensity.compact,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Adjust',
                                style: TextStyle(fontSize: 12)),
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
                            'Load More (${products.length - displayedCount} remaining)'),
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

// ── Logs Panel ─────────────────────────────────────────────────────────────────
class _LogsPanel extends StatelessWidget {
  final List<dynamic> logs;
  final int displayedCount;
  final VoidCallback onLoadMore;

  const _LogsPanel({
    required this.logs,
    required this.displayedCount,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final displayedLogs = logs.take(displayedCount).toList();
    final hasMore = logs.length > displayedCount;

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
                Icon(Icons.history_rounded, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Text('Recent Adjustments',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface)),
                const Spacer(),
                Text('${displayedLogs.length}/${logs.length} logs',
                    style: TextStyle(
                        fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
              ],
            ),
          ),
          const Divider(height: 1),
          if (logs.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                  child: Text('No adjustments yet',
                      style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4)))),
            )
          else
            Column(
              children: [
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayedLogs.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: cs.outline.withValues(alpha: 0.08)),
                  itemBuilder: (context, index) {
                    final log = displayedLogs[index];
                    final change =
                        int.tryParse(log['quantity_change'].toString()) ?? 0;
                    final isPositive = change > 0;
                    final color = isPositive ? Colors.green : Colors.red;

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                                isPositive
                                    ? Icons.add_rounded
                                    : Icons.remove_rounded,
                                size: 18,
                                color: color),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(log['product_name'] ?? '',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13),
                                    overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 2),
                                Text(log['notes'] ?? log['type'] ?? '',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: cs.onSurface.withValues(alpha: 0.5)),
                                    overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${isPositive ? '+' : ''}$change',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: color),
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
                            'Load More (${logs.length - displayedCount} remaining)'),
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

// ── Adjustment Dialog ──────────────────────────────────────────────────────────
class _StockAdjustmentDialog extends StatefulWidget {
  final Map<String, dynamic> product;
  final VoidCallback onSaved;

  const _StockAdjustmentDialog({required this.product, required this.onSaved});

  @override
  State<_StockAdjustmentDialog> createState() => _StockAdjustmentDialogState();
}

class _StockAdjustmentDialogState extends State<_StockAdjustmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();
  String _type = 'add';
  bool _isLoading = false;

  int get _currentStock =>
      int.tryParse(widget.product['stock_quantity'].toString()) ?? 0;

  int get _previewStock {
    final qty = int.tryParse(_quantityController.text) ?? 0;
    return _type == 'add' ? _currentStock + qty : _currentStock - qty;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final qty = int.parse(_quantityController.text);
    try {
      final response =
          await ApiService.post('${ApiConfig.baseUrl}/stock_management.php', {
        'product_id': widget.product['id'],
        'quantity_change': _type == 'add' ? qty : -qty,
        'notes': _notesController.text,
      });
      if (response['success'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Stock adjusted successfully'),
              backgroundColor: Colors.green),
        );
        widget.onSaved();
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
    final cs = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 450,
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [cs.primary, cs.primary.withValues(alpha: 0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child:
                        Icon(Icons.tune_rounded, color: cs.onPrimary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.product['name'] ?? '',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Current stock display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      cs.primaryContainer,
                      cs.primaryContainer.withValues(alpha: 0.7)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text('Current Stock',
                        style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.7))),
                    const SizedBox(height: 4),
                    Text('$_currentStock units',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: cs.primary)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Add / Remove toggle
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: cs.outline.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _type = 'add'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _type == 'add'
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.transparent,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(11),
                              bottomLeft: Radius.circular(11),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_rounded,
                                  size: 18,
                                  color: _type == 'add'
                                      ? Colors.green
                                      : cs.onSurface.withValues(alpha: 0.6)),
                              const SizedBox(width: 6),
                              Text('Add Stock',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: _type == 'add'
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: _type == 'add'
                                          ? Colors.green
                                          : cs.onSurface)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(
                        width: 1,
                        height: 40,
                        color: cs.outline.withValues(alpha: 0.3)),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _type = 'remove'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _type == 'remove'
                                ? Colors.red.withValues(alpha: 0.1)
                                : Colors.transparent,
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(11),
                              bottomRight: Radius.circular(11),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.remove_rounded,
                                  size: 18,
                                  color: _type == 'remove'
                                      ? Colors.red
                                      : cs.onSurface.withValues(alpha: 0.6)),
                              const SizedBox(width: 6),
                              Text('Remove Stock',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: _type == 'remove'
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: _type == 'remove'
                                          ? Colors.red
                                          : cs.onSurface)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Quantity input
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  prefixIcon: Icon(
                      _type == 'add' ? Icons.add_rounded : Icons.remove_rounded,
                      color: _type == 'add' ? Colors.green : Colors.red),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (int.tryParse(v) == null || int.parse(v) <= 0) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Preview
              if (_quantityController.text.isNotEmpty &&
                  int.tryParse(_quantityController.text) != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.visibility_rounded,
                          size: 16, color: cs.onSurface.withValues(alpha: 0.6)),
                      const SizedBox(width: 8),
                      Text('New stock: $_previewStock units',
                          style: TextStyle(
                              fontSize: 14,
                              color: cs.onSurface.withValues(alpha: 0.8))),
                    ],
                  ),
                ),
              const SizedBox(height: 12),

              // Notes
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  prefixIcon: Icon(Icons.notes_rounded,
                      color: cs.onSurface.withValues(alpha: 0.6)),
                ),
              ),
              const SizedBox(height: 24),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    child: Text('Cancel',
                        style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7))),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _isLoading ? null : _save,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Save Adjustment'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
