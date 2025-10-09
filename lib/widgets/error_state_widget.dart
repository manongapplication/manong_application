import 'package:flutter/material.dart';
import 'package:manong_application/theme/colors.dart';

class ErrorStateWidget extends StatelessWidget {
  final String errorText;
  final VoidCallback? onPressed;
  final String? buttonText;

  const ErrorStateWidget({
    super.key,
    this.errorText = "Error",
    this.onPressed,
    this.buttonText,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 45, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            errorText,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorScheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text(buttonText ?? 'Retry'),
          ),
        ],
      ),
    );
  }
}
