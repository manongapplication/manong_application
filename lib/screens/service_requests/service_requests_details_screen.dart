import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iconify_design/iconify_design.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/api/fcm_api_service.dart';
import 'package:manong_application/api/firebase_api_token.dart';
import 'package:manong_application/api/manong_api_service.dart';
import 'package:manong_application/api/service_request_api_service.dart';
import 'package:manong_application/api/service_settings_api_service.dart';
import 'package:manong_application/api/tracking_api_service.dart';
import 'package:manong_application/main.dart';
import 'package:manong_application/models/manong.dart';
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
import 'package:manong_application/utils/icon_mapper.dart';
import 'package:manong_application/utils/notification_utils.dart';
import 'package:manong_application/utils/snackbar_utils.dart';
import 'package:manong_application/utils/status_utils.dart';
import 'package:manong_application/widgets/card_container.dart';
import 'package:manong_application/widgets/error_state_widget.dart';
import 'package:manong_application/widgets/label_value_row.dart';
import 'package:manong_application/widgets/price_tag.dart';

class ServiceRequestsDetailsScreen extends StatefulWidget {
  final ServiceRequest? serviceRequest;
  final bool? isManong;

  const ServiceRequestsDetailsScreen({
    super.key,
    this.serviceRequest,
    this.isManong,
  });

  @override
  State<ServiceRequestsDetailsScreen> createState() =>
      _ServiceRequestsDetailsScreenState();
}

class _ServiceRequestsDetailsScreenState
    extends State<ServiceRequestsDetailsScreen> {
  final Logger logger = Logger('ServiceRequestsDetailsScreen');
  final _trackingApiService = TrackingApiService();
  late bool? _isManong;
  final distance = latlong.Distance();
  final storage = FlutterSecureStorage();
  bool checked = false;
  bool _isLoading = false;
  bool _isButtonLoading = false;
  String? _error;
  late ServiceRequest? _serviceRequest;
  bool _isEditingPaymentStatus = false;
  final baseImageUrl = dotenv.env['APP_URL'];
  bool _isServiceCompleted = false;
  ServiceSettings? _serviceSettings;
  Manong? _manong;

  @override
  void initState() {
    super.initState();
    _initializeComponents();
    _fetchManongDetails();
    _getTrackingStream();
    _fetchServiceSettings();
  }

  void _initializeComponents() {
    _isManong = widget.isManong;
    _serviceRequest = widget.serviceRequest;
  }

  Future<void> _fetchManongDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      if (_serviceRequest == null) return;
      final response = await ManongApiService().fetchAManong(
        _serviceRequest!.manongId!,
      );

      if (response != null) {
        setState(() {
          _manong = response;
        });
      } else {
        logger.warning('Failed fetching a manong');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });

      logger.severe('Error fetching a manong $_error');
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
      const SizedBox.shrink();
    }

    final serviceName =
        _serviceRequest!.otherServiceName.toString().trim().isNotEmpty &&
            _serviceRequest!.otherServiceName != null
        ? _serviceRequest?.otherServiceName
        : _serviceRequest?.subServiceItem?.title;

    return CardContainer(
      children: [
        Divider(color: Colors.grey, thickness: 1, indent: 20, endIndent: 20),
        LabelValueRow(
          label: 'Service: ',
          valueWidget: Expanded(
            child: Text(
              serviceName ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        LabelValueRow(
          label: 'Payment:',
          valueWidget: Text(_serviceRequest?.paymentMethod?.name ?? ''),
        ),
        const SizedBox(height: 4),
        LabelValueRow(
          label: 'Base Fee:',
          valueWidget: _serviceRequest?.subServiceItem?.fee != null
              ? PriceTag(
                  price: _serviceRequest!.subServiceItem!.fee!.toDouble(),
                )
              : null,
        ),
        LabelValueRow(
          label: 'Urgency Fee:',
          valueWidget: _serviceRequest?.urgencyLevel?.level != null
              ? PriceTag(
                  price: _serviceRequest!.urgencyLevel!.price!.toDouble(),
                )
              : null,
        ),
        Divider(color: Colors.grey, thickness: 1, indent: 20, endIndent: 20),
        LabelValueRow(
          label: 'Subtotal',
          valueWidget: PriceTag(
            price: CalculationTotals().calculateSubTotal(_serviceRequest),
          ),
        ),
        // _buildTaxes()
        Divider(color: Colors.grey, thickness: 1, indent: 20, endIndent: 20),
        Text('Total To Pay:'),
        const SizedBox(height: 4),
        PriceTag(
          price: CalculationTotals().calculateTotal(
            _serviceRequest,
            meters,
            _serviceSettings?.serviceTax,
          ),
          textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildUserDetails(double meters) {
    if (_serviceRequest!.user == null || _serviceRequest == null) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_serviceRequest?.user?.firstName != null &&
            _serviceRequest?.user?.lastName != null) ...[
          Text(
            "Name",
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 4),

          Row(
            children: [
              Text(
                '${_serviceRequest!.user?.firstName} ${_serviceRequest!.user?.lastName}',
                style: TextStyle(fontSize: 18, color: Colors.black),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],

        if (_serviceRequest?.user?.nickname != null) ...[
          Text(
            "Nickname",
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 4),

          Row(
            children: [
              Text(
                '${_serviceRequest!.user?.nickname}',
                style: TextStyle(fontSize: 18, color: Colors.black),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],

        Text(
          "Contact",
          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 4),

        Row(
          children: [
            Text(
              _serviceRequest!.user?.phone ?? "",
              style: TextStyle(fontSize: 18, color: Colors.black),
            ),
          ],
        ),

        // -- Payment Status
        if (_serviceRequest?.paymentStatus != null) ...[
          const SizedBox(height: 8),
          Text(
            "Payment Status",
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),

          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: getStatusColor(
                _serviceRequest!.paymentStatus!.name,
              ).withOpacity(0.1),
              border: Border.all(
                color: getStatusBorderColor(
                  _serviceRequest!.paymentStatus!.name,
                ),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Text(
              _serviceRequest!.paymentStatus!.name
                  .split(' ')
                  .map((word) => word[0].toUpperCase() + word.substring(1))
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
          const SizedBox(height: 6),
        ],

        // -- Request Status
        Text(
          "Request Status",
          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: getStatusColor(
              _serviceRequest!.status!.value,
            ).withOpacity(0.1),
            border: Border.all(
              color: getStatusBorderColor(_serviceRequest!.status!.value),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Text(
            getStatusText(_serviceRequest!.status!.value),
            style: TextStyle(
              fontSize: 11,
              color: getStatusBorderColor(_serviceRequest!.status!.value),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        const SizedBox(height: 4),

        // -- Payment Method
        Text(
          "Payment Method",
          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 4),

        Text(_serviceRequest?.paymentMethod?.name ?? ''),
        const SizedBox(height: 8),

        Divider(),

        // -- Other Service Name
        if (_serviceRequest?.otherServiceName != null &&
            _serviceRequest!.otherServiceName.toString().trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            'Custom Service',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColorScheme.primaryLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColorScheme.primaryColor),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Text(
              _serviceRequest?.otherServiceName ?? '',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColorScheme.primaryDark,
              ),
            ),
          ),
        ] else ...[
          const SizedBox(height: 4),
          Text(
            'Service',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColorScheme.primaryLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColorScheme.primaryColor),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Text(
              _serviceRequest?.subServiceItem?.title ?? '',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColorScheme.primaryDark,
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),

        // -- Service Details
        if (_serviceRequest?.serviceDetails != null &&
            _serviceRequest!.serviceDetails.toString().trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            'Service Details',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(_serviceRequest?.serviceDetails ?? ''),
          ),
        ],
        const SizedBox(height: 8),

        // -- Notes
        if (_serviceRequest?.notes != null) ...[
          const SizedBox(height: 4),
          Text(
            'Notes',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(_serviceRequest!.notes ?? ''),
          ),
        ],

        // -- Images
        _buildUploadedPhotos(),

        // -- Totals
        _buildTotals(meters),
      ],
    );
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

        Row(
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
                  _manong?.profile?.status,
                ).withOpacity(0.1),
                border: Border.all(
                  color: getStatusBorderColor(_manong?.profile?.status),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Text(
                _manong?.profile?.status ?? '',
                style: TextStyle(
                  fontSize: 11,
                  color: getStatusBorderColor(_manong!.profile!.status),
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
                            child: Padding(
                              padding: const EdgeInsets.all(16),
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
      if (_serviceRequest == null ||
          _serviceRequest!.status == null ||
          _serviceRequest!.user?.fcmToken == null) {
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
    setState(() {
      _isButtonLoading = true;
      _error = null;
    });
    try {
      if (_serviceRequest == null) return;
      final response = await ServiceRequestApiService()
          .markServiceRequestCompleted(_serviceRequest!.id!);

      if (response != null) {
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

  Widget _buildDistanceRow() {
    if (_serviceRequest?.status != 'inprogress') return const SizedBox.shrink();
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

  Future<void> _showDialogCancelConfirmation() async {
    showDialog(
      context: navigatorKey.currentContext!,
      builder: (context) {
        return AlertDialog(
          title: Text('Cancel Service Request', style: TextStyle(fontSize: 22)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Are you sure you want to cancel this service request?'),
              SizedBox(height: 8),
              Text(
                'This action cannot be undone.',
                textAlign: TextAlign.start,
                style: TextStyle(color: Colors.redAccent),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('No, keep request'),
            ),
            TextButton(
              onPressed: () {
                _cancelServiceRequest();
              },
              child: Text('Yes, cancel it'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBottomNav(double? meters, ScrollController scrollController) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ListView(
        controller: scrollController,
        children: [
          // -- Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // --- Time + Distance
          _buildDistanceRow(),
          const SizedBox(height: 12),

          // --- Accept Button
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
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _showDialogCancelConfirmation();
                      },
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
                      child: Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ],
          ],

          // -- Complete Button
          if (_serviceRequest?.arrivedAt != null &&
              _serviceRequest?.status == ServiceRequestStatus.inProgress &&
              !(_isServiceCompleted)) ...[
            if (_isManong == true) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: !_isButtonLoading
                          ? _markServiceRequestCompleted
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
                          : Text('Complete Service Request'),
                    ),
                  ),
                ],
              ),
            ],
          ],

          // -- More details
          Visibility(
            visible: true,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: Column(
              children: [
                const SizedBox(height: 3),
                Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade700),
              ],
            ),
          ),
          SizedBox(height: 12),

          if (_isManong == true) _buildUserDetails(meters ?? 0),

          if (_isManong == false) _buildManongDetails(meters ?? 0),

          // if (_fcmToken != null) ...[Text('Token for me: $_fcmToken')],
          // if (_serviceRequest != null) ...[
          //   const SizedBox(height: 8),
          //   Text('Token of the other side: ${_serviceRequest?.user?.fcmToken}'),
          // ],
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

      if (_serviceRequest?.status != 'inprogress') return;

      logger.info('Live now');

      _trackingApiService.joinRoom(
        manongId: _serviceRequest!.manongId.toString(),
        serviceRequestId: _serviceRequest!.id.toString(),
      );

      if (_isManong == true) {
        logger.info('Started Tracking');
        _trackingApiService.startTracking(
          manongId: _serviceRequest!.manongId.toString(),
          serviceRequestId: _serviceRequest!.id.toString(),
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
    if (_manong == null) return SizedBox.shrink();
    return Stack(
      children: [
        _buildRouteTracking(),
        if (_manong?.profile?.specialities?.length != null)
          SafeArea(
            child: DraggableScrollableSheet(
              initialChildSize: 0.20,
              minChildSize: 0.05,
              maxChildSize:
                  _manong!.profile!.specialities!.length >= 6 ||
                      _serviceRequest!.images.isNotEmpty
                  ? 0.99
                  : 0.5,

              snap: true,
              snapSizes: [
                0.20,
                _manong!.profile!.specialities!.length >= 6 ||
                        _serviceRequest!.images.isNotEmpty
                    ? 0.99
                    : 0.5,
              ],
              builder: (context, scrollController) {
                return _buildBottomNav(meters, scrollController);
              },
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

  void _goToChat() {
    Navigator.pushNamed(
      navigatorKey.currentContext!,
      '/chat-manong',
      arguments: {'serviceRequest': _serviceRequest},
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_serviceRequest == null) {
      return const SizedBox.shrink();
    }

    final meters = DistanceMatrix().calculateDistance(
      startLat: widget.serviceRequest?.customerLat,
      startLng: widget.serviceRequest?.customerLng,
      endLat: _trackingApiService.manongLatLngNotifier.value?.latitude ?? 0,
      endLng: _trackingApiService.manongLatLngNotifier.value?.longitude ?? 0,
    );

    return Material(
      child: Scaffold(
        body: meters != null ? _buildState(meters) : null,
        floatingActionButton: FloatingActionButton(
          onPressed: _goToChat,
          tooltip: 'Message Manong',
          backgroundColor: AppColorScheme.primaryLight,
          child: Icon(Icons.message, color: AppColorScheme.primaryDark),
        ),
      ),
    );
  }

  @override
  void dispose() {
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
