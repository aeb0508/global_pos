import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_settings_provider.dart';
import '../services/api_service.dart';
import '../utils/api_config.dart';

class EmployeeManagementScreen extends StatefulWidget {
  const EmployeeManagementScreen({super.key});

  @override
  State<EmployeeManagementScreen> createState() =>
      _EmployeeManagementScreenState();
}

class _EmployeeManagementScreenState extends State<EmployeeManagementScreen> {
  List<dynamic> _employees = [];
  bool _isLoading = true;
  String _sortBy = 'sales'; // sales, orders, name

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    setState(() => _isLoading = true);
    try {
      final response =
          await ApiService.get('${ApiConfig.baseUrl}/employee_management.php');
      if (response['success']) {
        setState(() {
          _employees = response['data'];
          _sortEmployees();
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

  void _sortEmployees() {
    _employees.sort((a, b) {
      switch (_sortBy) {
        case 'sales':
          final aSales = double.parse(a['total_sales']?.toString() ?? '0');
          final bSales = double.parse(b['total_sales']?.toString() ?? '0');
          return bSales.compareTo(aSales);
        case 'orders':
          final aOrders = int.parse(a['order_count']?.toString() ?? '0');
          final bOrders = int.parse(b['order_count']?.toString() ?? '0');
          return bOrders.compareTo(aOrders);
        case 'name':
          return (a['full_name'] ?? '').compareTo(b['full_name'] ?? '');
        default:
          return 0;
      }
    });
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'manager':
        return Colors.orange;
      case 'cashier':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'manager':
        return Icons.manage_accounts;
      case 'cashier':
        return Icons.point_of_sale;
      default:
        return Icons.person;
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
                colors: [Colors.indigo.shade600, Colors.indigo.shade800],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
            child: Row(
              children: [
                const Icon(Icons.badge_outlined, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Employee Management',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                DropdownButton<String>(
                  value: _sortBy,
                  dropdownColor: Colors.indigo.shade700,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.sort, color: Colors.white70),
                  style: const TextStyle(color: Colors.white),
                  items: const [
                    DropdownMenuItem(
                        value: 'sales', child: Text('Sort by Sales')),
                    DropdownMenuItem(
                        value: 'orders', child: Text('Sort by Orders')),
                    DropdownMenuItem(
                        value: 'name', child: Text('Sort by Name')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _sortBy = value!;
                      _sortEmployees();
                    });
                  },
                ),
                IconButton(
                  onPressed: _loadEmployees,
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
    if (_employees.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No employees found',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    // Calculate totals
    double totalSales = 0;
    int totalOrders = 0;
    for (var emp in _employees) {
      totalSales += double.parse(emp['total_sales']?.toString() ?? '0');
      totalOrders += int.parse(emp['order_count']?.toString() ?? '0');
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final narrow = width < 900;
              final cardWidth = narrow ? width : (width - 48) / 4;

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: _buildSummaryCard(
                      'Total Employees',
                      '${_employees.length}',
                      Icons.people,
                      Colors.blue,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _buildSummaryCard(
                      'Total Sales',
                      '${totalSales.toStringAsFixed(2)} ${context.watch<AppSettingsProvider>().currencySymbol}',
                      Icons.attach_money,
                      Colors.green,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _buildSummaryCard(
                      'Total Orders',
                      '$totalOrders',
                      Icons.shopping_cart,
                      Colors.orange,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _buildSummaryCard(
                      'Avg per Employee',
                      '${(totalSales / _employees.length).toStringAsFixed(2)} ${context.watch<AppSettingsProvider>().currencySymbol}',
                      Icons.trending_up,
                      Colors.purple,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Employee Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final crossAxisCount = width < 600
                  ? 1
                  : width < 900
                      ? 2
                      : 3;
              final aspectRatio = width < 600 ? 1.7 : 1.8;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: aspectRatio,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                ),
                itemCount: _employees.length,
                itemBuilder: (context, index) {
                  return _buildEmployeeCard(_employees[index], index);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
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
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard(Map<String, dynamic> employee, int index) {
    final role = employee['role'] ?? 'cashier';
    final totalSales = double.parse(employee['total_sales']?.toString() ?? '0');
    final orderCount = int.parse(employee['order_count']?.toString() ?? '0');
    final avgOrderValue = orderCount > 0 ? totalSales / orderCount : 0;
    final roleColor = _getRoleColor(role);

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
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with gradient
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      roleColor.withValues(alpha: 0.1),
                      roleColor.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [roleColor, roleColor.withValues(alpha: 0.7)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          employee['full_name'][0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            employee['full_name'],
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: roleColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getRoleIcon(role),
                                  size: 9,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  role.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (index < 3)
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: _getTopPerformerColor(index),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.emoji_events,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                  ],
                ),
              ),

              // Stats
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatItem(
                              'Sales',
                              '${totalSales.toStringAsFixed(0)} ${context.watch<AppSettingsProvider>().currencySymbol}',
                              Icons.attach_money,
                              Colors.green,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 25,
                            color: Colors.grey[200],
                          ),
                          Expanded(
                            child: _buildStatItem(
                              'Orders',
                              '$orderCount',
                              Icons.shopping_bag_outlined,
                              Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.trending_up,
                                size: 10, color: Colors.grey[600]),
                            const SizedBox(width: 3),
                            Text(
                              'Avg: ${avgOrderValue.toStringAsFixed(0)} ${context.watch<AppSettingsProvider>().currencySymbol}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Color _getTopPerformerColor(int index) {
    switch (index) {
      case 0:
        return Colors.amber; // Gold
      case 1:
        return Colors.grey[600]!; // Silver
      case 2:
        return Colors.brown; // Bronze
      default:
        return Colors.grey;
    }
  }
}
