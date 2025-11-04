import 'package:flutter/material.dart';
import 'package:manong_application/models/service_item.dart';
import 'package:manong_application/models/service_item_status.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:manong_application/utils/color_utils.dart';
import 'package:manong_application/widgets/icon_card.dart';

class ServiceCardLite extends StatelessWidget {
  final ServiceItem serviceItem;
  final VoidCallback onTap;

  const ServiceCardLite({
    super.key,
    required this.serviceItem,
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
        onTap: serviceItem.status == ServiceItemStatus.comingSoon
            ? null
            : onTap,
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Material(
                  color: AppColorScheme.primaryLight,
                  shape: const CircleBorder(),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: iconCard(
                      iconColor: colorFromHex(serviceItem.iconColor),
                      iconName: serviceItem.iconName,
                      iconTextColor: colorFromHex(serviceItem.iconTextColor),
                      size: 38,
                    ),
                  ),
                ),

                if (serviceItem.status == ServiceItemStatus.comingSoon)
                  Positioned(
                    bottom: 0, // or top: 0 if you want it on top
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColorScheme.goldDeep.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Coming Soon', // fixed spelling
                        style: TextStyle(
                          fontSize: 7,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
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
