import 'package:flutter/material.dart';
import 'package:manong_application/theme/colors.dart';

class InstructionSteps extends StatelessWidget {
  InstructionSteps({super.key});

  final instructions = [
    {
      'title': 'Meet your Manong',
      'description':
          'Check their name, photo, and details in the app before starting.',
      'imagePath': 'assets/icon/manong_verify_icon.png',
      'height': '120',
    },
    {
      'title': 'Confirm service',
      'description': 'Review the service type, rate, and estimated cost.',
      'imagePath': 'assets/icon/manong_service_icon.png',
      'height': '150',
    },
    {
      'title': 'Prepare your area',
      'description': 'Keep the workspace safe, clear, and accessible.',
      'imagePath': 'assets/icon/manong_prepare_icon.png',
      'height': '120',
    },
    {
      'title': 'Rate after',
      'description': 'Share honest ratings and feedback.',
      'imagePath': 'assets/icon/manong_review_icon.png',
      'height': '120',
    },
  ];

  Widget _buildInstructionStep(String text, String imagePath, double height) {
    return SizedBox(
      width: 140,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: AppColorScheme.primaryLight,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                height: 50,
                child: Text(
                  text,
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  softWrap: true,
                  textAlign: TextAlign.start,
                ),
              ),
            ),
            SizedBox(height: 4),
            SizedBox(
              height: 140,
              child: Center(child: Image.asset(imagePath, fit: BoxFit.contain)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var item in instructions)
            Container(
              margin: EdgeInsets.only(right: 8),
              child: _buildInstructionStep(
                item['description']!,
                item['imagePath']!,
                double.parse(item['height'].toString()),
              ),
            ),
        ],
      ),
    );
  }
}
