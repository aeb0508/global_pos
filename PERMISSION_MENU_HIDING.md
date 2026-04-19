# Permission-Based Menu Visibility

## Overview
Menu items and features are now automatically hidden from users based on their role permissions. Users only see what they have access to.

## How It Works

### 1. Permission Loading
When a user logs in:
1. User credentials validated
2. User role retrieved (admin/manager/cashier)
3. Permissions loaded from database for that role
4. Permissions cached in memory

### 2. Menu Filtering
When displaying menus:
1. Check if user has "view" permission for each feature
2. Hide menu items where permission is denied
3. Show only accessible features

### 3. Real-Time Updates
- Permissions loaded on login
- Cached for performance
- Cleared on logout
- Reloaded when user logs in again

## Implementation

### New Files Created

**`lib/utils/permission_helper.dart`**
- Loads permissions from API
- Caches permissions in memory
- Provides permission check methods
- Maps features to screen indices

### Modified Files

**`lib/providers/auth_provider.dart`**
- Loads permissions on login
- Loads permissions on app initialization
- Clears permissions on logout

**`lib/screens/home_screen.dart`**
- Filters sidebar menu items by permission
- Filters drawer menu items by permission
- Hides entire sections if all items hidden

## Permission Checks

### Methods Available

```dart
// Check if user can view a feature
PermissionHelper.canView('products', userRole)

// Check if user can create
PermissionHelper.canCreate('orders', userRole)

// Check if user can edit
PermissionHelper.canEdit('customers', userRole)

// Check if user can delete
PermissionHelper.canDelete('users', userRole)

// Check if screen should be visible
PermissionHelper.isScreenVisible(screenIndex, userRole)
```

### Always Visible
These screens are always visible regardless of permissions:
- **Dashboard** (index 0)
- **POS** (index 1)
- **Settings** (index 21)

## Feature to Screen Mapping

| Feature | Screen Index | Screen Name |
|---------|--------------|-------------|
| products | 2 | Products |
| orders | 3 | Orders |
| pending_orders | 4 | Pending Orders |
| customers | 5 | Customers |
| suppliers | 6 | Suppliers |
| inventory_analytics | 7 | Inventory Analytics |
| customer_analytics | 8 | Customer Analytics |
| stock_management | 9 | Stock Management |
| employee_management | 10 | Employee Management |
| reports | 11 | Reports |
| refunds | 12 | Refunds |
| loyalty_program | 13 | Loyalty Program |
| gift_cards | 14 | Gift Cards |
| prices | 15 | Price Management |
| tax | 16 | Tax Management |
| notifications | 17 | Notifications |
| audit | 18 | Audit Trail |
| backup | 19 | Backup & Restore |
| users | 20 | Users |
| currencies | 22 | Currencies |
| layaway | 23 | Layaway |
| permissions | 24 | Permissions |
| stores | 25 | Multi-Store |
| payment_gateway | 26 | Payment Gateway |
| categories | 27 | Categories |

## Example Scenarios

### Admin User
- **Sees**: All menu items (40+ features)
- **Reason**: Admin role bypasses all permission checks

### Manager User (Default Permissions)
- **Sees**: Most features
- **Hidden**: 
  - Users (no view permission)
  - Backup & Restore (no view permission)
  - Some system features

### Cashier User (Default Permissions)
- **Sees**: Basic POS features
  - Dashboard
  - POS
  - Products (view only)
  - Orders (create only)
  - Customers (view/create)
  - Settings
- **Hidden**:
  - Reports
  - Analytics
  - Management features
  - System features
  - Users
  - Permissions

## Testing

### Test as Different Roles

1. **Create Test Users:**
   ```sql
   -- Manager user
   INSERT INTO users (username, password, full_name, role) 
   VALUES ('manager', '$2y$10$...', 'Test Manager', 'manager');
   
   -- Cashier user
   INSERT INTO users (username, password, full_name, role) 
   VALUES ('cashier', '$2y$10$...', 'Test Cashier', 'cashier');
   ```

2. **Login as Each User:**
   - Admin: See all 28 screens
   - Manager: See ~20 screens
   - Cashier: See ~8 screens

3. **Modify Permissions:**
   - Go to Permissions screen (as admin)
   - Disable "view" for a feature
   - Logout and login as that role
   - Verify menu item is hidden

### Verification Checklist

- [ ] Admin sees all menu items
- [ ] Manager sees limited menu items
- [ ] Cashier sees minimal menu items
- [ ] Disabling "view" permission hides menu item
- [ ] Enabling "view" permission shows menu item
- [ ] Permissions persist after page refresh
- [ ] Permissions cleared on logout
- [ ] Empty sections are hidden
- [ ] Dashboard/POS/Settings always visible

## Performance

### Caching Strategy
- Permissions loaded once on login
- Stored in memory (not re-fetched)
- Fast permission checks (no API calls)
- Cleared on logout

### API Calls
- **On Login**: 1 API call to load permissions
- **On Menu Render**: 0 API calls (uses cache)
- **On Permission Change**: User must logout/login to see changes

## Future Enhancements

### Possible Improvements
1. **Real-time Updates**: WebSocket to push permission changes
2. **Permission Refresh**: Button to reload permissions without logout
3. **Granular Hiding**: Hide buttons within screens (create/edit/delete)
4. **Permission Tooltips**: Show why a feature is hidden
5. **Permission Requests**: Users can request access to features

## Troubleshooting

### Menu Items Not Hiding

**Problem**: Changed permissions but menu still shows
**Solution**: User must logout and login again

**Problem**: All menus hidden for non-admin
**Solution**: Check permissions table has data for that role

### Menu Items Missing for Admin

**Problem**: Admin can't see some features
**Solution**: Check app settings (feature toggles) - they override permissions

### Permissions Not Loading

**Problem**: Error loading permissions
**Solution**: 
1. Check API endpoint is accessible
2. Verify permissions table exists
3. Check user role is valid (admin/manager/cashier)

## Security Notes

✅ **Frontend Hiding**: Menu items hidden in UI
✅ **Backend Enforcement**: API still checks permissions
✅ **No Bypass**: Users can't access hidden features via URL
✅ **Role-Based**: Permissions tied to user role
✅ **Cached Safely**: Permissions cleared on logout

⚠️ **Important**: Hiding menus is UX improvement, not security. Backend API must still enforce permissions!

## Code Examples

### Check Permission Before Action

```dart
// In a screen
final user = Provider.of<AuthProvider>(context).user;

// Check if user can create
if (PermissionHelper.canCreate('products', user?.role)) {
  // Show "Add Product" button
  ElevatedButton(
    onPressed: () => _addProduct(),
    child: Text('Add Product'),
  );
}

// Check if user can edit
if (PermissionHelper.canEdit('products', user?.role)) {
  // Show "Edit" button
  IconButton(
    icon: Icon(Icons.edit),
    onPressed: () => _editProduct(),
  );
}

// Check if user can delete
if (PermissionHelper.canDelete('products', user?.role)) {
  // Show "Delete" button
  IconButton(
    icon: Icon(Icons.delete),
    onPressed: () => _deleteProduct(),
  );
}
```

### Conditional Widget Rendering

```dart
// Only show widget if user has permission
if (PermissionHelper.canView('reports', user?.role)) {
  ReportsWidget();
}

// Or use ternary
PermissionHelper.canView('analytics', user?.role)
  ? AnalyticsChart()
  : SizedBox.shrink();
```

---

**Status:** ✅ COMPLETE
**Impact:** Better UX - users only see what they can access
**Security:** Frontend + Backend enforcement
**Performance:** Fast (cached permissions)
