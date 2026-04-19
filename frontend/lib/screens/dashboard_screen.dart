import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/app_settings_provider.dart';
import '../services/api_service.dart';
import '../utils/api_config.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with AutomaticKeepAliveClientMixin {
  Map<String, dynamic>? _stats;
  List<dynamic> _salesData = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _period = 'today';

  @override
  bool get wantKeepAlive => false;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final now = DateTime.now();
      final formattedToday = DateFormat('yyyy-MM-dd').format(now);
      final formattedStart = _period == 'today'
          ? formattedToday
          : DateFormat('yyyy-MM-dd')
              .format(now.subtract(Duration(days: _period == 'week' ? 7 : 30)));

      final statsResponse = await ApiService.get(
          '${ApiConfig.ordersEndpoint}?dashboard=1&period=$_period');

      final salesResponse = await ApiService.get(
          '${ApiConfig.reportsEndpoint}?type=sales&start_date=$formattedStart&end_date=$formattedToday&group_by=${_period == 'today' ? 'hour' : 'day'}');

      if (statsResponse['success'] == true &&
          salesResponse['success'] == true) {
        setState(() {
          _stats = statsResponse['data'];
          _salesData = salesResponse['data'] as List;
          _isLoading = false;
        });
      } else {
        final msg = statsResponse['message'] ??
            salesResponse['message'] ??
            'Failed to load dashboard data';
        setState(() {
          _errorMessage = msg.toString();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // Show UI immediately with loading state, don't block rendering
    if (_isLoading && _stats == null) {
      // First load - show skeleton/placeholder
      return _buildSkeletonUI(context);
    }

    if (_errorMessage != null && _stats == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(_errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 16)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadDashboard,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final topProducts = _stats?['top_products'] as List? ?? [];

    // Always use responsive desktop view
    final totalOrders =
        int.tryParse(_stats?['total_orders']?.toString() ?? '0') ?? 0;
    final totalRevenue =
        double.tryParse(_stats?['total_revenue']?.toString() ?? '0') ?? 0;
    final totalProductsSold = topProducts.fold<int>(
        0,
        (sum, p) =>
            sum + (int.tryParse(p['total_sold']?.toString() ?? '0') ?? 0));
    final avgOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0.0;

    return RefreshIndicator(
        onRefresh: _loadDashboard,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(context),
              const SizedBox(height: 24),

              // Stat Cards - Responsive
              LayoutBuilder(
                builder: (context, constraints) {
                  final isSmall = constraints.maxWidth < 600;
                  return isSmall
                      ? Column(
                          children: [
                            _StatCard(
                              title: 'Total Revenue',
                              value:
                                  '${totalRevenue.toStringAsFixed(2)} ${context.watch<AppSettingsProvider>().currencySymbol}',
                              subtitle: _period == 'today'
                                  ? 'Today'
                                  : _period == 'week'
                                      ? 'This Week'
                                      : 'This Month',
                              icon: Icons.attach_money,
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF4CAF50),
                                  Color(0xFF2E7D32)
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            _StatCard(
                              title: 'Total Orders',
                              value: totalOrders.toString(),
                              subtitle: 'Transactions',
                              icon: Icons.receipt_long,
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF2196F3),
                                  Color(0xFF1565C0)
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            _StatCard(
                              title: 'Avg Order Value',
                              value:
                                  '${avgOrderValue.toStringAsFixed(2)} ${context.watch<AppSettingsProvider>().currencySymbol}',
                              subtitle: 'Per transaction',
                              icon: Icons.trending_up,
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFFF9800),
                                  Color(0xFFE65100)
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            _StatCard(
                              title: 'Items Sold',
                              value: totalProductsSold.toString(),
                              subtitle: 'Units',
                              icon: Icons.inventory_2,
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF9C27B0),
                                  Color(0xFF6A1B9A)
                                ],
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                title: 'Total Revenue',
                                value:
                                    '${totalRevenue.toStringAsFixed(2)} ${context.watch<AppSettingsProvider>().currencySymbol}',
                                subtitle: _period == 'today'
                                    ? 'Today'
                                    : _period == 'week'
                                        ? 'This Week'
                                        : 'This Month',
                                icon: Icons.attach_money,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF4CAF50),
                                    Color(0xFF2E7D32)
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _StatCard(
                                title: 'Total Orders',
                                value: totalOrders.toString(),
                                subtitle: 'Transactions',
                                icon: Icons.receipt_long,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF2196F3),
                                    Color(0xFF1565C0)
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _StatCard(
                                title: 'Avg Order Value',
                                value:
                                    '${avgOrderValue.toStringAsFixed(2)} ${context.watch<AppSettingsProvider>().currencySymbol}',
                                subtitle: 'Per transaction',
                                icon: Icons.trending_up,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFF9800),
                                    Color(0xFFE65100)
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _StatCard(
                                title: 'Items Sold',
                                value: totalProductsSold.toString(),
                                subtitle: 'Units',
                                icon: Icons.inventory_2,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF9C27B0),
                                    Color(0xFF6A1B9A)
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                },
              ),
              const SizedBox(height: 24),

              // Chart + Top Products - Responsive
              LayoutBuilder(
                builder: (context, constraints) {
                  final isSmall = constraints.maxWidth < 800;
                  return isSmall
                      ? Column(
                          children: [
                            // Sales Chart
                            Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.bar_chart,
                                            color: Colors.blue),
                                        const SizedBox(width: 8),
                                        Text('Sales Overview',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge
                                                ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      height: 200,
                                      child: _salesData.isEmpty
                                          ? Center(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.bar_chart,
                                                      size: 64,
                                                      color: Colors.grey[300]),
                                                  const SizedBox(height: 8),
                                                  Text('No sales data',
                                                      style: TextStyle(
                                                          color: Colors
                                                              .grey[500])),
                                                ],
                                              ),
                                            )
                                          : LineChart(
                                              LineChartData(
                                                gridData: FlGridData(
                                                  show: true,
                                                  drawVerticalLine: false,
                                                  getDrawingHorizontalLine:
                                                      (value) => FlLine(
                                                    color: Colors.grey
                                                        .withValues(
                                                            alpha: 0.15),
                                                    strokeWidth: 1,
                                                  ),
                                                ),
                                                titlesData: FlTitlesData(
                                                  leftTitles: AxisTitles(
                                                    sideTitles: SideTitles(
                                                      showTitles: true,
                                                      reservedSize: 48,
                                                      getTitlesWidget:
                                                          (value, meta) => Text(
                                                        '${value.toInt()} ${context.watch<AppSettingsProvider>().currencySymbol}',
                                                        style: TextStyle(
                                                            fontSize: 10,
                                                            color: Colors
                                                                .grey[600]),
                                                      ),
                                                    ),
                                                  ),
                                                  bottomTitles: AxisTitles(
                                                    sideTitles: SideTitles(
                                                      showTitles: true,
                                                      getTitlesWidget:
                                                          (value, meta) {
                                                        final i = value.toInt();
                                                        if (i >= 0 &&
                                                            i <
                                                                _salesData
                                                                    .length) {
                                                          final raw = _salesData[
                                                                      i]['date']
                                                                  ?.toString() ??
                                                              '';
                                                          if (raw.isEmpty) {
                                                            return const Text(
                                                                '');
                                                          }
                                                          final date =
                                                              DateTime.tryParse(
                                                                  raw);
                                                          if (date == null) {
                                                            return const Text(
                                                                '');
                                                          }
                                                          return Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .only(
                                                                    top: 8),
                                                            child: Text(
                                                              _period == 'today'
                                                                  ? DateFormat(
                                                                          'HH:mm')
                                                                      .format(
                                                                          date)
                                                                  : DateFormat(
                                                                          'MM/dd')
                                                                      .format(
                                                                          date),
                                                              style: TextStyle(
                                                                  fontSize: 10,
                                                                  color: Colors
                                                                          .grey[
                                                                      600]),
                                                            ),
                                                          );
                                                        }
                                                        return const Text('');
                                                      },
                                                      interval: 1,
                                                    ),
                                                  ),
                                                  rightTitles: const AxisTitles(
                                                      sideTitles: SideTitles(
                                                          showTitles: false)),
                                                  topTitles: const AxisTitles(
                                                      sideTitles: SideTitles(
                                                          showTitles: false)),
                                                ),
                                                borderData:
                                                    FlBorderData(show: false),
                                                lineBarsData: [
                                                  LineChartBarData(
                                                    spots: _salesData
                                                        .asMap()
                                                        .entries
                                                        .map((e) => FlSpot(
                                                              e.key.toDouble(),
                                                              double.tryParse(e
                                                                          .value[
                                                                              'total_sales']
                                                                          ?.toString() ??
                                                                      '0') ??
                                                                  0,
                                                            ))
                                                        .toList(),
                                                    isCurved: true,
                                                    color: Colors.blue,
                                                    barWidth: 3,
                                                    dotData: FlDotData(
                                                      show: true,
                                                      getDotPainter: (spot,
                                                              percent,
                                                              barData,
                                                              index) =>
                                                          FlDotCirclePainter(
                                                        radius: 4,
                                                        color: Colors.white,
                                                        strokeWidth: 2,
                                                        strokeColor:
                                                            Colors.blue,
                                                      ),
                                                    ),
                                                    belowBarData: BarAreaData(
                                                      show: true,
                                                      gradient: LinearGradient(
                                                        colors: [
                                                          Colors.blue
                                                              .withValues(
                                                                  alpha: 0.2),
                                                          Colors.blue
                                                              .withValues(
                                                                  alpha: 0.0),
                                                        ],
                                                        begin:
                                                            Alignment.topCenter,
                                                        end: Alignment
                                                            .bottomCenter,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Top Products
                            Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.emoji_events,
                                            color: Colors.amber),
                                        const SizedBox(width: 8),
                                        Text('Top Products',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge
                                                ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    topProducts.isEmpty
                                        ? Center(
                                            child: Padding(
                                              padding: const EdgeInsets.all(32),
                                              child: Column(
                                                children: [
                                                  Icon(Icons.inventory_2,
                                                      size: 48,
                                                      color: Colors.grey[300]),
                                                  const SizedBox(height: 8),
                                                  Text('No sales yet',
                                                      style: TextStyle(
                                                          color: Colors
                                                              .grey[500])),
                                                ],
                                              ),
                                            ),
                                          )
                                        : Column(
                                            children: topProducts
                                                .take(5)
                                                .toList()
                                                .asMap()
                                                .entries
                                                .map((entry) {
                                              final index = entry.key;
                                              final product = entry.value;
                                              final maxSold = int.tryParse(
                                                      topProducts[0]
                                                                  ['total_sold']
                                                              ?.toString() ??
                                                          '1') ??
                                                  1;
                                              final sold = int.tryParse(
                                                      product['total_sold']
                                                              ?.toString() ??
                                                          '0') ??
                                                  0;
                                              return _TopProductRow(
                                                rank: index + 1,
                                                name: product['name']
                                                        ?.toString() ??
                                                    product['product_name']
                                                        ?.toString() ??
                                                    '—',
                                                sold: sold,
                                                maxSold: maxSold,
                                              );
                                            }).toList(),
                                          ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Sales Chart
                            Expanded(
                              flex: 3,
                              child: Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.bar_chart,
                                              color: Colors.blue),
                                          const SizedBox(width: 8),
                                          Text('Sales Overview',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleLarge
                                                  ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold)),
                                        ],
                                      ),
                                      const SizedBox(height: 24),
                                      SizedBox(
                                        height: 260,
                                        child: _salesData.isEmpty
                                            ? Center(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.bar_chart,
                                                        size: 64,
                                                        color:
                                                            Colors.grey[300]),
                                                    const SizedBox(height: 8),
                                                    Text('No sales data',
                                                        style: TextStyle(
                                                            color: Colors
                                                                .grey[500])),
                                                  ],
                                                ),
                                              )
                                            : LineChart(
                                                LineChartData(
                                                  gridData: FlGridData(
                                                    show: true,
                                                    drawVerticalLine: false,
                                                    getDrawingHorizontalLine:
                                                        (value) => FlLine(
                                                      color: Colors.grey
                                                          .withValues(
                                                              alpha: 0.15),
                                                      strokeWidth: 1,
                                                    ),
                                                  ),
                                                  titlesData: FlTitlesData(
                                                    leftTitles: AxisTitles(
                                                      sideTitles: SideTitles(
                                                        showTitles: true,
                                                        reservedSize: 48,
                                                        getTitlesWidget:
                                                            (value, meta) =>
                                                                Text(
                                                          '${value.toInt()} ${context.watch<AppSettingsProvider>().currencySymbol}',
                                                          style: TextStyle(
                                                              fontSize: 10,
                                                              color: Colors
                                                                  .grey[600]),
                                                        ),
                                                      ),
                                                    ),
                                                    bottomTitles: AxisTitles(
                                                      sideTitles: SideTitles(
                                                        showTitles: true,
                                                        getTitlesWidget:
                                                            (value, meta) {
                                                          final i =
                                                              value.toInt();
                                                          if (i >= 0 &&
                                                              i <
                                                                  _salesData
                                                                      .length) {
                                                            final raw = _salesData[
                                                                            i]
                                                                        ['date']
                                                                    ?.toString() ??
                                                                '';
                                                            if (raw.isEmpty) {
                                                              return const Text(
                                                                  '');
                                                            }
                                                            final date =
                                                                DateTime
                                                                    .tryParse(
                                                                        raw);
                                                            if (date == null) {
                                                              return const Text(
                                                                  '');
                                                            }
                                                            return Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .only(
                                                                      top: 8),
                                                              child: Text(
                                                                _period ==
                                                                        'today'
                                                                    ? DateFormat(
                                                                            'HH:mm')
                                                                        .format(
                                                                            date)
                                                                    : DateFormat(
                                                                            'MM/dd')
                                                                        .format(
                                                                            date),
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        10,
                                                                    color: Colors
                                                                            .grey[
                                                                        600]),
                                                              ),
                                                            );
                                                          }
                                                          return const Text('');
                                                        },
                                                        interval: 1,
                                                      ),
                                                    ),
                                                    rightTitles:
                                                        const AxisTitles(
                                                            sideTitles:
                                                                SideTitles(
                                                                    showTitles:
                                                                        false)),
                                                    topTitles: const AxisTitles(
                                                        sideTitles: SideTitles(
                                                            showTitles: false)),
                                                  ),
                                                  borderData:
                                                      FlBorderData(show: false),
                                                  lineBarsData: [
                                                    LineChartBarData(
                                                      spots: _salesData
                                                          .asMap()
                                                          .entries
                                                          .map((e) => FlSpot(
                                                                e.key
                                                                    .toDouble(),
                                                                double.tryParse(e
                                                                            .value['total_sales']
                                                                            ?.toString() ??
                                                                        '0') ??
                                                                    0,
                                                              ))
                                                          .toList(),
                                                      isCurved: true,
                                                      color: Colors.blue,
                                                      barWidth: 3,
                                                      dotData: FlDotData(
                                                        show: true,
                                                        getDotPainter: (spot,
                                                                percent,
                                                                barData,
                                                                index) =>
                                                            FlDotCirclePainter(
                                                          radius: 4,
                                                          color: Colors.white,
                                                          strokeWidth: 2,
                                                          strokeColor:
                                                              Colors.blue,
                                                        ),
                                                      ),
                                                      belowBarData: BarAreaData(
                                                        show: true,
                                                        gradient:
                                                            LinearGradient(
                                                          colors: [
                                                            Colors.blue
                                                                .withValues(
                                                                    alpha: 0.2),
                                                            Colors.blue
                                                                .withValues(
                                                                    alpha: 0.0),
                                                          ],
                                                          begin: Alignment
                                                              .topCenter,
                                                          end: Alignment
                                                              .bottomCenter,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Top Products
                            Expanded(
                              flex: 2,
                              child: Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.emoji_events,
                                              color: Colors.amber),
                                          const SizedBox(width: 8),
                                          Text('Top Products',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleLarge
                                                  ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold)),
                                        ],
                                      ),
                                      const SizedBox(height: 24),
                                      topProducts.isEmpty
                                          ? Center(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(32),
                                                child: Column(
                                                  children: [
                                                    Icon(Icons.inventory_2,
                                                        size: 48,
                                                        color:
                                                            Colors.grey[300]),
                                                    const SizedBox(height: 8),
                                                    Text('No sales yet',
                                                        style: TextStyle(
                                                            color: Colors
                                                                .grey[500])),
                                                  ],
                                                ),
                                              ),
                                            )
                                          : Column(
                                              children: topProducts
                                                  .take(5)
                                                  .toList()
                                                  .asMap()
                                                  .entries
                                                  .map((entry) {
                                                final index = entry.key;
                                                final product = entry.value;
                                                final maxSold = int.tryParse(
                                                        topProducts[0][
                                                                    'total_sold']
                                                                ?.toString() ??
                                                            '1') ??
                                                    1;
                                                final sold = int.tryParse(
                                                        product['total_sold']
                                                                ?.toString() ??
                                                            '0') ??
                                                    0;
                                                return _TopProductRow(
                                                  rank: index + 1,
                                                  name: product['name']
                                                          ?.toString() ??
                                                      product['product_name']
                                                          ?.toString() ??
                                                      '—',
                                                  sold: sold,
                                                  maxSold: maxSold,
                                                );
                                              }).toList(),
                                            ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                },
              ),
            ],
          ),
        ));
  }

  Widget _buildHeader(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 600;

        if (isSmall) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dashboard',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          DateFormat('EEE, MMM dd').format(DateTime.now()),
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filled(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadDashboard,
                    tooltip: 'Refresh',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'today', label: Text('Today')),
                    ButtonSegment(value: 'week', label: Text('Week')),
                    ButtonSegment(value: 'month', label: Text('Month')),
                  ],
                  selected: {_period},
                  onSelectionChanged: (s) {
                    setState(() => _period = s.first);
                    _loadDashboard();
                  },
                ),
              ),
            ],
          );
        }

        return Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  DateFormat('EEEE, MMMM dd, yyyy').format(DateTime.now()),
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
            const Spacer(),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'today', label: Text('Today')),
                  ButtonSegment(value: 'week', label: Text('Week')),
                  ButtonSegment(value: 'month', label: Text('Month')),
                ],
                selected: {_period},
                onSelectionChanged: (s) {
                  setState(() => _period = s.first);
                  _loadDashboard();
                },
              ),
            ),
            const SizedBox(width: 12),
            IconButton.filled(
              icon: const Icon(Icons.refresh),
              onPressed: _loadDashboard,
              tooltip: 'Refresh',
            ),
          ],
        );
      },
    );
  }

  Widget _buildSkeletonUI(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 24),
          // Skeleton stat cards
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  height: 340,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Container(
                  height: 340,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(),
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

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 900;
    
    return Container(
      padding: EdgeInsets.all(isSmall ? 12 : 24),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(isSmall ? 12 : 16),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withValues(alpha: 0.3),
            blurRadius: isSmall ? 8 : 12,
            offset: Offset(0, isSmall ? 2 : 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isSmall ? 6 : 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(isSmall ? 6 : 8),
                ),
                child: Icon(icon, color: Colors.white, size: isSmall ? 16 : 22),
              ),
              const Spacer(),
              Text(
                subtitle,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8), fontSize: isSmall ? 9 : 11),
              ),
            ],
          ),
          SizedBox(height: isSmall ? 8 : 16),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmall ? 18 : 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: isSmall ? 2 : 4),
          Text(
            title,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85), fontSize: isSmall ? 10 : 13),
          ),
        ],
      ),
    );
  }
}

class _TopProductRow extends StatelessWidget {
  final int rank;
  final String name;
  final int sold;
  final int maxSold;

  const _TopProductRow({
    required this.rank,
    required this.name,
    required this.sold,
    required this.maxSold,
  });

  Color get _rankColor {
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

  @override
  Widget build(BuildContext context) {
    final progress = maxSold > 0 ? sold / maxSold : 0.0;
    final isSmall = MediaQuery.of(context).size.width < 900;

    return Padding(
      padding: EdgeInsets.only(bottom: isSmall ? 10 : 16),
      child: Row(
        children: [
          Container(
            width: isSmall ? 22 : 28,
            height: isSmall ? 22 : 28,
            decoration: BoxDecoration(
              color: _rankColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                    color: _rankColor,
                    fontWeight: FontWeight.bold,
                    fontSize: isSmall ? 10 : 12),
              ),
            ),
          ),
          SizedBox(width: isSmall ? 8 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: isSmall ? 11 : 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '$sold sold',
                      style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: isSmall ? 10 : 12,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                SizedBox(height: isSmall ? 4 : 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(isSmall ? 3 : 4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(_rankColor),
                    minHeight: isSmall ? 4 : 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
