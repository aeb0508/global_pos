import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_settings_provider.dart';
import '../services/api_service.dart';
import '../utils/api_config.dart';

class PriceManagementScreen extends StatefulWidget {
  const PriceManagementScreen({super.key});

  @override
  State<PriceManagementScreen> createState() => _PriceManagementScreenState();
}

class _PriceManagementScreenState extends State<PriceManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _products = [];
  List<dynamic> _filteredProducts = [];
  List<dynamic> _priceHistory = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _filterType = 'all';
  final Map<String, TextEditingController> _priceControllers = {};
  final Map<String, bool> _saving = {};
  static const int _itemsPerPage = 10;
  int _displayedCount = _itemsPerPage;
  int _displayedHistoryCount = _itemsPerPage;

  int get _changedCount {
    int count = 0;
    for (final p in _products) {
      final id = p['id'].toString();
      final current = double.tryParse(_priceControllers[id]?.text ?? '') ?? 0;
      final original = double.tryParse(p['selling_price'].toString()) ?? 0;
      if ((current - original).abs() > 0.001) count++;
    }
    return count;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final c in _priceControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.get('${ApiConfig.baseUrl}/products.php'),
        ApiService.get('${ApiConfig.baseUrl}/price_management.php?history=1'),
      ]);
      if (results[0]['success'] == true) {
        final products = results[0]['data'] as List;
        for (final c in _priceControllers.values) {
          c.dispose();
        }
        _priceControllers.clear();
        for (final p in products) {
          final id = p['id'].toString();
          _priceControllers[id] = TextEditingController(
              text: double.parse(p['selling_price'].toString())
                  .toStringAsFixed(2));
        }
        setState(() {
          _products = products;
          _priceHistory =
              results[1]['success'] == true ? (results[1]['data'] ?? []) : [];
          _applySearch(_searchQuery);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _applySearch(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
  }

  void _applyFilters() {
    _filteredProducts = _products.where((p) {
      final matchesSearch =
          (p['name'] as String).toLowerCase().contains(_searchQuery);
      final cost = double.tryParse(p['cost_price'].toString()) ?? 0;
      final price = double.tryParse(p['selling_price'].toString()) ?? 0;
      final margin = cost > 0 ? ((price - cost) / cost * 100) : 0;

      final matchesFilter = switch (_filterType) {
        'high' => margin >= 50,
        'medium' => margin >= 20 && margin < 50,
        'low' => margin < 20,
        'updated' => _changedCount > 0,
        _ => true,
      };
      return matchesSearch && matchesFilter;
    }).toList();
    _displayedCount = _itemsPerPage; // Reset pagination on filter change
  }

  Future<void> _updatePrice(Map<String, dynamic> product) async {
    final id = product['id'].toString();
    final newPrice = double.tryParse(_priceControllers[id]?.text ?? '');
    if (newPrice == null || newPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Invalid price'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _saving[id] = true);
    try {
      final response =
          await ApiService.post('${ApiConfig.baseUrl}/price_management.php', {
        'product_id': id,
        'new_price': newPrice,
        'old_price': double.parse(product['selling_price'].toString()),
      });
      if (response['success'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Price updated'), backgroundColor: Colors.green),
        );
        _loadData();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(response['message'] ?? 'Failed'),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving.remove(id));
    }
  }

  void _loadMore() {
    setState(() {
      _displayedCount += _itemsPerPage;
    });
  }

  void _loadMoreHistory() {
    setState(() {
      _displayedHistoryCount += _itemsPerPage;
    });
  }

  double get _totalCost => _products.fold(0.0, (sum, p) {
        return sum + (double.tryParse(p['cost_price'].toString()) ?? 0);
      });

  double get _totalRevenue => _products.fold(0.0, (sum, p) {
        return sum + (double.tryParse(p['selling_price'].toString()) ?? 0);
      });

  double get _avgMargin {
    if (_products.isEmpty) return 0;
    double totalMargin = 0;
    for (final p in _products) {
      final cost = double.tryParse(p['cost_price'].toString()) ?? 0;
      final price = double.tryParse(p['selling_price'].toString()) ?? 0;
      if (cost > 0) {
        totalMargin += ((price - cost) / cost * 100);
      }
    }
    return totalMargin / _products.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              physics: const ClampingScrollPhysics(),
              slivers: [
                // ── App Bar with Search ─────────────────────────
                SliverAppBar(
                  floating: true,
                  pinned: true,
                  expandedHeight: 120,
                  title: const Row(
                    children: [
                      Icon(Icons.sell_outlined, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('Price Management',
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
                            //   'Price Management',
                            //   style: TextStyle(
                            //     fontSize: 24,
                            //     fontWeight: FontWeight.bold,
                            //     color: Colors.white,
                            //   ),
                            // ),
                            const SizedBox(height: 8),
                            TextField(
                              onChanged: (q) {
                                setState(() => _applySearch(q));
                              },
                              decoration: InputDecoration(
                                hintText: 'Search products by name or code...',
                                prefixIcon: const Icon(Icons.search,
                                    color: Colors.white70),
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
                        // Add new price
                      },
                      tooltip: 'Add Product Price',
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: _loadData,
                      tooltip: 'Refresh',
                    ),
                  ],
                ),

                // ── Stat Cards ──────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: Builder(builder: (ctx) {
                      final sym =
                          ctx.watch<AppSettingsProvider>().currencySymbol;
                      return Row(children: [
                        Expanded(
                            child: _GradientMetricCard(
                                label: 'Total Revenue',
                                value:
                                    '${_totalRevenue.toStringAsFixed(2)} $sym',
                                icon: Icons.trending_up_rounded,
                                gradient: [
                              Colors.green,
                              Colors.green.withValues(alpha: 0.7)
                            ])),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _GradientMetricCard(
                                label: 'Total Cost',
                                value: '${_totalCost.toStringAsFixed(2)} $sym',
                                icon: Icons.attach_money_rounded,
                                gradient: [
                              Colors.orange,
                              Colors.orange.withValues(alpha: 0.7)
                            ])),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _GradientMetricCard(
                                label: 'Avg Margin',
                                value: '${_avgMargin.toStringAsFixed(1)}%',
                                icon: Icons.percent_rounded,
                                gradient: [
                              Colors.purple,
                              Colors.purple.withValues(alpha: 0.7)
                            ])),
                      ]);
                    }),
                  ),
                ),

                // ── Filter Tabs ────────────────────────────────
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
                            label: 'High Margin',
                            isSelected: _filterType == 'high',
                            onTap: () {
                              setState(() {
                                _filterType = 'high';
                                _applyFilters();
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          _FilterTab(
                            label: 'Medium Margin',
                            isSelected: _filterType == 'medium',
                            onTap: () {
                              setState(() {
                                _filterType = 'medium';
                                _applyFilters();
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          _FilterTab(
                            label: 'Low Margin',
                            isSelected: _filterType == 'low',
                            onTap: () {
                              setState(() {
                                _filterType = 'low';
                                _applyFilters();
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Products List ───────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverToBoxAdapter(
                    child: _ProductsPanel(
                      products: _filteredProducts,
                      displayedCount: _displayedCount,
                      priceControllers: _priceControllers,
                      saving: _saving,
                      onUpdate: _updatePrice,
                      onLoadMore: _loadMore,
                    ),
                  ),
                ),

                // ── History Tab ────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverToBoxAdapter(
                    child: _HistoryPanel(
                      history: _priceHistory,
                      displayedCount: _displayedHistoryCount,
                      onLoadMore: _loadMoreHistory,
                    ),
                  ),
                ),
              ],
            ),
    );
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

// ── Products Panel ─────────────────────────────────────────────────────────
class _ProductsPanel extends StatelessWidget {
  final List<dynamic> products;
  final int displayedCount;
  final Map<String, TextEditingController> priceControllers;
  final Map<String, bool> saving;
  final Future<void> Function(Map<String, dynamic>) onUpdate;
  final VoidCallback onLoadMore;

  const _ProductsPanel({
    required this.products,
    required this.displayedCount,
    required this.priceControllers,
    required this.saving,
    required this.onUpdate,
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
                    final id = product['id'].toString();
                    final cost =
                        double.tryParse(product['cost_price'].toString()) ?? 0;
                    final current =
                        double.tryParse(product['selling_price'].toString()) ??
                            0;
                    final margin =
                        cost > 0 ? ((current - cost) / cost * 100) : 0.0;
                    final isSaving = saving[id] == true;
                    final marginColor = margin >= 50
                        ? Colors.green
                        : margin >= 20
                            ? Colors.orange
                            : Colors.red;

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: marginColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.sell_outlined,
                                size: 18, color: marginColor),
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
                                    Text(
                                        'Cost: ${cost.toStringAsFixed(2)} ${context.watch<AppSettingsProvider>().currencySymbol}',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color:
                                                cs.onSurface.withValues(alpha: 0.5))),
                                    Text('  ·  ',
                                        style: TextStyle(
                                            color:
                                                cs.onSurface.withValues(alpha: 0.3))),
                                    Text(
                                        'Margin: ${margin.toStringAsFixed(1)}%',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: marginColor,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                LinearProgressIndicator(
                                  value: (margin / 100).clamp(0.0, 1.0),
                                  backgroundColor: cs.outline.withValues(alpha: 0.2),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      marginColor),
                                  minHeight: 4,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Current',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: cs.onSurface.withValues(alpha: 0.45))),
                              Text(
                                  '${current.toStringAsFixed(2)} ${context.watch<AppSettingsProvider>().currencySymbol}',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: cs.onSurface)),
                            ],
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            height: 38,
                            child: FilledButton.icon(
                              onPressed: isSaving
                                  ? null
                                  : () => _showPriceDialog(
                                      context, product, onUpdate),
                              style: FilledButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: isSaving
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.edit_rounded, size: 16),
                              label: const Text('Edit',
                                  style: TextStyle(fontSize: 12)),
                            ),
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

  static void _showPriceDialog(
    BuildContext context,
    Map<String, dynamic> product,
    Future<void> Function(Map<String, dynamic>) onUpdate,
  ) {
    showDialog(
      context: context,
      builder: (context) => _PriceUpdateDialog(
        product: product,
        onUpdate: onUpdate,
      ),
    );
  }
}

// ── Price Update Dialog ────────────────────────────────────────────────────
class _PriceUpdateDialog extends StatefulWidget {
  final Map<String, dynamic> product;
  final Future<void> Function(Map<String, dynamic>) onUpdate;

  const _PriceUpdateDialog({
    required this.product,
    required this.onUpdate,
  });

  @override
  State<_PriceUpdateDialog> createState() => _PriceUpdateDialogState();
}

class _PriceUpdateDialogState extends State<_PriceUpdateDialog> {
  late TextEditingController _priceController;
  bool _isLoading = false;

  double get _cost =>
      double.tryParse(widget.product['cost_price'].toString()) ?? 0;

  double get _newPrice => double.tryParse(_priceController.text) ?? 0;

  double get _margin => _cost > 0 ? ((_newPrice - _cost) / _cost * 100) : 0;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(
      text: double.parse(widget.product['selling_price'].toString())
          .toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_newPrice <= 0 || _newPrice == _cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a valid price'),
            backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await widget.onUpdate(widget.product);
      if (mounted) Navigator.pop(context);
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
                      Icon(Icons.sell_outlined, color: cs.onPrimary, size: 20),
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

            // Cost and Pricing Info
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Cost Price',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text(
                            '${_cost.toStringAsFixed(2)} ${context.watch<AppSettingsProvider>().currencySymbol}',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          cs.primaryContainer,
                          cs.primaryContainer.withValues(alpha: 0.7)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Margin',
                            style: TextStyle(
                                fontSize: 11,
                                color: cs.onPrimaryContainer,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text('${_margin.toStringAsFixed(1)}%',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: cs.primary)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Price Input
            TextField(
              controller: _priceController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'New Price',
                prefixText: null,
                suffixText: context.watch<AppSettingsProvider>().currencySymbol,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixStyle:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            // Profit Display
            if (_newPrice > 0)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Profit per unit:',
                        style: TextStyle(
                            fontSize: 14,
                            color: cs.onSurface,
                            fontWeight: FontWeight.w500)),
                    Text(
                      '${(_newPrice - _cost).toStringAsFixed(2)} ${context.watch<AppSettingsProvider>().currencySymbol}',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: cs.primary),
                    ),
                  ],
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
                  onPressed: _isLoading ? null : _handleSave,
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
                  label: const Text('Save Price'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── History Panel ──────────────────────────────────────────────────────────
class _HistoryPanel extends StatelessWidget {
  final List<dynamic> history;
  final int displayedCount;
  final VoidCallback onLoadMore;

  const _HistoryPanel({
    required this.history,
    required this.displayedCount,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final displayedHistory = history.take(displayedCount).toList();
    final hasMore = history.length > displayedCount;

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
                Text('Price History',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface)),
                const Spacer(),
                Text('${displayedHistory.length}/${history.length} changes',
                    style: TextStyle(
                        fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
              ],
            ),
          ),
          const Divider(height: 1),
          if (history.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                  child: Text('No price changes yet',
                      style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4)))),
            )
          else
            Column(
              children: [
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayedHistory.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: cs.outline.withValues(alpha: 0.08)),
                  itemBuilder: (context, index) {
                    final h = displayedHistory[index];
                    final oldPrice =
                        double.tryParse(h['old_price'].toString()) ?? 0;
                    final newPrice =
                        double.tryParse(h['new_price'].toString()) ?? 0;
                    final increased = newPrice > oldPrice;
                    final color = increased ? Colors.green : Colors.red;
                    final diff = newPrice - oldPrice;
                    final pct = oldPrice > 0 ? (diff / oldPrice * 100) : 0.0;

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
                                increased
                                    ? Icons.trending_up
                                    : Icons.trending_down,
                                size: 18,
                                color: color),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(h['product_name'] ?? '',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13),
                                    overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 2),
                                Text(
                                    'By ${h['changed_by_name'] ?? 'Unknown'}  ·  ${h['created_at'] ?? ''}',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: cs.onSurface.withValues(alpha: 0.45))),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  Builder(builder: (ctx) {
                                    final sym = ctx
                                        .watch<AppSettingsProvider>()
                                        .currencySymbol;
                                    return Row(children: [
                                      Text(
                                          '${oldPrice.toStringAsFixed(2)} $sym',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color:
                                                  cs.onSurface.withValues(alpha: 0.5),
                                              decoration:
                                                  TextDecoration.lineThrough)),
                                      const SizedBox(width: 6),
                                      const Icon(Icons.arrow_forward_rounded,
                                          size: 12, color: Colors.grey),
                                      const SizedBox(width: 6),
                                      Text(
                                          '${newPrice.toStringAsFixed(2)} $sym',
                                          style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: cs.onSurface)),
                                    ]);
                                  }),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                  '${increased ? '+' : ''}${diff.toStringAsFixed(2)} (${pct.toStringAsFixed(1)}%)',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: color,
                                      fontWeight: FontWeight.w600)),
                            ],
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
                            'Load More (${history.length - displayedCount} remaining)'),
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
