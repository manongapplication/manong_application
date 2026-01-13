import 'package:flutter/material.dart';
import 'package:manong_application/theme/colors.dart';

class ModalIconOverlay extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icons;
  final String description;
  final String? text;
  const ModalIconOverlay({
    super.key,
    required this.onPressed,
    required this.icons,
    required this.description,
    this.text,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icons, color: AppColorScheme.primaryColor, size: 40),
          const SizedBox(height: 16),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorScheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            onPressed: onPressed,
            child: Text(text ?? 'Continue'),
          ),
        ],
      ),
    );
  }
}
