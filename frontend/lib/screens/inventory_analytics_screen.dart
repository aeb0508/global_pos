import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_settings_provider.dart';
import '../services/api_service.dart';
import '../utils/api_config.dart';

class InventoryAnalyticsScreen extends StatefulWidget {
  const InventoryAnalyticsScreen({super.key});

  @override
  State<InventoryAnalyticsScreen> createState() =>
      _InventoryAnalyticsScreenState();
}

class _InventoryAnalyticsScreenState extends State<InventoryAnalyticsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _analytics = {};

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    try {
      final response =
          await ApiService.get('${ApiConfig.baseUrl}/inventory_analytics.php');
      if (response['success']) {
        setState(() {
          _analytics = response['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Header
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade600, Colors.green.shade800],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
            child: Row(
              children: [
                const Icon(Icons.analytics_outlined,
                    color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Inventory Analytics',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _loadAnalytics,
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final fastMoving = _analytics['fast_moving'] as List? ?? [];
    final slowMoving = _analytics['slow_moving'] as List? ?? [];
    final lowStock = _analytics['low_stock'] as List? ?? [];
    final stockValue = _analytics['total_stock_value'] ?? 0;

    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Summary Cards
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final singleColumn = width < 800;
                  final cardWidth = singleColumn ? width : (width - 48) / 4;

                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SizedBox(
                        width: cardWidth,
                        child: _buildMetricCard(
                          'Total Stock Value',
                          '${stockValue.toStringAsFixed(2)} ${context.watch<AppSettingsProvider>().currencySymbol}',
                          Icons.account_balance_wallet,
                          Colors.blue,
                          'Current inventory worth',
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: _buildMetricCard(
                          'Fast Moving',
                          '${fastMoving.length}',
                          Icons.trending_up,
                          Colors.green,
                          'High demand products',
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: _buildMetricCard(
                          'Slow Moving',
                          '${slowMoving.length}',
                          Icons.trending_down,
                          Colors.orange,
                          'Low turnover items',
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: _buildMetricCard(
                          'Low Stock Alert',
                          '${lowStock.length}',
                          Icons.warning_amber_rounded,
                          Colors.red,
                          'Needs reordering',
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              // Fast & Slow Moving section
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final narrow = width < 900;
                  if (narrow) {
                    return Column(
                      children: [
                        _buildItemsCard(
                            'Fast Moving Items',
                            'Top performing products',
                            Icons.rocket_launch,
                            Colors.green,
                            fastMoving,
                            true),
                        const SizedBox(height: 16),
                        _buildItemsCard(
                            'Slow Moving Items',
                            'Products with low turnover',
                            Icons.hourglass_empty,
                            Colors.orange,
                            slowMoving,
                            false),
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildItemsCard(
                          'Fast Moving Items',
                          'Top performing products',
                          Icons.rocket_launch,
                          Colors.green,
                          fastMoving,
                          true,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _buildItemsCard(
                          'Slow Moving Items',
                          'Products with low turnover',
                          Icons.hourglass_empty,
                          Colors.orange,
                          slowMoving,
                          false,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              // Low Stock
              _buildLowStockCard(lowStock),
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsCard(String title, String subtitle, IconData icon,
      Color color, List items, bool isFastMoving) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 520;
                if (narrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10)),
                            child: Icon(icon, color: color, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(title,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                Text(subtitle,
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey[600])),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20)),
                        child: Text('${items.length} items',
                            style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w600,
                                fontSize: 12)),
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10)),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(subtitle,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20)),
                      child: Text('${items.length} items',
                          style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w600,
                              fontSize: 12)),
                    ),
                  ],
                );
              },
            ),
          ),
          const Divider(height: 1),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(48),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.inbox_outlined,
                        size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text('No items found',
                        style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: List.generate(items.length, (index) {
                  final item = items[index];
                  return Padding(
                    padding: EdgeInsets.only(
                        bottom: index < items.length - 1 ? 8 : 0),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8)),
                            child: Center(
                                child: Text('${index + 1}',
                                    style: TextStyle(
                                        color: color,
                                        fontWeight: FontWeight.bold))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['name'] ?? 'Unknown',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14)),
                                const SizedBox(height: 4),
                                Text(
                                  isFastMoving
                                      ? 'Sold: ${item['total_sold']} units'
                                      : 'Stock: ${item['stock_quantity']} units',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                isFastMoving
                                    ? '${item['revenue']} ${context.watch<AppSettingsProvider>().currencySymbol}'
                                    : 'Sold: ${item['total_sold'] ?? 0}',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                    fontSize: 14),
                              ),
                              if (isFastMoving)
                                Text('Revenue',
                                    style: TextStyle(
                                        fontSize: 11, color: Colors.grey[500])),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLowStockCard(List items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.inventory_2_outlined,
                      color: Colors.red, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Low Stock Alert',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Items that need immediate reordering',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${items.length} items',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          items.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(48),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 64, color: Colors.green[300]),
                        const SizedBox(height: 16),
                        Text(
                          'All items are well stocked!',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: items.map<Widget>((item) {
                      return Container(
                        width: (MediaQuery.of(context).size.width - 120) / 4,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.red.withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.warning_amber,
                                      color: Colors.red, size: 16),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${item['stock_quantity']} left',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              item['name'] ?? 'Unknown',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.inventory_2,
                                    size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  'Min: ${item['reorder_level'] ?? 'N/A'}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
        ],
      ),
    );
  }
}
