import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/app_settings_provider.dart';

class MobileDashboardView extends StatelessWidget {
  final Map<String, dynamic>? stats;
  final List<dynamic> salesData;
  final List<dynamic> topProducts;
  final VoidCallback onRefresh;

  const MobileDashboardView({
    super.key,
    required this.stats,
    required this.salesData,
    required this.topProducts,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final totalOrders =
        int.tryParse(stats?['total_orders']?.toString() ?? '0') ?? 0;
    final totalRevenue =
        double.tryParse(stats?['total_revenue']?.toString() ?? '0') ?? 0;
    final totalProductsSold = topProducts.fold<int>(
        0,
        (sum, p) =>
            sum + (int.tryParse(p['total_sold']?.toString() ?? '0') ?? 0));
    final avgOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0.0;

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // Welcome Card
          Card(
            elevation: 2,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cs.primaryContainer, cs.secondaryContainer],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.waving_hand, color: cs.primary, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Welcome Back!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE, MMMM dd, yyyy').format(DateTime.now()),
                    style: TextStyle(
                      fontSize: 13,
                      color: cs.onPrimaryContainer.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Stats Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              _MobileStatCard(
                title: 'Revenue',
                value: '${totalRevenue.toStringAsFixed(0)} ${context.watch<AppSettingsProvider>().currencySymbol}',
                icon: Icons.attach_money,
                color: Colors.green,
                subtitle: 'Total sales',
              ),
              _MobileStatCard(
                title: 'Orders',
                value: totalOrders.toString(),
                icon: Icons.receipt_long,
                color: Colors.blue,
                subtitle: 'Transactions',
              ),
              _MobileStatCard(
                title: 'Avg Order',
                value: '${avgOrderValue.toStringAsFixed(0)} ${context.watch<AppSettingsProvider>().currencySymbol}',
                icon: Icons.trending_up,
                color: Colors.orange,
                subtitle: 'Per transaction',
              ),
              _MobileStatCard(
                title: 'Items Sold',
                value: totalProductsSold.toString(),
                icon: Icons.inventory_2,
                color: Colors.purple,
                subtitle: 'Total units',
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Top Products
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.emoji_events, color: Colors.amber, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Top Products',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (topProducts.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(Icons.inventory_2,
                                size: 48, color: Colors.grey[300]),
                            const SizedBox(height: 8),
                            Text('No sales yet',
                                style: TextStyle(color: Colors.grey[500])),
                          ],
                        ),
                      ),
                    )
                  else
                    ...topProducts
                        .take(5)
                        .toList()
                        .asMap()
                        .entries
                        .map((entry) {
                      final index = entry.key;
                      final product = entry.value;
                      final maxSold = int.tryParse(
                              topProducts[0]['total_sold']?.toString() ??
                                  '1') ??
                          1;
                      final sold = int.tryParse(
                              product['total_sold']?.toString() ?? '0') ??
                          0;
                      final progress = maxSold > 0 ? sold / maxSold : 0.0;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color:
                                    _getRankColor(index + 1).withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: _getRankColor(index + 1),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          product['product_name'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        '$sold sold',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      backgroundColor:
                                          Colors.grey.withValues(alpha: 0.15),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        _getRankColor(index + 1),
                                      ),
                                      minHeight: 6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey;
      case 3:
        return Colors.brown;
      default:
        return Colors.blue;
    }
  }
}

class _MobileStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;

  const _MobileStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
