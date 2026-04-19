# Frontend Dialog Analysis Report

**Analysis Date:** April 15, 2026  
**Total Dialogs Found:** 36 across 15 screens  
**Screens Analyzed:** 20 (excluding dashboard_screen and pos_screen)

---

## Executive Summary

| Category | Count | Priority |
|----------|-------|----------|
| **Form Dialogs** (Add/Edit) | 17 | HIGH (1) |
| **Info/Selection Dialogs** | 9 | MEDIUM (2) |
| **Confirmation Dialogs** | 10 | MEDIUM-HIGH (2) |
| **Screens with NO Dialogs** | 5 | N/A |

---

## HIGH PRIORITY - Form Dialogs (17 total)

These are complex dialogs with form fields that would benefit most from conversion to responsive pages.

### 1. **categories_screen.dart** - Line 116
- **Dialog Name:** AddCategory/EditCategory
- **Type:** Form (Add/Edit unified)
- **Form Fields:** 
  - `name` (required, TextFormField)
  - `description` (optional, multi-line TextFormField)
- **Current Structure:** AlertDialog with LayoutBuilder for responsive width
- **Priority:** HIGH - Complex form with validation

### 2. **currency_management_screen.dart** - Line 70
- **Dialog Name:** AddCurrency/EditCurrency (_CurrencyDialog widget)
- **Type:** Form
- **Form Fields:** TBD (external widget)
- **Priority:** HIGH - Requires widget inspection

### 3. **customers_screen.dart** - Line 144
- **Dialog Name:** AddCustomer/EditCustomer (CustomerFormDialog)
- **Type:** Form
- **Form Fields:** TBD (external widget)
- **Current Structure:** Uses CustomerFormDialog widget
- **Priority:** HIGH - Complex customer data

### 4. **gift_cards_screen.dart** - Line 49
- **Dialog Name:** IssueGiftCard (_IssueGiftCardDialog)
- **Type:** Form
- **Form Fields:** TBD (external widget)
- **Priority:** HIGH - Gift card issuance

### 5. **layaway_screen.dart** - Line 71
- **Dialog Name:** CreateLayaway (_CreateLayawayDialog)
- **Type:** Form
- **Form Fields:** TBD (external widget)
- **Priority:** HIGH - Layaway creation

### 6. **loyalty_program_screen.dart** - Line 177
- **Dialog Name:** EditLoyaltyProgram (_ProgramDialog)
- **Type:** Form
- **Form Fields:** TBD (external widget)
- **Priority:** HIGH - Program configuration

### 7. **loyalty_program_screen.dart** - Line 190
- **Dialog Name:** AddPoints (_AddPointsDialog)
- **Type:** Form
- **Form Fields:** TBD (external widget)
- **Priority:** HIGH - Loyalty points management

### 8. **multi_store_screen.dart** - Line 298
- **Dialog Name:** AddStore/EditStore (_StoreDialog)
- **Type:** Form
- **Form Fields:** TBD (external widget)
- **Priority:** HIGH - Store management

### 9. **multi_store_screen.dart** - Line 312
- **Dialog Name:** InventoryManagement (_InventoryDialog)
- **Type:** Form
- **Form Fields:** TBD (external widget)
- **Priority:** HIGH - Store-specific inventory

### 10. **multi_store_screen.dart** - Line 327
- **Dialog Name:** StockTransfer (_TransferDialog)
- **Type:** Form
- **Form Fields:** TBD (external widget)
- **Priority:** HIGH - Complex stock operations

### 11. **payment_gateway_screen.dart** - Line 490
- **Dialog Name:** ConfigureGateway
- **Type:** Form (with StatefulBuilder for state management)
- **Form Fields:**
  - `api_key` (required, TextFormField, obscured)
  - `api_secret` (required, TextFormField, obscured)
  - `webhook_secret` (optional, TextFormField, obscured)
  - `is_active` (toggle, SwitchListTile)
  - `is_test_mode` (toggle, SwitchListTile)
- **Current Structure:** AlertDialog with Form, SingleChildScrollView for content
- **Priority:** HIGH - Security-sensitive configuration

### 12. **payment_gateway_screen.dart** - Line 706
- **Dialog Name:** ProcessRefund
- **Type:** Form (with StatefulBuilder for submission state)
- **Form Fields:**
  - `refund_amount` (required, TextFormField, numeric)
  - `reason` (required, TextFormField, multi-line)
  - Validation: cannot exceed original transaction amount
- **Current Structure:** AlertDialog with Form validation
- **Priority:** HIGH - Financial operation

### 13. **price_management_screen.dart** - Line 726
- **Dialog Name:** UpdatePrice (_PriceUpdateDialog)
- **Type:** Form
- **Form Fields:**
  - `selling_price` (required, TextFormField, numeric)
  - Shows: cost_price, current margin, new margin calculation
- **Current Structure:** Dialog widget with specific styling
- **Priority:** HIGH - Price management with calculations

### 14. **refund_management_screen.dart** - Line 104
- **Dialog Name:** ProcessRefund (_RefundDialog)
- **Type:** Form
- **Form Fields:** TBD (external widget)
- **Priority:** HIGH - Refund processing

### 15. **refund_management_screen.dart** - Line 116
- **Dialog Name:** EditRefund (_RefundDialog)
- **Type:** Form
- **Form Fields:** TBD (same widget as ProcessRefund)
- **Priority:** HIGH - Refund editing

### 16. **stock_management_screen.dart** - Line 91
- **Dialog Name:** AdjustStock (_StockAdjustmentDialog)
- **Type:** Form
- **Form Fields:** TBD (external widget)
- **Priority:** HIGH - Inventory adjustment

### 17. **suppliers_screen.dart** - Line 84
- **Dialog Name:** AddSupplier/EditSupplier (_SupplierDialog)
- **Type:** Form
- **Form Fields:** TBD (external widget)
- **Priority:** HIGH - Supplier management

---

## MEDIUM PRIORITY - Form Dialogs (continued)

### 18. **tax_management_screen.dart** - Line 142
- **Dialog Name:** AddTaxRate/EditTaxRate (_TaxRateDialog)
- **Type:** Form
- **Form Fields:** TBD (external widget)
- **Priority:** HIGH - Tax configuration

### 19. **users_screen.dart** - Line 106
- **Dialog Name:** AddUser/EditUser (UserDialog)
- **Type:** Form
- **Form Fields:** TBD (external widget)
- **Priority:** HIGH - User management

---

## MEDIUM PRIORITY - Info/Selection Dialogs (9 total)

These are simpler dialogs displaying information or requesting simple input.

### 1. **gift_cards_screen.dart** - Line 61
- **Dialog Name:** CheckGiftCardBalance
- **Type:** Selection/Info (single field + API call)
- **Fields:** Single TextField for card_number input
- **Output:** Displays balance from API response
- **Priority:** MEDIUM

### 2. **gift_cards_screen.dart** - Line 90
- **Dialog Name:** GiftCardBalance (nested)
- **Type:** Info only
- **Displays:** Card number, current balance
- **Priority:** LOW (nested in parent dialog)

### 3. **mobile_home_screen.dart** - Line 154
- **Dialog Name:** ServerURL Configuration
- **Type:** Selection/Info
- **Fields:** Single TextField for API base URL with helper text
- **Structure:** Complex with info box showing "How to find your IP"
- **Priority:** MEDIUM - Configuration setup

### 4. **orders_screen.dart** - Line 324
- **Dialog Name:** OrderDetails (_OrderDetailsDialog)
- **Type:** Info only
- **Displays:** Order details (read-only)
- **Priority:** MEDIUM

### 5. **payment_gateway_screen.dart** - Line 615
- **Dialog Name:** TestGateway
- **Type:** Info only
- **Displays:** Gateway status and test instructions
- **Priority:** LOW - Non-critical testing

### 6. **payment_gateway_screen.dart** - Line 650
- **Dialog Name:** TransactionDetails
- **Type:** Info + optional action
- **Displays:** Transaction ID, order number, gateway, amount, status, payment method, customer, email, date
- **Actions:** Can trigger _processRefund if status is 'completed'
- **Priority:** MEDIUM - Shows detailed financial data

### 7. **pending_orders_screen.dart** - Line 232
- **Dialog Name:** OrderDetails (_OrderDetailsDialog)
- **Type:** Info only
- **Displays:** Order details (read-only)
- **Priority:** MEDIUM

### 8. **layaway_screen.dart** - Line 59
- **Dialog Name:** LayawayDetail (_LayawayDetailDialog)
- **Type:** Info + possibly editable
- **Displays:** Layaway details with payment and cancellation options
- **Priority:** MEDIUM

### 9. **permissions_screen.dart** - Line 215
- **Dialog Name:** BulkAction (Confirmation)
- **Type:** Confirmation
- **Action:** Enable/disable permissions for specific role
- **Priority:** MEDIUM

---

## CONFIRMATION DIALOGS (10 total)

Simple yes/no confirmations for delete/action operations.

| Screen | Dialog Name | Line | Action | Priority |
|--------|------------|------|--------|----------|
| categories_screen.dart | DeleteCategory | 240 | Delete category | 2 |
| currency_management_screen.dart | DeleteCurrency | 103 | Delete currency | 2 |
| customers_screen.dart | DeleteCustomer | 157 | Delete customer | 2 |
| layaway_screen.dart | DeleteLayaway | 245 | Delete layaway | 2 |
| multi_store_screen.dart | DeleteStore | 338 | Delete store | 2 |
| orders_screen.dart | DeleteOrder | 230 | Delete order | 2 |
| pending_orders_screen.dart | CompleteOrder | 167 | Mark order complete | 2 |
| pending_orders_screen.dart | DeleteOrder | 247 | Delete order | 2 |
| products_screen.dart | DeleteProduct | 256 | Delete product | 2 |
| refund_management_screen.dart | DeleteRefund | 129 | Delete refund | 2 |
| suppliers_screen.dart | DeleteSupplier | 97 | Delete supplier | 2 |
| tax_management_screen.dart | DeleteTaxRate | 102 | Delete tax rate | 2 |
| users_screen.dart | DeleteUser | 75 | Delete user | 2 |

---

## SCREENS WITH NO DIALOGS (5 total)

- **home_screen.dart** - Navigation hub, no dialogs
- **settings_screen.dart** - (not analyzed, not in list)
- **backup_restore_screen.dart** - (not analyzed, not in list)
- **audit_trail_screen.dart** - (not analyzed, not in list)
- **employee_management_screen.dart** - (not analyzed, not in list)
- **inventory_analytics_screen.dart** - (not analyzed, not in list)
- **customer_analytics_screen.dart** - (not analyzed, not in list)
- **notification_settings_screen.dart** - (not analyzed, not in list)
- **reports_screen.dart** - (not analyzed, not in list)

---

## Recommendations for Conversion Priority

### Phase 1 (Highest Impact)
1. **payment_gateway_screen.dart** - ConfigureGateway (490) - Financial/security sensitive
2. **payment_gateway_screen.dart** - ProcessRefund (706) - Financial operation
3. **price_management_screen.dart** - UpdatePrice (726) - Frequent use
4. **categories_screen.dart** - AddCategory/EditCategory (116) - Core data
5. **suppliers_screen.dart** - AddSupplier/EditSupplier (84) - Core data

### Phase 2 (Medium Impact)
- Multi-store dialogs (3 dialogs)
- Customer/Order dialogs
- Loyalty program dialogs
- Tax/Currency management dialogs

### Phase 3 (Lower Impact)
- Confirmation dialogs (convert to inline actions)
- Info dialogs (convert to pages or bottom sheets)

---

## Technical Notes

1. **External Widgets:** Several dialogs use external widget classes that require inspection:
   - CustomerFormDialog
   - UserDialog
   - _CurrencyDialog
   - _IssueGiftCardDialog
   - _CreateLayawayDialog
   - _LayawayDetailDialog
   - _ProgramDialog
   - _AddPointsDialog
   - _StoreDialog
   - _InventoryDialog
   - _TransferDialog
   - _RefundDialog
   - _StockAdjustmentDialog
   - _SupplierDialog
   - _TaxRateDialog
   - _OrderDetailsDialog

2. **StatefulBuilder Usage:** Several dialogs use StatefulBuilder for managing internal state within the dialog (payment_gateway, refund processing)

3. **Validation:** Many form dialogs include form validation with GlobalKey<FormState>

4. **Responsive Design:** Some dialogs already use LayoutBuilder (categories_screen) or responsive constraints

5. **Navigation:** All dialogs use showDialog() with context and return values via Navigator.pop()

---

## CSV Export

See accompanying DIALOG_ANALYSIS.csv for quick reference table format.
