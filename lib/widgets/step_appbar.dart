import 'package:flutter/material.dart';
import 'package:manong_application/theme/colors.dart';

// ignore: must_be_immutable
class StepAppbar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final int currentStep;
  final int totalSteps;
  Widget? trailing;

  StepAppbar({
    super.key,
    required this.title,
    this.subtitle,
    required this.currentStep,
    required this.totalSteps,
    this.trailing,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 4);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
          if (subtitle != null) ...[
            Text(
              subtitle!,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade300),
            ),
          ],
        ],
      ),
      elevation: 0,
      backgroundColor: AppColorScheme.primaryColor,
      foregroundColor: Colors.white,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(4),
        child: Row(
          children: List.generate(totalSteps, (index) {
            final isActive = index < currentStep;

            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColorScheme.deepTeal
                      : Colors.grey.shade300,
                ),
              ),
            );
          }),
        ),
      ),
      actions: trailing != null
          ? [
              Padding(
                padding: EdgeInsets.only(right: 20),
                child: Row(children: [?trailing]),
              ),
            ]
          : null,
    );
  }
}
