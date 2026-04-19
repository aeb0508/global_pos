# SnackBar Standardization Guide

## Overview
All SnackBars in the app now use the POS screen style for consistency.

## Import
```dart
import '../utils/snackbar_helper.dart';
```

## Usage

### Success Messages (Green)
```dart
SnackBarHelper.showSuccess(context, 'Product added successfully');
```

### Error Messages (Red, 2 seconds)
```dart
SnackBarHelper.showError(context, 'Failed to save product');
```

### Warning Messages (Orange, 2 seconds)
```dart
SnackBarHelper.showWarning(context, 'Low stock warning');
```

### Info Messages (Blue, 1 second)
```dart
SnackBarHelper.showInfo(context, 'Order loaded for editing');
```

### Custom Messages
```dart
SnackBarHelper.show(
  context,
  'Custom message',
  backgroundColor: Colors.purple,
  duration: Duration(seconds: 3),
  icon: Icons.star,
);
```

## Style Properties
All SnackBars use:
- **behavior**: SnackBarBehavior.floating
- **margin**: EdgeInsets.only(bottom: 16, left: 16, right: 400)
- **padding**: EdgeInsets.symmetric(horizontal: 12, vertical: 10)
- **fontSize**: 12
- **duration**: 500ms (default), 1-2s for warnings/errors

## Migration Pattern

### Before:
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Product added'),
    backgroundColor: Colors.green,
  ),
);
```

### After:
```dart
SnackBarHelper.showSuccess(context, 'Product added');
```

## Files Updated
- ✅ categories_screen.dart
- ✅ customers_screen.dart
- ✅ products_screen.dart
- ✅ pos_screen.dart (already using this style)

## Remaining Files to Update
Run this command to find all remaining SnackBar usages:
```bash
findstr /S /I /N "ScaffoldMessenger" *.dart
```

Then replace with appropriate SnackBarHelper methods.
