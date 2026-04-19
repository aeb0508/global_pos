import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/api_config.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _roles = ['admin', 'manager', 'cashier'];
  Map<String, List<dynamic>> _permissionsByRole = {};
  bool _isLoading = true;
  bool _isSaving = false;

  static const Map<String, List<Map<String, String>>> _featuresByCategory = {
    'Core Operations': [
      {'key': 'pos', 'label': 'POS (Point of Sale)', 'icon': '🛒'},
      {'key': 'products', 'label': 'Products', 'icon': '📦'},
      {'key': 'orders', 'label': 'Orders & Sales', 'icon': '🛒'},
      {'key': 'customers', 'label': 'Customers', 'icon': '👥'},
      {'key': 'categories', 'label': 'Categories', 'icon': '🏷️'},
      {'key': 'stores', 'label': 'Stores', 'icon': '🏪'},
    ],
    'Inventory Management': [
      {'key': 'inventory', 'label': 'Inventory', 'icon': '📊'},
      {'key': 'stock_management', 'label': 'Stock Management', 'icon': '📈'},
      {'key': 'inventory_analytics', 'label': 'Inventory Analytics', 'icon': '📉'},
      {'key': 'suppliers', 'label': 'Suppliers', 'icon': '🚚'},
    ],
    'Financial': [
      {'key': 'refunds', 'label': 'Refunds & Returns', 'icon': '💸'},
      {'key': 'discounts', 'label': 'Discounts', 'icon': '🎁'},
      {'key': 'prices', 'label': 'Price Management', 'icon': '💰'},
      {'key': 'tax', 'label': 'Tax Rates', 'icon': '💳'},
      {'key': 'multi_payment', 'label': 'Multi-Payment', 'icon': '💵'},
      {'key': 'payment_gateway', 'label': 'Payment Gateway', 'icon': '🏦'},
    ],
    'Customer Programs': [
      {'key': 'loyalty_program', 'label': 'Loyalty Program', 'icon': '⭐'},
      {'key': 'gift_cards', 'label': 'Gift Cards', 'icon': '🎫'},
      {'key': 'layaway', 'label': 'Layaway', 'icon': '📅'},
      {'key': 'customer_analytics', 'label': 'Customer Analytics', 'icon': '📊'},
    ],
    'Administration': [
      {'key': 'users', 'label': 'Users', 'icon': '👤'},
      {'key': 'employee_management', 'label': 'Employee Management', 'icon': '👨‍💼'},
      {'key': 'permissions', 'label': 'Permissions', 'icon': '🔐'},
      {'key': 'audit', 'label': 'Audit Logs', 'icon': '📋'},
    ],
    'Reports & Analytics': [
      {'key': 'reports', 'label': 'Reports', 'icon': '📈'},
      {'key': 'notifications', 'label': 'Notifications', 'icon': '🔔'},
    ],
    'System': [
      {'key': 'backup', 'label': 'Backup & Restore', 'icon': '💾'},
      {'key': 'app_settings', 'label': 'App Settings', 'icon': '⚙️'},
      {'key': 'currencies', 'label': 'Currencies', 'icon': '💱'},
      {'key': 'offline_sync', 'label': 'Offline Sync', 'icon': '🔄'},
    ],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _roles.length, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final res = await ApiService.get('${ApiConfig.baseUrl}/permissions.php');
    if (res['success']) {
      final data = res['data'] as List;
      
      // Get all valid feature keys from our UI definition
      final validFeatures = <String>{};
      for (var category in _featuresByCategory.values) {
        for (var feature in category) {
          validFeatures.add(feature['key']!);
        }
      }
      
      final map = <String, List<dynamic>>{};
      for (final role in _roles) {
        // Only include permissions for features that exist in our UI
        map[role] = data.where((p) => p['role'] == role && validFeatures.contains(p['feature'])).toList();
      }
      setState(() { _permissionsByRole = map; _isLoading = false; });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic>? _getPermission(String role, String feature) {
    final perms = _permissionsByRole[role] ?? [];
    try {
      return perms.firstWhere((p) => p['feature'] == feature) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  bool _getBool(Map<String, dynamic>? perm, String key) {
    if (perm == null) return false;
    final v = perm[key];
    return v == true || v == 1 || v == '1';
  }

  Future<void> _toggle(String role, String feature, String key, bool value) async {
    if (role == 'admin') return; // Admin always has full access

    final perm = _getPermission(role, feature) ?? {
      'role': role, 'feature': feature,
      'can_view': false, 'can_create': false, 'can_edit': false, 'can_delete': false,
    };

    final updated = Map<String, dynamic>.from(perm);
    updated[key] = value;
    // If disabling view, disable all
    if (key == 'can_view' && !value) {
      updated['can_create'] = false;
      updated['can_edit'] = false;
      updated['can_delete'] = false;
    }
    // If enabling create/edit/delete, ensure view is on
    if (key != 'can_view' && value) {
      updated['can_view'] = true;
    }

    setState(() {
      final list = _permissionsByRole[role] ?? [];
      final idx = list.indexWhere((p) => p['feature'] == feature);
      if (idx >= 0) {
        list[idx] = updated;
      } else {
        list.add(updated);
      }
      _permissionsByRole[role] = list;
    });

    await _savePermission(role, feature, updated);
  }

  Future<void> _savePermission(String role, String feature, Map<String, dynamic> perm) async {
    setState(() => _isSaving = true);
    try {
      print('Saving permission: role=$role, feature=$feature');
      
      // Only send the required fields, not the entire permission object
      final payload = {
        'role': role,
        'feature': feature,
        'can_view': perm['can_view'] == true || perm['can_view'] == 1,
        'can_create': perm['can_create'] == true || perm['can_create'] == 1,
        'can_edit': perm['can_edit'] == true || perm['can_edit'] == 1,
        'can_delete': perm['can_delete'] == true || perm['can_delete'] == 1,
      };
      
      print('Payload: $payload');
      
      final response = await ApiService.put('${ApiConfig.baseUrl}/permissions.php', payload);
      
      print('Response: $response');
      
      if (mounted) {
        if (response['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ $feature saved for $role'),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Failed: ${response['message'] ?? 'Unknown error'}'),
              duration: const Duration(seconds: 3),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Save error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _handleBulkAction(String action) async {
    final role = _roles[_tabController.index];
    if (role == 'admin') return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Bulk Action'),
        content: Text('Are you sure you want to $action for $role role?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSaving = true);

    try {
      // Get all features
      final allFeatures = <String>[];
      for (var category in _featuresByCategory.values) {
        for (var feature in category) {
          allFeatures.add(feature['key']!);
        }
      }

      for (var feature in allFeatures) {
        Map<String, dynamic> perm;
        
        switch (action) {
          case 'enable_all_view':
            perm = {
              'role': role,
              'feature': feature,
              'can_view': true,
              'can_create': false,
              'can_edit': false,
              'can_delete': false,
            };
            break;
          case 'disable_all':
            perm = {
              'role': role,
              'feature': feature,
              'can_view': false,
              'can_create': false,
              'can_edit': false,
              'can_delete': false,
            };
            break;
          case 'reset_defaults':
            // Will be handled by reloading from server
            continue;
          default:
            continue;
        }

        await _savePermission(role, feature, perm);
      }

      if (action == 'reset_defaults') {
        // For reset, just reload from server
        await _load();
      } else {
        // Update local state
        await _load();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bulk action completed for $role'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bulk action failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepOrange.shade600, Colors.deepOrange.shade800],
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
                    const Icon(Icons.security, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    const Text('Advanced Permissions',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    if (_isSaving) ...[
                      const SizedBox(width: 12),
                      const SizedBox(width: 14, height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70)),
                      const SizedBox(width: 6),
                      const Text('Saving...', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                    const Spacer(),
                    // Bulk actions dropdown
                    if (!_isLoading && _tabController.index != 0) // Don't show for admin
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        tooltip: 'Bulk Actions',
                        onSelected: (value) => _handleBulkAction(value),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'enable_all_view',
                            child: Row(
                              children: [
                                Icon(Icons.visibility, size: 18),
                                SizedBox(width: 8),
                                Text('Enable All View'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'disable_all',
                            child: Row(
                              children: [
                                Icon(Icons.block, size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Disable All', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'reset_defaults',
                            child: Row(
                              children: [
                                Icon(Icons.restore, size: 18),
                                SizedBox(width: 8),
                                Text('Reset to Defaults'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: _load,
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
              ),
              TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                tabs: _roles.map((r) => Tab(text: r[0].toUpperCase() + r.substring(1))).toList(),
              ),
            ],
          ),
        ),
        if (_isLoading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _roles.map((role) => _buildRoleTab(role)).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildRoleTab(String role) {
    final isAdmin = role == 'admin';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAdmin)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!, width: 2),
              ),
              child: const Row(
                children: [
                  Icon(Icons.admin_panel_settings, color: Colors.blue, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Admin has full access to all features and cannot be restricted.',
                      style: TextStyle(color: Colors.blue, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ..._featuresByCategory.entries.map((category) {
            return _buildCategorySection(role, category.key, category.value, isAdmin);
          }),
        ],
      ),
    );
  }

  Widget _buildCategorySection(String role, String categoryName, List<Map<String, String>> features, bool isAdmin) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.folder_outlined, color: Colors.deepOrange[700], size: 20),
                const SizedBox(width: 8),
                Text(
                  categoryName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
          Table(
            border: TableBorder.symmetric(
              inside: BorderSide(color: Colors.grey[200]!),
            ),
            columnWidths: const {
              0: FlexColumnWidth(3),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(1),
              4: FlexColumnWidth(1),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(color: Colors.grey[50]),
                children: [
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Feature',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  ...['View', 'Create', 'Edit', 'Delete'].map((label) {
                    return Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        label,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }),
                ],
              ),
              ...features.map((feature) {
                final featureKey = feature['key']!;
                final featureLabel = feature['label']!;
                final featureIcon = feature['icon']!;
                final perm = _getPermission(role, featureKey);
                
                return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      child: Row(
                        children: [
                          Text(featureIcon, style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              featureLabel,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...['can_view', 'can_create', 'can_edit', 'can_delete'].map((key) {
                      final val = isAdmin ? true : _getBool(perm, key);
                      return Center(
                        child: Checkbox(
                          value: val,
                          onChanged: isAdmin ? null : (v) => _toggle(role, featureKey, key, v!),
                          tristate: false,
                          activeColor: Colors.deepOrange,
                        ),
                      );
                    }),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}
