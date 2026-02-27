import 'package:flutter/material.dart';

class SnackBarUtils {
  /// Safely shows a SnackBar with proper mounted and context checks
  static void showSnackBar(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
    bool floating = true,
    double elevation = 0,
  }) {
    // Check if context is still valid and mounted
    if (!context.mounted) return;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.2,
            ),
          ),
          backgroundColor: backgroundColor,
          duration: duration,
          action: action,
          behavior: floating
              ? SnackBarBehavior.floating
              : SnackBarBehavior.fixed,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: elevation,
          margin: floating ? const EdgeInsets.all(16) : null,
        ),
      );
    } catch (e) {
      // Silently handle any context-related errors
      debugPrint('Error showing SnackBar: $e');
    }
  }

  /// Shows a success message with green gradient background
  static void showSuccess(BuildContext context, String message) {
    showSnackBar(
      context,
      message,
      backgroundColor: Colors.green.shade600,
      floating: true,
      elevation: 4,
    );
  }

  /// Shows an error message with red gradient background
  static void showError(BuildContext context, String message) {
    showSnackBar(
      context,
      message,
      backgroundColor: Colors.red.shade600,
      floating: true,
      elevation: 4,
    );
  }

  /// Shows a warning message with orange background
  static void showWarning(BuildContext context, String message) {
    showSnackBar(
      context,
      message,
      backgroundColor: Colors.orange.shade600,
      floating: true,
      elevation: 4,
    );
  }

  /// Shows an info message with blue background
  static void showInfo(BuildContext context, String message) {
    showSnackBar(
      context,
      message,
      backgroundColor: Colors.blue.shade600,
      floating: true,
      elevation: 4,
    );
  }

  /// Shows a custom styled SnackBar with icon
  static void showWithIcon(
    BuildContext context,
    String message, {
    required IconData icon,
    required Color color,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: color,
          duration: duration,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      debugPrint('Error showing SnackBar: $e');
    }
  }

  /// Shows an action SnackBar with button
  static void showWithAction(
    BuildContext context,
    String message, {
    required String actionLabel,
    required VoidCallback onPressed,
    Color? backgroundColor,
    Color? actionColor,
  }) {
    showSnackBar(
      context,
      message,
      backgroundColor: backgroundColor ?? Colors.grey.shade900,
      action: SnackBarAction(
        label: actionLabel,
        textColor: actionColor ?? Colors.white,
        onPressed: onPressed,
      ),
      floating: true,
      duration: const Duration(seconds: 5),
    );
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
    bool floating = true,
  }) {
    SnackBarUtils.showSnackBar(
      this,
      message,
      backgroundColor: backgroundColor,
      duration: duration,
      action: action,
      floating: floating,
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

  /// Show SnackBar with icon
  void showWithIcon(
    String message, {
    required IconData icon,
    required Color color,
  }) {
    SnackBarUtils.showWithIcon(this, message, icon: icon, color: color);
  }

  /// Show SnackBar with action button
  void showWithAction(
    String message, {
    required String actionLabel,
    required VoidCallback onPressed,
    Color? backgroundColor,
    Color? actionColor,
  }) {
    SnackBarUtils.showWithAction(
      this,
      message,
      actionLabel: actionLabel,
      onPressed: onPressed,
      backgroundColor: backgroundColor,
      actionColor: actionColor,
    );
  }
}
