import 'package:flutter/material.dart';
import 'package:manong_application/models/service_item.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:manong_application/utils/icon_mapper.dart';
import 'package:manong_application/widgets/icon_card.dart';

class ServiceCardLite extends StatelessWidget {
  final ServiceItem serviceItem;
  final Color iconColor;
  final VoidCallback onTap;

  const ServiceCardLite({
    super.key,
    required this.serviceItem,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // return Container(
    //   decoration: BoxDecoration(
    //     color: AppColorScheme.primaryLight,
    //     borderRadius: BorderRadius.circular(16),
    //     // // Enhanced shadow for better CTA visibility
    //     // boxShadow: [
    //     //   BoxShadow(
    //     //     color: Colors.black.withOpacity(0.08),
    //     //     blurRadius: 12,
    //     //     spreadRadius: 1,
    //     //     offset: Offset(0, 4),
    //     //   ),
    //     //   BoxShadow(
    //     //     color: Colors.black.withOpacity(0.04),
    //     //     blurRadius: 6,
    //     //     spreadRadius: 0,
    //     //     offset: Offset(0, 2),
    //     //   ),
    //     // ],
    //   ),
    //   child:
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Column(
          children: [
            Material(
              color: AppColorScheme.primaryLight,
              shape: const CircleBorder(),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: iconCard(
                  iconColor: iconColor,
                  iconName: serviceItem.iconName,
                  size: 38,
                ),
              ),
            ),

            const SizedBox(height: 8),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                serviceItem.title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                  letterSpacing: -0.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.visible,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
