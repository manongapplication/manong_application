import 'package:flutter/material.dart';
import 'package:manong_application/main.dart';
import 'package:manong_application/models/payment_status.dart';
import 'package:manong_application/models/refund_status.dart';
import 'package:manong_application/models/service_request_status.dart';
import 'package:manong_application/models/service_request.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:manong_application/utils/color_utils.dart';
import 'package:manong_application/utils/distance_matrix.dart';
import 'package:manong_application/utils/feedback_utils.dart';
import 'package:manong_application/utils/status_utils.dart';
import 'package:manong_application/widgets/icon_card.dart';
import 'package:manong_application/widgets/price_tag.dart';

class ServiceRequestCard extends StatefulWidget {
  final ServiceRequest serviceRequestItem;
  final double? meters;
  final VoidCallback? onTap;
  final bool? isManong;
  final VoidCallback? onStartJob;
  final bool? isButtonLoading;
  final bool? disableOnStartJob;
  final Function(int rating)? onTapRate;
  final VoidCallback? onTapReview;

  const ServiceRequestCard({
    super.key,
    required this.serviceRequestItem,
    this.meters,
    this.onTap,
    this.isManong,
    this.onStartJob,
    this.isButtonLoading,
    this.disableOnStartJob = false,
    this.onTapRate,
    this.onTapReview,
  });

  @override
  State<ServiceRequestCard> createState() => _ServiceRequestCardState();
}

class _ServiceRequestCardState extends State<ServiceRequestCard> {
  late int _selectedRating;
  late String _rateText;
  late Function(int rating)? _onTapRate;

  @override
  void initState() {
    super.initState();
    _onTapRate = widget.onTapRate;
    _selectedRating = widget.serviceRequestItem.feedback?.rating != null
        ? widget.serviceRequestItem.feedback!.rating
        : 0;
    _rateText = widget.serviceRequestItem.feedback?.rating != null
        ? widget.serviceRequestItem.feedback!.rating > 0
              ? 'Update your rating'
              : ''
        : widget.isManong == true
        ? 'Service Rating'
        : 'Rate this service';
  }

  void _updateRatingDialog(int oldRating) {
    showDialog(
      context: navigatorKey.currentContext!,
      builder: (context) {
        return WillPopScope(
          onWillPop: () async {
            setState(() {
              _selectedRating = oldRating;
            });
            return true;
          },
          child: AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: const Text(
              'Update your rating? This will replace the previous one.',
            ),
            actions: <Widget>[
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.black),
                onPressed: () {
                  setState(() {
                    _selectedRating = oldRating;
                  });
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  FeedbackUtils().createFeedback(
                    serviceRequestId: widget.serviceRequestItem.id!,
                    revieweeId: widget.serviceRequestItem.manongId!,
                    rating: _selectedRating,
                    comment: '',
                  );
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorScheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Update'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _onTapRatings(int index) {
    final oldRating = _selectedRating;
    setState(() {
      _selectedRating = index + 1;
    });

    if (oldRating > 0) {
      _updateRatingDialog(oldRating);
      return;
    }

    setState(() {
      _rateText = 'Thank you for rating!';
    });

    if (_onTapRate != null) {
      _onTapRate!(_selectedRating);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasRefundRequest =
        widget.serviceRequestItem.refundRequests != null &&
        widget.serviceRequestItem.refundRequests!.isNotEmpty &&
        widget.serviceRequestItem.paymentStatus != PaymentStatus.refunded &&
        widget.serviceRequestItem.refundRequests!.last.status !=
            RefundStatus.approved;
    final serviceItemTitle =
        widget.serviceRequestItem.serviceItem?.title ?? 'Unknown Service';
    // final serviceItemDate = widget.serviceRequestItem.createdAt;
    final dateText = widget.serviceRequestItem.createdAt
        ?.toLocal()
        .toString()
        .split(' ')[0];
    final subServiceItemTitle =
        widget.serviceRequestItem.otherServiceName
                .toString()
                .trim()
                .isNotEmpty &&
            widget.serviceRequestItem.otherServiceName != null
        ? widget.serviceRequestItem.otherServiceName
        : widget.serviceRequestItem.subServiceItem?.title;
    final urgencyLevelText =
        widget.serviceRequestItem.urgencyLevel?.level ?? 'No urgency set';
    final iconName = widget.serviceRequestItem.serviceItem?.iconName ?? 'help';
    final iconColorHex =
        widget.serviceRequestItem.serviceItem?.iconColor ?? '#3B82F6';
    final iconTextColorHex =
        widget.serviceRequestItem.serviceItem?.iconTextColor ?? '#FFFFF';
    final manongName =
        widget.serviceRequestItem.manong?.appUser.firstName ?? '';
    final status = widget.serviceRequestItem.status?.value;
    final finalStatus =
        manongName.isEmpty && widget.serviceRequestItem.paymentStatus != null
        ? widget.serviceRequestItem.paymentStatus!.value
        : status;
    final int messagesCount =
        widget.serviceRequestItem.messages
            ?.where((e) => e.seenAt == null)
            .length ??
        0;

    return Card(
      color: status == 'inProgress'
          ? AppColorScheme.primaryLight
          : status == 'expired'
          ? const Color.fromARGB(255, 240, 199, 199)
          : AppColorScheme.backgroundGrey,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: status == 'inProgress'
              ? (widget.serviceRequestItem.refundRequests != null &&
                        widget.serviceRequestItem.refundRequests!.isNotEmpty)
                    ? Colors.deepPurple
                    : AppColorScheme.orangeAccent
              : status == 'expired'
              ? Colors.redAccent
              : AppColorScheme.backgroundGrey,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon section
                  iconCard(
                    iconColor: colorFromHex(iconColorHex),
                    iconName: iconName,
                    iconTextColor: colorFromHex(iconTextColorHex),
                  ),
                  const SizedBox(width: 12),

                  // Content section
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 110),
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
                          const SizedBox(height: 4),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColorScheme.primaryLight.withOpacity(
                                0.5,
                              ),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppColorScheme.primaryColor.withOpacity(
                                  0.3,
                                ),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              widget.serviceRequestItem.requestNumber ?? 'N/A',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColorScheme.primaryDark,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),

                          Text(
                            '$dateText',
                            style: TextStyle(
                              fontWeight: FontWeight.w400,
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),

                          // Status chip
                          if (widget.serviceRequestItem.status !=
                              ServiceRequestStatus.completed) ...[
                            Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: getStatusColor(
                                      finalStatus,
                                    ).withOpacity(0.1),
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
                                        widget
                                                .serviceRequestItem
                                                .manong
                                                ?.appUser
                                                .firstName ??
                                            '',
                                        (widget
                                                    .serviceRequestItem
                                                    .status
                                                    ?.readable ??
                                                ServiceRequestStatus
                                                    .pending
                                                    .value)
                                            .toLowerCase(),
                                      ),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: getStatusBorderColor(
                                          finalStatus,
                                        ),
                                        fontWeight: FontWeight.w500,
                                        decoration: hasRefundRequest
                                            ? TextDecoration.lineThrough
                                            : TextDecoration.none,
                                      ),
                                    ),
                                  ),
                                ),

                                // if (widget.isManong == true) ...[
                                //   const SizedBox(width: 4),
                                //   Icon(Icons.edit, color: Colors.grey.shade700),
                                // ],
                              ],
                            ),

                            if (hasRefundRequest) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      color: getStatusColor(
                                        'refunding',
                                      ).withOpacity(0.1),
                                      border: Border.all(
                                        color: getStatusBorderColor(
                                          'refunding',
                                        ),
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
                                        'Refund Requested. 1-2 business day',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: getStatusBorderColor(
                                            'refunding',
                                          ),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // if (widget.isManong == true) ...[
                                  //   const SizedBox(width: 4),
                                  //   Icon(Icons.edit, color: Colors.grey.shade700),
                                  // ],
                                ],
                              ),
                            ],

                            if (widget.serviceRequestItem.paymentStatus !=
                                null) ...[
                              const SizedBox(height: 6),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: getStatusColor(
                                    widget
                                        .serviceRequestItem
                                        .paymentStatus!
                                        .name,
                                  ).withOpacity(0.1),
                                  border: Border.all(
                                    color: getStatusBorderColor(
                                      widget
                                          .serviceRequestItem
                                          .paymentStatus!
                                          .name,
                                    ),
                                    width: 1,
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                child: Text(
                                  widget.serviceRequestItem.paymentStatus!.name
                                      .split(' ')
                                      .map(
                                        (word) =>
                                            word[0].toUpperCase() +
                                            word.substring(1),
                                      )
                                      .join(' '),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: getStatusBorderColor(
                                      widget
                                          .serviceRequestItem
                                          .paymentStatus!
                                          .name,
                                    ),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ],

                          // Urgency info
                          if (widget.serviceRequestItem.manong?.appUser.id !=
                                  null &&
                              widget.serviceRequestItem.urgencyLevel?.time !=
                                  null) ...[
                            const SizedBox(height: 6),
                            Text(
                              '$urgencyLevelText (${widget.serviceRequestItem.urgencyLevel!.time})',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],

                          // Total
                          if (widget.serviceRequestItem.total != null) ...[
                            const SizedBox(height: 6),
                            PriceTag(price: widget.serviceRequestItem.total!),
                          ],
                        ],
                      ),
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
                          if (_selectedRating == 0)
                            Icon(
                              widget.meters != null
                                  ? Icons.location_on
                                  : Icons.location_off,
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

                          if (_selectedRating > 0 && widget.isManong == false)
                            const SizedBox(height: 4),
                          if (_selectedRating > 0 && widget.isManong == false)
                            ElevatedButton(
                              onPressed: widget.onTapReview,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColorScheme.primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                              ),
                              child: const Text(
                                'Leave A Review',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 4),
                      widget.meters != null &&
                              widget.serviceRequestItem.status ==
                                  ServiceRequestStatus.inProgress
                          ? Text(
                              DistanceMatrix().formatDistance(widget.meters!),
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

                      if (widget.isManong == true &&
                          widget.onStartJob != null) ...[
                        const SizedBox(height: 14),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColorScheme.primaryDark,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: widget.isButtonLoading != null
                              ? (widget.isButtonLoading == true ||
                                        widget.disableOnStartJob == true)
                                    ? null
                                    : widget.onStartJob
                              : null,
                          child: Row(
                            children: [
                              Icon(Icons.directions_run),
                              Icon(Icons.forward),
                            ],
                          ),
                        ),
                      ],

                      if (widget.meters != null &&
                          DistanceMatrix()
                                  .estimateTime(widget.meters!)
                                  .toLowerCase() ==
                              'arrived' &&
                          widget.serviceRequestItem.status ==
                              ServiceRequestStatus.inProgress) ...[
                        Icon(Icons.flag, color: Colors.green, size: 28),
                      ],
                    ],
                  ),
                ],
              ),

              if (widget.serviceRequestItem.status ==
                  ServiceRequestStatus.completed) ...[
                const SizedBox(height: 4),

                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey.shade200,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _rateText,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),

                      Stack(
                        children: [
                          Row(
                            children: List.generate(5, (index) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                child: GestureDetector(
                                  onTap: widget.isManong == true
                                      ? null
                                      : () => _onTapRatings(index),
                                  child: Icon(
                                    index < _selectedRating
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: AppColorScheme.gold,
                                    size: 22,
                                  ),
                                ),
                              );
                            }),
                          ),

                          if (widget.isManong == true) ...[
                            if (widget.isManong == true && _selectedRating == 0)
                              Positioned.fill(
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 6,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      'No Ratings Yet',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
