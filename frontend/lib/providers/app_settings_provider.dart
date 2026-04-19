import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../utils/api_config.dart';

class AppSettingsProvider with ChangeNotifier {
  bool _loyaltyEnabled = false;
  bool _giftCardsEnabled = false;
  bool _layawayEnabled = false;
  bool _multiStoreEnabled = true;
  bool _paymentGatewayEnabled = true;
  bool _reportsEnabled = true;
  bool _auditTrailEnabled = true;
  bool _backupRestoreEnabled = true;
  bool _notificationsEnabled = true;
  bool _permissionsEnabled = true;
  bool _refundsEnabled = true;
  bool _priceManagementEnabled = true;
  bool _taxManagementEnabled = true;
  bool _currencyManagementEnabled = true;
  bool _stockManagementEnabled = true;
  bool _employeeManagementEnabled = true;
  bool _suppliersEnabled = true;
  bool _customersEnabled = true;
  bool _categoriesEnabled = true;
  bool _pendingOrdersEnabled = true;
  bool _customerAnalyticsEnabled = true;
  bool _inventoryAnalyticsEnabled = true;
  bool _isLoading = false;
  String? _loadError;
  String _currencySymbol = '\$';
  String _currencyCode = 'USD';
  double _taxRate = 0.1;

  bool get loyaltyEnabled => _loyaltyEnabled;
  bool get giftCardsEnabled => _giftCardsEnabled;
  bool get layawayEnabled => _layawayEnabled;
  bool get multiStoreEnabled => _multiStoreEnabled;
  bool get paymentGatewayEnabled => _paymentGatewayEnabled;
  bool get reportsEnabled => _reportsEnabled;
  bool get auditTrailEnabled => _auditTrailEnabled;
  bool get backupRestoreEnabled => _backupRestoreEnabled;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get permissionsEnabled => _permissionsEnabled;
  bool get refundsEnabled => _refundsEnabled;
  bool get priceManagementEnabled => _priceManagementEnabled;
  bool get taxManagementEnabled => _taxManagementEnabled;
  bool get currencyManagementEnabled => _currencyManagementEnabled;
  bool get stockManagementEnabled => _stockManagementEnabled;
  bool get employeeManagementEnabled => _employeeManagementEnabled;
  bool get suppliersEnabled => _suppliersEnabled;
  bool get customersEnabled => _customersEnabled;
  bool get categoriesEnabled => _categoriesEnabled;
  bool get pendingOrdersEnabled => _pendingOrdersEnabled;
  bool get customerAnalyticsEnabled => _customerAnalyticsEnabled;
  bool get inventoryAnalyticsEnabled => _inventoryAnalyticsEnabled;
  bool get isLoading => _isLoading;
  String? get loadError => _loadError;
  String get currencySymbol => _currencySymbol;
  String get currencyCode => _currencyCode;
  double get taxRate => _taxRate;

  String formatPrice(double amount) =>
      '${amount.toStringAsFixed(2)} $_currencySymbol';

  Future<void> loadSettings() async {
    _isLoading = true;
    _loadError = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        ApiService.get(ApiConfig.appSettingsEndpoint),
        ApiService.get(ApiConfig.currenciesEndpoint),
      ]);

      final settingsRes = results[0];
      if (settingsRes['success'] == true && settingsRes['data'] != null) {
        final data = settingsRes['data'];
        _loyaltyEnabled = data['feature_loyalty_program'] ?? false;
        _giftCardsEnabled = data['feature_gift_cards'] ?? false;
        _layawayEnabled = data['feature_layaway'] ?? false;
        _multiStoreEnabled = data['feature_multi_store'] ?? true;
        _paymentGatewayEnabled = data['feature_payment_gateway'] ?? true;
        _reportsEnabled = data['feature_reports'] ?? true;
        _auditTrailEnabled = data['feature_audit_trail'] ?? true;
        _backupRestoreEnabled = data['feature_backup_restore'] ?? true;
        _notificationsEnabled = data['feature_notifications'] ?? true;
        _permissionsEnabled = data['feature_permissions'] ?? true;
        _refundsEnabled = data['feature_refunds'] ?? true;
        _priceManagementEnabled = data['feature_price_management'] ?? true;
        _taxManagementEnabled = data['feature_tax_management'] ?? true;
        _currencyManagementEnabled = data['feature_currency_management'] ?? true;
        _stockManagementEnabled = data['feature_stock_management'] ?? true;
        _employeeManagementEnabled = data['feature_employee_management'] ?? true;
        _suppliersEnabled = data['feature_suppliers'] ?? true;
        _customersEnabled = data['feature_customers'] ?? true;
        _categoriesEnabled = data['feature_categories'] ?? true;
        _pendingOrdersEnabled = data['feature_pending_orders'] ?? true;
        _customerAnalyticsEnabled = data['feature_customer_analytics'] ?? true;
        _inventoryAnalyticsEnabled = data['feature_inventory_analytics'] ?? true;
      }

      final currenciesRes = results[1];
      if (currenciesRes['success'] == true && currenciesRes['data'] != null) {
        final currencies = currenciesRes['data'] as List;
        final base = currencies.firstWhere(
          (c) => c['is_base'] == 1 || c['is_base'] == true,
          orElse: () => null,
        );
        if (base != null) {
          _currencySymbol = base['symbol']?.toString() ?? '\$';
          _currencyCode = base['code']?.toString() ?? 'USD';
        }
      }

      // Load default tax rate
      final taxRes = await ApiService.get(ApiConfig.taxRatesEndpoint);
      if (taxRes['success'] == true && taxRes['data'] != null) {
        final taxes = taxRes['data'] as List;
        final defaultTax = taxes.firstWhere(
          (t) => t['is_default'] == 1 || t['is_default'] == true,
          orElse: () => null,
        );
        if (defaultTax != null) {
          _taxRate = (double.tryParse(defaultTax['rate'].toString()) ?? 10.0) / 100.0;
        }
      }
    } catch (e) {
      _loadError = 'Failed to load settings. Using defaults.';
      debugPrint('Error loading settings: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updateSettings({
    bool? loyaltyEnabled,
    bool? giftCardsEnabled,
    bool? layawayEnabled,
    bool? multiStoreEnabled,
    bool? paymentGatewayEnabled,
    bool? reportsEnabled,
    bool? auditTrailEnabled,
    bool? backupRestoreEnabled,
    bool? notificationsEnabled,
    bool? permissionsEnabled,
    bool? refundsEnabled,
    bool? priceManagementEnabled,
    bool? taxManagementEnabled,
    bool? currencyManagementEnabled,
    bool? stockManagementEnabled,
    bool? employeeManagementEnabled,
    bool? suppliersEnabled,
    bool? customersEnabled,
    bool? categoriesEnabled,
    bool? pendingOrdersEnabled,
    bool? customerAnalyticsEnabled,
    bool? inventoryAnalyticsEnabled,
  }) async {
    try {
      final updates = <String, bool>{};
      if (loyaltyEnabled != null) updates['feature_loyalty_program'] = loyaltyEnabled;
      if (giftCardsEnabled != null) updates['feature_gift_cards'] = giftCardsEnabled;
      if (layawayEnabled != null) updates['feature_layaway'] = layawayEnabled;
      if (multiStoreEnabled != null) updates['feature_multi_store'] = multiStoreEnabled;
      if (paymentGatewayEnabled != null) updates['feature_payment_gateway'] = paymentGatewayEnabled;
      if (reportsEnabled != null) updates['feature_reports'] = reportsEnabled;
      if (auditTrailEnabled != null) updates['feature_audit_trail'] = auditTrailEnabled;
      if (backupRestoreEnabled != null) updates['feature_backup_restore'] = backupRestoreEnabled;
      if (notificationsEnabled != null) updates['feature_notifications'] = notificationsEnabled;
      if (permissionsEnabled != null) updates['feature_permissions'] = permissionsEnabled;
      if (refundsEnabled != null) updates['feature_refunds'] = refundsEnabled;
      if (priceManagementEnabled != null) updates['feature_price_management'] = priceManagementEnabled;
      if (taxManagementEnabled != null) updates['feature_tax_management'] = taxManagementEnabled;
      if (currencyManagementEnabled != null) updates['feature_currency_management'] = currencyManagementEnabled;
      if (stockManagementEnabled != null) updates['feature_stock_management'] = stockManagementEnabled;
      if (employeeManagementEnabled != null) updates['feature_employee_management'] = employeeManagementEnabled;
      if (suppliersEnabled != null) updates['feature_suppliers'] = suppliersEnabled;
      if (customersEnabled != null) updates['feature_customers'] = customersEnabled;
      if (categoriesEnabled != null) updates['feature_categories'] = categoriesEnabled;
      if (pendingOrdersEnabled != null) updates['feature_pending_orders'] = pendingOrdersEnabled;
      if (customerAnalyticsEnabled != null) updates['feature_customer_analytics'] = customerAnalyticsEnabled;
      if (inventoryAnalyticsEnabled != null) updates['feature_inventory_analytics'] = inventoryAnalyticsEnabled;

      final response = await ApiService.put(ApiConfig.appSettingsEndpoint, updates);

      if (response['success'] == true) {
        if (loyaltyEnabled != null) _loyaltyEnabled = loyaltyEnabled;
        if (giftCardsEnabled != null) _giftCardsEnabled = giftCardsEnabled;
        if (layawayEnabled != null) _layawayEnabled = layawayEnabled;
        if (multiStoreEnabled != null) _multiStoreEnabled = multiStoreEnabled;
        if (paymentGatewayEnabled != null) _paymentGatewayEnabled = paymentGatewayEnabled;
        if (reportsEnabled != null) _reportsEnabled = reportsEnabled;
        if (auditTrailEnabled != null) _auditTrailEnabled = auditTrailEnabled;
        if (backupRestoreEnabled != null) _backupRestoreEnabled = backupRestoreEnabled;
        if (notificationsEnabled != null) _notificationsEnabled = notificationsEnabled;
        if (permissionsEnabled != null) _permissionsEnabled = permissionsEnabled;
        if (refundsEnabled != null) _refundsEnabled = refundsEnabled;
        if (priceManagementEnabled != null) _priceManagementEnabled = priceManagementEnabled;
        if (taxManagementEnabled != null) _taxManagementEnabled = taxManagementEnabled;
        if (currencyManagementEnabled != null) _currencyManagementEnabled = currencyManagementEnabled;
        if (stockManagementEnabled != null) _stockManagementEnabled = stockManagementEnabled;
        if (employeeManagementEnabled != null) _employeeManagementEnabled = employeeManagementEnabled;
        if (suppliersEnabled != null) _suppliersEnabled = suppliersEnabled;
        if (customersEnabled != null) _customersEnabled = customersEnabled;
        if (categoriesEnabled != null) _categoriesEnabled = categoriesEnabled;
        if (pendingOrdersEnabled != null) _pendingOrdersEnabled = pendingOrdersEnabled;
        if (customerAnalyticsEnabled != null) _customerAnalyticsEnabled = customerAnalyticsEnabled;
        if (inventoryAnalyticsEnabled != null) _inventoryAnalyticsEnabled = inventoryAnalyticsEnabled;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating settings: $e');
      return false;
    }
  }
}
