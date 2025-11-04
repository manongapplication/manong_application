import 'package:flutter/material.dart';
import 'package:iconify_design/iconify_design.dart';
import 'package:manong_application/main.dart';
import 'package:manong_application/models/manong.dart';
import 'package:manong_application/models/sub_service_item.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:manong_application/utils/color_utils.dart';

class ManongListCard extends StatelessWidget {
  final Manong manong;
  final Color iconColor;
  final VoidCallback onTap;
  final double? meters;
  final SubServiceItem? subServiceItem;

  const ManongListCard({
    super.key,
    required this.manong,
    required this.iconColor,
    required this.onTap,
    this.meters,
    this.subServiceItem,
  });

  Widget _buildSpecialities() {
    final remaining = manong.profile!.specialities!.skip(5).toList();
    final hasContains =
        subServiceItem != null &&
        remaining.any(
          (item) => item.subServiceItem.title.contains(subServiceItem!.title),
        );

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ...manong.profile!.specialities!.take(5).map((item) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: subServiceItem != null
                  ? item.subServiceItem.title.contains(subServiceItem!.title)
                        ? Colors.amber.withOpacity(0.7)
                        : iconColor.withOpacity(0.1)
                  : iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconifyIcon(
                  icon: item.subServiceItem.iconName,
                  size: 24,
                  color: Colors.grey.shade800,
                ),
                SizedBox(width: 4),
                Flexible(
                  child: Text(
                    item.subServiceItem.title,
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis, // <-- truncate long text
                  ),
                ),
              ],
            ),
          );
        }),

        if (manong.profile!.specialities!.length >= 6)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: hasContains
                  ? Colors.amber.withOpacity(0.7)
                  : Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: navigatorKey.currentContext!,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  builder: (context) {
                    final remaining = manong.profile!.specialities!
                        .skip(5)
                        .toList();

                    return SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Scrollbar(
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "More Specialities",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: remaining.map((item) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            item.subServiceItem.title.contains(
                                              subServiceItem?.title ?? "",
                                            )
                                            ? Colors.amber.withOpacity(0.7)
                                            : iconColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconifyIcon(
                                            icon: item.subServiceItem.iconName,
                                            size: 24,
                                            color: Colors.grey.shade800,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            item.subServiceItem.title,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              child: Text(
                "+${manong.profile!.specialities!.length - 5} show more",
                style: TextStyle(
                  fontSize: 12,
                  color: hasContains ? Colors.black : Colors.black54,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildManongInfo() {
    return Expanded(
      flex: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // -- Manong Name
              Text(
                manong.appUser.firstName ?? '',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),

              // Verified
              if (manong.profile?.isProfessionallyVerified == true) ...[
                const SizedBox(width: 4),
                Icon(Icons.verified_rounded, size: 20, color: Colors.lightBlue),
              ],
            ],
          ),

          const SizedBox(height: 4),

          // -- Status
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: getStatusColor(manong.profile?.status).withOpacity(0.1),
              border: Border.all(
                color: getStatusBorderColor(manong.profile?.status),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Text(
              manong.profile?.status ?? '',
              style: TextStyle(
                fontSize: 11,
                color: getStatusBorderColor(manong.profile?.status),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // -- Specialities
          if (manong.profile?.specialities != null &&
              manong.profile!.specialities!.isNotEmpty)
            _buildSpecialities(),
        ],
      ),
    );
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()}m';
    } else {
      final km = meters / 1000;
      return '${km.toStringAsFixed(1)}km';
    }
  }

  Widget _buildDistanceInfo() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Icon(Icons.location_on, size: 24, color: Colors.grey.shade600),
        const SizedBox(height: 4),
        meters != null
            ? Text(
                _formatDistance(meters!),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              )
            : Text(
                'N/A',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColorScheme.backgroundGrey,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 4),
              _buildManongInfo(),
              _buildDistanceInfo(),
            ],
          ),
        ),
      ),
    );
  }
}
