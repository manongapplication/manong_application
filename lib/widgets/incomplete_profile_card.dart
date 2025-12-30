import 'package:flutter/material.dart';
import 'package:manong_application/theme/colors.dart';

class IncompleteProfileCard extends StatelessWidget {
  final VoidCallback onTap;
  final String title;
  final String description;
  final String buttonText;
  final String imagePath;

  const IncompleteProfileCard({
    super.key,
    required this.onTap,
    this.title = 'Complete Your Profile',
    this.description =
        'You haven\'t set up your profile yet. Complete your information to start requesting services.',
    this.buttonText = 'Complete Profile',
    this.imagePath = 'assets/icon/manong_setup_acc_icon.png',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildImageOrIcon(),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: AppColorScheme.primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorScheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              buttonText,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageOrIcon() {
    try {
      // Try to load the image asset
      return Image.asset(
        imagePath,
        height: 100,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to icon if image doesn't exist
          return Icon(
            Icons.person_add_alt_1,
            size: 80,
            color: AppColorScheme.primaryColor,
          );
        },
      );
    } catch (e) {
      // Fallback to icon
      return Icon(
        Icons.person_add_alt_1,
        size: 80,
        color: AppColorScheme.primaryColor,
      );
    }
  }
}
