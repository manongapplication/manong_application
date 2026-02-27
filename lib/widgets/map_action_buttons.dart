import 'package:flutter/material.dart';
import 'package:manong_application/theme/colors.dart';

class MapActionButtons extends StatelessWidget {
  final VoidCallback onCenterManong;
  final VoidCallback onCenterUser;
  final double topPadding;

  const MapActionButtons({
    super.key,
    required this.onCenterManong,
    required this.onCenterUser,
    this.topPadding = 80,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + topPadding,
      right: 16,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top button (Manong)
            SizedBox(
              width: 44,
              height: 44,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onCenterManong,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey.shade200,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: const Icon(
                      Icons.directions_car,
                      size: 22,
                      color: AppColorScheme.primaryColor,
                    ),
                  ),
                ),
              ),
            ),

            // Bottom button (User)
            SizedBox(
              width: 44,
              height: 44,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onCenterUser,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 22,
                    color: AppColorScheme.primaryColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
