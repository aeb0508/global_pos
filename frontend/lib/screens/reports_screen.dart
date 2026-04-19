import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' show TableHelper;
import 'package:provider/provider.dart';
import '../providers/app_settings_provider.dart';
import '../services/api_service.dart';
import '../utils/api_config.dart';
// Conditional imports for file saving
import 'reports_screen_io.dart'
    if (dart.library.html) 'reports_screen_web.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  Map<String, dynamic>? _salesData;
  Map<String, dynamic>? _profitData;
  Map<String, dynamic>? _productsData;
  Map<String, dynamic>? _employeesData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _loadCurrentReport();
      }
    });
    _loadCurrentReport();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentReport() async {
    switch (_tabController.index) {
      case 0:
        await _loadReport('sales');
        break;
      case 1:
        await _loadReport('profit');
        break;
      case 2:
        await _loadReport('products');
        break;
      case 3:
        await _loadReport('employees');
        break;
    }
  }

  Future<void> _loadReport(String type) async {
    setState(() => _isLoading = true);

    try {
      final startStr = DateFormat('yyyy-MM-dd').format(_startDate);
      final endStr = DateFormat('yyyy-MM-dd').format(_endDate);

      final response = await ApiService.get(
        '${ApiConfig.reportsEndpoint}?type=$type&start_date=$startStr&end_date=$endStr',
      );

      if (response['success']) {
        setState(() {
          switch (type) {
            case 'sales':
              _salesData = response;
              break;
            case 'profit':
              _profitData = response;
              break;
            case 'products':
              _productsData = response;
              break;
            case 'employees':
              _employeesData = response;
              break;
          }
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
                colors: [
                  Colors.indigo.shade600,
                  Colors.indigo.shade800,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final narrow = constraints.maxWidth < 760;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Expanded(
                                child: Row(
                                  children: [
                                    Icon(Icons.analytics,
                                        color: Colors.white, size: 22),
                                    SizedBox(width: 10),
                                    Text(
                                      'Reports & Analytics',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!narrow) ...[
                                // Date Range Selector
                                InkWell(
                                  onTap: () => _selectDateRange(context),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today,
                                            size: 16, color: Colors.white70),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${DateFormat('MMM dd').format(_startDate)} - ${DateFormat('MMM dd, yyyy').format(_endDate)}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: _loadCurrentReport,
                                  icon: const Icon(Icons.refresh,
                                      color: Colors.white),
                                  tooltip: 'Refresh',
                                ),
                                IconButton(
                                  onPressed: _exportToPDF,
                                  icon: const Icon(Icons.picture_as_pdf,
                                      color: Colors.white),
                                  tooltip: 'Export PDF',
                                ),
                                IconButton(
                                  onPressed: _exportToExcel,
                                  icon: const Icon(Icons.table_chart,
                                      color: Colors.white),
                                  tooltip: 'Export Excel',
                                ),
                              ]
                            ],
                          ),
                          if (narrow) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _selectDateRange(context),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.calendar_today,
                                              size: 16, color: Colors.white70),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              '${DateFormat('MMM dd').format(_startDate)} - ${DateFormat('MMM dd, yyyy').format(_endDate)}',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: _loadCurrentReport,
                                  icon: const Icon(Icons.refresh,
                                      color: Colors.white),
                                  tooltip: 'Refresh',
                                ),
                                IconButton(
                                  onPressed: _exportToPDF,
                                  icon: const Icon(Icons.picture_as_pdf,
                                      color: Colors.white),
                                  tooltip: 'Export PDF',
                                ),
                                IconButton(
                                  onPressed: _exportToExcel,
                                  icon: const Icon(Icons.table_chart,
                                      color: Colors.white),
                                  tooltip: 'Export Excel',
                                ),
                              ],
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
                // Tabs
                LayoutBuilder(
                  builder: (context, constraints) {
                    final narrow = constraints.maxWidth < 300;
                    return TabBar(
                      controller: _tabController,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white60,
                      indicatorColor: Colors.white,
                      indicatorWeight: 3,
                      isScrollable: narrow,
                      tabs: [
                        const Tab(icon: Icon(Icons.trending_up), text: 'Sales'),
                        Tab(
                          icon: const Icon(Icons.account_balance_wallet),
                          text: narrow ? 'P&L' : 'Profit & Loss',
                        ),
                        Tab(
                          icon: const Icon(Icons.inventory_2),
                          text: narrow ? 'Prod' : 'Products',
                        ),
                        Tab(
                          icon: const Icon(Icons.people),
                          text: narrow ? 'Emp' : 'Employees',
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSalesReport(),
                      _buildProfitReport(),
                      _buildProductsReport(),
                      _buildEmployeesReport(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesReport() {
    if (_salesData == null) return _buildEmptyState();

    final data = _salesData!['data'] as List;
    final totals = _salesData!['totals'] as Map<String, dynamic>?;

    if (data.isEmpty) return _buildEmptyState();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          if (totals != null)
            _buildSummaryCards(totals, [
              _SummaryCardData(
                  'Total Orders',
                  totals['total_orders'].toString(),
                  Icons.shopping_cart,
                  Colors.blue),
              _SummaryCardData(
                  'Total Sales',
                  '${double.parse(totals['total_sales'].toString()).toStringAsFixed(2)} ${context.read<AppSettingsProvider>().currencySymbol}',
                  Icons.attach_money,
                  Colors.green),
              _SummaryCardData(
                  'Total Discount',
                  '${double.parse(totals['total_discount'].toString()).toStringAsFixed(2)} ${context.read<AppSettingsProvider>().currencySymbol}',
                  Icons.discount,
                  Colors.orange),
              _SummaryCardData(
                  'Total Tax',
                  '${double.parse(totals['total_tax'].toString()).toStringAsFixed(2)} ${context.read<AppSettingsProvider>().currencySymbol}',
                  Icons.receipt,
                  Colors.purple),
            ]),
          const SizedBox(height: 24),

          // Chart
          _buildChartCard(
            'Sales Trend',
            _buildSalesChart(data),
          ),
          const SizedBox(height: 24),

          // Data Table
          _buildDataTableCard('Daily Sales Breakdown', data),
        ],
      ),
    );
  }

  Widget _buildProfitReport() {
    if (_profitData == null) return _buildEmptyState();

    final data = _profitData!['data'] as List;
    final totals = _profitData!['totals'] as Map<String, dynamic>?;

    if (data.isEmpty) return _buildEmptyState();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (totals != null)
            _buildSummaryCards(totals, [
              _SummaryCardData(
                  'Revenue',
                  '${double.parse(totals['total_revenue'].toString()).toStringAsFixed(2)} ${context.read<AppSettingsProvider>().currencySymbol}',
                  Icons.trending_up,
                  Colors.green),
              _SummaryCardData(
                  'Cost',
                  '${double.parse(totals['total_cost'].toString()).toStringAsFixed(2)} ${context.read<AppSettingsProvider>().currencySymbol}',
                  Icons.trending_down,
                  Colors.red),
              _SummaryCardData(
                  'Gross Profit',
                  '${double.parse(totals['gross_profit'].toString()).toStringAsFixed(2)} ${context.read<AppSettingsProvider>().currencySymbol}',
                  Icons.account_balance,
                  Colors.blue),
              _SummaryCardData('Profit Margin', '${totals['profit_margin']}%',
                  Icons.percent, Colors.purple),
            ]),
          const SizedBox(height: 24),
          _buildChartCard(
            'Profit Trend',
            _buildProfitChart(data),
          ),
          const SizedBox(height: 24),
          _buildDataTableCard('Daily Profit Breakdown', data),
        ],
      ),
    );
  }

  Widget _buildProductsReport() {
    if (_productsData == null) return _buildEmptyState();

    final data = _productsData!['data'] as List;
    if (data.isEmpty) return _buildEmptyState();

    // Sort by total sold
    data.sort((a, b) => (int.tryParse(b['total_sold']?.toString() ?? '0') ?? 0)
        .compareTo(int.tryParse(a['total_sold']?.toString() ?? '0') ?? 0));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 900;
              if (narrow) {
                return Column(
                  children: [
                    _buildChartCard(
                      'Top 10 Products by Revenue',
                      _buildTopProductsChart(data.take(10).toList()),
                    ),
                    const SizedBox(height: 16),
                    _buildChartCard(
                      'Top 10 Products by Quantity',
                      _buildTopProductsQuantityChart(data.take(10).toList()),
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: _buildChartCard(
                      'Top 10 Products by Revenue',
                      _buildTopProductsChart(data.take(10).toList()),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _buildChartCard(
                      'Top 10 Products by Quantity',
                      _buildTopProductsQuantityChart(data.take(10).toList()),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          _buildDataTableCard('Product Performance', data),
        ],
      ),
    );
  }

  Widget _buildEmployeesReport() {
    if (_employeesData == null) return _buildEmptyState();

    final data = _employeesData!['data'] as List;
    if (data.isEmpty) return _buildEmptyState();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChartCard(
            'Employee Performance',
            _buildEmployeeChart(data),
          ),
          const SizedBox(height: 24),
          _buildDataTableCard('Employee Details', data),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(
      Map<String, dynamic> totals, List<_SummaryCardData> cards) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        if (maxWidth < 900) {
          final itemWidth = maxWidth < 600 ? maxWidth : (maxWidth - 12) / 2;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: cards
                .map((card) => SizedBox(
                      width: itemWidth,
                      child: _buildSummaryCard(card),
                    ))
                .toList(),
          );
        }
        return Row(
          children: cards
              .map((card) => Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(right: 16),
                      child: _buildSummaryCard(card),
                    ),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildSummaryCard(_SummaryCardData card) {
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: card.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(card.icon, color: card.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  card.title,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  card.value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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

  Widget _buildChartCard(String title, Widget chart) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 400;
              return Padding(
                padding: EdgeInsets.only(bottom: narrow ? 12 : 16),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: narrow ? 16 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                  softWrap: true,
                ),
              );
            },
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              double chartHeight = 220;

              if (width >= 600) {
                chartHeight = 300;
              }
              if (width >= 900) {
                chartHeight = 350;
              }

              return SizedBox(height: chartHeight, child: chart);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDataTableCard(String title, List data) {
    if (data.isEmpty) return const SizedBox();

    var headers = (data.first as Map<String, dynamic>).keys.toList();
    // Remove 'id' column (case-insensitive)
    headers = headers.where((h) => h.toString().toLowerCase() != 'id').toList();

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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 400;
                if (narrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        softWrap: true,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${data.length} records',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        softWrap: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '${data.length} records',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                );
              },
            ),
          ),
          const Divider(height: 1),
          // Custom table that fills width
          Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Table(
                border: TableBorder.all(color: Colors.grey[300]!, width: 1),
                defaultColumnWidth: const FixedColumnWidth(160),
                children: <TableRow>[
                  // Header row
                  TableRow(
                    decoration: BoxDecoration(color: Colors.grey[50]),
                    children: List<Widget>.from(
                      headers.map((h) => Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              h.toString().replaceAll('_', ' ').toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              softWrap: true,
                              maxLines: 2,
                            ),
                          )),
                    ),
                  ),
                  // Data rows
                  ...data.map<TableRow>((row) => TableRow(
                        children: List<Widget>.from(
                          headers.map((h) => Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  row[h]?.toString() ?? '-',
                                  style: const TextStyle(fontSize: 13),
                                  softWrap: true,
                                  maxLines: 2,
                                ),
                              )),
                        ),
                      )),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSalesChart(List data) {
    if (data.isEmpty) return const Center(child: Text('No data'));

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        titlesData: const FlTitlesData(
          leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 60)),
          bottomTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: data
                .asMap()
                .entries
                .map((e) => FlSpot(
                      e.key.toDouble(),
                      double.parse(e.value['total_sales']?.toString() ?? '0'),
                    ))
                .toList(),
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitChart(List data) {
    if (data.isEmpty) return const Center(child: Text('No data'));

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        titlesData: const FlTitlesData(
          leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 60)),
          bottomTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: data
                .asMap()
                .entries
                .map((e) => FlSpot(
                      e.key.toDouble(),
                      double.parse(e.value['gross_profit']?.toString() ?? '0'),
                    ))
                .toList(),
            isCurved: true,
            color: Colors.green,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.green.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProductsChart(List data) {
    if (data.isEmpty) return const Center(child: Text('No data'));

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(
          leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 60)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: data
            .asMap()
            .entries
            .map((e) => BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: double.parse(
                          e.value['total_revenue']?.toString() ?? '0'),
                      color: Colors.blue,
                      width: 16,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                ))
            .toList(),
      ),
    );
  }

  Widget _buildTopProductsQuantityChart(List data) {
    if (data.isEmpty) return const Center(child: Text('No data'));

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(
          leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: data
            .asMap()
            .entries
            .map((e) => BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: double.parse(
                          e.value['total_sold']?.toString() ?? '0'),
                      color: Colors.green,
                      width: 16,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                ))
            .toList(),
      ),
    );
  }

  Widget _buildEmployeeChart(List data) {
    if (data.isEmpty) return const Center(child: Text('No data'));

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(
          leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 60)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: data
            .asMap()
            .entries
            .map((e) => BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: double.parse(
                          e.value['total_sales']?.toString() ?? '0'),
                      color: Colors.purple,
                      width: 20,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                ))
            .toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No data available',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Try selecting a different date range',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadCurrentReport();
    }
  }

  Future<void> _exportToPDF() async {
    Map<String, dynamic>? currentData;
    String reportTitle = '';

    switch (_tabController.index) {
      case 0:
        currentData = _salesData;
        reportTitle = 'Sales Report';
        break;
      case 1:
        currentData = _profitData;
        reportTitle = 'Profit & Loss Report';
        break;
      case 2:
        currentData = _productsData;
        reportTitle = 'Product Performance Report';
        break;
      case 3:
        currentData = _employeesData;
        reportTitle = 'Employee Performance Report';
        break;
    }

    if (currentData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data to export')),
      );
      return;
    }

    final data = currentData['data'] as List;
    if (data.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data to export')),
      );
      return;
    }

    final pdf = pw.Document();
    final headers = (data.first as Map<String, dynamic>).keys.toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  reportTitle,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Period: ${DateFormat('MMM dd, yyyy').format(_startDate)} - ${DateFormat('MMM dd, yyyy').format(_endDate)}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.Text(
                  'Generated: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}',
                  style: const pw.TextStyle(
                      fontSize: 10, color: PdfColors.grey700),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          TableHelper.fromTextArray(
            headers: headers
                .map((h) => h.toString().replaceAll('_', ' ').toUpperCase())
                .toList(),
            data: data
                .map((row) {
                  final rowMap = row as Map<String, dynamic>;
                  return headers
                      .map((h) => rowMap[h]?.toString() ?? '-')
                      .toList();
                })
                .toList()
                .cast<List<dynamic>>(),
            headerStyle:
                pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignments: {
              for (int i = 0; i < headers.length; i++)
                i: pw.Alignment.centerLeft,
            },
          ),
          if (currentData?['totals'] != null) ...[
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Text('Summary',
                style:
                    pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            ...((currentData?['totals'] as Map<String, dynamic>?)
                    ?.entries
                    .map((e) => pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 4),
                          child: pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                e.key.replaceAll('_', ' ').toUpperCase(),
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold),
                              ),
                              pw.Text(
                                e.value.toString(),
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold),
                              ),
                            ],
                          ),
                        )) ??
                []),
          ],
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name:
          '${reportTitle.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  Future<void> _exportToExcel() async {
    Map<String, dynamic>? currentData;
    String reportTitle = '';

    switch (_tabController.index) {
      case 0:
        currentData = _salesData;
        reportTitle = 'Sales Report';
        break;
      case 1:
        currentData = _profitData;
        reportTitle = 'Profit & Loss Report';
        break;
      case 2:
        currentData = _productsData;
        reportTitle = 'Product Performance Report';
        break;
      case 3:
        currentData = _employeesData;
        reportTitle = 'Employee Performance Report';
        break;
    }

    if (currentData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data to export')),
      );
      return;
    }

    final data = currentData['data'] as List;
    if (data.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data to export')),
      );
      return;
    }

    final headers = (data.first as Map<String, dynamic>).keys.toList();
    final csvContent = StringBuffer();
    csvContent.writeln(reportTitle);
    csvContent.writeln(
        'Period: ${DateFormat('MMM dd, yyyy').format(_startDate)} - ${DateFormat('MMM dd, yyyy').format(_endDate)}');
    csvContent.writeln(
        'Generated: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}');
    csvContent.writeln('');
    csvContent.writeln(headers
        .map((h) => '"${h.toString().replaceAll('_', ' ').toUpperCase()}"')
        .join(','));
    for (var row in data) {
      final rowMap = row as Map<String, dynamic>;
      csvContent.writeln(
          headers.map((h) => '"${rowMap[h]?.toString() ?? '-'}"').join(','));
    }
    if (currentData['totals'] != null) {
      csvContent.writeln('');
      csvContent.writeln('SUMMARY');
      final totals = currentData['totals'] as Map<String, dynamic>?;
      totals?.forEach((key, value) {
        csvContent
            .writeln('"${key.replaceAll('_', ' ').toUpperCase()}","$value"');
      });
    }

    final fileName =
        '${reportTitle.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';

    try {
      await saveFile(fileName, csvContent.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(kIsWeb
                ? 'File "$fileName" downloaded'
                : 'File saved: $fileName'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting: $e')),
        );
      }
    }
  }
}

class _SummaryCardData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  _SummaryCardData(this.title, this.value, this.icon, this.color);
}
