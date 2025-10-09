import 'package:flutter/material.dart';

class SnackBarUtils {
  /// Safely shows a SnackBar with proper mounted and context checks
  static void showSnackBar(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    // Check if context is still valid and mounted
    if (!context.mounted) return;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.white)),
          backgroundColor: backgroundColor,
          duration: duration,
          action: action,
        ),
      );
    } catch (e) {
      // Silently handle any context-related errors
      debugPrint('Error showing SnackBar: $e');
    }
  }

  /// Shows a success message with green background
  static void showSuccess(BuildContext context, String message) {
    showSnackBar(context, message, backgroundColor: Colors.green);
  }

  /// Shows an error message with red background
  static void showError(BuildContext context, String message) {
    showSnackBar(context, message, backgroundColor: Colors.red);
  }

  /// Shows a warning message with orange background
  static void showWarning(BuildContext context, String message) {
    showSnackBar(context, message, backgroundColor: Colors.orange);
  }

  /// Shows an info message with blue background
  static void showInfo(BuildContext context, String message) {
    showSnackBar(context, message, backgroundColor: Colors.blue);
  }
}

// Alternative approach using extension methods for even cleaner usage
extension BuildContextSnackBar on BuildContext {
  /// Show a basic SnackBar
  void showSnackBar(
    String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    SnackBarUtils.showSnackBar(
      this,
      message,
      backgroundColor: backgroundColor,
      duration: duration,
      action: action,
    );
  }

  /// Show success SnackBar
  void showSuccess(String message) {
    SnackBarUtils.showSuccess(this, message);
  }

  /// Show error SnackBar
  void showError(String message) {
    SnackBarUtils.showError(this, message);
  }

  /// Show warning SnackBar
  void showWarning(String message) {
    SnackBarUtils.showWarning(this, message);
  }

  /// Show info SnackBar
  void showInfo(String message) {
    SnackBarUtils.showInfo(this, message);
  }
}
