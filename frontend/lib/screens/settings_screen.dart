import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/app_settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppSettingsProvider>(context, listen: false).loadSettings();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Header
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cs.primary, cs.primary.withValues(alpha: 0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.settings_rounded,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Settings',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          Text('Customize your POS experience',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.white70)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Tabs
              TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                tabs: const [
                  Tab(icon: Icon(Icons.tune_rounded), text: 'Features'),
                  Tab(icon: Icon(Icons.palette_rounded), text: 'Appearance'),
                  Tab(icon: Icon(Icons.info_rounded), text: 'System'),
                ],
              ),
            ],
          ),
        ),
        // Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildFeaturesTab(),
              _buildAppearanceTab(),
              _buildSystemTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesTab() {
    return Consumer<AppSettingsProvider>(
      builder: (context, settings, _) {
        if (settings.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final sections = [
          _FeatureSection('Commerce', [
            _FeatureItem(
                Icons.people_rounded,
                'Customers',
                'Customer management',
                Colors.blue,
                settings.customersEnabled,
                (v) => settings.updateSettings(customersEnabled: v)),
            _FeatureItem(
                Icons.category_rounded,
                'Categories',
                'Product categories',
                Colors.cyan,
                settings.categoriesEnabled,
                (v) => settings.updateSettings(categoriesEnabled: v)),
            _FeatureItem(
                Icons.local_shipping_rounded,
                'Suppliers',
                'Vendor management',
                Colors.brown,
                settings.suppliersEnabled,
                (v) => settings.updateSettings(suppliersEnabled: v)),
            _FeatureItem(
                Icons.schedule_rounded,
                'Pending Orders',
                'Pending order queue',
                Colors.amber,
                settings.pendingOrdersEnabled,
                (v) => settings.updateSettings(pendingOrdersEnabled: v)),
            _FeatureItem(
                Icons.assignment_return_rounded,
                'Refunds',
                'Refund management',
                Colors.red,
                settings.refundsEnabled,
                (v) => settings.updateSettings(refundsEnabled: v)),
            _FeatureItem(
                Icons.loyalty_rounded,
                'Loyalty Program',
                'Points & rewards',
                Colors.purple,
                settings.loyaltyEnabled,
                (v) => settings.updateSettings(loyaltyEnabled: v)),
            _FeatureItem(
                Icons.card_giftcard_rounded,
                'Gift Cards',
                'Issue & manage cards',
                Colors.pink,
                settings.giftCardsEnabled,
                (v) => settings.updateSettings(giftCardsEnabled: v)),
            _FeatureItem(
                Icons.pause_circle_rounded,
                'Layaway',
                'Partial payments',
                Colors.orange,
                settings.layawayEnabled,
                (v) => settings.updateSettings(layawayEnabled: v)),
          ]),
          _FeatureSection('Analytics', [
            _FeatureItem(
                Icons.bar_chart_rounded,
                'Reports',
                'Sales & business reports',
                Colors.indigo,
                settings.reportsEnabled,
                (v) => settings.updateSettings(reportsEnabled: v)),
            _FeatureItem(
                Icons.inventory_rounded,
                'Inv. Analytics',
                'Inventory insights',
                Colors.teal,
                settings.inventoryAnalyticsEnabled,
                (v) => settings.updateSettings(inventoryAnalyticsEnabled: v)),
            _FeatureItem(
                Icons.person_search_rounded,
                'Cust. Analytics',
                'Customer insights',
                Colors.green,
                settings.customerAnalyticsEnabled,
                (v) => settings.updateSettings(customerAnalyticsEnabled: v)),
            _FeatureItem(
                Icons.badge_rounded,
                'Employees',
                'Staff management',
                Colors.blueGrey,
                settings.employeeManagementEnabled,
                (v) => settings.updateSettings(employeeManagementEnabled: v)),
          ]),
          _FeatureSection('Management', [
            _FeatureItem(
                Icons.warehouse_rounded,
                'Stock',
                'Stock adjustments',
                Colors.deepOrange,
                settings.stockManagementEnabled,
                (v) => settings.updateSettings(stockManagementEnabled: v)),
            _FeatureItem(
                Icons.price_change_rounded,
                'Prices',
                'Pricing & history',
                Colors.lime,
                settings.priceManagementEnabled,
                (v) => settings.updateSettings(priceManagementEnabled: v)),
            _FeatureItem(
                Icons.percent_rounded,
                'Tax',
                'Tax rates & rules',
                Colors.deepPurple,
                settings.taxManagementEnabled,
                (v) => settings.updateSettings(taxManagementEnabled: v)),
            _FeatureItem(
                Icons.currency_exchange_rounded,
                'Currencies',
                'Exchange rates',
                Colors.teal,
                settings.currencyManagementEnabled,
                (v) => settings.updateSettings(currencyManagementEnabled: v)),
            _FeatureItem(
                Icons.store_rounded,
                'Multi-Store',
                'Multiple locations',
                Colors.blue,
                settings.multiStoreEnabled,
                (v) => settings.updateSettings(multiStoreEnabled: v)),
            _FeatureItem(
                Icons.payment_rounded,
                'Payment Gateway',
                'Gateway config',
                Colors.indigo,
                settings.paymentGatewayEnabled,
                (v) => settings.updateSettings(paymentGatewayEnabled: v)),
          ]),
          _FeatureSection('System', [
            _FeatureItem(
                Icons.notifications_rounded,
                'Notifications',
                'Alerts & notifications',
                Colors.orange,
                settings.notificationsEnabled,
                (v) => settings.updateSettings(notificationsEnabled: v)),
            _FeatureItem(
                Icons.history_rounded,
                'Audit Trail',
                'Activity tracking',
                Colors.grey,
                settings.auditTrailEnabled,
                (v) => settings.updateSettings(auditTrailEnabled: v)),
            _FeatureItem(
                Icons.backup_rounded,
                'Backup',
                'Backup & restore',
                Colors.green,
                settings.backupRestoreEnabled,
                (v) => settings.updateSettings(backupRestoreEnabled: v)),
            _FeatureItem(
                Icons.security_rounded,
                'Permissions',
                'Access control',
                Colors.red,
                settings.permissionsEnabled,
                (v) => settings.updateSettings(permissionsEnabled: v)),
          ]),
        ];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final section in sections) ...[
                _buildSectionHeader(section.title),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 700
                        ? 4
                        : constraints.maxWidth > 480
                            ? 3
                            : 2;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.1,
                      ),
                      itemCount: section.items.length,
                      itemBuilder: (context, i) =>
                          _buildGridCard(section.items[i]),
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildGridCard(_FeatureItem item) {
    return Card(
      elevation: item.value ? 3 : 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final success = await item.onChanged(!item.value);
          if (mounted) _showSnackbar(success, item.title, !item.value);
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  item.value ? item.color.withValues(alpha: 0.4) : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: item.value ? 0.15 : 0.07),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(item.icon, color: item.color, size: 22),
                  ),
                  Switch(
                    value: item.value,
                    onChanged: (v) async {
                      final success = await item.onChanged(v);
                      if (mounted) _showSnackbar(success, item.title, v);
                    },
                    activeThumbColor: item.color,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(item.description,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppearanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Customize Appearance',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Personalize the look and feel of your application',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey)),
          const SizedBox(height: 24),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return Column(
                children: [
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.indigo.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              themeProvider.isDarkMode
                                  ? Icons.dark_mode_rounded
                                  : Icons.light_mode_rounded,
                              color: Colors.indigo,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Dark Mode',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                                SizedBox(height: 4),
                                Text('Switch between light and dark theme',
                                    style: TextStyle(
                                        fontSize: 13, color: Colors.grey)),
                              ],
                            ),
                          ),
                          Switch(
                            value: themeProvider.isDarkMode,
                            onChanged: (_) => themeProvider.toggleTheme(),
                            activeThumbColor: Colors.indigo,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: themeProvider.primaryColor
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.palette_rounded,
                                    color: themeProvider.primaryColor,
                                    size: 28),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Theme Color',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold)),
                                    SizedBox(height: 4),
                                    Text('Choose your primary accent color',
                                        style: TextStyle(
                                            fontSize: 13, color: Colors.grey)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _buildColorOption(Colors.blue, themeProvider),
                              _buildColorOption(Colors.red, themeProvider),
                              _buildColorOption(Colors.green, themeProvider),
                              _buildColorOption(Colors.purple, themeProvider),
                              _buildColorOption(Colors.orange, themeProvider),
                              _buildColorOption(Colors.teal, themeProvider),
                              _buildColorOption(Colors.pink, themeProvider),
                              _buildColorOption(Colors.indigo, themeProvider),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildColorOption(Color color, ThemeProvider themeProvider) {
    final isSelected = themeProvider.primaryColor.toARGB32() == color.toARGB32();
    return InkWell(
      onTap: () => themeProvider.setPrimaryColor(color),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isSelected ? Colors.white : Colors.transparent, width: 3),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 2)
                ]
              : null,
        ),
        child: isSelected
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 28)
            : null,
      ),
    );
  }

  Widget _buildSystemTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('System Information',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Application details and system utilities',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey)),
          const SizedBox(height: 24),
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                _buildSystemTile(
                    icon: Icons.info_rounded,
                    title: 'About',
                    subtitle: 'Version 2.0.0 - Global POS',
                    color: Colors.blue,
                    onTap: () => _showAboutDialog(context)),
                const Divider(height: 1),
                _buildSystemTile(
                    icon: Icons.update_rounded,
                    title: 'Check for Updates',
                    subtitle: 'You are running the latest version',
                    color: Colors.purple,
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('✓ Application is up to date'),
                            behavior: SnackBarBehavior.floating))),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 2,
            color: Theme.of(context).colorScheme.primaryContainer,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_rounded,
                      color: Theme.of(context).colorScheme.primary, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pro Tip',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary)),
                        const SizedBox(height: 4),
                        Text('Press F1 to view all keyboard shortcuts',
                            style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer)),
                      ],
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

  Widget _buildSystemTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }

  void _showSnackbar(bool success, String feature, bool enabled) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(success ? Icons.check_circle_rounded : Icons.error_rounded,
                color: Colors.white),
            const SizedBox(width: 12),
            Text(success
                ? '$feature ${enabled ? "enabled" : "disabled"}'
                : 'Failed to update setting'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: success ? Colors.green : Colors.red,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Global POS',
      applicationVersion: '2.0.0',
      applicationIcon: const Icon(Icons.point_of_sale, size: 48),
      children: [
        const Text('A professional Point of Sale system'),
        const SizedBox(height: 8),
        const Text('Built with Flutter and PHP'),
      ],
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final bool value;
  final Future<bool> Function(bool) onChanged;

  const _FeatureItem(this.icon, this.title, this.description, this.color,
      this.value, this.onChanged);
}

class _FeatureSection {
  final String title;
  final List<_FeatureItem> items;

  const _FeatureSection(this.title, this.items);
}
