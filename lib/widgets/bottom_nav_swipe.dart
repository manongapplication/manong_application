import 'package:flutter/material.dart';
import 'package:manong_application/api/auth_service.dart';
import 'package:manong_application/main.dart';
import 'package:manong_application/models/account_status.dart';
import 'package:manong_application/models/app_user.dart';
import 'package:manong_application/models/service_request.dart';
import 'package:manong_application/models/service_request_status.dart';
import 'package:manong_application/models/user_role.dart';
import 'package:manong_application/providers/bottom_nav_provider.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:manong_application/utils/color_utils.dart';
import 'package:manong_application/utils/feedback_utils.dart';
import 'package:manong_application/widgets/animated_progress_bar.dart';
import 'package:manong_application/widgets/dashed_divider.dart';
import 'package:manong_application/widgets/icon_card.dart';
import 'package:manong_application/widgets/modal_icon_overlay.dart';
import 'package:manong_application/widgets/rounded_draggable_sheet.dart';

class BottomNavSwipe extends StatefulWidget {
  final PageController pageController;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onItemTapped;
  final List<Widget> pages;
  final ServiceRequest? serviceRequest;
  final String? serviceRequestMessage;
  final VoidCallback? onTapContainer;
  final bool? manongArrived;
  final bool? isManong;
  final ServiceRequestStatus? serviceRequestStatus;
  final bool? serviceRequestIsExpired;
  final AppUser? user;
  final VoidCallback? onTapCompleteProfile;
  final bool? hasNoFeedback;
  final BottomNavProvider? navProvider;

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
    this.isManong,
    this.serviceRequestStatus,
    this.serviceRequestIsExpired,
    this.user,
    this.onTapCompleteProfile,
    this.hasNoFeedback,
    this.navProvider,
  });

  @override
  State<BottomNavSwipe> createState() => _BottomNavSwipeState();
}

class _BottomNavSwipeState extends State<BottomNavSwipe> {
  bool _accountStatusDialogShown = false;
  final TextEditingController _commentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  int _commentCount = 0;
  String? _error;
  late bool? _hasNoFeedback;

  @override
  void initState() {
    super.initState();
    _hasNoFeedback = widget.hasNoFeedback;
  }

  @override
  void didUpdateWidget(covariant BottomNavSwipe oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user?.status != widget.user?.status) {
      debugPrint(
        'User status changed from ${oldWidget.user?.status} to ${widget.user?.status}. Resetting dialog flag.',
      );
      _accountStatusDialogShown = false;
    }

    if (oldWidget.hasNoFeedback != widget.hasNoFeedback) {
      setState(() {
        _hasNoFeedback = widget.hasNoFeedback;
      });
    }
  }

  void _setHasSeenVerificationCongrats() async {
    try {
      await AuthService().updateProfile(hasSeenVerificationCongrats: true);
    } catch (e) {
      logger.severe('Error hasSeenVerificationCongrats');
    }
  }

  Widget _buildLeaveReviewContainer() {
    if (_hasNoFeedback == false || _hasNoFeedback == null) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 100),
          child: InkWell(
            onTap: () => FeedbackUtils().leaveAReviewDialog(
              context: context,
              formKey: _formKey,
              commentController: _commentController,
              commentCount: _commentCount,
              serviceRequest: widget.user!.userRequests![0],
              navProvider: widget.navProvider,
            ), // Optional: show full review dialog
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColorScheme.primaryLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColorScheme.primaryColor),
                    ),
                    child: Image.asset('assets/icon/manong_review_icon.png'),
                  ),

                  const SizedBox(width: 12),

                  // Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'Leave a review',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Help others by giving feedback to your Manong',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColorScheme.deepTeal,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 20,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeaveReviewDraggableContainer() {
    if (_hasNoFeedback == false || _hasNoFeedback == null) {
      return const SizedBox.shrink();
    }

    return RoundedDraggableSheet(
      initialChildSize: 0.15,
      maxChildSize: 0.15,
      minChildSize: 0,
      snapSizes: [0.05, 0.15],
      color: AppColorScheme.primaryLight,
      children: [
        InkWell(
          onTap: () => FeedbackUtils().leaveAReviewDialog(
            context: context,
            formKey: _formKey,
            commentController: _commentController,
            commentCount: _commentCount,
            serviceRequest: widget.user!.userRequests![0],
            navProvider: widget.navProvider,
          ), // Optional: show full review dialog
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColorScheme.primaryColor),
                  ),
                  child: Image.asset('assets/icon/manong_review_icon.png'),
                ),

                const SizedBox(width: 12),

                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Leave a review',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Help others by giving feedback to your Manong',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColorScheme.deepTeal,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                const Icon(
                  Icons.arrow_forward_ios,
                  size: 20,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountStatus() {
    if (widget.user == null) return const SizedBox.shrink();

    if (widget.user?.status == AccountStatus.pending) {
      debugPrint('Pending account');
      return RoundedDraggableSheet(
        children: [
          AnimatedStackProgressBar(
            percent: 0.7,
            fillColor: AppColorScheme.primaryColor,
            trackColor: AppColorScheme.primaryLight,
            percentTextStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColorScheme.deepTeal,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Complete your profile to start requesting services.',
            style: const TextStyle(
              color: AppColorScheme.deepTeal,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColorScheme.primaryDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  onPressed: widget.onTapCompleteProfile,
                  child: const Text('Set up'),
                ),
              ),
            ],
          ),
        ],
      );
    }

    final AccountStatus? status = widget.user?.status;
    final bool shouldShowVerificationDialog =
        status == AccountStatus.onHold || status == AccountStatus.verified;

    if (shouldShowVerificationDialog && !_accountStatusDialogShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _accountStatusDialogShown = true;
          });
        }

        String? description;
        IconData? icon;

        if (status == AccountStatus.onHold) {
          description =
              'Your account is still under verification. You’ll be able to access service requests once it’s verified.';
          icon = Icons.hourglass_empty;
        } else {
          if (widget.user?.hasSeenVerificationCongrats == false) {
            description =
                'Your account has been successfully verified! You can now access all services.';
            icon = Icons.check_circle_outline;

            _setHasSeenVerificationCongrats();
          }
        }

        if (description != null && icon != null) {
          showDialog(
            context: navigatorKey.currentContext!,
            barrierDismissible: false,
            builder: (context) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ModalIconOverlay(
                  text: 'Okay',
                  onPressed: () => Navigator.pop(context),
                  icons: icon!,
                  description: description ?? '',
                ),
              );
            },
          );
        }
      });
    }

    return const SizedBox.shrink();
  }

  Widget _buildOngoingContainer() {
    debugPrint('_buildOngoingContainer ${(widget.isManong == null)}');

    if (widget.serviceRequest == null ||
        widget.isManong == null ||
        widget.serviceRequestStatus == ServiceRequestStatus.completed ||
        widget.serviceRequestIsExpired == true) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: const EdgeInsets.only(left: 20, right: 20, bottom: 100),
          child: InkWell(
            onTap: widget.onTapContainer,
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
                          widget.manongArrived != null &&
                                  widget.manongArrived == true
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
                                widget.manongArrived == true
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
                            (widget.serviceRequest?.serviceItem?.iconColor !=
                                null)
                            ? colorFromHex(
                                widget.serviceRequest!.serviceItem!.iconColor,
                              )
                            : Colors.blue,
                        iconName:
                            widget.serviceRequest?.serviceItem?.iconName ?? '',
                        iconTextColor:
                            (widget
                                    .serviceRequest
                                    ?.serviceItem
                                    ?.iconTextColor !=
                                null)
                            ? colorFromHex(
                                widget
                                    .serviceRequest!
                                    .serviceItem!
                                    .iconTextColor,
                              )
                            : Colors.blue,
                      ),

                      const SizedBox(width: 12),

                      // Text content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.serviceRequest?.subServiceItem?.title ??
                                  '',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              (widget.manongArrived == true)
                                  ? (widget.isManong == true
                                        ? 'Reached destination'
                                        : 'Your Manong has arrived 🙌')
                                  : widget.serviceRequestMessage ?? '',
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
    final bool isActive = widget.currentIndex == index;

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
                  controller: widget.pageController,
                  onPageChanged: widget.onPageChanged,
                  children: widget.pages,
                ),
              ),
            ],
          ),

          _buildAccountStatus(),

          // Ongoing service container overlay
          _buildOngoingContainer(),

          _buildLeaveReviewDraggableContainer(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColorScheme.backgroundGrey,
        selectedItemColor: AppColorScheme.primaryColor,
        unselectedItemColor: Colors.grey,
        currentIndex: widget.currentIndex,
        onTap: widget.onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: [
          _buildNavItem(Icons.home, 'Home', 0),
          _buildNavItem(Icons.assignment, 'My Requests', 1),
          _buildNavItem(Icons.person, 'Settings', 2),
          if (widget.user?.role == UserRole.manong)
            _buildNavItem(Icons.wallet, 'Wallet', 3),
        ],
      ),
    );
  }
}
