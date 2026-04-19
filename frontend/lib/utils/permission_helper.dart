import '../services/api_service.dart';
import '../utils/api_config.dart';

class PermissionHelper {
  static Map<String, Map<String, bool>>? _cachedPermissions;
  static String? _cachedRole;

  // Feature key mapping to screen indices
  static const Map<String, int> _featureToIndex = {
    'pos': 1,
    'products': 2,
    'orders': 3,
    'pending_orders': 4,
    'customers': 5,
    'suppliers': 6,
    'inventory_analytics': 7,
    'customer_analytics': 8,
    'stock_management': 9,
    'employee_management': 10,
    'reports': 11,
    'refunds': 12,
    'loyalty_program': 13,
    'gift_cards': 14,
    'prices': 15,
    'tax': 16,
    'notifications': 17,
    'audit': 18,
    'backup': 19,
    'users': 20,
    'permissions': 24,
    'stores': 25,
    'payment_gateway': 26,
    'categories': 27,
    'currencies': 22,
    'layaway': 23,
  };

  // Load permissions for a user role (force reload option)
  static Future<void> loadPermissions(String role, {bool forceReload = false}) async {
    if (!forceReload && _cachedRole == role && _cachedPermissions != null) {
      return; // Already loaded
    }

    try {
      final response = await ApiService.get(
        '${ApiConfig.permissionsEndpoint}?role=$role',
      );

      if (response['success'] == true) {
        final permissions = <String, Map<String, bool>>{};
        final data = response['data'] as List;

        for (var perm in data) {
          final feature = perm['feature'] as String;
          permissions[feature] = {
            'can_view': perm['can_view'] == true || perm['can_view'] == 1,
            'can_create': perm['can_create'] == true || perm['can_create'] == 1,
            'can_edit': perm['can_edit'] == true || perm['can_edit'] == 1,
            'can_delete': perm['can_delete'] == true || perm['can_delete'] == 1,
          };
        }

        _cachedPermissions = permissions;
        _cachedRole = role;
      }
    } catch (e) {
      // If loading fails, assume no permissions
      _cachedPermissions = {};
      _cachedRole = role;
    }
  }

  // Clear cached permissions (call on logout)
  static void clearCache() {
    _cachedPermissions = null;
    _cachedRole = null;
  }

  // Check if user can view a feature
  static bool canView(String feature, String? role) {
    if (role == 'admin') return true; // Admin can see everything
    if (_cachedPermissions == null) return false;

    final perm = _cachedPermissions![feature];
    return perm?['can_view'] ?? false;
  }

  // Check if user can create in a feature
  static bool canCreate(String feature, String? role) {
    if (role == 'admin') return true;
    if (_cachedPermissions == null) return false;

    final perm = _cachedPermissions![feature];
    return perm?['can_create'] ?? false;
  }

  // Check if user can edit in a feature
  static bool canEdit(String feature, String? role) {
    if (role == 'admin') return true;
    if (_cachedPermissions == null) return false;

    final perm = _cachedPermissions![feature];
    return perm?['can_edit'] ?? false;
  }

  // Check if user can delete in a feature
  static bool canDelete(String feature, String? role) {
    if (role == 'admin') return true;
    if (_cachedPermissions == null) return false;

    final perm = _cachedPermissions![feature];
    return perm?['can_delete'] ?? false;
  }

  // Check if a screen index should be visible
  static bool isScreenVisible(int screenIndex, String? role) {
    if (role == 'admin') return true; // Admin sees everything

    // Dashboard is always visible
    if (screenIndex == 0) return true;
    
    // Settings requires app_settings permission
    if (screenIndex == 21) {
      return canView('app_settings', role);
    }

    // Find feature key for this screen index
    String? featureKey;
    for (var entry in _featureToIndex.entries) {
      if (entry.value == screenIndex) {
        featureKey = entry.key;
        break;
      }
    }

    if (featureKey == null) return true; // Unknown screen, show it

    return canView(featureKey, role);
  }

  // Get list of visible screen indices for a role
  static List<int> getVisibleScreens(String? role) {
    if (role == 'admin') {
      // Admin sees all screens
      return List.generate(28, (index) => index);
    }

    final visible = <int>[0, 21]; // Dashboard and Settings always visible

    for (var entry in _featureToIndex.entries) {
      if (canView(entry.key, role)) {
        visible.add(entry.value);
      }
    }

    return visible;
  }
}
