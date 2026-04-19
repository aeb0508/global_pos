import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/app_settings_provider.dart';
import '../providers/cart_provider.dart';
import '../utils/keyboard_shortcuts.dart';
import '../utils/permission_helper.dart';
import 'dashboard_screen.dart';
import 'pos_screen.dart';
import 'products_screen.dart';
import 'orders_screen.dart';
import 'pending_orders_screen.dart';
import 'customers_screen.dart';
import 'suppliers_screen.dart';
import 'inventory_analytics_screen.dart';
import 'customer_analytics_screen.dart';
import 'stock_management_screen.dart';
import 'employee_management_screen.dart';
import 'backup_restore_screen.dart';
import 'gift_cards_screen.dart';
import 'price_management_screen.dart';
import 'notification_settings_screen.dart';
import 'refund_management_screen.dart';
import 'loyalty_program_screen.dart';
import 'tax_management_screen.dart';
import 'audit_trail_screen.dart';
import 'users_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'login_screen.dart';
import 'currency_management_screen.dart';
import 'layaway_screen.dart';
import 'permissions_screen.dart';
import 'multi_store_screen.dart';
import 'payment_gateway_screen.dart';
import 'categories_screen.dart';

class HomeScreen extends StatefulWidget {
  final int? initialIndex;
  final Map<String, dynamic>? orderToEdit;
  final String? initialOrderSearch;
  final String? initialPendingOrderSearch;
  final String? initialProductSearch;
  const HomeScreen(
      {super.key,
      this.initialIndex,
      this.orderToEdit,
      this.initialOrderSearch,
      this.initialPendingOrderSearch,
      this.initialProductSearch});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _sidebarCollapsed = false;
  bool _autoCollapsed = false;
  final Map<int, int> _screenVersions = {};
  // Consumed once on first build, then cleared so refreshes start clean
  String? _initialOrderSearch;
  String? _initialPendingOrderSearch;
  String? _initialProductSearch;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex ?? 0;
    _initialOrderSearch = widget.initialOrderSearch;
    _initialPendingOrderSearch = widget.initialPendingOrderSearch;
    _initialProductSearch = widget.initialProductSearch;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = Provider.of<AppSettingsProvider>(context, listen: false);
      settings.loadSettings().then((_) {
        if (settings.loadError != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(settings.loadError!),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ));
        }
        // Sync tax rate into cart
        if (mounted) {
          Provider.of<CartProvider>(context, listen: false)
              .setTaxRate(settings.taxRate);
        }
      });
    });
  }

  void _onScreenChanged(int index) {
    setState(() {
      _selectedIndex = index;
      _screenVersions[index] = (_screenVersions[index] ?? 0) + 1;
      // Clear search/edit terms when manually navigating so screens reload fresh
      if (index == 2) {
        _initialProductSearch = null;
      }
      if (index == 3) _initialOrderSearch = null;
      if (index == 4) _initialPendingOrderSearch = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) => KeyboardShortcuts.handleKeyPress(
        event,
        context,
        (index) => _onScreenChanged(index),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 1024;

          if (isDesktop) {
            return Scaffold(
              body: Row(
                children: [
                  _Sidebar(
                    selectedIndex: _selectedIndex,
                    collapsed: _sidebarCollapsed,
                    onToggleCollapse: () => setState(() {
                      _sidebarCollapsed = !_sidebarCollapsed;
                      _autoCollapsed = false;
                    }),
                    user: user,
                    onSelect: (i) => _onScreenChanged(i),
                    onLogout: () async {
                      await Provider.of<AuthProvider>(context, listen: false)
                          .logout();
                      if (!context.mounted) return;
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    onShortcuts: () => showDialog(
                      context: context,
                      builder: (_) => const KeyboardShortcutsDialog(),
                    ),
                  ),
                  Expanded(
                    child: _RefreshingIndexedStack(
                      index: _selectedIndex,
                      versions: _screenVersions,
                      builders: [
                        () => const DashboardScreen(),
                        () => PosScreen(orderToEdit: widget.orderToEdit),
                        () => ProductsScreen(
                            initialSearch: _initialProductSearch),
                        () => OrdersScreen(initialSearch: _initialOrderSearch),
                        () => PendingOrdersScreen(
                            initialSearch: _initialPendingOrderSearch),
                        () => const CustomersScreen(),
                        () => const SuppliersScreen(),
                        () => const InventoryAnalyticsScreen(),
                        () => const CustomerAnalyticsScreen(),
                        () => const StockManagementScreen(),
                        () => const EmployeeManagementScreen(),
                        () => const ReportsScreen(),
                        () => const RefundManagementScreen(),
                        () => const LoyaltyProgramScreen(),
                        () => const GiftCardsScreen(),
                        () => const PriceManagementScreen(),
                        () => const TaxManagementScreen(),
                        () => const NotificationSettingsScreen(),
                        () => const AuditTrailScreen(),
                        () => const BackupRestoreScreen(),
                        () => const UsersScreen(),
                        () => const SettingsScreen(),
                        () => const CurrencyManagementScreen(),
                        () => const LayawayScreen(),
                        () => const PermissionsScreen(),
                        () => const MultiStoreScreen(),
                        () => const PaymentGatewayScreen(),
                        () => const CategoriesScreen(),
                      ],
                    ),
                  ),
                ],
              ),
            );
          } else {
            return Scaffold(
              appBar: AppBar(
                elevation: 2,
                toolbarHeight: 64,
                titleSpacing: 16,
                backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
                surfaceTintColor:
                    Theme.of(context).appBarTheme.surfaceTintColor,
                iconTheme: Theme.of(context).appBarTheme.iconTheme,
                actionsIconTheme:
                    Theme.of(context).appBarTheme.actionsIconTheme,
                titleTextStyle: Theme.of(context).appBarTheme.titleTextStyle,
                toolbarTextStyle:
                    Theme.of(context).appBarTheme.toolbarTextStyle,
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.point_of_sale,
                          size: 22,
                          color: Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      'Global POS',
                      style: Theme.of(context)
                              .appBarTheme
                              .titleTextStyle
                              ?.copyWith(
                                color: Theme.of(context)
                                        .appBarTheme
                                        .foregroundColor ??
                                    Theme.of(context).colorScheme.onSurface,
                              ) ??
                          TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
              drawer: _buildDrawer(context, user),
              body: _RefreshingIndexedStack(
                index: _selectedIndex,
                versions: _screenVersions,
                builders: [
                  () => const DashboardScreen(),
                  () => PosScreen(orderToEdit: widget.orderToEdit),
                  () => ProductsScreen(initialSearch: _initialProductSearch),
                  () => OrdersScreen(initialSearch: _initialOrderSearch),
                  () => PendingOrdersScreen(
                      initialSearch: _initialPendingOrderSearch),
                  () => const CustomersScreen(),
                  () => const SuppliersScreen(),
                  () => const InventoryAnalyticsScreen(),
                  () => const CustomerAnalyticsScreen(),
                  () => const StockManagementScreen(),
                  () => const EmployeeManagementScreen(),
                  () => const ReportsScreen(),
                  () => const RefundManagementScreen(),
                  () => const LoyaltyProgramScreen(),
                  () => const GiftCardsScreen(),
                  () => const PriceManagementScreen(),
                  () => const TaxManagementScreen(),
                  () => const NotificationSettingsScreen(),
                  () => const AuditTrailScreen(),
                  () => const BackupRestoreScreen(),
                  () => const UsersScreen(),
                  () => const SettingsScreen(),
                  () => const CurrencyManagementScreen(),
                  () => const LayawayScreen(),
                  () => const PermissionsScreen(),
                  () => const MultiStoreScreen(),
                  () => const PaymentGatewayScreen(),
                  () => const CategoriesScreen(),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, dynamic user) {
    final cs = Theme.of(context).colorScheme;
    final appSettings =
        Provider.of<AppSettingsProvider>(context, listen: false);

    return Drawer(
      width: 280,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.indigo.shade700,
              Colors.indigo.shade900,
            ],
          ),
        ),
        child: Column(
          children: [
            // Header with user info
            SafeArea(
              bottom: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: Column(
                  children: [
                    // Avatar and user info
                    Row(
                      children: [
                        Hero(
                          tag: 'user_avatar',
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white,
                                  Colors.white.withOpacity(0.8),
                                ],
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 28,
                              backgroundColor: cs.primary,
                              child: Text(
                                (user?.fullName.isNotEmpty == true
                                        ? user!.fullName[0]
                                        : '?')
                                    .toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.fullName ?? 'User',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  user?.role.toUpperCase() ?? '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout_rounded,
                              color: Colors.white, size: 22),
                          onPressed: () async {
                            Navigator.pop(context);
                            await Provider.of<AuthProvider>(context,
                                    listen: false)
                                .logout();
                            if (!context.mounted) return;
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                  builder: (_) => const LoginScreen()),
                            );
                          },
                          tooltip: 'Logout',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Quick stats
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          const _QuickStat(
                            icon: Icons.inventory_2,
                            label: 'Products',
                            value: '41',
                          ),
                          Container(
                            width: 1,
                            height: 30,
                            color: Colors.white.withOpacity(0.2),
                          ),
                          const _QuickStat(
                            icon: Icons.shopping_cart,
                            label: 'Orders',
                            value: '128',
                          ),
                          Container(
                            width: 1,
                            height: 30,
                            color: Colors.white.withOpacity(0.2),
                          ),
                          const _QuickStat(
                            icon: Icons.people,
                            label: 'Customers',
                            value: '89',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Navigation items
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    for (final section in _sections)
                      _buildDrawerSection(section, appSettings),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerSection(
      _NavSection section, AppSettingsProvider appSettings) {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    final userRole = user?.role;

    final visibleItems = section.items.where((item) {
      if (!PermissionHelper.isScreenVisible(item.index, userRole)) {
        return false;
      }

      if (item.index == 4 && !appSettings.pendingOrdersEnabled) return false;
      if (item.index == 5 && !appSettings.customersEnabled) return false;
      if (item.index == 6 && !appSettings.suppliersEnabled) return false;
      if (item.index == 7 && !appSettings.inventoryAnalyticsEnabled) {
        return false;
      }
      if (item.index == 8 && !appSettings.customerAnalyticsEnabled) {
        return false;
      }
      if (item.index == 9 && !appSettings.stockManagementEnabled) return false;
      if (item.index == 10 && !appSettings.employeeManagementEnabled) {
        return false;
      }
      if (item.index == 11 && !appSettings.reportsEnabled) return false;
      if (item.index == 12 && !appSettings.refundsEnabled) return false;
      if (item.index == 13 && !appSettings.loyaltyEnabled) return false;
      if (item.index == 14 && !appSettings.giftCardsEnabled) return false;
      if (item.index == 15 && !appSettings.priceManagementEnabled) return false;
      if (item.index == 16 && !appSettings.taxManagementEnabled) return false;
      if (item.index == 17 && !appSettings.notificationsEnabled) return false;
      if (item.index == 18 && !appSettings.auditTrailEnabled) return false;
      if (item.index == 19 && !appSettings.backupRestoreEnabled) return false;
      if (item.index == 22 && !appSettings.currencyManagementEnabled) {
        return false;
      }
      if (item.index == 23 && !appSettings.layawayEnabled) return false;
      if (item.index == 24 && !appSettings.permissionsEnabled) return false;
      if (item.index == 25 && !appSettings.multiStoreEnabled) return false;
      if (item.index == 26 && !appSettings.paymentGatewayEnabled) return false;
      if (item.index == 27 && !appSettings.categoriesEnabled) return false;
      return true;
    }).toList();

    if (visibleItems.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                section.title.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        for (final item in visibleItems)
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 200),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(20 * (1 - value), 0),
                child: Opacity(opacity: value, child: child),
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: BoxDecoration(
                color: _selectedIndex == item.index
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: _selectedIndex == item.index
                    ? Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.3),
                        width: 1,
                      )
                    : null,
              ),
              child: ListTile(
                dense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _selectedIndex == item.index
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    item.icon,
                    size: 20,
                    color: _selectedIndex == item.index
                        ? Colors.white
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                  ),
                ),
                title: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: _selectedIndex == item.index
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: _selectedIndex == item.index
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                trailing: _selectedIndex == item.index
                    ? Icon(
                        Icons.chevron_right_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      )
                    : null,
                onTap: () {
                  _onScreenChanged(item.index);
                  Navigator.pop(context);
                },
              ),
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ─── Sidebar ────────────────────────────────────────────────────────────────

class _QuickStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _QuickStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _NavItem {
  final int index;
  final IconData icon;
  final String label;
  const _NavItem(this.index, this.icon, this.label);
}

class _NavSection {
  final String title;
  final List<_NavItem> items;
  const _NavSection(this.title, this.items);
}

const _sections = [
  _NavSection('Main', [
    _NavItem(0, Icons.dashboard_rounded, 'Dashboard'),
    _NavItem(1, Icons.point_of_sale_rounded, 'POS'),
  ]),
  _NavSection('Commerce', [
    _NavItem(2, Icons.inventory_2_rounded, 'Products'),
    _NavItem(27, Icons.category_rounded, 'Categories'),
    _NavItem(3, Icons.receipt_long_rounded, 'Orders'),
    _NavItem(4, Icons.schedule_rounded, 'Pending Orders'),
    _NavItem(5, Icons.people_rounded, 'Customers'),
    _NavItem(6, Icons.local_shipping_rounded, 'Suppliers'),
    _NavItem(12, Icons.assignment_return_rounded, 'Refunds'),
    _NavItem(13, Icons.loyalty_rounded, 'Loyalty'),
    _NavItem(14, Icons.card_giftcard_rounded, 'Gift Cards'),
    _NavItem(23, Icons.pause_circle_rounded, 'Layaway'),
  ]),
  _NavSection('Analytics', [
    _NavItem(11, Icons.bar_chart_rounded, 'Reports'),
    _NavItem(7, Icons.inventory_rounded, 'Inv. Analytics'),
    _NavItem(8, Icons.person_search_rounded, 'Cust. Analytics'),
    _NavItem(10, Icons.badge_rounded, 'Employees'),
  ]),
  _NavSection('Management', [
    _NavItem(9, Icons.warehouse_rounded, 'Stock'),
    _NavItem(15, Icons.price_change_rounded, 'Prices'),
    _NavItem(16, Icons.percent_rounded, 'Tax'),
    _NavItem(22, Icons.currency_exchange_rounded, 'Currencies'),
    _NavItem(25, Icons.store_rounded, 'Multi-Store'),
    _NavItem(26, Icons.payment_rounded, 'Payment Gateway'),
    _NavItem(20, Icons.manage_accounts_rounded, 'Users'),
    _NavItem(24, Icons.security_rounded, 'Permissions'),
  ]),
  _NavSection('System', [
    _NavItem(17, Icons.notifications_rounded, 'Notifications'),
    _NavItem(18, Icons.history_rounded, 'Audit Trail'),
    _NavItem(19, Icons.backup_rounded, 'Backup'),
    _NavItem(21, Icons.settings_rounded, 'Settings'),
  ]),
];

class _Sidebar extends StatefulWidget {
  final int selectedIndex;
  final bool collapsed;
  final VoidCallback onToggleCollapse;
  final dynamic user;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;
  final VoidCallback onShortcuts;

  const _Sidebar({
    required this.selectedIndex,
    required this.collapsed,
    required this.onToggleCollapse,
    required this.user,
    required this.onSelect,
    required this.onLogout,
    required this.onShortcuts,
  });

  @override
  State<_Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<_Sidebar> {
  // Track which sections are expanded (only expand section with current screen)
  late Map<String, bool> _expandedSections;

  @override
  void initState() {
    super.initState();
    _updateExpandedSections();
  }

  @override
  void didUpdateWidget(_Sidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _updateExpandedSections();
    }
  }

  void _updateExpandedSections() {
    // Find which section contains the current screen
    String? activeSection;
    for (final section in _sections) {
      for (final item in section.items) {
        if (item.index == widget.selectedIndex) {
          activeSection = section.title;
          break;
        }
      }
      if (activeSection != null) break;
    }

    // Expand only the active section
    setState(() {
      _expandedSections = {
        'Main': activeSection == 'Main',
        'Commerce': activeSection == 'Commerce',
        'Analytics': activeSection == 'Analytics',
        'Management': activeSection == 'Management',
        'System': activeSection == 'System',
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appSettings = context.watch<AppSettingsProvider>();

    final sidebarBg =
        isDark ? const Color(0xFF1A1D23) : const Color(0xFF1E2433);
    final activeBg = cs.primary.withValues(alpha: 0.18);
    final activeColor = cs.primary;
    final inactiveColor = Colors.white.withValues(alpha: 0.55);
    final sectionLabelColor = Colors.white.withValues(alpha: 0.3);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      width: widget.collapsed ? 64 : 220,
      color: sidebarBg,
      child: Column(
        children: [
          // ── Logo header ──────────────────────────────────────
          SizedBox(
            height: 64,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: widget.collapsed
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.point_of_sale_rounded,
                        color: Colors.white, size: 18),
                  ),
                  if (!widget.collapsed) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Global POS',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                          Text('v2.0.0',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.35),
                                  fontSize: 11)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.keyboard_outlined,
                          size: 16, color: Colors.white.withValues(alpha: 0.4)),
                      onPressed: widget.onShortcuts,
                      tooltip: 'Shortcuts (F1)',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── User card ────────────────────────────────────────
          if (!widget.collapsed)
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: cs.primary,
                    child: Text(
                      (widget.user?.fullName.isNotEmpty == true
                              ? widget.user!.fullName[0]
                              : '?')
                          .toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.user?.fullName ?? '',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          widget.user?.role.toUpperCase() ?? '',
                          style: TextStyle(
                              fontSize: 10,
                              color: cs.primary.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: widget.onLogout,
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.logout_rounded,
                          size: 16, color: Colors.red[300]),
                    ),
                  ),
                ],
              ),
            )
          else
            Tooltip(
              message: widget.user?.fullName ?? '',
              preferBelow: false,
              child: Container(
                margin: const EdgeInsets.fromLTRB(10, 0, 10, 12),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: cs.primary,
                  child: Text(
                    (widget.user?.fullName.isNotEmpty == true
                            ? widget.user!.fullName[0]
                            : '?')
                        .toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),

          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 4),

          // ── Nav sections ─────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              children: [
                for (final section in _sections)
                  _buildSection(
                    section,
                    widget.collapsed,
                    activeBg,
                    activeColor,
                    inactiveColor,
                    sectionLabelColor,
                    appSettings,
                  ),
              ],
            ),
          ),

          // ── Collapse toggle ──────────────────────────────────
          const Divider(color: Colors.white12, height: 1),
          InkWell(
            onTap: widget.onToggleCollapse,
            child: SizedBox(
              height: 44,
              child: Row(
                mainAxisAlignment: widget.collapsed
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.end,
                children: [
                  if (!widget.collapsed)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text('Collapse',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.35))),
                    ),
                  Padding(
                    padding: EdgeInsets.only(right: widget.collapsed ? 0 : 12),
                    child: Icon(
                      widget.collapsed
                          ? Icons.chevron_right_rounded
                          : Icons.chevron_left_rounded,
                      size: 20,
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    _NavSection section,
    bool collapsed,
    Color activeBg,
    Color activeColor,
    Color inactiveColor,
    Color sectionLabelColor,
    AppSettingsProvider appSettings,
  ) {
    final isExpanded = _expandedSections[section.title] ?? true;
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    final userRole = user?.role;

    // Filter items based on permissions and feature toggles
    final visibleItems = section.items.where((item) {
      // Check permission first
      if (!PermissionHelper.isScreenVisible(item.index, userRole)) {
        return false;
      }

      // Then check app settings
      if (item.index == 4 && !appSettings.pendingOrdersEnabled) return false;
      if (item.index == 5 && !appSettings.customersEnabled) return false;
      if (item.index == 6 && !appSettings.suppliersEnabled) return false;
      if (item.index == 7 && !appSettings.inventoryAnalyticsEnabled) {
        return false;
      }
      if (item.index == 8 && !appSettings.customerAnalyticsEnabled) {
        return false;
      }
      if (item.index == 9 && !appSettings.stockManagementEnabled) return false;
      if (item.index == 10 && !appSettings.employeeManagementEnabled) {
        return false;
      }
      if (item.index == 11 && !appSettings.reportsEnabled) return false;
      if (item.index == 12 && !appSettings.refundsEnabled) return false;
      if (item.index == 13 && !appSettings.loyaltyEnabled) return false;
      if (item.index == 14 && !appSettings.giftCardsEnabled) return false;
      if (item.index == 15 && !appSettings.priceManagementEnabled) return false;
      if (item.index == 16 && !appSettings.taxManagementEnabled) return false;
      if (item.index == 17 && !appSettings.notificationsEnabled) return false;
      if (item.index == 18 && !appSettings.auditTrailEnabled) return false;
      if (item.index == 19 && !appSettings.backupRestoreEnabled) return false;
      if (item.index == 22 && !appSettings.currencyManagementEnabled) {
        return false;
      }
      if (item.index == 23 && !appSettings.layawayEnabled) return false;
      if (item.index == 24 && !appSettings.permissionsEnabled) return false;
      if (item.index == 25 && !appSettings.multiStoreEnabled) return false;
      if (item.index == 26 && !appSettings.paymentGatewayEnabled) return false;
      if (item.index == 27 && !appSettings.categoriesEnabled) return false;
      return true;
    }).toList();

    // Skip section if no visible items
    if (visibleItems.isEmpty) return const SizedBox.shrink();

    if (collapsed) {
      // When collapsed, show all items without section headers
      return Column(
        children: [
          const SizedBox(height: 8),
          for (final item in visibleItems)
            _NavTile(
              item: item,
              isSelected: widget.selectedIndex == item.index,
              collapsed: collapsed,
              activeBg: activeBg,
              activeColor: activeColor,
              inactiveColor: inactiveColor,
              onTap: () => widget.onSelect(item.index),
            ),
        ],
      );
    }

    // When expanded, show collapsible sections
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header with dropdown
        InkWell(
          onTap: () {
            setState(() {
              _expandedSections[section.title] = !isExpanded;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    section.title.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: sectionLabelColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_down_rounded
                      : Icons.keyboard_arrow_right_rounded,
                  size: 16,
                  color: sectionLabelColor,
                ),
              ],
            ),
          ),
        ),
        // Section items (collapsible)
        AnimatedCrossFade(
          firstChild: Column(
            children: [
              for (final item in visibleItems)
                _NavTile(
                  item: item,
                  isSelected: widget.selectedIndex == item.index,
                  collapsed: collapsed,
                  activeBg: activeBg,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                  onTap: () => widget.onSelect(item.index),
                ),
            ],
          ),
          secondChild: const SizedBox.shrink(),
          crossFadeState:
              isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}

class _NavTile extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final bool collapsed;
  final Color activeBg;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _NavTile({
    required this.item,
    required this.isSelected,
    required this.collapsed,
    required this.activeBg,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tile = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(vertical: 1),
      decoration: BoxDecoration(
        color: isSelected ? activeBg : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          hoverColor: Colors.white.withValues(alpha: 0.05),
          child: collapsed
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Center(
                    child: Icon(item.icon,
                        size: 20,
                        color: isSelected ? activeColor : inactiveColor),
                  ),
                )
              : Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                  child: Row(
                    children: [
                      if (isSelected)
                        Container(
                          width: 3,
                          height: 18,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: activeColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        )
                      else
                        const SizedBox(width: 11),
                      Icon(item.icon,
                          size: 18,
                          color: isSelected ? activeColor : inactiveColor),
                      const SizedBox(width: 10),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected ? activeColor : inactiveColor,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );

    if (collapsed) {
      return Tooltip(
        message: item.label,
        preferBelow: false,
        waitDuration: const Duration(milliseconds: 300),
        child: tile,
      );
    }
    return tile;
  }
}

// ─── Refreshing IndexedStack ────────────────────────────────────────────────
class _RefreshingIndexedStack extends StatefulWidget {
  final int index;
  final Map<int, int> versions;
  final List<Widget Function()> builders;
  const _RefreshingIndexedStack({
    required this.index,
    required this.versions,
    required this.builders,
  });

  @override
  State<_RefreshingIndexedStack> createState() =>
      _RefreshingIndexedStackState();
}

class _RefreshingIndexedStackState extends State<_RefreshingIndexedStack> {
  late final List<bool> _activated;

  @override
  void initState() {
    super.initState();
    _activated = List.filled(widget.builders.length, false);
    _activated[widget.index] = true;
  }

  @override
  void didUpdateWidget(_RefreshingIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_activated[widget.index]) {
      setState(() => _activated[widget.index] = true);
    } else if (oldWidget.versions[widget.index] !=
        widget.versions[widget.index]) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: widget.index,
      children: List.generate(widget.builders.length, (i) {
        if (!_activated[i]) return const SizedBox.shrink();
        final version = widget.versions[i] ?? 0;
        return KeyedSubtree(
          key: ValueKey('s${i}_v$version'),
          child: widget.builders[i](),
        );
      }),
    );
  }
}
