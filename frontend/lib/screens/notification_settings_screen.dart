import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/api_config.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _isLoading = true;
  bool _emailReceipts = false;
  bool _lowStockAlerts = false;
  bool _dailySummary = false;
  bool _smsNotifications = false;
  final _emailController = TextEditingController();
  final _smtpHostController = TextEditingController();
  final _smtpPortController = TextEditingController(text: '587');
  final _smtpUserController = TextEditingController();
  final _smtpPassController = TextEditingController();
  List<dynamic> _logs = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _smtpHostController.dispose();
    _smtpPortController.dispose();
    _smtpUserController.dispose();
    _smtpPassController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get('${ApiConfig.baseUrl}/notifications.php?settings=1');
      if (response['success'] && response['data'] != null) {
        final s = response['data'];
        setState(() {
          _emailReceipts = s['email_receipts'] == '1';
          _lowStockAlerts = s['low_stock_alerts'] == '1';
          _dailySummary = s['daily_summary'] == '1';
          _smsNotifications = s['sms_notifications'] == '1';
          _emailController.text = s['admin_email'] ?? '';
          _smtpHostController.text = s['smtp_host'] ?? '';
          _smtpPortController.text = s['smtp_port'] ?? '587';
          _smtpUserController.text = s['smtp_user'] ?? '';
        });
      }
      final logsRes = await ApiService.get('${ApiConfig.baseUrl}/notifications.php?logs=1');
      if (logsRes['success']) {
        setState(() => _logs = logsRes['data'] ?? []);
      }
    } catch (e) {
      // ignore
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    try {
      final response = await ApiService.post('${ApiConfig.baseUrl}/notifications.php', {
        'action': 'save_settings',
        'email_receipts': _emailReceipts ? '1' : '0',
        'low_stock_alerts': _lowStockAlerts ? '1' : '0',
        'daily_summary': _dailySummary ? '1' : '0',
        'sms_notifications': _smsNotifications ? '1' : '0',
        'admin_email': _emailController.text,
        'smtp_host': _smtpHostController.text,
        'smtp_port': _smtpPortController.text,
        'smtp_user': _smtpUserController.text,
        'smtp_pass': _smtpPassController.text,
      });
      if (response['success'] && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _sendTestEmail() async {
    try {
      final response = await ApiService.post('${ApiConfig.baseUrl}/notifications.php', {
        'action': 'test_email',
        'email': _emailController.text,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Test email sent'),
            backgroundColor: response['success'] == true ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            expandedHeight: 0,
            title: const Row(
              children: [
                Icon(Icons.notifications, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Notification Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade600, Colors.orange.shade800],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(icon: const Icon(Icons.save, color: Colors.white), onPressed: _saveSettings, tooltip: 'Save Settings'),
              IconButton(icon: const Icon(Icons.send, color: Colors.white), onPressed: _sendTestEmail, tooltip: 'Send Test Email'),
              IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _loadSettings, tooltip: 'Refresh'),
            ],
          ),
          SliverFillRemaining(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Card(
                            child: Column(
                              children: [
                                SwitchListTile(title: const Text('Email Receipts'), subtitle: const Text('Send receipt to customer email after sale'), value: _emailReceipts, onChanged: (v) => setState(() => _emailReceipts = v)),
                                SwitchListTile(title: const Text('Low Stock Alerts'), subtitle: const Text('Email when products reach low stock threshold'), value: _lowStockAlerts, onChanged: (v) => setState(() => _lowStockAlerts = v)),
                                SwitchListTile(title: const Text('Daily Sales Summary'), subtitle: const Text('Send daily sales report by email'), value: _dailySummary, onChanged: (v) => setState(() => _dailySummary = v)),
                                SwitchListTile(title: const Text('SMS Notifications'), subtitle: const Text('Send SMS alerts (requires Twilio)'), value: _smsNotifications, onChanged: (v) => setState(() => _smsNotifications = v)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text('Email Configuration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.blue.shade700),
                                const SizedBox(width: 8),
                                Expanded(child: Text('For Gmail: Use smtp.gmail.com, port 587, and an App Password', style: TextStyle(fontSize: 12, color: Colors.blue.shade900))),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Admin Email', border: OutlineInputBorder())),
                                  const SizedBox(height: 12),
                                  TextField(controller: _smtpHostController, decoration: const InputDecoration(labelText: 'SMTP Host', border: OutlineInputBorder())),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(child: TextField(controller: _smtpPortController, decoration: const InputDecoration(labelText: 'SMTP Port', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                                      const SizedBox(width: 12),
                                      Expanded(child: TextField(controller: _smtpUserController, decoration: const InputDecoration(labelText: 'SMTP Username', border: OutlineInputBorder()))),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(controller: _smtpPassController, obscureText: true, decoration: const InputDecoration(labelText: 'SMTP Password', border: OutlineInputBorder())),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Notification Logs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Card(
                            child: _logs.isEmpty
                                ? const Center(child: Text('No notifications sent yet'))
                                : ListView.builder(
                                    itemCount: _logs.length,
                                    itemBuilder: (context, index) {
                                      final log = _logs[index];
                                      return ListTile(
                                        leading: Icon(log['type'] == 'email' ? Icons.email : Icons.sms, color: log['status'] == 'sent' ? Colors.green : Colors.red),
                                        title: Text(log['subject'] ?? log['type']),
                                        subtitle: Text(log['recipient'] ?? ''),
                                        trailing: Text(log['created_at'] ?? '', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                      );
                                    },
                                  ),
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
      ),
    );
  }
}
