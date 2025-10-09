import 'package:flutter/material.dart';
import 'package:manong_application/api/service_item_api_service.dart';
import 'package:manong_application/api/service_request_api_service.dart';
import 'package:manong_application/models/service_request.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:manong_application/utils/color_utils.dart';
import 'package:manong_application/widgets/dashed_divider.dart';
import 'package:manong_application/widgets/icon_card.dart';

class BottomNavSwipe extends StatelessWidget {
  final PageController pageController;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onItemTapped;
  final List<Widget> pages;
  final ServiceRequest? serviceRequest;
  final String? serviceRequestMessage;
  final VoidCallback? onTapContainer;
  final bool? manongArrived;
  final bool? isAdmin;
  final String? serviceRequestStatus;
  final bool? serviceRequestIsExpired;

  const BottomNavSwipe({
    super.key,
    required this.pages,
    required this.pageController,
    required this.currentIndex,
    required this.onPageChanged,
    required this.onItemTapped,
    this.serviceRequest,
    this.serviceRequestMessage,
    this.onTapContainer,
    this.manongArrived,
    this.isAdmin,
    this.serviceRequestStatus,
    this.serviceRequestIsExpired,
  });

  Widget _buildOngoingContainer() {
    debugPrint('_buildOngoingContainer ${(isAdmin == null)}');

    if (serviceRequest == null ||
        isAdmin == null ||
        serviceRequestStatus == 'completed' ||
        serviceRequestIsExpired == true) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: const EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: 100, // Account for bottom nav bar height
          ),
          child: InkWell(
            onTap: onTapContainer,
            borderRadius: BorderRadius.circular(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image and dashed line section
                SizedBox(
                  height: 90,
                  child: Row(
                    children: [
                      // Image container
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Image.asset(
                          manongArrived != null && manongArrived == true
                              ? 'assets/icon/manong_verify_icon.png'
                              : 'assets/icon/manong_riding_scooter.png',
                          height: 90,
                          width: 90,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback if image fails to load
                            return Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                manongArrived == true
                                    ? Icons.check_circle
                                    : Icons.delivery_dining,
                                size: 40,
                                color: Colors.grey.shade500,
                              ),
                            );
                          },
                        ),
                      ),

                      // Dashed line
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(left: 10),
                          child: DashedDividerPainter(
                            color: Colors.grey.shade500,
                            height: 2,
                            dashWidth: 8,
                            dashSpace: 4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Info container
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColorScheme.primaryLight,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                    border: Border.all(
                      color: AppColorScheme.orangeAccent,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Service icon
                      iconCard(
                        iconColor:
                            (serviceRequest?.serviceItem?.iconColor != null)
                            ? colorFromHex(
                                serviceRequest!.serviceItem!.iconColor,
                              )
                            : Colors.blue,
                        iconName: serviceRequest?.serviceItem?.iconName ?? '',
                      ),

                      const SizedBox(width: 12),

                      // Text content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              serviceRequest?.subServiceItem?.title ?? '',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              (manongArrived == true)
                                  ? (isAdmin == true
                                        ? 'Reached destination'
                                        : 'Your Manong has arrived 🙌')
                                  : serviceRequestMessage ?? '',
                              style: TextStyle(
                                color: AppColorScheme.deepTeal,
                                fontSize: 12,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Arrow icon
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 20,
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
    IconData icon,
    String label,
    int index,
  ) {
    final bool isActive = currentIndex == index;

    return BottomNavigationBarItem(
      label: label,
      icon: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 3,
            width: 80,
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColorScheme.primaryColor
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Icon(
            icon,
            color: isActive ? AppColorScheme.primaryColor : Colors.grey,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              Expanded(
                child: PageView(
                  controller: pageController,
                  onPageChanged: onPageChanged,
                  children: pages,
                ),
              ),
            ],
          ),

          // Ongoing service container overlay
          _buildOngoingContainer(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColorScheme.backgroundGrey,
        selectedItemColor: AppColorScheme.primaryColor,
        unselectedItemColor: Colors.grey,
        currentIndex: currentIndex,
        onTap: onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: [
          _buildNavItem(Icons.home, 'Home', 0),
          _buildNavItem(Icons.assignment, 'My Requests', 1),
          _buildNavItem(Icons.person, 'Profile', 2),
        ],
      ),
    );
  }
}
