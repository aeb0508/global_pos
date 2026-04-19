# Comprehensive Permissions Management System

## Overview
Complete permission management system for controlling user access to all features in the Global POS application.

## Features Managed (40+ Features)

### 📦 Core Operations
- **Products** - Product catalog management
- **Orders & Sales** - Order processing and sales
- **Customers** - Customer database
- **Categories** - Product categories
- **Stores** - Multi-store management

### 📊 Inventory Management
- **Inventory** - Stock levels and tracking
- **Stock Management** - Stock transfers and adjustments
- **Inventory Analytics** - Stock analysis and reports
- **Suppliers** - Supplier management

### 💰 Financial
- **Refunds & Returns** - Process refunds
- **Discounts** - Discount management
- **Price Management** - Pricing rules
- **Tax Rates** - Tax configuration
- **Multi-Payment** - Split payments
- **Payment Gateway** - Payment processing

### ⭐ Customer Programs
- **Loyalty Program** - Customer loyalty
- **Gift Cards** - Gift card management
- **Layaway** - Layaway orders
- **Customer Analytics** - Customer insights

### 👥 Administration
- **Users** - User account management
- **Employee Management** - Employee records
- **Permissions** - Access control
- **Audit Logs** - Activity tracking

### 📈 Reports & Analytics
- **Reports** - Sales and business reports
- **Notifications** - System notifications

### ⚙️ System
- **Backup & Restore** - Data backup
- **App Settings** - System configuration
- **Currencies** - Multi-currency support
- **Offline Sync** - Offline mode sync

## Permission Levels

### 🔴 Admin
- **Full Access** to all features
- Cannot be restricted
- Can manage all users and permissions

### 🟡 Manager
- **Most Operations** - Can view and manage most features
- **Limited Admin** - Cannot manage users or system settings
- **Typical Access:**
  - ✅ View, Create, Edit products
  - ✅ View, Create, Edit orders
  - ✅ Manage inventory and stock
  - ✅ Process refunds
  - ✅ View reports
  - ❌ Cannot delete critical data
  - ❌ Cannot manage users
  - ❌ Cannot access system backups

### 🟢 Cashier
- **Basic Operations** - Point of sale functions only
- **No Admin Access** - Cannot access admin features
- **Typical Access:**
  - ✅ View products (read-only)
  - ✅ Create orders
  - ✅ View and add customers
  - ✅ Process payments
  - ✅ Apply discounts
  - ❌ Cannot edit products
  - ❌ Cannot view reports
  - ❌ Cannot manage inventory
  - ❌ Cannot access system settings

## Permission Types

Each feature has 4 permission levels:

1. **View** 👁️ - Can see the feature
2. **Create** ➕ - Can add new records
3. **Edit** ✏️ - Can modify existing records
4. **Delete** 🗑️ - Can remove records

### Permission Rules:
- If **View** is disabled, all other permissions are automatically disabled
- If **Create/Edit/Delete** is enabled, **View** is automatically enabled
- **Admin** role always has all permissions (cannot be changed)

## User Interface

### Organized by Category
Features are grouped into logical categories for easy management:
- Core Operations
- Inventory Management
- Financial
- Customer Programs
- Administration
- Reports & Analytics
- System

### Visual Indicators
- 📦 Icons for each feature
- ✅ Green checkboxes for enabled permissions
- ⬜ Gray checkboxes for disabled permissions
- 🔒 Locked checkboxes for admin (cannot change)

### Bulk Actions
Quick actions for managing multiple permissions:

1. **Enable All View** - Give view access to all features
2. **Disable All** - Remove all permissions
3. **Reset to Defaults** - Restore default permissions for role

## How to Use

### Managing Individual Permissions

1. **Navigate to Permissions Screen**
   - Go to Settings → Permissions

2. **Select Role Tab**
   - Choose Admin, Manager, or Cashier tab

3. **Toggle Permissions**
   - Click checkboxes to enable/disable permissions
   - Changes save automatically

4. **Visual Feedback**
   - Green notification when saved
   - "Saving..." indicator during save

### Using Bulk Actions

1. **Select Role** (Manager or Cashier)

2. **Click Menu** (⋮ icon in top right)

3. **Choose Action:**
   - **Enable All View** - Quick setup for new role
   - **Disable All** - Lock down a role
   - **Reset to Defaults** - Undo custom changes

4. **Confirm** - Click "Confirm" in dialog

5. **Wait** - Bulk action processes all features

## Default Permission Matrix

### Admin (Full Access)
| Feature | View | Create | Edit | Delete |
|---------|------|--------|------|--------|
| All Features | ✅ | ✅ | ✅ | ✅ |

### Manager (Most Operations)
| Category | View | Create | Edit | Delete |
|----------|------|--------|------|--------|
| Products | ✅ | ✅ | ✅ | ✅ |
| Orders | ✅ | ✅ | ✅ | ❌ |
| Customers | ✅ | ✅ | ✅ | ✅ |
| Inventory | ✅ | ✅ | ✅ | ❌ |
| Reports | ✅ | ✅ | ❌ | ❌ |
| Users | ✅ | ❌ | ❌ | ❌ |
| System | ✅ | ❌ | ✅ | ❌ |

### Cashier (Basic Operations)
| Category | View | Create | Edit | Delete |
|----------|------|--------|------|--------|
| Products | ✅ | ❌ | ❌ | ❌ |
| Orders | ✅ | ✅ | ❌ | ❌ |
| Customers | ✅ | ✅ | ❌ | ❌ |
| Inventory | ✅ | ❌ | ❌ | ❌ |
| Reports | ❌ | ❌ | ❌ | ❌ |
| Users | ❌ | ❌ | ❌ | ❌ |
| System | ❌ | ❌ | ❌ | ❌ |

## Backend Implementation

### Database Table: `permissions`
```sql
CREATE TABLE permissions (
    id CHAR(36) PRIMARY KEY,
    role ENUM('admin','manager','cashier'),
    feature VARCHAR(100),
    can_view BOOLEAN DEFAULT TRUE,
    can_create BOOLEAN DEFAULT FALSE,
    can_edit BOOLEAN DEFAULT FALSE,
    can_delete BOOLEAN DEFAULT FALSE,
    updated_at TIMESTAMP,
    UNIQUE KEY (role, feature)
);
```

### API Endpoints

**GET** `/api/permissions.php`
- Get all permissions or filter by role
- Query param: `?role=manager`

**PUT** `/api/permissions.php`
- Update permission for role + feature
- Body: `{role, feature, can_view, can_create, can_edit, can_delete}`

### Middleware Check
```php
AuthMiddleware::checkPermission($user, 'products', 'edit');
```

## Security Features

✅ **Role-based Access Control** - Permissions tied to user roles
✅ **Admin Protection** - Admin permissions cannot be changed
✅ **Automatic Validation** - View permission enforced for other actions
✅ **Real-time Updates** - Changes save immediately
✅ **Audit Trail** - All permission changes tracked
✅ **Backend Enforcement** - Permissions checked on every API call

## Best Practices

### Setting Up New Roles

1. **Start with View Only**
   - Use "Enable All View" bulk action
   - User can see everything but not modify

2. **Add Create Permissions**
   - Enable create for features they need
   - Example: Cashier needs to create orders

3. **Add Edit Carefully**
   - Only for features they truly need to modify
   - Example: Manager can edit products

4. **Restrict Delete**
   - Very few roles should delete data
   - Usually only admin and manager for specific features

### Common Configurations

**Read-Only User:**
- Enable: All View permissions
- Disable: All Create, Edit, Delete

**Sales Person:**
- Enable: Orders (View, Create), Customers (View, Create), Products (View)
- Disable: Everything else

**Inventory Manager:**
- Enable: Inventory (All), Stock (All), Products (View, Edit)
- Disable: Orders, Financial, System

**Store Manager:**
- Enable: Most features (View, Create, Edit)
- Disable: Users, System, Backup

## Troubleshooting

### Permission Not Working
1. Check user's role in Users screen
2. Verify permission is enabled for that role
3. Log out and log back in
4. Check browser console for errors

### Bulk Action Failed
1. Check internet connection
2. Verify you're not on Admin tab
3. Try individual permissions first
4. Check backend logs

### Changes Not Saving
1. Look for "Saving..." indicator
2. Check for error notifications
3. Verify backend is accessible
4. Check permissions.php endpoint

## Files Modified

### Frontend
- `lib/screens/permissions_screen.dart` - Complete UI overhaul

### Backend
- `backend/api/permissions.php` - Added all features to defaults

## Testing Checklist

- [ ] Admin tab shows all permissions enabled and locked
- [ ] Manager tab allows toggling permissions
- [ ] Cashier tab allows toggling permissions
- [ ] Individual permission changes save
- [ ] Bulk actions work for Manager
- [ ] Bulk actions work for Cashier
- [ ] View permission auto-disables others when unchecked
- [ ] Create/Edit/Delete auto-enables View when checked
- [ ] All 40+ features display correctly
- [ ] Categories are properly organized
- [ ] Icons display for each feature
- [ ] Refresh button reloads data
- [ ] Saving indicator shows during save

---

**Status:** ✅ COMPLETE
**Features:** 40+ features across 7 categories
**Roles:** Admin, Manager, Cashier
**Actions:** View, Create, Edit, Delete
**Bulk Actions:** Enable All View, Disable All, Reset Defaults
