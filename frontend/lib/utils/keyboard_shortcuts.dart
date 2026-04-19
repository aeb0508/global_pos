import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class KeyboardShortcuts {
  static const Map<String, String> shortcuts = {
    'F1': 'Help',
    'F2': 'New Sale (POS)',
    'F3': 'Products',
    'F4': 'Orders',
    'F5': 'Refresh',
    'F6': 'Customers',
    'F7': 'Reports',
    'F8': 'Settings',
    'F9': 'Inventory',
    'F10': 'Dashboard',
    'F11': 'Suppliers',
    'F12': 'Backup',
    'Ctrl+S': 'Save',
    'Ctrl+N': 'New',
    'Ctrl+F': 'Search',
    'Ctrl+P': 'Print',
    'Ctrl+E': 'Export',
    'Ctrl+Q': 'Quick Actions',
    'Ctrl+Shift+N': 'New Customer',
    'Ctrl+Shift+P': 'New Product',
    'Alt+1-9': 'Quick Navigation',
    'Esc': 'Cancel/Close',
  };

  static KeyEventResult handleKeyPress(
    KeyEvent event,
    BuildContext context,
    Function(int) onNavigate,
  ) {
    if (event is KeyDownEvent) {
      // F1 - Help (safe on all platforms)
      if (event.logicalKey == LogicalKeyboardKey.f1) {
        _showHelpDialog(context);
        return KeyEventResult.handled;
      }

      // F2 - POS
      if (event.logicalKey == LogicalKeyboardKey.f2) {
        onNavigate(1);
        return KeyEventResult.handled;
      }

      // F3 - Products
      if (event.logicalKey == LogicalKeyboardKey.f3) {
        onNavigate(2);
        return KeyEventResult.handled;
      }

      // F4 - Orders
      if (event.logicalKey == LogicalKeyboardKey.f4) {
        onNavigate(3);
        return KeyEventResult.handled;
      }

      // F5 - Refresh: browser intercepts on web, skip
      // F6 - Customers (safe)
      if (event.logicalKey == LogicalKeyboardKey.f6) {
        onNavigate(5);
        return KeyEventResult.handled;
      }

      // F7 - Reports
      if (event.logicalKey == LogicalKeyboardKey.f7) {
        onNavigate(11);
        return KeyEventResult.handled;
      }

      // F8 - Settings
      if (event.logicalKey == LogicalKeyboardKey.f8) {
        onNavigate(21);
        return KeyEventResult.handled;
      }

      // F9 - Inventory Analytics
      if (event.logicalKey == LogicalKeyboardKey.f9) {
        onNavigate(7);
        return KeyEventResult.handled;
      }

      // F10 - Dashboard (browser may intercept menu bar on web, but generally safe)
      if (!kIsWeb && event.logicalKey == LogicalKeyboardKey.f10) {
        onNavigate(0);
        return KeyEventResult.handled;
      }

      // F11 - Suppliers: browser uses for fullscreen on web, skip on web
      if (!kIsWeb && event.logicalKey == LogicalKeyboardKey.f11) {
        onNavigate(6);
        return KeyEventResult.handled;
      }

      // F12 - Backup: browser opens DevTools on web, skip on web
      if (!kIsWeb && event.logicalKey == LogicalKeyboardKey.f12) {
        onNavigate(19);
        return KeyEventResult.handled;
      }

      // Ctrl+Q - Quick Actions Menu
      if (HardwareKeyboard.instance.isControlPressed &&
          event.logicalKey == LogicalKeyboardKey.keyQ) {
        _showQuickActionsMenu(context, onNavigate);
        return KeyEventResult.handled;
      }

      // Alt+Number: browser intercepts for tab switching on web, skip on web
      if (!kIsWeb && HardwareKeyboard.instance.isAltPressed) {
        if (event.logicalKey == LogicalKeyboardKey.digit1) {
          onNavigate(0);
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.digit2) {
          onNavigate(1);
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.digit3) {
          onNavigate(2);
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.digit4) {
          onNavigate(3);
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.digit5) {
          onNavigate(5);
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.digit6) {
          onNavigate(11);
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.digit7) {
          onNavigate(7);
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.digit8) {
          onNavigate(20);
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.digit9) {
          onNavigate(21);
          return KeyEventResult.handled;
        }
      }
    }

    return KeyEventResult.ignored;
  }

  static void _showQuickActionsMenu(BuildContext context, Function(int) onNavigate) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quick Actions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.point_of_sale),
              title: const Text('New Sale'),
              subtitle: const Text('F2'),
              onTap: () {
                Navigator.pop(context);
                onNavigate(1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_box),
              title: const Text('Add Product'),
              subtitle: const Text('Ctrl+Shift+P'),
              onTap: () {
                Navigator.pop(context);
                onNavigate(2);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Add Customer'),
              subtitle: const Text('Ctrl+Shift+N'),
              onTap: () {
                Navigator.pop(context);
                onNavigate(5);
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('View Orders'),
              subtitle: const Text('F4'),
              onTap: () {
                Navigator.pop(context);
                onNavigate(3);
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('Reports'),
              subtitle: const Text('F7'),
              onTap: () {
                Navigator.pop(context);
                onNavigate(11);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  static void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const KeyboardShortcutsDialog(),
    );
  }
}

class KeyboardShortcutsDialog extends StatelessWidget {
  const KeyboardShortcutsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.keyboard),
          SizedBox(width: 8),
          Text('Keyboard Shortcuts'),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Navigation',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildShortcutRow('F1', 'Show this help dialog'),
              _buildShortcutRow('F2', 'Go to POS (New Sale)'),
              _buildShortcutRow('F3', 'Go to Products'),
              _buildShortcutRow('F4', 'Go to Orders'),
              _buildShortcutRow('F5', 'Refresh (browser/system — Windows only)'),
              _buildShortcutRow('F6', 'Go to Customers'),
              _buildShortcutRow('F7', 'Go to Reports'),
              _buildShortcutRow('F8', 'Go to Settings'),
              _buildShortcutRow('F9', 'Go to Inventory Analytics'),
              _buildShortcutRow('F10', 'Go to Dashboard (Windows only)'),
              _buildShortcutRow('F11', 'Go to Suppliers (Windows only)'),
              _buildShortcutRow('F12', 'Go to Backup & Restore (Windows only)'),
              const SizedBox(height: 16),
              const Text(
                'Actions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildShortcutRow('Ctrl+S', 'Save current form'),
              _buildShortcutRow('Ctrl+N', 'Create new item'),
              _buildShortcutRow('Ctrl+F', 'Focus search field'),
              _buildShortcutRow('Ctrl+P', 'Print current page'),
              _buildShortcutRow('Ctrl+E', 'Export data'),
              _buildShortcutRow('Ctrl+Q', 'Quick actions menu'),
              _buildShortcutRow('Ctrl+Shift+N', 'New customer'),
              _buildShortcutRow('Ctrl+Shift+P', 'New product'),
              _buildShortcutRow('Alt+1-9', 'Quick navigation (1=Dashboard, 2=POS, etc.)'),
              _buildShortcutRow('Esc', 'Cancel or close dialog'),
              const SizedBox(height: 16),
              const Text(
                'POS Screen',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildShortcutRow('Ctrl+Enter', 'Complete checkout'),
              _buildShortcutRow('Ctrl+D', 'Apply discount'),
              _buildShortcutRow('Ctrl+Backspace', 'Clear cart'),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildShortcutRow(String key, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: Text(
              key,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(description)),
        ],
      ),
    );
  }
}
