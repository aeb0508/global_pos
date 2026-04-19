import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/api_config.dart';
import 'dashboard_screen.dart';
import 'pos_screen.dart';
import 'products_screen.dart';
import 'orders_screen.dart';
import 'customers_screen.dart';
import 'reports_screen.dart';
import 'users_screen.dart';
import 'stock_management_screen.dart';
import 'inventory_analytics_screen.dart';
import 'backup_restore_screen.dart';
import 'settings_screen.dart';
import 'notification_settings_screen.dart';
import 'login_screen.dart';

class MobileHomeScreen extends StatefulWidget {
  const MobileHomeScreen({super.key});

  @override
  State<MobileHomeScreen> createState() => _MobileHomeScreenState();
}

class _MobileHomeScreenState extends State<MobileHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const PosScreen(),
    const ProductsScreen(),
    const OrdersScreen(),
    const MobileMoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [cs.primary, cs.secondary]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.point_of_sale,
                  size: 20, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Text('Global POS', style: TextStyle(fontSize: 18)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: PopupMenuButton<String>(
              icon: CircleAvatar(
                backgroundColor: cs.primaryContainer,
                child: Text(
                  authProvider.user?.fullName[0].toUpperCase() ?? 'U',
                  style: TextStyle(
                      color: cs.onPrimaryContainer,
                      fontWeight: FontWeight.bold),
                ),
              ),
              onSelected: (value) async {
                if (value == 'logout') {
                  await authProvider.logout();
                  if (!context.mounted) return;
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                } else if (value == 'server') {
                  _showServerUrlDialog(context);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(authProvider.user?.fullName ?? 'User',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(authProvider.user?.role.toUpperCase() ?? '',
                          style: TextStyle(fontSize: 12, color: cs.primary)),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'server',
                  child: Row(children: [
                    Icon(Icons.dns_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('Server URL'),
                  ]),
                ),
                PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(children: [
                    Icon(Icons.logout, size: 20, color: cs.error),
                    const SizedBox(width: 12),
                    Text('Logout', style: TextStyle(color: cs.error)),
                  ]),
                ),
              ],
            ),
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Dashboard'),
          NavigationDestination(
              icon: Icon(Icons.point_of_sale_outlined),
              selectedIcon: Icon(Icons.point_of_sale),
              label: 'POS'),
          NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: 'Products'),
          NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Orders'),
          NavigationDestination(
              icon: Icon(Icons.more_horiz),
              selectedIcon: Icon(Icons.more_horiz),
              label: 'More'),
        ],
        height: 65,
        elevation: 8,
      ),
    );
  }

  void _showServerUrlDialog(BuildContext context) {
    final controller = TextEditingController(text: ApiConfig.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Server URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your computer\'s IP address:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'API Base URL',
                hintText: 'http://192.168.1.72/backend/api',
                border: OutlineInputBorder(),
                helperText: 'Example: http://192.168.1.X/backend/api',
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💡 How to find your IP:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '1. On your computer, open CMD\n2. Type: ipconfig\n3. Look for IPv4 Address\n4. Use that IP in the URL above',
                    style: TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ApiConfig.setCustomUrl(null);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Reset to default (automatic detection)')),
                );
              }
            },
            child: const Text('Reset'),
          ),
          ElevatedButton(
            onPressed: () async {
              final url = controller.text.trim();
              if (url.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a URL')),
                );
                return;
              }
              await ApiConfig.setCustomUrl(url);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Server URL updated to: $url')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class MobileMoreScreen extends StatelessWidget {
  const MobileMoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    void go(Widget screen) =>
        Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.analytics, color: cs.primary),
                  const SizedBox(width: 8),
                  const Text('Quick Access',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    _QuickAccessCard(
                      icon: Icons.people_outline,
                      label: 'Customers',
                      color: Colors.blue,
                      onTap: () => go(const CustomersScreen()),
                    ),
                    _QuickAccessCard(
                      icon: Icons.assessment_outlined,
                      label: 'Reports',
                      color: Colors.green,
                      onTap: () => go(const ReportsScreen()),
                    ),
                    _QuickAccessCard(
                      icon: Icons.person_outline,
                      label: 'Users',
                      color: Colors.orange,
                      onTap: () => go(const UsersScreen()),
                    ),
                    _QuickAccessCard(
                      icon: Icons.inventory_outlined,
                      label: 'Stock',
                      color: Colors.purple,
                      onTap: () => go(const StockManagementScreen()),
                    ),
                    _QuickAccessCard(
                      icon: Icons.analytics_outlined,
                      label: 'Analytics',
                      color: Colors.teal,
                      onTap: () => go(const InventoryAnalyticsScreen()),
                    ),
                    _QuickAccessCard(
                      icon: Icons.backup_outlined,
                      label: 'Backup',
                      color: Colors.red,
                      onTap: () => go(const BackupRestoreScreen()),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              _SettingsTile(
                icon: Icons.settings_outlined,
                title: 'Settings',
                subtitle: 'App preferences',
                onTap: () => go(const SettingsScreen()),
              ),
              const Divider(height: 1),
              _SettingsTile(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                subtitle: 'Manage alerts',
                onTap: () => go(const NotificationSettingsScreen()),
              ),
              const Divider(height: 1),
              _SettingsTile(
                icon: Icons.dark_mode_outlined,
                title: 'Theme',
                subtitle: themeProvider.themeMode == ThemeMode.dark
                    ? 'Dark mode'
                    : 'Light mode',
                onTap: () => themeProvider.toggleTheme(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAccessCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: color),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
