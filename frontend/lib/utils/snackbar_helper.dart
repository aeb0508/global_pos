import 'package:flutter/material.dart';

class SnackBarHelper {
  // Standard POS-style SnackBar
  static void show(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Duration? duration,
    IconData? icon,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        duration: duration ?? const Duration(milliseconds: 500),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 16, left: 16, right: 400),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  // Success message
  static void showSuccess(BuildContext context, String message) {
    show(
      context,
      message,
      backgroundColor: Colors.green,
      icon: Icons.check_circle,
    );
  }

  // Error message
  static void showError(BuildContext context, String message) {
    show(
      context,
      message,
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 2),
      icon: Icons.error,
    );
  }

  // Warning message
  static void showWarning(BuildContext context, String message) {
    show(
      context,
      message,
      backgroundColor: Colors.orange,
      duration: const Duration(seconds: 2),
      icon: Icons.warning,
    );
  }

  // Info message
  static void showInfo(BuildContext context, String message) {
    show(
      context,
      message,
      backgroundColor: Colors.blue,
      duration: const Duration(seconds: 1),
      icon: Icons.info,
    );
  }
}
