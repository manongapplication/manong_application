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
  final bool? isBookmarked;
  final VoidCallback? onBookmarkToggled;

  const ManongListCard({
    super.key,
    required this.manong,
    required this.iconColor,
    required this.onTap,
    this.meters,
    this.subServiceItem,
    this.isBookmarked,
    this.onBookmarkToggled,
  });

  Widget _buildBookmarkButton() {
    return GestureDetector(
      onTap: onBookmarkToggled,
      child: Container(
        width: 32,
        height: 32,
        margin: EdgeInsets.only(left: 4),
        child: Center(
          child: Icon(
            isBookmarked == true
                ? Icons.bookmark_added
                : Icons.bookmark_add_outlined,
            color: isBookmarked == true ? Colors.amber : Colors.grey[600],
            size: 24,
          ),
        ),
      ),
    );
  }

  List<ManongSpeciality> _getSortedSpecialities(
    List<ManongSpeciality> specialities,
  ) {
    if (subServiceItem == null) return specialities;

    // Create a mutable copy
    List<ManongSpeciality> sorted = List.from(specialities);

    // Sort: highlighted items first, then alphabetical by title
    sorted.sort((a, b) {
      bool aHighlighted = a.subServiceItem.title.contains(
        subServiceItem!.title,
      );
      bool bHighlighted = b.subServiceItem.title.contains(
        subServiceItem!.title,
      );

      if (aHighlighted && !bHighlighted) return -1; // a comes first
      if (!aHighlighted && bHighlighted) return 1; // b comes first

      // Both have same highlight status, sort alphabetically
      return a.subServiceItem.title.compareTo(b.subServiceItem.title);
    });

    return sorted;
  }

  Widget _buildSpecialities() {
    if (manong.profile?.specialities == null ||
        manong.profile!.specialities!.isEmpty) {
      return Container(); // Return empty if no specialities
    }

    // Get sorted specialities with highlighted ones first
    final sortedSpecialities = _getSortedSpecialities(
      manong.profile!.specialities!,
    );

    // Take first 5 for display
    final displaySpecialities = sortedSpecialities.take(5).toList();
    final remainingCount = sortedSpecialities.length - 5;

    // Check if any of the remaining specialities are highlighted
    final hasRemainingHighlighted =
        remainingCount > 0 &&
        sortedSpecialities
            .skip(5)
            .any(
              (item) => item.subServiceItem.title.contains(
                subServiceItem?.title ?? '',
              ),
            );

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ...displaySpecialities.map((item) {
          final isHighlighted =
              subServiceItem != null &&
              item.subServiceItem.title.contains(subServiceItem!.title);

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: isHighlighted
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
                SizedBox(width: 4),
                Flexible(
                  child: Text(
                    item.subServiceItem.title,
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }),

        if (remainingCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: hasRemainingHighlighted
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
                    final remainingSpecialities = sortedSpecialities
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
                                  children: remainingSpecialities.map((item) {
                                    final isHighlighted = item
                                        .subServiceItem
                                        .title
                                        .contains(subServiceItem?.title ?? '');

                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isHighlighted
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
                "+$remainingCount show more",
                style: TextStyle(
                  fontSize: 12,
                  color: hasRemainingHighlighted
                      ? Colors.black
                      : Colors.black54,
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
              color: getStatusColor(
                manong.profile?.status.name,
              ).withOpacity(0.1),
              border: Border.all(
                color: getStatusBorderColor(manong.profile?.status.name),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Text(
              manong.profile?.status.name ?? '',
              style: TextStyle(
                fontSize: 11,
                color: getStatusBorderColor(manong.profile?.status.name),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [_buildBookmarkButton(), _buildDistanceInfo()],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
