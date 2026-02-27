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
  final VoidCallback? onRefresh;

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
    this.onRefresh,
  });

  @override
  State<ServiceRequestCard> createState() => _ServiceRequestCardState();
}

class _ServiceRequestCardState extends State<ServiceRequestCard> {
  late int _selectedRating;
  late String _rateText;
  late Function(int rating)? _onTapRate;
  final TextEditingController _commentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final int _commentCount = 0;

  // Payment method icons mapping
  final Map<String, IconData> _paymentMethodIcons = {
    'gcash': Icons.phone_android,
    'paymaya': Icons.credit_card,
    'cash': Icons.money,
    'card': Icons.credit_card,
  };

  // Payment method colors mapping
  final Map<String, Color> _paymentMethodColors = {
    'gcash': const Color(0xFF0066B3),
    'paymaya': const Color(0xFF00B5B0),
    'cash': Colors.green,
    'card': Colors.purple,
  };

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
    _updateRatingFromServiceRequest();
  }

  void _updateRatingFromServiceRequest() {
    // Check if feedback exists and has a rating
    if (widget.serviceRequestItem.feedback != null &&
        widget.serviceRequestItem.feedback!.rating != null) {
      _selectedRating = widget.serviceRequestItem.feedback!.rating;
      _rateText = widget.serviceRequestItem.feedback!.rating > 0
          ? 'Thank you for rating!'
          : '';
    } else {
      _selectedRating = 0;
      _rateText = widget.isManong == true
          ? 'Service Rating'
          : 'Rate this service';
    }
  }

  @override
  void didUpdateWidget(ServiceRequestCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if feedback has changed
    if (oldWidget.serviceRequestItem.feedback?.rating !=
        widget.serviceRequestItem.feedback?.rating) {
      _updateRatingFromServiceRequest();
    }
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
                  if (widget.onRefresh != null) {
                    widget.onRefresh!();
                  }

                  if (_selectedRating <= 2) {
                    FeedbackUtils().dissastisfiedDialog(
                      context: context,
                      rating: _selectedRating,
                      serviceRequestId: widget.serviceRequestItem.id!,
                      reveweeId: widget.serviceRequestItem.manongId!,
                      formKey: _formKey,
                      commentController: _commentController,
                      commentCount: _commentCount,
                      onClose: () {
                        if (widget.onRefresh != null) {
                          widget.onRefresh!();
                        }
                      },
                    );
                    return;
                  }
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

  // Helper method to get payment method display name
  String _getPaymentMethodName() {
    if (widget.serviceRequestItem.paymentMethod == null) return 'Unknown';

    final methodName =
        widget.serviceRequestItem.paymentMethod!.name?.toLowerCase() ?? '';

    switch (methodName) {
      case 'gcash':
        return 'GCash';
      case 'paymaya':
        return 'Maya';
      case 'cash':
        return 'Cash';
      default:
        return widget.serviceRequestItem.paymentMethod!.name ?? 'Unknown';
    }
  }

  // Helper method to get payment method icon
  IconData _getPaymentMethodIcon() {
    if (widget.serviceRequestItem.paymentMethod == null) return Icons.payment;

    final methodName =
        widget.serviceRequestItem.paymentMethod!.name?.toLowerCase() ?? '';
    return _paymentMethodIcons[methodName] ?? Icons.payment;
  }

  // Helper method to get payment method color
  Color _getPaymentMethodColor() {
    if (widget.serviceRequestItem.paymentMethod == null) return Colors.grey;

    final methodName =
        widget.serviceRequestItem.paymentMethod!.name?.toLowerCase() ?? '';
    return _paymentMethodColors[methodName] ?? AppColorScheme.primaryColor;
  }

  @override
  Widget build(BuildContext context) {
    final serviceItem = widget.serviceRequestItem.serviceItem;
    final subServiceItem = widget.serviceRequestItem.subServiceItem;
    final manong = widget.serviceRequestItem.manong;

    final hasRefundRequest =
        widget.serviceRequestItem.refundRequests != null &&
        widget.serviceRequestItem.refundRequests!.isNotEmpty &&
        widget.serviceRequestItem.paymentStatus != PaymentStatus.refunded &&
        widget.serviceRequestItem.refundRequests!.last.status !=
            RefundStatus.approved;

    final dateText = widget.serviceRequestItem.createdAt
        ?.toLocal()
        .toString()
        .split(' ')[0];
    final serviceItemTitle = serviceItem?.title ?? 'Unknown Service';
    final subServiceItemTitle =
        (widget.serviceRequestItem.otherServiceName?.trim().isNotEmpty ?? false)
        ? widget.serviceRequestItem.otherServiceName
        : subServiceItem?.title ?? 'N/A';
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

    final int messagesCount = widget.serviceRequestItem.messages != null
        ? widget.serviceRequestItem.messages!
              .where((message) => message.seenAt == null)
              .take(10)
              .length
        : 0;

    final bool hasReviewFeedback =
        widget.serviceRequestItem.feedback?.comment != null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: status == 'inProgress'
            ? AppColorScheme.primaryLight
            : status == 'expired'
            ? const Color.fromARGB(255, 240, 199, 199)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: status == 'inProgress'
              ? (widget.serviceRequestItem.refundRequests != null &&
                        widget.serviceRequestItem.refundRequests!.isNotEmpty)
                    ? Colors.deepPurple.withOpacity(0.3)
                    : AppColorScheme.orangeAccent.withOpacity(0.3)
              : status == 'expired'
              ? Colors.redAccent.withOpacity(0.3)
              : Colors.grey.shade200,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Service Title
                          Text(
                            '$serviceItemTitle → $subServiceItemTitle',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),

                          // Request Number and Payment Method
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              // Request Number
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColorScheme.primaryColor
                                      .withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  widget.serviceRequestItem.requestNumber ??
                                      'N/A',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: AppColorScheme.primaryDark,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),

                              // Payment Method
                              if (widget.serviceRequestItem.paymentMethod !=
                                  null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getPaymentMethodColor().withOpacity(
                                      0.08,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _getPaymentMethodIcon(),
                                        size: 10,
                                        color: _getPaymentMethodColor(),
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        _getPaymentMethodName(),
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: _getPaymentMethodColor(),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // Date
                          Text(
                            dateText ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Status chips
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              if (widget.serviceRequestItem.status !=
                                  ServiceRequestStatus.completed) ...[
                                // Main status chip
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: getStatusColor(
                                      finalStatus,
                                    ).withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: getStatusColor(
                                        finalStatus,
                                      ).withOpacity(0.2),
                                      width: 0.5,
                                    ),
                                  ),
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
                                      color: getStatusColor(finalStatus),
                                      fontWeight: FontWeight.w500,
                                      decoration: hasRefundRequest
                                          ? TextDecoration.lineThrough
                                          : TextDecoration.none,
                                    ),
                                  ),
                                ),

                                // Payment status chip
                                if (widget.serviceRequestItem.paymentStatus !=
                                    null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: getStatusColor(
                                        widget
                                            .serviceRequestItem
                                            .paymentStatus!
                                            .name,
                                      ).withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: getStatusColor(
                                          widget
                                              .serviceRequestItem
                                              .paymentStatus!
                                              .name,
                                        ).withOpacity(0.2),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Text(
                                      widget
                                          .serviceRequestItem
                                          .paymentStatus!
                                          .name
                                          .split(' ')
                                          .map(
                                            (word) =>
                                                word[0].toUpperCase() +
                                                word.substring(1),
                                          )
                                          .join(' '),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: getStatusColor(
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
                          ),

                          // Refund request chip
                          if (hasRefundRequest) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: getStatusColor(
                                  'refunding',
                                ).withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: getStatusColor(
                                    'refunding',
                                  ).withOpacity(0.2),
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                'Refund Requested',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: getStatusColor('refunding'),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],

                          // Urgency info
                          if (widget.serviceRequestItem.manong?.appUser.id !=
                                  null &&
                              widget.serviceRequestItem.urgencyLevel?.time !=
                                  null) ...[
                            const SizedBox(height: 8),
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
                            const SizedBox(height: 8),
                            PriceTag(price: widget.serviceRequestItem.total!),
                          ],
                        ],
                      ),
                    ),

                    // Right side with distance and actions
                    SizedBox(
                      width: 70,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Message badge and location
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Icon(
                                widget.meters != null
                                    ? Icons.location_on
                                    : Icons.location_off,
                                size: 20,
                                color: Colors.grey.shade400,
                              ),
                              if (messagesCount > 0)
                                Positioned(
                                  top: -8,
                                  right: -8,
                                  child: Container(
                                    width: 18,
                                    height: 18,
                                    decoration: const BoxDecoration(
                                      color: Colors.redAccent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        messagesCount > 9
                                            ? '9+'
                                            : messagesCount.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 4),

                          // Distance
                          if (widget.meters != null &&
                              widget.serviceRequestItem.status ==
                                  ServiceRequestStatus.inProgress)
                            Text(
                              DistanceMatrix().formatDistance(widget.meters!),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),

                          // Review button
                          if (_selectedRating > 0 &&
                              widget.isManong == false &&
                              widget.serviceRequestItem.status ==
                                  ServiceRequestStatus.completed)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: widget.onTapReview,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        AppColorScheme.primaryColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    minimumSize: const Size(0, 28),
                                  ),
                                  child: Text(
                                    hasReviewFeedback
                                        ? 'Edit Review'
                                        : 'Review',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                              ),
                            ),

                          // Start job button for manong
                          if (widget.isManong == true &&
                              widget.onStartJob != null) ...[
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColorScheme.primaryDark,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  minimumSize: const Size(0, 28),
                                ),
                                onPressed: widget.isButtonLoading != null
                                    ? (widget.isButtonLoading == true ||
                                              widget.disableOnStartJob == true)
                                          ? null
                                          : widget.onStartJob
                                    : null,
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.play_arrow, size: 14),
                                    SizedBox(width: 2),
                                    Text(
                                      'Start',
                                      style: TextStyle(fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],

                          // Arrived flag
                          if (widget.meters != null &&
                              DistanceMatrix()
                                      .estimateTime(widget.meters!)
                                      .toLowerCase() ==
                                  'arrived' &&
                              widget.serviceRequestItem.status ==
                                  ServiceRequestStatus.inProgress)
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Icon(
                                Icons.flag,
                                color: Colors.green,
                                size: 24,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Rating section for completed services
                if (widget.serviceRequestItem.status ==
                    ServiceRequestStatus.completed) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.shade200,
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _rateText,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                        ),
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
                                  size: 20,
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
