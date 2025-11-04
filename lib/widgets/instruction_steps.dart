import 'package:flutter/material.dart';
import 'package:manong_application/theme/colors.dart';

class InstructionSteps extends StatelessWidget {
  final bool showHorizontalBar; // 👈 optional scrollbar toggle

  InstructionSteps({
    super.key,
    this.showHorizontalBar = false, // default: no scrollbar
  });

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
      'height': '140',
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
    return Container(
      width: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: AppColorScheme.primaryLight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              softWrap: true,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: height,
            child: Center(child: Image.asset(imagePath, fit: BoxFit.contain)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scrollContent = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          for (var item in instructions)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _buildInstructionStep(
                item['description']!,
                item['imagePath']!,
                double.parse(item['height'].toString()),
              ),
            ),
        ],
      ),
    );

    // 👇 Conditionally wrap in Scrollbar
    return SizedBox(
      height: 220,
      child: showHorizontalBar
          ? Scrollbar(
              thumbVisibility: true,
              trackVisibility: false,
              thickness: 6,
              radius: const Radius.circular(8),
              child: scrollContent,
            )
          : scrollContent,
    );
  }
}
