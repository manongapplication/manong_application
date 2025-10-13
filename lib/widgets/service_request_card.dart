import 'package:flutter/material.dart';
import 'package:manong_application/models/payment_status.dart';
import 'package:manong_application/models/request_status.dart';
import 'package:manong_application/models/service_request.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:manong_application/utils/color_utils.dart';
import 'package:manong_application/utils/distance_matrix.dart';
import 'package:manong_application/utils/status_utils.dart';
import 'package:manong_application/widgets/icon_card.dart';
import 'package:manong_application/widgets/price_tag.dart';

class ServiceRequestCard extends StatelessWidget {
  final ServiceRequest serviceRequestItem;
  final double? meters;
  final VoidCallback? onTap;
  final bool? isAdmin;
  final VoidCallback? onStartJob;
  final bool? isButtonLoading;
  final bool? disableOnStartJob;

  const ServiceRequestCard({
    super.key,
    required this.serviceRequestItem,
    this.meters,
    this.onTap,
    this.isAdmin,
    this.onStartJob,
    this.isButtonLoading,
    this.disableOnStartJob = false,
  });

  @override
  Widget build(BuildContext context) {
    final serviceItemTitle =
        serviceRequestItem.serviceItem?.title ?? 'Unknown Service';
    final subServiceItemTitle =
        serviceRequestItem.otherServiceName.toString().trim().isNotEmpty &&
            serviceRequestItem.otherServiceName != null
        ? serviceRequestItem.otherServiceName
        : serviceRequestItem.subServiceItem?.title;
    final urgencyLevelText =
        serviceRequestItem.urgencyLevel?.level ?? 'No urgency set';
    final iconName = serviceRequestItem.serviceItem?.iconName ?? 'help';
    final iconColorHex = serviceRequestItem.serviceItem?.iconColor ?? '#3B82F6';
    final manongName = serviceRequestItem.manong?.appUser.firstName ?? '';
    final status = serviceRequestItem.status;
    final finalStatus =
        manongName.isEmpty && serviceRequestItem.paymentStatus != null
        ? serviceRequestItem.paymentStatus!.value
        : status;
    final int messagesCount =
        serviceRequestItem.messages?.where((e) => e.seenAt == null).length ?? 0;

    return Card(
      color: status == 'inprogress'
          ? AppColorScheme.primaryLight
          : status == 'expired'
          ? const Color.fromARGB(255, 240, 199, 199)
          : AppColorScheme.backgroundGrey,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: status == 'inprogress'
              ? AppColorScheme.orangeAccent
              : status == 'expired'
              ? Colors.redAccent
              : AppColorScheme.backgroundGrey,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon section
              iconCard(
                iconColor: colorFromHex(iconColorHex),
                iconName: iconName,
              ),
              const SizedBox(width: 12),

              // Content section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Service Title
                    Text(
                      '$serviceItemTitle -> $subServiceItemTitle',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Status chip
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: getStatusColor(finalStatus).withOpacity(0.1),
                            border: Border.all(
                              color: getStatusBorderColor(finalStatus),
                              width: 1,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              getStatusWithManongText(
                                serviceRequestItem.manong?.appUser.firstName ??
                                    '',
                                (serviceRequestItem.status ?? 'pending')
                                    .toLowerCase(),
                              ),
                              style: TextStyle(
                                fontSize: 11,
                                color: getStatusBorderColor(finalStatus),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),

                        // if (isAdmin == true) ...[
                        //   const SizedBox(width: 4),
                        //   Icon(Icons.edit, color: Colors.grey.shade700),
                        // ],
                      ],
                    ),

                    if (serviceRequestItem.paymentStatus != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: getStatusColor(
                            serviceRequestItem.paymentStatus!.name,
                          ).withOpacity(0.1),
                          border: Border.all(
                            color: getStatusBorderColor(
                              serviceRequestItem.paymentStatus!.name,
                            ),
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        child: Text(
                          serviceRequestItem.paymentStatus!.name
                              .split(' ')
                              .map(
                                (word) =>
                                    word[0].toUpperCase() + word.substring(1),
                              )
                              .join(' '),
                          style: TextStyle(
                            fontSize: 11,
                            color: getStatusBorderColor(
                              serviceRequestItem.paymentStatus!.name,
                            ),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],

                    // Urgency info
                    if (serviceRequestItem.manong?.appUser.id != null &&
                        serviceRequestItem.urgencyLevel?.time != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        '$urgencyLevelText (${serviceRequestItem.urgencyLevel!.time})',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],

                    // Total
                    if (serviceRequestItem.total != null) ...[
                      const SizedBox(height: 6),
                      PriceTag(price: serviceRequestItem.total!),
                    ],
                  ],
                ),
              ),

              // Distance
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        meters != null ? Icons.location_on : Icons.location_off,
                        size: 24,
                        color: Colors.grey.shade600,
                      ),

                      if (messagesCount > 0) ...[
                        Positioned(
                          top: -12,
                          right: -4,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              messagesCount == 5
                                  ? '${messagesCount.toString()}+'
                                  : messagesCount.toString(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 4),
                  meters != null &&
                          serviceRequestItem.status ==
                              RequestStatus.inprogress.value
                      ? Text(
                          DistanceMatrix().formatDistance(meters!),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        )
                      : Text(
                          '',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),

                  if (isAdmin == true && onStartJob != null) ...[
                    const SizedBox(height: 14),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColorScheme.primaryDark,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: isButtonLoading != null
                          ? (isButtonLoading == true ||
                                    disableOnStartJob == true)
                                ? null
                                : onStartJob
                          : null,
                      child: Row(
                        children: [
                          Icon(Icons.directions_run),
                          Icon(Icons.forward),
                        ],
                      ),
                    ),
                  ],

                  if (meters != null &&
                      DistanceMatrix().estimateTime(meters!).toLowerCase() ==
                          'arrived' &&
                      serviceRequestItem.status ==
                          RequestStatus.inprogress.value) ...[
                    Icon(Icons.flag, color: Colors.green, size: 28),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
