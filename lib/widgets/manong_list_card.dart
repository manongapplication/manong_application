import 'package:flutter/material.dart';
import 'package:manong_application/main.dart';
import 'package:manong_application/models/manong.dart';
import 'package:manong_application/models/sub_service_item.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:manong_application/utils/color_utils.dart';
import 'package:manong_application/utils/icon_mapper.dart';

class ManongListCard extends StatelessWidget {
  final String name;
  final Color iconColor;
  final VoidCallback onTap;
  final bool isProfessionallyVerified;
  final String status;
  final List<ManongSpeciality>? specialities;
  final double? hourlyRate;
  final double? startingPrice;
  final double? meters;
  final SubServiceItem? subServiceItem;

  const ManongListCard({
    super.key,
    required this.name,
    required this.iconColor,
    required this.onTap,
    required this.isProfessionallyVerified,
    required this.status,
    this.specialities,
    this.hourlyRate,
    this.startingPrice,
    this.meters,
    this.subServiceItem,
  });

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
                name,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),

              // Verified
              if (isProfessionallyVerified == 1) ...[
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
              color: getStatusColor(status).withOpacity(0.1),
              border: Border.all(color: getStatusBorderColor(status), width: 1),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 11,
                color: getStatusBorderColor(status),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // -- Specialities
          if (specialities != null && specialities!.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ...specialities!.take(5).map((item) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: subServiceItem != null
                          ? item.subServiceItem.title.contains(
                                  subServiceItem!.title,
                                )
                                ? Colors.amber.withOpacity(0.7)
                                : iconColor.withOpacity(0.1)
                          : iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(getIconFromName(item.subServiceItem.iconName)),
                        SizedBox(width: 4),
                        Text(
                          item.subServiceItem.title,
                          style: TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                      ],
                    ),
                  );
                }),

                if (specialities!.length >= 6)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.2),
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
                            final remaining = specialities!.skip(5).toList();

                            return SafeArea(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
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
                                                item.subServiceItem.title
                                                    .contains(
                                                      subServiceItem?.title ??
                                                          "",
                                                    )
                                                ? Colors.amber.withOpacity(0.7)
                                                : iconColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                getIconFromName(
                                                  item.subServiceItem.iconName,
                                                ),
                                                size: 14,
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
                            );
                          },
                        );
                      },
                      child: Text(
                        "+${specialities!.length - 5} show more",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
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
