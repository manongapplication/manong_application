import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iconify_design/iconify_design.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/api/service_request_api_service.dart';
import 'package:manong_application/api/service_settings_api_service.dart';
import 'package:manong_application/api/tracking_api_service.dart';
import 'package:manong_application/main.dart';
import 'package:manong_application/models/manong.dart';
import 'package:manong_application/models/manong_report.dart';
import 'package:manong_application/models/payment_status.dart';
import 'package:manong_application/models/refund_request.dart';
import 'package:manong_application/models/service_request_status.dart';
import 'package:manong_application/models/service_request.dart';
import 'package:manong_application/models/service_settings.dart';
import 'package:manong_application/screens/service_requests/route_tracking_screen.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:manong_application/utils/calculation_totals.dart';
import 'package:manong_application/utils/color_utils.dart';
import 'package:manong_application/utils/dialog_utils.dart';
import 'package:manong_application/utils/distance_matrix.dart';
import 'package:manong_application/utils/manong_report_utils.dart';
import 'package:manong_application/utils/notification_utils.dart';
import 'package:manong_application/utils/refund_utils.dart';
import 'package:manong_application/utils/snackbar_utils.dart';
import 'package:manong_application/utils/status_utils.dart';
import 'package:manong_application/widgets/card_container.dart';
import 'package:manong_application/widgets/chat_widget.dart';
import 'package:manong_application/widgets/detailed_manong_report_card.dart';
import 'package:manong_application/widgets/disclaimer_dialog.dart';
import 'package:manong_application/widgets/error_state_widget.dart';
import 'package:manong_application/widgets/label_value_row.dart';
import 'package:manong_application/widgets/price_tag.dart';
import 'package:manong_application/widgets/refund_dialog.dart';
import 'package:manong_application/widgets/transaction_list.dart';

class ServiceRequestsDetailsScreen extends StatefulWidget {
  final ServiceRequest? serviceRequest;
  final bool? isManong;
  final bool? goToChat;

  const ServiceRequestsDetailsScreen({
    super.key,
    this.serviceRequest,
    this.isManong,
    this.goToChat,
  });

  @override
  State<ServiceRequestsDetailsScreen> createState() =>
      _ServiceRequestsDetailsScreenState();
}

class _ServiceRequestsDetailsScreenState
    extends State<ServiceRequestsDetailsScreen>
    with TickerProviderStateMixin {
  final Logger logger = Logger('ServiceRequestsDetailsScreen');
  final _trackingApiService = TrackingApiService();
  late bool? _isManong;
  late bool? _goToChat;
  final distance = latlong.Distance();
  final storage = FlutterSecureStorage();
  bool checked = false;
  bool _isLoading = false;
  bool _isButtonLoading = false;
  String? _error;
  ServiceRequest? _serviceRequest;
  bool _isEditingPaymentStatus = false;
  final baseImageUrl = dotenv.env['APP_URL'];
  bool _isServiceCompleted = false;
  ServiceSettings? _serviceSettings;
  Manong? _manong;
  bool _showFullReason = false;
  bool _showChat = false;
  bool _isKeyboardVisible = false;

  late double _sheetHeight = 0.45; // Track current sheet height
  late bool _isSheetExpanded = false;
  late bool _isMapDragging = false;
  late DraggableScrollableController _draggableController;
  double _dragStartPosition = 0;

  late AnimationController _chatAnimationController;
  late Animation<double> _chatScaleAnimation;
  late Animation<Offset> _chatSlideAnimation;
  bool _isChatAnimating = false;

  @override
  void initState() {
    super.initState();
    _initializeComponents();
    _fetchServiceRequest().then((_) {
      if (_goToChat == true && _serviceRequest != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _goToChatFunction();
        });
      }
    });

    _getTrackingStream();
    _fetchServiceSettings();
    _setupChatAnimationController();
  }

  void _setupChatAnimationController() {
    // Initialize animation controller
    _chatAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Scale animation for the FAB
    _chatScaleAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(
        parent: _chatAnimationController,
        curve: Curves.easeOutBack,
      ),
    );

    // Slide animation for the chat panel
    _chatSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _chatAnimationController,
            curve: Curves.easeOutCubic,
          ),
        );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check if keyboard is visible using MediaQuery
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final keyboardVisible = bottomInset > 0;

    if (keyboardVisible != _isKeyboardVisible) {
      setState(() {
        _isKeyboardVisible = keyboardVisible;
      });
    }
  }

  Future<void> _manualMarkArrived() async {
    // Get current distance
    final currentDistance = _trackingApiService.distanceNotifier.value;

    // Check if distance is available and within threshold
    if (currentDistance == null) {
      SnackBarUtils.showError(
        context,
        'Unable to detect your location. Please make sure GPS is enabled.',
      );
      return;
    }

    // If too far, show dialog
    if (currentDistance > 100) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Too Far from Location'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You are currently ${currentDistance.round()}m away from the customer\'s location.',
              ),
              const SizedBox(height: 12),
              const Text(
                'Please move closer to the pin on the map before confirming arrival.',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // If within 100m, proceed with confirmation
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Arrival'),
        content: Text(
          'You are ${currentDistance.round()}m away from the location.\n\n'
          'Are you sure you have arrived?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Yes, I\'m here'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isButtonLoading = true;
    });

    try {
      final response = await ServiceRequestApiService().markServiceAsArrived(
        _serviceRequest!.id!,
      );

      if (response != null && response['success'] == true) {
        setState(() {
          _serviceRequest = _serviceRequest?.copyWith(
            arrivedAt: DateTime.now(),
          );
        });

        SnackBarUtils.showSuccess(
          context,
          'Arrival confirmed! You can now complete the service.',
        );
      } else {
        SnackBarUtils.showError(
          context,
          response?['message'] ?? 'Failed to mark arrival',
        );
      }
    } catch (e) {
      SnackBarUtils.showError(
        context,
        'Failed to mark arrival. Please try again.',
      );
    } finally {
      setState(() {
        _isButtonLoading = false;
      });
    }
  }

  void _toggleChat() {
    if (_isChatAnimating) return;

    setState(() {
      _isChatAnimating = true;
    });

    if (_showChat) {
      FocusScope.of(context).unfocus();
      // Start both operations simultaneously
      Future.wait([
        // Refresh messages in background
        _refreshMessageCountSilently(),
        // Start closing animation
        _chatAnimationController.reverse(),
      ]).then((_) {
        if (mounted) {
          setState(() {
            _showChat = false;
            _isChatAnimating = false;
          });
        }
      });
    } else {
      setState(() {
        _showChat = true;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _chatAnimationController.forward().then((_) {
          if (mounted) {
            setState(() {
              _isChatAnimating = false;
            });
          }
        });
      });
    }
  }

  Future<void> _refreshMessageCountSilently() async {
    if (_serviceRequest?.id == null) return;

    try {
      final updatedRequest = await ServiceRequestApiService()
          .fetchServiceRequest(_serviceRequest!.id!);

      if (updatedRequest != null && mounted) {
        // Update without triggering a rebuild until animation completes
        _serviceRequest = updatedRequest;
      }
    } catch (e) {
      logger.warning('Failed to refresh message count: $e');
    }
  }

  void _onMapDragStart(PointerMoveEvent event) {
    // Only trigger if this is the first move after a drag start
    if (_dragStartPosition == 0) {
      _dragStartPosition = event.position.dy;
      return;
    }

    // Check if there's significant movement (actual dragging)
    double delta = (event.position.dy - _dragStartPosition).abs();

    if (delta > 10 && !_isMapDragging && !_isSheetExpanded) {
      setState(() {
        _isMapDragging = true;
      });

      _draggableController.animateTo(
        0.15, // minChildSize
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );

      // Reset the flag after animation completes
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _isMapDragging = false;
            _dragStartPosition = 0;
          });
        }
      });
    }
  }

  void _initializeComponents() {
    _draggableController = DraggableScrollableController();
    _isManong = widget.isManong;
    _goToChat = widget.goToChat;
  }

  Future<void> _fetchServiceRequest() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final serviceRequestId = widget.serviceRequest?.id;
      if (serviceRequestId == null) {
        throw Exception('Service request ID is null');
      }

      final response = await ServiceRequestApiService().fetchServiceRequest(
        serviceRequestId,
      );

      logger.info('Response ${response?.manongReport}');

      if (!mounted) return;
      setState(() {
        _serviceRequest = response;
        _manong = _serviceRequest?.manong;
      });

      logger.info('Working $_serviceRequest');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });

      logger.severe('Error fetching user service request $_error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchServiceSettings() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await ServiceSettingsApiService().fetchServiceSettings();

      if (response != null) {
        _serviceSettings = response;
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });

      logger.severe('Error to fetch Service Settings $_error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildUploadedPhotos() {
    final images = _serviceRequest?.images;
    if (images == null || images.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Images',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColorScheme.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SingleChildScrollView(
                  controller: ScrollController(),
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: images.expand((file) {
                      final cleanedPaths = file.path
                          .replaceAll(RegExp(r'[\[\]"]'), '')
                          .replaceAll("\\", "/")
                          .replaceAll("//", "/")
                          .split(',');

                      return cleanedPaths.map((path) {
                        final imageUrl = baseImageUrl != null
                            ? '$baseImageUrl/$path'
                            : '';
                        return Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              onTap: () {
                                if (imageUrl.isNotEmpty) {
                                  showImageDialog(
                                    navigatorKey.currentContext!,
                                    imageUrl,
                                  );
                                }
                              },
                              child: imageUrl.isNotEmpty
                                  ? Image.network(
                                      imageUrl,
                                      errorBuilder: (_, _, _) =>
                                          const Icon(Icons.broken_image),
                                      height: 150,
                                      width: 100,
                                    )
                                  : const Icon(Icons.broken_image, size: 100),
                            ),
                          ),
                        );
                      });
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaxes(double meters) {
    return Column(
      children: [
        LabelValueRow(
          label:
              'Service Tax (${(_serviceSettings!.serviceTax * 100).toStringAsFixed(0)})',
          valueWidget: PriceTag(
            price: double.parse(
              CalculationTotals()
                  .calculateServiceTaxAmount(
                    _serviceRequest,
                    _serviceSettings?.serviceTax ?? 0,
                  )
                  .toStringAsFixed(2),
            ),
          ),
        ),
        LabelValueRow(
          label: 'Distance Fee:',
          valueWidget: PriceTag(
            price: CalculationTotals().distanceFee(
              meters: meters,
              ratePerKm: _serviceRequest!.serviceItem!.ratePerKm,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTotals(double meters) {
    if (_serviceRequest == null || _serviceSettings == null) {
      return const SizedBox.shrink();
    }

    final serviceName =
        _serviceRequest!.otherServiceName.toString().trim().isNotEmpty &&
            _serviceRequest!.otherServiceName != null
        ? _serviceRequest?.otherServiceName
        : _serviceRequest?.subServiceItem?.title;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Service Row
          _buildTotalRow(
            label: 'Service',
            value: serviceName ?? '',
            isBold: false,
          ),

          const SizedBox(height: 12),

          // Payment Method Row
          _buildTotalRow(
            label: 'Payment',
            value: _serviceRequest?.paymentMethod?.name ?? '',
            isBold: false,
          ),

          const SizedBox(height: 12),

          // Divider
          Container(height: 1, color: Colors.grey.shade200),

          const SizedBox(height: 12),

          // Base Fee Row
          if (_serviceRequest?.subServiceItem?.fee != null)
            _buildTotalRow(
              label: 'Base Fee',
              valueWidget: PriceTag(
                price: _serviceRequest!.subServiceItem!.fee!.toDouble(),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.black87,
                ),
              ),
            ),

          if (_serviceRequest?.subServiceItem?.fee != null)
            const SizedBox(height: 8),

          // Urgency Fee Row
          if (_serviceRequest?.urgencyLevel?.level != null)
            _buildTotalRow(
              label: 'Urgency Fee',
              valueWidget: PriceTag(
                price: _serviceRequest!.urgencyLevel!.price!.toDouble(),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.black87,
                ),
              ),
            ),

          if (_serviceRequest?.urgencyLevel?.level != null)
            const SizedBox(height: 8),

          // Tax Row (if exists)
          if (_serviceSettings != null) ...[
            _buildTotalRow(
              label:
                  'Service Tax (${(_serviceSettings!.serviceTax * 100).toStringAsFixed(0)}%)',
              valueWidget: PriceTag(
                price: double.parse(
                  CalculationTotals()
                      .calculateServiceTaxAmount(
                        _serviceRequest,
                        _serviceSettings?.serviceTax ?? 0,
                      )
                      .toStringAsFixed(2),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Distance Fee Row
          _buildTotalRow(
            label: 'Distance Fee',
            valueWidget: PriceTag(
              price: CalculationTotals().distanceFee(
                meters: meters,
                ratePerKm: _serviceRequest!.serviceItem!.ratePerKm,
              ),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.black87,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Divider
          Container(height: 1, color: Colors.grey.shade200),

          const SizedBox(height: 12),

          // Subtotal Row
          _buildTotalRow(
            label: 'Subtotal',
            valueWidget: PriceTag(
              price: CalculationTotals().calculateSubTotal(_serviceRequest),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Divider
          Container(height: 1, color: Colors.grey.shade200),

          const SizedBox(height: 12),

          // Total Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColorScheme.primaryDark,
                ),
              ),
              PriceTag(
                price: CalculationTotals().calculateTotal(
                  _serviceRequest,
                  meters,
                  _serviceSettings?.serviceTax,
                ),
                textStyle: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColorScheme.primaryColor,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper method for consistent row styling
  Widget _buildTotalRow({
    required String label,
    String? value,
    Widget? valueWidget,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w500 : FontWeight.w400,
            color: Colors.grey.shade700,
          ),
        ),
        valueWidget ??
            Text(
              value ?? '',
              style: TextStyle(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
                color: Colors.black87,
              ),
            ),
      ],
    );
  }

  Widget _buildStarRatings() {
    return Row(
      children: List.generate(5, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: GestureDetector(
            onTap: null,
            child: Icon(
              index < (_serviceRequest?.feedback?.rating ?? 0)
                  ? Icons.star
                  : Icons.star_border,
              color: AppColorScheme.gold,
              size: 22,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildFeedbackDetails() {
    if (_serviceRequest?.feedback == null) return const SizedBox.shrink();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Feedback',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),

          CardContainer(
            padding: const EdgeInsets.all(12),
            borderRadius: BorderRadius.circular(12),
            color: AppColorScheme.backgroundGrey,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(_serviceRequest?.user?.firstName ?? ''),
                  _buildStarRatings(),
                  if (_serviceRequest?.feedback?.comment != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: SelectableText(
                        _serviceRequest?.feedback?.comment ?? '',
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _updateManong(ManongReport details) async {
    setState(() {
      _isButtonLoading = true;
      _error = null;
    });
    try {
      if (_serviceRequest?.manongReport == null) return;
      final response = await ManongReportUtils().update(
        id: _serviceRequest!.manongReport!.id,
        details: details,
      );

      if (response != null) {
        if (response['success'] == true) {
          SnackBarUtils.showSuccess(
            navigatorKey.currentContext!,
            response['message'],
          );
          _fetchServiceRequest();
        } else {
          SnackBarUtils.showWarning(
            navigatorKey.currentContext!,
            response['message'],
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
      logger.severe('Error updating manong $_error');
    } finally {
      if (mounted) {
        setState(() {
          _isButtonLoading = false;
        });
      }
    }
  }

  void _copyToClipboard(String? text) {
    final value = text ?? 'N/A';
    if (value.isNotEmpty && value != 'N/A') {
      Clipboard.setData(ClipboardData(text: value));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Copied: $value'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildUserDetails(double meters) {
    if (_serviceRequest!.user == null || _serviceRequest == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_serviceRequest?.manongReport != null) ...[
          Stack(
            children: [
              DetailedManongReportCard(
                report: _serviceRequest!.manongReport!,
                isManong: _isManong ?? false,
                onSave: (report) {
                  _updateManong(report);
                },
              ),
              if (_isButtonLoading == true) ...[
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white.withOpacity(0.8),
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColorScheme.primaryColor,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],

        const SizedBox(height: 16),

        // Request Number Section - iPhone style
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200, width: 0.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.receipt_outlined,
                    size: 16,
                    color: AppColorScheme.primaryColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'REQUEST NUMBER',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade500,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () =>
                        _copyToClipboard(_serviceRequest?.requestNumber),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColorScheme.primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.copy,
                        size: 14,
                        color: AppColorScheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _copyToClipboard(_serviceRequest?.requestNumber),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColorScheme.primaryColor.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SelectableText(
                    _serviceRequest?.requestNumber ?? 'N/A',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColorScheme.primaryDark,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Customer Info Card - iPhone style
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200, width: 0.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.person_outline_rounded,
                    size: 16,
                    color: AppColorScheme.primaryColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'CUSTOMER INFORMATION',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade500,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Name
              if (_serviceRequest?.user?.firstName != null &&
                  _serviceRequest?.user?.lastName != null) ...[
                _buildInfoRow(
                  icon: Icons.badge_outlined,
                  label: 'Name',
                  value:
                      '${_serviceRequest!.user!.firstName} ${_serviceRequest!.user!.lastName}',
                ),
                const SizedBox(height: 12),
              ],

              // Nickname
              if (_serviceRequest?.user?.nickname != null) ...[
                _buildInfoRow(
                  icon: Icons.alternate_email_rounded,
                  label: 'Nickname',
                  value: _serviceRequest!.user!.nickname!,
                ),
                const SizedBox(height: 12),
              ],

              // Contact
              _buildInfoRow(
                icon: Icons.phone_outlined,
                label: 'Contact',
                value: _serviceRequest!.user?.phone ?? 'No contact',
                canCopy: true,
                onCopy: () => _copyToClipboard(_serviceRequest!.user?.phone),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Status Card - iPhone style
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200, width: 0.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: AppColorScheme.primaryColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'STATUS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade500,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Payment Status
              if (_serviceRequest?.paymentStatus != null) ...[
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: getStatusColor(
                          _serviceRequest!.paymentStatus!.name,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.payments_outlined,
                        size: 16,
                        color: getStatusBorderColor(
                          _serviceRequest!.paymentStatus!.name,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment Status',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: getStatusColor(
                                _serviceRequest!.paymentStatus!.name,
                              ).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _serviceRequest!.paymentStatus!.name
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
                                  _serviceRequest!.paymentStatus!.name,
                                ),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // Request Status
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: getStatusColor(
                        _serviceRequest!.status!.value,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.pending_outlined,
                      size: 16,
                      color: getStatusBorderColor(
                        _serviceRequest!.status!.value,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Request Status',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: getStatusColor(
                              _serviceRequest!.status!.value,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            getStatusText(_serviceRequest!.status!.value),
                            style: TextStyle(
                              fontSize: 11,
                              color: getStatusBorderColor(
                                _serviceRequest!.status!.value,
                              ),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Payment Method
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColorScheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.credit_card_outlined,
                      size: 16,
                      color: AppColorScheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment Method',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _serviceRequest?.paymentMethod?.name ??
                              'Not specified',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColorScheme.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Service Details Card - iPhone style
        if (_serviceRequest?.otherServiceName != null ||
            _serviceRequest?.subServiceItem?.title != null ||
            (_serviceRequest?.serviceDetails?.isNotEmpty == true) ||
            (_serviceRequest?.notes?.isNotEmpty == true)) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200, width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      Icons.build_outlined,
                      size: 16,
                      color: AppColorScheme.primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'SERVICE DETAILS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade500,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Service Name
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Service',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColorScheme.primaryColor.withOpacity(
                                0.08,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _serviceRequest?.otherServiceName?.isNotEmpty ==
                                      true
                                  ? _serviceRequest!.otherServiceName!
                                  : _serviceRequest?.subServiceItem?.title ??
                                        'Service',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColorScheme.primaryDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (_serviceRequest?.serviceDetails?.isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  _buildExpandableSection(
                    icon: Icons.description_outlined,
                    label: 'Service Details',
                    content: _serviceRequest!.serviceDetails!,
                  ),
                ],

                if (_serviceRequest?.notes?.isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  _buildExpandableSection(
                    icon: Icons.note_outlined,
                    label: 'Notes',
                    content: _serviceRequest!.notes!,
                  ),
                ],
              ],
            ),
          ),
        ],

        // Images Section
        _buildUploadedPhotos(),

        const SizedBox(height: 16),

        // Totals Card
        _buildTotals(meters),

        const SizedBox(height: 20),

        // Payment History
        TransactionList(
          transactions: _serviceRequest?.paymentTransactions ?? [],
          title: 'Payment History',
        ),

        const SizedBox(height: 20),

        // Feedback
        _buildFeedbackDetails(),

        const SizedBox(height: 56),
      ],
    );
  }

  // Helper method for info rows
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool canCopy = false,
    VoidCallback? onCopy,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColorScheme.primaryColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppColorScheme.primaryColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      value,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColorScheme.primaryDark,
                      ),
                    ),
                  ),
                  if (canCopy && onCopy != null)
                    GestureDetector(
                      onTap: onCopy,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.copy,
                          size: 14,
                          color: AppColorScheme.primaryColor,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper method for expandable sections
  Widget _buildExpandableSection({
    required IconData icon,
    required String label,
    required String content,
  }) {
    final ValueNotifier<bool> isExpanded = ValueNotifier(false);
    final bool isLong = content.length > 100;

    return ValueListenableBuilder<bool>(
      valueListenable: isExpanded,
      builder: (context, expanded, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColorScheme.primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 16,
                    color: AppColorScheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        expanded ? content : _truncateContent(content),
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColorScheme.primaryDark,
                          height: 1.4,
                        ),
                      ),
                      if (isLong)
                        GestureDetector(
                          onTap: () => isExpanded.value = !expanded,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  expanded ? 'Show less' : 'Show more',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColorScheme.primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  expanded
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  size: 16,
                                  color: AppColorScheme.primaryColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  String _truncateContent(String content) {
    if (content.length <= 100) return content;
    return '${content.substring(0, 97)}...';
  }

  void _toggleIsEditingPaymentStatus() {
    setState(() {
      _isEditingPaymentStatus = !_isEditingPaymentStatus;
    });
  }

  Widget _buildManongDetails(double meters) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // -- Manong Name
        Text(
          "Name",
          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 4),

        Wrap(
          children: [
            Text(
              _manong?.appUser.firstName ?? "No name",
              style: TextStyle(fontSize: 18, color: Colors.black),
            ),
            if (_manong?.profile!.isProfessionallyVerified == true) ...[
              const SizedBox(width: 4),
              Icon(Icons.verified_rounded, size: 20, color: Colors.lightBlue),
            ],
          ],
        ),
        const SizedBox(height: 8),

        // -- Status
        Text(
          "Status",
          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
        ),
        SizedBox(height: 4),
        Wrap(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: getStatusColor(
                  _manong?.profile?.status.name,
                ).withOpacity(0.1),
                border: Border.all(
                  color: getStatusBorderColor(_manong?.profile?.status.name),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Text(
                _manong?.profile?.status.name ?? '',
                style: TextStyle(
                  fontSize: 11,
                  color: getStatusBorderColor(_manong!.profile!.status.name),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (_manong?.profile?.specialities != null &&
            _manong!.profile!.specialities!.isNotEmpty) ...[
          // -- Specialities
          Text(
            "Specialities",
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
          SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              // Show first 5 specialities
              ..._manong!.profile!.specialities!.take(5).map((item) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        item.subServiceItem.title.contains(
                          _serviceRequest!.subServiceItem!.title,
                        )
                        ? Colors.amber.withOpacity(0.7)
                        : AppColorScheme.primaryColor.withOpacity(0.1),
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
                      Text(
                        item.subServiceItem.title,
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ],
                  ),
                );
              }),

              // Show more button if there are more than 5 specialities
              if (_manong!.profile!.specialities!.length > 5)
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
                          final remaining = _manong!.profile!.specialities!
                              .skip(5)
                              .toList();

                          return SafeArea(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              width: double.infinity,
                              child: Scrollbar(
                                thumbVisibility: true,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                                        _serviceRequest
                                                                ?.subServiceItem
                                                                ?.title ??
                                                            "",
                                                      )
                                                  ? Colors.amber.withOpacity(
                                                      0.7,
                                                    )
                                                  : AppColorScheme.primaryColor
                                                        .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconifyIcon(
                                                  icon: item
                                                      .subServiceItem
                                                      .iconName,
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
                      "+${_manong!.profile!.specialities!.length - 5} show more",
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ),
                ),
            ],
          ),
        ],

        const SizedBox(height: 8),

        // -- Assistants
        if (_manong?.profile?.manongAssistants != null) ...[
          if (_manong!.profile!.manongAssistants!.isNotEmpty) ...[
            Text(
              "Assistant(s)",
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
            Wrap(
              spacing: 6,
              runSpacing: 2,
              children: _manong!.profile!.manongAssistants!.map((assistant) {
                return Chip(
                  avatar: Icon(
                    Icons.person,
                    size: 16,
                    color: AppColorScheme.primaryDark,
                  ),
                  label: Text(
                    assistant.fullName.trim(),
                    style: TextStyle(color: AppColorScheme.primaryDark),
                  ),
                  backgroundColor: AppColorScheme.primaryLight,
                );
              }).toList(),
            ),
          ],
        ],

        const Divider(),

        _buildUserDetails(meters),
      ],
    );
  }

  void _acceptServiceRequest() async {
    setState(() {
      _isButtonLoading = true;
      _error = null;
    });
    try {
      if (_serviceRequest == null || _serviceRequest!.status == null) {
        logger.warning(
          'Cannot accept service request: missing status or user FCM token.',
        );
        return;
      }
      final response = await ServiceRequestApiService().acceptServiceRequest(
        _serviceRequest!.id!,
      );

      final parsedStatus = parseRequestStatus(_serviceRequest!.status!.value);

      if (parsedStatus != null && _serviceRequest != null) {
        await NotificationUtils.sendStatusUpdateNotification(
          status: parsedStatus,
          token: _serviceRequest?.user?.fcmToken ?? '',
          serviceRequestId: _serviceRequest?.id.toString(),
          userId: _serviceRequest!.userId!,
        );
      }

      setState(() {
        _error = null;
      });

      if (response != null) {
        if (response['data'] != null) {
          final sr = ServiceRequest.fromJson(response['data']);
          SnackBarUtils.showInfo(
            navigatorKey.currentContext!,
            'Service Request ${sr.status}',
          );
          if (sr.status != _serviceRequest?.status) {
            Navigator.pop(navigatorKey.currentContext!, {
              'updated': true,
              'status': sr.status,
            });
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
      logger.severe('Error accepting service request $_error');
    } finally {
      if (mounted) {
        setState(() {
          _isButtonLoading = false;
        });
      }
    }
  }

  void _markServiceRequestCompleted() async {
    if (_serviceRequest == null) return;
    final result = await ManongReportUtils().showManongReport(
      navigatorKey.currentContext!,
      serviceRequest: _serviceRequest!,
    );

    if (result != null && result is Map) {
      if (result['success'] != true) {
        return;
      }
    } else {
      return;
    }

    setState(() {
      _isButtonLoading = true;
      _error = null;
    });
    try {
      if (_serviceRequest == null) return;
      final response = await ServiceRequestApiService()
          .markServiceRequestCompleted(_serviceRequest!.id!);

      if (response != null) {
        if (response['success'] == true) {
          SnackBarUtils.showSuccess(
            navigatorKey.currentContext!,
            'Service request marked as completed!',
          );

          setState(() {
            _isServiceCompleted = true;
          });

          Navigator.of(navigatorKey.currentContext!).pushNamedAndRemoveUntil(
            '/',
            (route) => false,
            arguments: {
              'index': 1,
              'serviceRequestStatusIndex': getTabIndex(
                ServiceRequestStatus.completed,
              ),
            },
          );
        } else {
          SnackBarUtils.showWarning(
            navigatorKey.currentContext!,
            response['message'] ??
                'Failed marking service request as completed.',
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
      logger.severe('Error updating service request $_error');
    } finally {
      if (mounted) {
        setState(() {
          _isButtonLoading = false;
        });
      }
    }
  }

  Future<void> _markAsPaid() async {
    if (_serviceRequest == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Paid'),
        content: const Text(
          'Did you receive cash payment from the customer?\n\n'
          'This will update the payment status to "paid".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _confirmMarkAsPaid();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text(
              'Yes, Mark as Paid',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmMarkAsPaid() async {
    if (_serviceRequest == null) return;

    setState(() {
      _isButtonLoading = true;
    });

    try {
      final response = await ServiceRequestApiService().markServiceAsPaid(
        _serviceRequest!.id!,
      );

      if (response?['success'] == true) {
        SnackBarUtils.showSuccess(
          navigatorKey.currentContext!,
          response?['message'] ?? 'Service marked as paid!',
        );

        // Refresh the service request data
        await _fetchServiceRequest();

        // Update UI
        if (mounted) {
          setState(() {
            // The status will be updated from _fetchServiceRequest
          });
        }
      } else {
        SnackBarUtils.showError(
          navigatorKey.currentContext!,
          response?['message'] ?? 'Failed to mark as paid',
        );
      }
    } catch (e) {
      SnackBarUtils.showError(
        navigatorKey.currentContext!,
        'Failed to mark as paid. Please try again.',
      );
      logger.severe('Error marking as paid: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isButtonLoading = false;
        });
      }
    }
  }

  Widget _buildDistanceRow() {
    if (_serviceRequest?.status != 'inProgress') return const SizedBox.shrink();
    return ValueListenableBuilder<latlong.LatLng?>(
      valueListenable: _trackingApiService.manongLatLngNotifier,
      builder: (context, value, child) {
        final meters = DistanceMatrix().calculateDistance(
          startLat: widget.serviceRequest?.customerLat,
          startLng: widget.serviceRequest?.customerLng,
          endLat: value?.latitude ?? 0,
          endLng: value?.longitude ?? 0,
        );

        return Row(
          children: [
            SizedBox(width: 10),
            Text(
              DistanceMatrix().estimateTime(meters ?? 0),
              style: TextStyle(fontSize: 18, color: Colors.red.shade700),
            ),
            SizedBox(width: 8),
            Text(
              '(${DistanceMatrix().formatDistance(meters ?? 0)})',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
            ),
            Spacer(),
          ],
        );
      },
    );
  }

  Future<void> _cancelServiceRequest() async {
    setState(() {
      _isButtonLoading = true;
      _error = null;
    });

    try {
      if (_serviceRequest == null && _serviceRequest?.id != null) return;

      final response = await ServiceRequestApiService().cancelServiceRequest(
        _serviceRequest!.id!,
      );

      if (response != null) {
        SnackBarUtils.showInfo(
          navigatorKey.currentContext!,
          response['message'] ?? 'Cancelled Service Request.',
        );
        Navigator.of(navigatorKey.currentContext!).pushNamedAndRemoveUntil(
          '/',
          (route) => false,
          arguments: {
            'index': 1,
            'serviceRequestStatusIndex': getTabIndex(
              ServiceRequestStatus.cancelled,
            ),
          },
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
      logger.severe('Error cancelling service request $_error');
    } finally {
      if (mounted) {
        setState(() {
          _isButtonLoading = false;
        });
      }
    }
  }

  Future<void> _showDialogCancelConfirmation({bool isRefund = false}) async {
    showDialog(
      context: navigatorKey.currentContext!,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            '${isRefund ? 'Refund' : 'Cancel'} Service Request',
            style: TextStyle(fontSize: 22),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Are you sure you want to ${isRefund ? 'Refund' : 'Cancel'} this service request?',
              ),
              SizedBox(height: 8),
              Text(
                'This action cannot be undone.',
                textAlign: TextAlign.start,
                style: TextStyle(color: Colors.redAccent),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColorScheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: Text('No, keep request'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (_serviceRequest?.status == ServiceRequestStatus.pending ||
                    _serviceRequest?.status ==
                        ServiceRequestStatus.awaitingAcceptance) {
                  Future.delayed(Duration(milliseconds: 50), () {
                    RefundDialog.show(
                      navigatorKey.currentContext!,
                      request: _serviceRequest!,
                    );
                  });
                  return;
                }
                showDisclaimerDialog(
                  context,
                  title: 'Refund Policy Disclaimer',
                  message:
                      'If a customer decides to cancel the service after the professional has confirmed that the reported concern was incorrect or not valid, a ₱300 Manong Fee will be charged to cover consultation and professional fees.',
                  hasCancel: true,
                  onAgree: () {
                    Future.delayed(Duration(milliseconds: 50), () {
                      RefundDialog.show(
                        navigatorKey.currentContext!,
                        request: _serviceRequest!,
                      );
                    });
                  },
                );
                // _cancelServiceRequest();
              },
              child: Text(
                'Yes, cancel it',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _requestRefund() async {
    if (_serviceRequest == null) return;

    setState(() => _isButtonLoading = true);

    try {
      List<RefundRequest>? response = await RefundUtils().fetchRequests(
        _serviceRequest!,
      );

      if (response != null) {
        if (response.isNotEmpty) {
          SnackBarUtils.showWarning(
            navigatorKey.currentContext!,
            'You\'ve already requested a refund for this service!',
          );
        } else {
          await _showDialogCancelConfirmation(
            isRefund: _serviceRequest?.paymentStatus == PaymentStatus.paid,
          );
        }
      }
    } catch (e) {
      SnackBarUtils.showError(
        navigatorKey.currentContext!,
        'Failed to request refund. Please try again later.',
      );
    } finally {
      if (mounted) setState(() => _isButtonLoading = false);
    }
  }

  Widget _refundButton() {
    if (_isManong == true) return const SizedBox.shrink();
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _isButtonLoading ? null : () async => _requestRefund(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorScheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isButtonLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColorScheme.primaryColor,
                      ),
                    ),
                  )
                : Text(
                    _serviceRequest?.paymentStatus == PaymentStatus.paid
                        ? _serviceRequest?.refundRequests != null &&
                                  _serviceRequest!.refundRequests!.isNotEmpty
                              ? 'Refund Requested'
                              : 'Request Refund'
                        : 'Cancel',
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav(double? meters, ScrollController scrollController) {
    // Safe access to refund request
    final hasRefundRequest =
        _serviceRequest?.refundRequests != null &&
        _serviceRequest!.refundRequests!.isNotEmpty;

    final refundRequest = hasRefundRequest
        ? _serviceRequest!.refundRequests![0]
        : null;
    final refundStatus = refundRequest?.status.name;

    return Container(
      color: Colors.white,
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          // Drag handle - with minimal top padding
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 8), // Minimal top padding
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: _isSheetExpanded ? 80 : 60,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _isSheetExpanded
                        ? Colors.grey.shade300
                        : Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),

          // Add a small gap after handle
          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // Refund Requested Section (if any)
          if (hasRefundRequest) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildRefundSection(
                  refundRequest,
                  refundStatus,
                  _showFullReason,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Divider(color: Colors.grey, thickness: 1),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],

          // Main content with horizontal padding only
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildDistanceRow(),
                const SizedBox(height: 12),

                // Accept Button
                if (_serviceRequest?.status == ServiceRequestStatus.pending ||
                    _serviceRequest?.status ==
                        ServiceRequestStatus.awaitingAcceptance) ...[
                  if (_isManong == true) ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: !_isButtonLoading
                                ? _acceptServiceRequest
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColorScheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isButtonLoading
                                ? SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: AppColorScheme.primaryColor,
                                      ),
                                    ),
                                  )
                                : Text('Accept'),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    _refundButton(),
                  ],
                ],

                if (_serviceRequest?.status ==
                        ServiceRequestStatus.inProgress ||
                    _serviceRequest?.status ==
                        ServiceRequestStatus.accepted) ...[
                  _refundButton(),
                ],

                _buildStartJobBtn(),
                _buildCompleteServiceSection(),

                // Mark As Paid Button
                if (_serviceRequest?.status == ServiceRequestStatus.completed &&
                    _serviceRequest?.paymentStatus == PaymentStatus.pending &&
                    _serviceRequest?.paymentMethod?.code == 'cash' &&
                    _isManong == true) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: !_isButtonLoading ? _markAsPaid : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isButtonLoading
                              ? SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.payments, size: 20),
                                    SizedBox(width: 8),
                                    Text('Mark as Paid'),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ],

                // More details indicator
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _isSheetExpanded ? 0.0 : 1.0,
                  child: const Column(
                    children: [
                      SizedBox(height: 8),
                      Icon(Icons.keyboard_arrow_down),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // User/Manong details
                if (_isManong == true)
                  _buildUserDetails(meters ?? 0)
                else
                  _buildManongDetails(meters ?? 0),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefundSection(
    RefundRequest? refundRequest,
    String? refundStatus,
    bool showFullReason,
  ) {
    final statusColor = getStatusColor(refundStatus);
    final borderColor = getStatusBorderColor(refundStatus);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withOpacity(0.3), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  size: 18,
                  color: borderColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Refund Requested',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: AppColorScheme.primaryDark,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: borderColor.withOpacity(0.2),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  refundStatus?.toUpperCase() ?? '',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: borderColor,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Reason section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'REASON',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade500,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200, width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      refundRequest?.reason ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppColorScheme.primaryDark,
                        height: 1.4,
                      ),
                      maxLines: showFullReason ? null : 3,
                      overflow: showFullReason ? null : TextOverflow.ellipsis,
                    ),
                    if ((refundRequest?.reason.length ?? 0) > 100)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showFullReason = !_showFullReason;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                showFullReason ? 'Show less' : 'Show more',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: borderColor,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                showFullReason
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                size: 16,
                                color: borderColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          // Remarks section (if exists)
          if (refundRequest?.remarks != null &&
              refundRequest!.remarks!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'REMARKS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200, width: 0.5),
                  ),
                  child: Text(
                    refundRequest.remarks!,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColorScheme.primaryDark,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompleteServiceSection() {
    if (_serviceRequest?.status != ServiceRequestStatus.inProgress ||
        _isManong != true) {
      return const SizedBox.shrink();
    }

    final bool hasArrived = _serviceRequest?.arrivedAt != null;

    return Column(
      children: [
        const SizedBox(height: 12),
        if (!hasArrived) _buildArrivalGuidance() else _buildCompleteButton(),
        const SizedBox(height: 8),
        _buildLocationStatusIndicator(),
      ],
    );
  }

  Widget _buildArrivalGuidance() {
    // Get current distance if available
    final currentDistance = _trackingApiService.distanceNotifier.value;

    return Column(
      children: [
        _buildDestinationCard(),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200, width: 0.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header with lock icon and status - iPhone style
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColorScheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.lock_outline_rounded,
                      size: 16,
                      color: AppColorScheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Complete Button Locked',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColorScheme.primaryDark,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),

                  // Distance indicator - iPhone style pill
                  if (currentDistance != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColorScheme.primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 12,
                            color: AppColorScheme.primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${currentDistance.round()}m',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColorScheme.primaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 14),

              // Instruction - iPhone style
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.location_on,
                      size: 16,
                      color: AppColorScheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Go to customer location',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppColorScheme.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Complete button will unlock automatically',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Tips card - iPhone style
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColorScheme.primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 16,
                      color: AppColorScheme.primaryColor,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Keep app open for automatic arrival detection',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColorScheme.primaryDark,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Trouble button - iPhone style
        _buildTroubleButton(),
      ],
    );
  }

  Widget _buildDestinationCard() {
    final bool isAddressLong =
        (_serviceRequest?.customerFullAddress?.length ?? 0) > 50;
    final ValueNotifier<bool> showFullAddress = ValueNotifier(false);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColorScheme.primaryColor,
                  AppColorScheme.primaryColor.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.flag_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DESTINATION',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),

                // Address with show more/less
                ValueListenableBuilder<bool>(
                  valueListenable: showFullAddress,
                  builder: (context, expanded, child) {
                    final address =
                        _serviceRequest?.customerFullAddress ??
                        'Customer Location';

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expanded ? address : _truncateAddress(address),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: AppColorScheme.primaryDark,
                            height: 1.3,
                          ),
                        ),
                        if (isAddressLong)
                          GestureDetector(
                            onTap: () => showFullAddress.value = !expanded,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    expanded ? 'Show less' : 'Show more',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppColorScheme.primaryColor,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    expanded
                                        ? Icons.keyboard_arrow_up
                                        : Icons.keyboard_arrow_down,
                                    size: 16,
                                    color: AppColorScheme.primaryColor,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _truncateAddress(String address) {
    if (address.length <= 50) return address;
    return '${address.substring(0, 47)}...';
  }

  Widget _buildTroubleButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: _isButtonLoading ? null : _manualMarkArrived,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.help_outline,
                    size: 18,
                    color: AppColorScheme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Having trouble? Tap to confirm arrival',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppColorScheme.primaryDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompleteButton() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: !_isButtonLoading ? _markServiceRequestCompleted : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: _isButtonLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Complete Service Request',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward, size: 18),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationStatusIndicator() {
    final bool hasArrived = _serviceRequest?.arrivedAt != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasArrived
              ? AppColorScheme.primaryColor.withOpacity(0.2)
              : Colors.grey.shade200,
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Status icon with gradient background
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: hasArrived
                    ? [
                        AppColorScheme.primaryColor,
                        AppColorScheme.primaryColor.withOpacity(0.8),
                      ]
                    : [AppColorScheme.goldDeep, AppColorScheme.goldLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              hasArrived ? Icons.check_box_rounded : Icons.navigation_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),

          const SizedBox(width: 12),

          // Status text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasArrived ? 'Arrived at destination' : 'En route',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppColorScheme.primaryDark,
                    fontSize: 15,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasArrived
                      ? 'You can now complete the service'
                      : 'Heading to customer location',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          // Distance or status badge
          if (!hasArrived)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColorScheme.primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColorScheme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'ETA',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColorScheme.primaryDark,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColorScheme.primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_box_rounded,
                    size: 12,
                    color: AppColorScheme.primaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Arrived',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColorScheme.primaryDark,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _getTrackingStream() {
    if (_serviceRequest == null) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Live Location Tracking
      if (_serviceRequest?.status != 'inProgress') return;

      logger.info('Live now');

      _trackingApiService.joinRoom(
        manongId: _serviceRequest!.manongId.toString(),
        serviceRequestId: _serviceRequest!.id.toString(),
      );

      _trackingApiService.onArrivalDetected((arrivedAt) {
        if (!mounted) return;

        logger.info('✅ ARRIVAL DETECTED via WebSocket!');

        // IMPORTANT: Create a new ServiceRequest instance with arrivedAt set
        setState(() {
          _serviceRequest = _serviceRequest?.copyWith(arrivedAt: arrivedAt);
        });

        // Show success message
        SnackBarUtils.showSuccess(
          context,
          'You have arrived at the destination!',
        );

        // Haptic feedback
        HapticFeedback.heavyImpact();
      });

      if (_isManong == true) {
        logger.info('Started Tracking');
        _trackingApiService.startTracking(
          manongId: _serviceRequest!.manongId.toString(),
          serviceRequestId: _serviceRequest!.id.toString(),
          destinationLat: _serviceRequest?.customerLat,
          destinationLng: _serviceRequest?.customerLng,
        );
      }

      _trackingApiService.onLocationUpdate((data) {
        final status = data['status'];

        if (status != null && status.toLowerCase() == 'completed') {
          logger.info('Service Request is done → stopping tracking');
          _trackingApiService.stopTracking();
          return;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
      logger.severe('Error getting live location of Manong $_error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildRouteTracking() {
    final lat = _manong?.appUser.latitude ?? 0;
    final lng = _manong?.appUser.longitude ?? 0;

    return Positioned.fill(
      child: RouteTrackingScreen(
        currentLatLng: LatLng(
          _serviceRequest!.customerLat,
          _serviceRequest!.customerLng,
        ),
        manongLatLng: LatLng(lat, lng),
        manongName: _manong?.appUser.firstName,
        manongLatLngNotifier: _trackingApiService.manongLatLngNotifier,
        serviceRequest: _serviceRequest,
      ),
    );
  }

  Widget _buildStack(double meters) {
    if (_manong == null) return const SizedBox.shrink();

    return Stack(
      children: [
        // Make the map area detect drag gestures with threshold
        Listener(
          onPointerDown: (event) {
            _dragStartPosition = event.position.dy;
          },
          onPointerMove: _onMapDragStart,
          behavior: HitTestBehavior.opaque,
          child: _buildRouteTracking(),
        ),

        NotificationListener<DraggableScrollableNotification>(
          onNotification: (notification) {
            setState(() {
              _sheetHeight = notification.extent;
              _isSheetExpanded = notification.extent > 0.8;
            });
            return false;
          },
          child: DraggableScrollableSheet(
            controller: _draggableController,
            initialChildSize: 0.45,
            minChildSize: 0.15,
            maxChildSize: 0.93,
            snap: true,
            snapSizes: const [0.15, 0.45, 0.93],
            builder: (context, scrollController) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                margin: EdgeInsets.all(_isSheetExpanded ? 0 : 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(_isSheetExpanded ? 0 : 20),
                    topRight: Radius.circular(_isSheetExpanded ? 0 : 20),
                    bottomLeft: Radius.circular(_isSheetExpanded ? 0 : 20),
                    bottomRight: Radius.circular(_isSheetExpanded ? 0 : 20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(_isSheetExpanded ? 0 : 20),
                    topRight: Radius.circular(_isSheetExpanded ? 0 : 20),
                    bottomLeft: Radius.circular(_isSheetExpanded ? 0 : 20),
                    bottomRight: Radius.circular(_isSheetExpanded ? 0 : 20),
                  ),
                  child: _buildBottomNav(meters, scrollController),
                ),
              );
            },
          ),
        ),

        // Chat overlay - always in the tree but animated
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _chatAnimationController,
            builder: (context, child) {
              return Opacity(
                opacity: _chatAnimationController.value,
                child: SlideTransition(
                  position: _chatSlideAnimation,
                  child: child,
                ),
              );
            },
            child: GestureDetector(
              onTap: _toggleChat,
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: GestureDetector(
                    onTap:
                        () {}, // Prevent taps from closing when tapping on chat
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.8,
                      margin: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: ChatWidget(
                          serviceRequest: _serviceRequest!,
                          onClose: _toggleChat,
                          isFullScreen: false,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildState(double meters) {
    if (_error != null) {
      return ErrorStateWidget(errorText: _error!);
    }

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppColorScheme.primaryColor),
      );
    }

    return _buildStack(meters);
  }

  void _goToChatFunction() {
    if (_serviceRequest == null) {
      logger.warning('Service request is null, cannot navigate to chat');
      return;
    }

    Navigator.of(
      context,
    ).pushNamed('/chat-manong', arguments: {'serviceRequest': _serviceRequest});
  }

  void _startServiceRequest(ServiceRequest serviceRequest) async {
    setState(() {
      _isButtonLoading = true;
      _error = null;
    });
    try {
      if (serviceRequest.id == null) return;
      final response = await ServiceRequestApiService().startServiceRequest(
        serviceRequest.id!,
      );

      setState(() {
        _error = null;
      });

      if (response != null) {
        if (response['data'] != null) {
          final sr = ServiceRequest.fromJson(response['data']);
          SnackBarUtils.showInfo(
            navigatorKey.currentContext!,
            'Service Request ${sr.status}',
          );
          if (sr.status != serviceRequest.status) {
            Navigator.pop(navigatorKey.currentContext!, {
              'updated': true,
              'status': sr.status,
              'startJob': true,
            });
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
      logger.severe('Error accepting service request $_error');
    } finally {
      if (mounted) {
        setState(() {
          _isButtonLoading = false;
        });
      }
    }
  }

  void _onStartJob(ServiceRequest serviceRequestItem) async {
    if (_isManong == true && serviceRequestItem.userId != null) {
      _startServiceRequest(serviceRequestItem);
      await NotificationUtils.sendStatusUpdateNotification(
        status: parseRequestStatus(serviceRequestItem.status!.value)!,
        token: serviceRequestItem.user?.fcmToken ?? '',
        serviceRequestId: serviceRequestItem.id.toString(),
        userId: serviceRequestItem.userId!,
      );
    }
  }

  Widget _buildStartJobBtn() {
    if (_serviceRequest == null) return const SizedBox.shrink();

    if (_serviceRequest!.status != ServiceRequestStatus.accepted) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _isButtonLoading
                ? null
                : () async => _onStartJob(_serviceRequest!),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorScheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isButtonLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColorScheme.primaryColor,
                      ),
                    ),
                  )
                : const Text('Start Job'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_serviceRequest == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColorScheme.primaryColor),
        ),
      );
    }

    final int messagesCount = _serviceRequest?.messages != null
        ? _serviceRequest!.messages!
              .where((message) => message.seenAt == null)
              .take(10)
              .length
        : 0;
    0;

    final meters = DistanceMatrix().calculateDistance(
      startLat: widget.serviceRequest?.customerLat,
      startLng: widget.serviceRequest?.customerLng,
      endLat: _trackingApiService.manongLatLngNotifier.value?.latitude ?? 0,
      endLng: _trackingApiService.manongLatLngNotifier.value?.longitude ?? 0,
    );

    return GestureDetector(
      onTap: () => FocusScope.of(navigatorKey.currentContext!).unfocus(),
      child: Material(
        child: Scaffold(
          body: meters != null ? _buildState(meters) : null,
          floatingActionButton: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _isKeyboardVisible ? 0.0 : 1.0,
            child: _isKeyboardVisible
                ? null
                : ScaleTransition(
                    scale: _chatScaleAnimation,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        FloatingActionButton(
                          onPressed: _isChatAnimating ? null : _toggleChat,
                          tooltip: 'Chat',
                          backgroundColor: _showChat
                              ? Colors.red
                              : AppColorScheme.primaryLight,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            transitionBuilder:
                                (Widget child, Animation<double> animation) {
                                  return ScaleTransition(
                                    scale: animation,
                                    child: child,
                                  );
                                },
                            child: Icon(
                              _showChat ? Icons.close : Icons.chat,
                              key: ValueKey(_showChat),
                              color: _showChat
                                  ? Colors.white
                                  : AppColorScheme.primaryDark,
                            ),
                          ),
                        ),
                        if (messagesCount > 0 && !_showChat)
                          Positioned(
                            top: -8,
                            right: -8,
                            child: ScaleTransition(
                              scale: _chatScaleAnimation,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: const BoxDecoration(
                                  color: Colors.redAccent,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  messagesCount > 9
                                      ? '9+'
                                      : messagesCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _draggableController.dispose();
    if (_serviceRequest != null) {
      logger.info(
        'Disconnected with lat ${_trackingApiService.manongLatLngNotifier.value?.latitude} && Lng ${_trackingApiService.manongLatLngNotifier.value?.longitude}',
      );
      _trackingApiService.disconnect(
        manongId: _serviceRequest!.manongId.toString(),
        serviceRequestId: _serviceRequest!.id.toString(),
        lastKnownLat: _trackingApiService.manongLatLngNotifier.value?.latitude,
        lastKnownLng: _trackingApiService.manongLatLngNotifier.value?.longitude,
      );
    }
    super.dispose();
  }
}
