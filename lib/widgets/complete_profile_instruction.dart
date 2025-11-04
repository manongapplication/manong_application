import 'package:flutter/material.dart';
import 'package:manong_application/theme/colors.dart';

class CompleteProfileInstruction extends StatelessWidget {
  const CompleteProfileInstruction({super.key});

  final instructions = const [
    {
      'title': 'Fill Out Required Details',
      'description':
          'Provide your Full Name, Email Address, and complete Address information to start setting up your account.',
      'icon': Icons.person_outline,
    },
    {
      'title': 'Add Your Nickname (Optional)',
      'description':
          'You can include a nickname to make your profile more personal. This field is optional.',
      'icon': Icons.tag_outlined,
    },
    {
      'title': 'Upload a Valid Photo',
      'description':
          'Submit a clear and valid photo or selfie. This helps verify your identity and keep the community secure.',
      'icon': Icons.camera_alt_outlined,
    },
    {
      'title': 'Account Review by Admin',
      'description':
          'After submission, your account will be placed on hold while our admin reviews your details.',
      'icon': Icons.hourglass_empty_outlined,
    },
    {
      'title': 'Verification and Activation',
      'description':
          'Once your profile is verified, your account will be activated — and you can start using service requests.',
      'icon': Icons.verified_outlined,
    },
  ];

  Widget _buildStep(BuildContext context, Map<String, dynamic> step) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColorScheme.primaryLight.withOpacity(0.25),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(step['icon'], size: 26, color: AppColorScheme.primaryDark),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step['title'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  step['description'],
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Before You Complete Your Profile',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Please follow these steps to complete your registration and get verified by the admin team.',
          style: TextStyle(fontSize: 12.5, color: Colors.black54),
        ),
        const SizedBox(height: 16),
        for (var step in instructions) _buildStep(context, step),
      ],
    );
  }
}
