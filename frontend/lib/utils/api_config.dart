import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  // Development/Local URL (for testing)
  static const String _localUrl = 'http://localhost/backend/api';

  // Production URL (Railway)
  static const String _productionUrl =
      'https://your-railway-backend.up.railway.app/backend/api';

  // Overridable at runtime via Settings screen
  static String? _customBaseUrl;

  static Future<void> loadCustomUrl() async {
    final prefs = await SharedPreferences.getInstance();
    _customBaseUrl = prefs.getString('custom_server_url');
  }

  static Future<void> setCustomUrl(String? url) async {
    _customBaseUrl = (url == null || url.trim().isEmpty) ? null : url.trim();
    final prefs = await SharedPreferences.getInstance();
    if (_customBaseUrl != null) {
      await prefs.setString('custom_server_url', _customBaseUrl!);
    } else {
      await prefs.remove('custom_server_url');
    }
  }

  static String get baseUrl {
    // Priority 1: Custom URL from settings (if set)
    if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) {
      return _customBaseUrl!;
    }

    // Priority 2: Use localhost only when running on localhost in web.
    if (kIsWeb) {
      final host = Uri.base.host;
      if (host == 'localhost' || host == '127.0.0.1') {
        return _localUrl;
      }
    }

    // Default production server
    return _productionUrl;
  }

  // Core
  static String get authEndpoint => '$baseUrl/auth.php';
  static String get productsEndpoint => '$baseUrl/products.php';
  static String get ordersEndpoint => '$baseUrl/orders.php';
  static String get categoriesEndpoint => '$baseUrl/categories.php';
  static String get customersEndpoint => '$baseUrl/customers.php';
  static String get reportsEndpoint => '$baseUrl/reports.php';
  static String get usersEndpoint => '$baseUrl/users.php';
  static String get suppliersEndpoint => '$baseUrl/suppliers.php';

  // Analytics
  static String get inventoryAnalyticsEndpoint =>
      '$baseUrl/inventory_analytics.php';
  static String get customerAnalyticsEndpoint =>
      '$baseUrl/customer_analytics.php';
  static String get employeeManagementEndpoint =>
      '$baseUrl/employee_management.php';

  // Operations
  static String get stockManagementEndpoint => '$baseUrl/stock_management.php';
  static String get refundsEndpoint => '$baseUrl/refunds.php';
  static String get taxRatesEndpoint => '$baseUrl/tax_rates.php';
  static String get auditLogsEndpoint => '$baseUrl/audit_logs.php';

  // Business
  static String get loyaltyEndpoint => '$baseUrl/loyalty_program.php';
  static String get giftCardsEndpoint => '$baseUrl/gift_cards.php';
  static String get priceManagementEndpoint => '$baseUrl/price_management.php';
  static String get notificationsEndpoint => '$baseUrl/notifications.php';

  // System
  static String get backupRestoreEndpoint => '$baseUrl/backup_restore.php';
  static String get multiPaymentEndpoint => '$baseUrl/multi_payment.php';
  static String get uploadImageEndpoint => '$baseUrl/upload_image.php';
  static String get currenciesEndpoint => '$baseUrl/currencies.php';
  static String get layawayEndpoint => '$baseUrl/layaway.php';
  static String get permissionsEndpoint => '$baseUrl/permissions.php';
  static String get appSettingsEndpoint => '$baseUrl/app_settings.php';
  static String get paymentGatewayEndpoint => '$baseUrl/payment_gateway.php';

  // Helper method to check current environment
  static String get currentEnvironment {
    if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) {
      return 'Custom: $_customBaseUrl';
    }
    if (kIsWeb &&
        (Uri.base.host == 'localhost' || Uri.base.host == '127.0.0.1')) {
      return 'Development (Localhost)';
    }
    return 'Production (InfinityFree)';
  }
}
