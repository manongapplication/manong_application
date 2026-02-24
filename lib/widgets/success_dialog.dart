import 'package:flutter/material.dart';
import 'package:manong_application/theme/colors.dart';

class SuccessDialog extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String message;
  final String actionButtonText;
  final String? secondaryButtonText;
  final Widget? customContent;
  final VoidCallback onActionPressed;
  final VoidCallback? onSecondaryPressed;
  final IconData? icon;
  final Color? iconColor;
  final Color? backgroundColor;

  const SuccessDialog({
    super.key,
    required this.title,
    this.subtitle,
    required this.message,
    this.actionButtonText = 'Done',
    this.secondaryButtonText,
    this.customContent,
    required this.onActionPressed,
    this.onSecondaryPressed,
    this.icon = Icons.check_circle,
    this.iconColor = Colors.green,
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 32,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with gradient
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 32,
                  horizontal: 24,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColorScheme.primaryDark,
                      AppColorScheme.primaryColor,
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    // Success Icon
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.2),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.4),
                          width: 3,
                        ),
                      ),
                      child: Icon(
                        icon ?? Icons.check_circle,
                        size: 48,
                        color: iconColor ?? Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        subtitle!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Content
              Container(
                padding: const EdgeInsets.all(24),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Message
                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColorScheme.primaryDark,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Custom content if provided
                    if (customContent != null) ...[
                      customContent!,
                      const SizedBox(height: 24),
                    ],

                    // Processing time note
                    const Text(
                      'Processing may take 1-3 business days.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Action Buttons
                    if (secondaryButtonText != null)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: BorderSide(color: Colors.grey[300]!),
                              ),
                              onPressed:
                                  onSecondaryPressed ??
                                  () => Navigator.pop(context),
                              child: Text(
                                secondaryButtonText!,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColorScheme.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              onPressed: onActionPressed,
                              child: Text(
                                actionButtonText,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColorScheme.primaryColor,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        onPressed: onActionPressed,
                        child: Text(
                          actionButtonText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper function to show the success dialog
Future<void> showSuccessDialog({
  required BuildContext context,
  required String title,
  String? subtitle,
  required String message,
  String actionButtonText = 'Done',
  String? secondaryButtonText,
  Widget? customContent,
  VoidCallback? onActionPressed,
  VoidCallback? onSecondaryPressed,
  IconData? icon,
  Color? iconColor,
  Color? backgroundColor,
  bool barrierDismissible = false,
}) async {
  return showDialog(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: Colors.black.withOpacity(0.75),
    builder: (context) => SuccessDialog(
      title: title,
      subtitle: subtitle,
      message: message,
      actionButtonText: actionButtonText,
      secondaryButtonText: secondaryButtonText,
      customContent: customContent,
      onActionPressed: onActionPressed ?? () => Navigator.pop(context),
      onSecondaryPressed: onSecondaryPressed ?? () => Navigator.pop(context),
      icon: icon,
      iconColor: iconColor,
      backgroundColor: backgroundColor,
    ),
  );
}
