import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/api/auth_service.dart';
import 'package:manong_application/api/fcm_api_service.dart';
import 'package:manong_application/api/payment_transaction_api_service.dart';
import 'package:manong_application/api/service_request_api_service.dart';
import 'package:manong_application/api/tracking_api_service.dart';
import 'package:manong_application/main.dart';
import 'package:manong_application/models/manong.dart';
import 'package:manong_application/models/manong_status.dart';
import 'package:manong_application/models/payment_status.dart';
import 'package:manong_application/models/service_request_status.dart';
import 'package:manong_application/models/service_request.dart';
import 'package:manong_application/providers/bottom_nav_provider.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:manong_application/utils/distance_matrix.dart';
import 'package:manong_application/utils/feedback_utils.dart';
import 'package:manong_application/utils/notification_utils.dart';
import 'package:manong_application/utils/permission_utils.dart';
import 'package:manong_application/utils/snackbar_utils.dart';
import 'package:manong_application/utils/status_utils.dart';
import 'package:manong_application/widgets/animated_progress_bar.dart';
import 'package:manong_application/widgets/app_bar_search.dart';
import 'package:manong_application/widgets/empty_state_widget.dart';
import 'package:manong_application/widgets/error_state_widget.dart';
import 'package:manong_application/widgets/modal_icon_overlay.dart';
import 'package:manong_application/widgets/rounded_draggable_sheet.dart';
import 'package:manong_application/widgets/service_request_card.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:manong_application/api/manong_api_service.dart';
import 'package:manong_application/widgets/manong_status_toggle.dart';

class ServiceRequestsScreen extends StatefulWidget {
  const ServiceRequestsScreen({super.key});
  @override
  State<ServiceRequestsScreen> createState() => _ServiceRequestsScreenState();
}

class _ServiceRequestsScreenState extends State<ServiceRequestsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final _trackingApiService = TrackingApiService();
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  final distance = latlong.Distance();
  bool _permissionDialogShown = false;

  late ServiceRequestApiService _serviceRequestApiService;
  final Logger logger = Logger('ServiceRequestScreen');
  late BottomNavProvider _navProvider;

  List<ServiceRequest> _serviceRequest = [];
  String _searchQuery = '';
  int _statusIndex = 0;
  double? meters;

  bool isLoading = true;
  String? _error;

  String _dateSortOrder = 'Descending';
  final List<String> _sortOptions = ['Descending', 'Ascending'];

  // Requests Pages
  int _currentPage = 1;
  final int _limit = 10; // items per page
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool? _isManong;
  bool _isButtonLoading = false;
  ServiceRequest? _ongoingServiceRequest;
  late PermissionUtils? _permissionUtils;
  bool _arrivalNotified = false;
  final ValueNotifier<int?> _highlightedId = ValueNotifier(null);

  final List<String> tabs = tabStatuses.keys.toList();
  bool _hasScrolledToRequest = false;

  final TextEditingController _commentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final int _commentCount = 0;
  double? _averageRating;
  int _transactionCount = 0;
  bool _arrivalFetchInProgress = false;
  Manong? _currentManong;
  bool _isToggleLoading = false;
  ManongDailyLimit? _manongDailyLimit;

  @override
  void initState() {
    super.initState();
    _initializeComponents();
    _fetchServiceRequests();
    _getOngoingServiceRequest().then((_) => _setManongLatLng());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupScrollListener();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _trackingApiService.manongLatLngNotifier.addListener(() {
        if (!mounted) return;
        setState(() {});
      });
    });

    _countUnseenPaymentTransactions();
  }

  Widget _buildManongDailyLimitDraggableContainer() {
    if (_isManong != true || _manongDailyLimit == null) {
      return const SizedBox.shrink();
    }

    return RoundedDraggableSheet(
      initialChildSize: 0.18,
      maxChildSize: 0.18,
      minChildSize: 0,
      snapSizes: [0.05, 0.18],
      color: AppColorScheme.primaryLight,
      children: [
        Text(
          _manongDailyLimit?.message ??
              'Your daily limit reached! Come back again tomorrow!',
          textAlign: TextAlign.center,
        ),

        AnimatedStackProgressBar(
          current: _manongDailyLimit?.count,
          total: _manongDailyLimit?.limit,
          fillColor: AppColorScheme.primaryColor,
          trackColor: AppColorScheme.primaryLight,
          percentTextStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColorScheme.deepTeal,
          ),
        ),
      ],
    );
  }

  Future<void> _fetchDailyLimit() async {
    if (_isManong != true) return;

    try {
      final response = await ManongApiService().checkDailyLimit();

      if (response != null) {
        logger.info('_fetchDailyLimit $response');
        final data = response['data'];
        if (data != null) {
          final ManongDailyLimit manongDailyLimit = ManongDailyLimit(
            isReached: true,
            message: data['message'],
            count: data['count'],
            limit: data['limit'],
          );

          setState(() {
            _manongDailyLimit = manongDailyLimit;
          });
        } else {
          setState(() {
            _manongDailyLimit = null;
          });
        }
      }
    } catch (e) {
      logger.info('Error fetching daily limit ${e.toString()}');
      _navProvider.unsetManongDailyLimit();
    }
  }

  Future<void> _fetchCurrentManong() async {
    if (_isManong != true) return;

    try {
      // Use getMyProfile() to get current user
      final user = await AuthService().getMyProfile();

      // ignore: unnecessary_null_comparison
      if (user.id != null) {
        final response = await ManongApiService().fetchAManong(user.id);
        if (mounted) {
          setState(() {
            _currentManong = response;
          });

          logger.info('_currentManong: $_currentManong');
        }

        await _fetchDailyLimit();
      }
    } catch (e) {
      logger.severe('Error fetching current manong: $e');
    }
  }

  Future<void> _showPermissionDialog() async {
    // Only show once and only if permission isn't already granted
    if (_permissionDialogShown || _permissionUtils == null) return;

    bool granted = await _permissionUtils!.isLocationPermissionGranted();

    if (!granted && mounted) {
      _permissionDialogShown = true; // Mark as shown

      showDialog(
        context: navigatorKey.currentContext!,
        barrierDismissible: false,
        builder: (context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ModalIconOverlay(
              icons: Icons.location_off,
              description:
                  'Location permission is required to show your position and track service requests.',
              onPressed: () async {
                await _permissionUtils!.checkLocationPermission();
                if (mounted) Navigator.of(navigatorKey.currentContext!).pop();
              },
            ),
          );
        },
      );
    }
  }

  void _checkAndShowPermissionDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showPermissionDialog();
    });
  }

  void _initializeComponents() {
    _permissionUtils = PermissionUtils();
    _permissionUtils?.checkLocationPermission();
    _serviceRequestApiService = ServiceRequestApiService();
    _navProvider = Provider.of<BottomNavProvider>(
      navigatorKey.currentContext!,
      listen: false,
    );
    if (_navProvider.statusIndex != null) {
      setState(() {
        _statusIndex = _navProvider.statusIndex!;
      });
    }
  }

  Future<void> _countUnseenPaymentTransactions() async {
    try {
      final response = await PaymentTransactionApiService()
          .countUnseenPaymentTransactions();

      if (response != null) {
        setState(() {
          _transactionCount = response;
        });
      }
    } catch (e) {
      if (!mounted) return;
      logger.severe('Error counting Payment Transactions ${e.toString()}');
    }
  }

  void _setManongLatLng() {
    logger.info('Has _setManongLatLng');
    if (_ongoingServiceRequest == null) return;
    final manong = _ongoingServiceRequest?.manong;
    if (manong != null) {
      logger.info('Has manong');
      if (_ongoingServiceRequest?.manong?.appUser.latitude != null &&
          _ongoingServiceRequest?.manong?.appUser.longitude != null) {
        logger.info(
          'Has last known ${_ongoingServiceRequest!.manong!.appUser.lastKnownLat} ${_ongoingServiceRequest!.manong!.appUser.longitude}',
        );
        _trackingApiService.manongLatLngNotifier.value = latlong.LatLng(
          manong.appUser.lastKnownLat!,
          manong.appUser.lastKnownLng!,
        );
      } else {
        _trackingApiService.manongLatLngNotifier.value = latlong.LatLng(
          manong.appUser.latitude!,
          manong.appUser.longitude!,
        );

        logger.info(
          'Has no last known ${_trackingApiService.manongLatLngNotifier.value}',
        );
      }
    }
  }

  Future<void> _setToArrived(ServiceRequest ongoingRequest) async {
    if (_arrivalNotified) {
      logger.info('Arrival already notified, skipping.');
      return;
    }
    if (ongoingRequest.arrivedAt != null || ongoingRequest.id == null) {
      logger.info('Already marked as arrived in DB, skipping.');
      return;
    }

    _arrivalNotified = true;
    logger.info('_setToArrived started');

    await FcmApiService().sendNotification(
      title: 'Manong ${ongoingRequest.manong?.appUser.firstName} has arrived!',
      body:
          'Your service request is ready. Please meet your Manong at the provided address.',
      fcmToken: ongoingRequest.user?.fcmToken ?? '',
      userId: ongoingRequest.userId!,
      json: {'serviceRequestId': ongoingRequest.id},
    );

    final response = await ServiceRequestApiService().updateServiceRequest(
      ongoingRequest.id!,
      {'arrivedAt': DateTime.now().toIso8601String()},
    );

    logger.info('_setToArrived ${jsonEncode(response)}');
  }

  Future<void> _getOngoingServiceRequest() async {
    try {
      await _navProvider.fetchOngoingServiceRequest();
      final ongoingRequest = _navProvider.ongoingServiceRequest;

      if (ongoingRequest != null) {
        if (_serviceRequest.any((s) => s.id == ongoingRequest.id)) {
          _trackingApiService.joinRoom(
            manongId: ongoingRequest.manongId.toString(),
            serviceRequestId: ongoingRequest.id.toString(),
          );

          if (_isManong == true) {
            _trackingApiService.startTracking(
              manongId: ongoingRequest.manongId.toString(),
              serviceRequestId: ongoingRequest.id.toString(),
            );
          }

          _trackingApiService.onLocationUpdate((data) async {
            final lat = data['lat'];
            final lng = data['lng'];
            final statusString = data['status']?.toString() ?? '';

            final status = ServiceRequestStatus.values.firstWhere(
              (e) => e.name.toLowerCase() == statusString.toLowerCase(),
              orElse: () => ServiceRequestStatus.pending,
            );

            if (status == ServiceRequestStatus.completed ||
                status == ServiceRequestStatus.cancelled) {
              _navProvider.setServiceRequestStatus(status);
              setState(() {
                _statusIndex = getTabIndex(status)!;
              });

              _updateManongStatusOnJobCompletion(status);
            }

            final meters = DistanceMatrix().calculateDistance(
              startLat: ongoingRequest.customerLat,
              startLng: ongoingRequest.customerLng,
              endLat:
                  lat ?? _ongoingServiceRequest?.manong?.appUser.lastKnownLat,
              endLng:
                  lng ?? _ongoingServiceRequest?.manong?.appUser.lastKnownLng,
            );

            final estimate = DistanceMatrix().estimateTime(meters ?? 0);

            if (estimate.toLowerCase() == 'arrived') {
              _navProvider.setManongArrived(true);
              if (ongoingRequest.arrivedAt == null) {
                await _setToArrived(ongoingRequest);
              }

              // Only fetch if not already fetching
              if (!_arrivalFetchInProgress) {
                _arrivalFetchInProgress = true;

                // Schedule the fetch for later (not during build)
                Future.microtask(() async {
                  try {
                    await _fetchServiceRequests();
                  } finally {
                    if (mounted) {
                      _arrivalFetchInProgress = false;
                    }
                  }
                });
              }
            }
          });
        } else {
          logger.info('Not ongoing request');
        }

        setState(() {
          _ongoingServiceRequest = ongoingRequest;
          _statusIndex = getTabIndex(
            ongoingRequest.status ?? ServiceRequestStatus.pending,
          )!;
        });
        _fetchServiceRequests();
      }
    } catch (e) {
      logger.severe('Error getting the ongoing service request $e');
    }
  }

  void _onStatusChanged(int index) {
    if (index != _statusIndex) {
      setState(() {
        _statusIndex = index;
      });
    }
  }

  // Widget _buildStatusChip({
  //   required String title,
  //   required int index,
  //   required bool active,
  // }) {
  //   return Padding(
  //     padding: const EdgeInsets.only(right: 6, left: 6),
  //     child: FilterChip(
  //       label: Text(title),
  //       selected: active,
  //       onSelected: (_) => _onStatusChanged(index),
  //       selectedColor: AppColorScheme.primaryColor,
  //       backgroundColor: AppColorScheme.primaryLight,
  //       labelStyle: TextStyle(
  //         color: active ? Colors.white : Colors.grey.shade700,
  //         fontWeight: active ? FontWeight.w600 : FontWeight.normal,
  //       ),
  //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  //       showCheckmark: false,
  //     ),
  //   );
  // }

  Widget _buildStatusRow() {
    return Container(
      color: AppColorScheme.primaryColor,
      height: 48,
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width,
          ),
          child: Row(
            children: List.generate(
              tabs.length,
              (index) => _buildTopStatusChip(
                title: tabs[index],
                index: index,
                active: _statusIndex == index,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopStatusChip({
    required String title,
    required int index,
    required bool active,
  }) {
    return GestureDetector(
      onTap: () => _onStatusChanged(index),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width > 600
              ? 24
              : 16, // Adjust padding for tablets
          vertical: 12,
        ),
        height: 48,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? Colors.white : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: active ? Colors.white : Colors.white.withOpacity(0.7),
              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              fontSize: MediaQuery.of(context).size.width > 600
                  ? 16
                  : 14, // Adjust font size for tablets
            ),
          ),
        ),
      ),
    );
  }

  void _setupScrollListener() {
    _itemPositionsListener.itemPositions.addListener(() {
      // Find the last visible item index
      final positions = _itemPositionsListener.itemPositions.value;
      if (positions.isNotEmpty) {
        final maxIndex = positions
            .map((p) => p.index)
            .reduce((a, b) => a > b ? a : b);

        // If the user scrolled close to the end
        if (maxIndex >= _getFilteredRequests().length - 3 &&
            !_isLoadingMore &&
            _hasMore) {
          _fetchMoreServiceRequests();
        }
      }
    });
  }

  Future<void> _fetchMoreServiceRequests() async {
    if (_isLoadingMore || !_hasMore) return; // lock to prevent multiple calls

    setState(() => _isLoadingMore = true);

    try {
      final response = await _serviceRequestApiService.fetchServiceRequests(
        page: _currentPage,
        limit: _limit,
      );

      logger.info('_fetchMoreServiceRequests $response');

      if (response == null) {
        setState(() => _hasMore = false);
        return;
      }

      final requests = (response as List<dynamic>)
          .map((json) => ServiceRequest.fromJson(json as Map<String, dynamic>))
          .toList();

      setState(() {
        _serviceRequest.addAll(requests);
        _currentPage++;
        _isLoadingMore = false;
        if (requests.length < _limit) _hasMore = false;
      });
    } catch (e) {
      logger.severe('Error fetching more service requests $e');
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _fetchServiceRequests({bool loadMore = false}) async {
    if (!mounted || (!_hasMore && loadMore)) return;

    try {
      if (loadMore) {
        setState(() {
          _isLoadingMore = true;
        });
      } else {
        setState(() {
          isLoading = true;
          _error = null;
          _currentPage = 1;
          _hasMore = true;
        });
      }

      if (loadMore) _isLoadingMore = true;

      final response = await _serviceRequestApiService.fetchServiceRequests(
        page: _currentPage,
        limit: _limit,
      );

      logger.info('_fetchServiceRequests raw $response');

      if (!mounted) return;

      if (response == null) {
        throw Exception('No response from server');
      }

      final bool? isManongFromResponse = response['isManong'];

      setState(() {
        isLoading = false;
        _error = null;
        _isManong = isManongFromResponse ?? _isManong;
      });

      if (_isManong == true) {
        await Future.delayed(const Duration(milliseconds: 100));
        _fetchCurrentManong();
      } else {
        _navProvider.unsetManongDailyLimit();
      }

      final requests = response['data'] as List<dynamic>?;

      logger.info('_fetchServiceRequests requests $requests');

      if (requests == null || requests.isEmpty) {
        setState(() {
          if (loadMore) {
            _hasMore = false;
          } else {
            _serviceRequest = [];
          }
          _isLoadingMore = false;
        });

        return;
      }

      final parsedRequests = requests
          .map((json) => ServiceRequest.fromJson(json as Map<String, dynamic>))
          .toList();

      logger.info('_fetchServiceRequests parsed $parsedRequests');

      setState(() {
        if (loadMore) {
          _serviceRequest.addAll(parsedRequests);
          _isLoadingMore = false;
        } else {
          _serviceRequest = parsedRequests;
          isLoading = false;
        }
        if (parsedRequests.length < _limit) _hasMore = false;

        final completedRequests = _serviceRequest
            .where(
              (r) =>
                  r.status == ServiceRequestStatus.completed &&
                  r.feedback?.rating != null,
            )
            .toList();

        if (completedRequests.isNotEmpty) {
          final ratings = completedRequests
              .map((r) => r.feedback!.rating.toDouble())
              .toList();
          final total = ratings.reduce((a, b) => a + b);
          _averageRating = total / ratings.length;
        } else {
          _averageRating = null;
        }
      });

      logger.info('_fetchServiceRequests _serviceRequest $_serviceRequest');

      if (_navProvider.serviceRequestId != null && !_hasScrolledToRequest) {
        _hasScrolledToRequest = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToServiceRequest(_navProvider.serviceRequestId!);
        });
      }

      _currentPage++;

      logger.info('Fetched ${parsedRequests.length} service requests');
    } catch (e) {
      logger.severe('Error fetching service requests $e');

      if (mounted) {
        setState(() {
          if (!loadMore) {
            _serviceRequest = [];
            isLoading = false;
            _error = 'Failed to load service requests. Please try again.';
          } else {
            _isLoadingMore = false;
          }
        });
      }
    }
  }

  List<ServiceRequest> _getFilteredRequests() {
    List<ServiceRequest> filtered = [];

    final tab = tabs[_statusIndex];
    final validStatuses = tabStatuses[tab] ?? [];

    logger.info('Unfiltered _serviceRequest $_serviceRequest');

    filtered = _serviceRequest.where((req) {
      final reqStatus = req.status ?? ServiceRequestStatus.pending;
      final paymentStatus = req.paymentStatus ?? PaymentStatus.pending;

      if (tab == 'To Pay' &&
          [
            ServiceRequestStatus.expired,
            ServiceRequestStatus.cancelled,
          ].contains(reqStatus)) {
        return false;
      }

      if (tab == 'Upcoming' &&
          [
            ServiceRequestStatus.completed,
            ServiceRequestStatus.inProgress,
            ServiceRequestStatus.cancelled,
          ].contains(reqStatus)) {
        return false;
      }

      return validStatuses.contains(reqStatus) ||
          validStatuses.contains(paymentStatus);
    }).toList();

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((req) {
        final manong = req.manong?.appUser.firstName?.toLowerCase() ?? '';
        final service = req.serviceItem?.title.toLowerCase() ?? '';
        final subService = req.subServiceItem?.title.toLowerCase() ?? '';
        final urgency = req.urgencyLevel?.level.toLowerCase() ?? '';
        final requestNumber = req.requestNumber?.toLowerCase() ?? '';

        final matches =
            manong.contains(query) ||
            service.contains(query) ||
            subService.contains(query) ||
            urgency.contains(query) ||
            requestNumber.contains(query);

        return matches;
      }).toList();
    }

    filtered.sort((a, b) {
      final aDate = a.createdAt ?? DateTime.fromMicrosecondsSinceEpoch(0);
      final bDate = b.createdAt ?? DateTime.fromMicrosecondsSinceEpoch(0);

      if (_dateSortOrder == 'Descending') {
        return bDate.compareTo(aDate);
      } else {
        return aDate.compareTo(bDate);
      }
    });

    return filtered;
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.trim();
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _onSearchChanged('');
  }

  Widget _buildResultsInfo(int count) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          DropdownButton<String>(
            dropdownColor: Colors.white,
            value: _dateSortOrder,
            items: _sortOptions.map((option) {
              return DropdownMenuItem(
                value: option,
                child: Row(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.sort, size: 18, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          'Sort: ${option.toLowerCase() == 'ascending' ? 'Date (Oldest)' : 'Date (Newest)'}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _dateSortOrder = value;
                });
              }
            },
          ),
          Text(
            '($count result${count != 1 ? 's' : ''})',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    if (_error != null) {
      ErrorStateWidget(errorText: _error!, onPressed: _fetchServiceRequests);
    }

    return EmptyStateWidget(
      searchQuery: _searchQuery,
      emptyMessage: 'No service requests found',
      onPressed: _clearSearch,
      onRefresh: _fetchServiceRequests,
    );
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
            'Service Request ${sr.status?.name}',
          );
          if (sr.status != serviceRequest.status) {
            _statusIndex = getTabIndex(
              sr.status ?? ServiceRequestStatus.pending,
            )!;
            _fetchServiceRequests();
            _getOngoingServiceRequest();
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

  void _onTapServiceCard(ServiceRequest serviceRequestItem) async {
    if (serviceRequestItem.manong?.appUser.id != null) {
      final conditionToAllowRedirect =
          serviceRequestItem.paymentTransactions != null &&
          serviceRequestItem.paymentTransactions!.isNotEmpty &&
          (serviceRequestItem.status != ServiceRequestStatus.cancelled &&
              serviceRequestItem.paymentStatus != PaymentStatus.refunded &&
              serviceRequestItem.status != ServiceRequestStatus.refunding);

      if (conditionToAllowRedirect) {
        final paymentRedirectUrl = serviceRequestItem
            .paymentTransactions?[0]
            .metadata?['paymentRedirectUrl'];
        if (paymentRedirectUrl != null) {
          if (paymentRedirectUrl.toString().trim().isNotEmpty &&
              serviceRequestItem.paymentStatus != PaymentStatus.paid) {
            final result = await Navigator.pushNamed(
              navigatorKey.currentContext!,
              '/payment-redirect',
              arguments: {'serviceRequest': serviceRequestItem},
            );

            if (result != null) {
              _fetchMoreServiceRequests();
            }

            return;
          }
        }
      }

      final result = await Navigator.pushNamed(
        navigatorKey.currentContext!,
        '/service-request-details',
        arguments: {
          'serviceRequest': serviceRequestItem,
          'isManong': _isManong,
        },
      );

      if (result != null && result is Map) {
        if (result['updated'] == true) {
          _fetchServiceRequests();
          if (result['status'] != null) {
            _statusIndex = getTabIndex(result['status'])!;

            if (_isManong == true) {
              _updateManongStatusOnJobCompletion(result['status']);
            }
          }
        }

        if (result['startJob'] == true) {
          _fetchServiceRequests();
          _getOngoingServiceRequest();
        }
      }
    } else {
      Navigator.pushNamed(
        context,
        '/manong-list',
        arguments: {
          'serviceRequest': serviceRequestItem,
          'subServiceItem': serviceRequestItem.subServiceItem,
        },
      );
    }
  }

  // Add this method to handle job completion status updates
  void _updateManongStatusOnJobCompletion(ServiceRequestStatus newStatus) {
    if (_isManong == true &&
        _currentManong != null &&
        _currentManong!.profile != null) {
      ManongStatus newManongStatus = _currentManong!.profile!.status;

      // Update manong status based on service request status
      if (newStatus == ServiceRequestStatus.completed) {
        newManongStatus =
            ManongStatus.available; // Back to available after completion
      } else if (newStatus == ServiceRequestStatus.cancelled) {
        newManongStatus =
            ManongStatus.available; // Back to available if cancelled
      }
      // For inProgress, keep as busy

      if (newManongStatus != _currentManong!.profile!.status) {
        setState(() {
          _currentManong = Manong(
            appUser: _currentManong!.appUser,
            profile: _currentManong!.profile!.copyWith(status: newManongStatus),
          );
        });
      }
    }
  }

  void _onStartJob(ServiceRequest serviceRequestItem) async {
    if (_isManong == true && serviceRequestItem.userId != null) {
      logger.info('_onStartJob ${_ongoingServiceRequest != null}');

      setState(() {
        _currentManong = Manong(
          appUser: _currentManong!.appUser,
          profile: _currentManong!.profile!.copyWith(status: ManongStatus.busy),
        );
      });

      _startServiceRequest(serviceRequestItem);
      await NotificationUtils.sendStatusUpdateNotification(
        status: parseRequestStatus(serviceRequestItem.status!.value)!,
        token: serviceRequestItem.user?.fcmToken ?? '',
        serviceRequestId: serviceRequestItem.id.toString(),
        userId: serviceRequestItem.userId!,
      );
    }
  }

  Widget _buildServiceRequestCard(
    ServiceRequest serviceRequestItem,
    double? meters,
  ) {
    if (meters != null) {
      if (DistanceMatrix().estimateTime(meters).toLowerCase() == 'arrived') {
        if (_ongoingServiceRequest != null) {
          _setToArrived(_ongoingServiceRequest!);
        }
      }
    }

    return ValueListenableBuilder<int?>(
      valueListenable: _highlightedId,
      builder: (context, highlightedId, child) {
        final isHighlighted = highlightedId == serviceRequestItem.id;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.only(bottom: 0),
          decoration: BoxDecoration(
            color: isHighlighted
                ? Colors.yellow.withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ServiceRequestCard(
            serviceRequestItem: serviceRequestItem,
            meters: meters,
            onTap: () => _onTapServiceCard(serviceRequestItem),
            isManong: _isManong,
            onStartJob:
                serviceRequestItem.status != ServiceRequestStatus.accepted
                ? null
                : () => _onStartJob(serviceRequestItem),
            isButtonLoading: _isButtonLoading,
            onTapRate: (rating) {
              if (serviceRequestItem.id == null ||
                  serviceRequestItem.manongId == null) {
                return;
              }

              if (rating <= 2) {
                FeedbackUtils().dissastisfiedDialog(
                  context: context,
                  rating: rating,
                  serviceRequestId: serviceRequestItem.id!,
                  reveweeId: serviceRequestItem.manongId!,
                  formKey: _formKey,
                  commentController: _commentController,
                  commentCount: _commentCount,
                  onClose: () {
                    _fetchServiceRequests();
                  },
                );
                return;
              }

              FeedbackUtils().createFeedback(
                serviceRequestId: serviceRequestItem.id!,
                revieweeId: serviceRequestItem.manongId!,
                rating: rating,
              );
            },
            onTapReview: () {
              FeedbackUtils().leaveAReviewDialog(
                context: context,
                formKey: _formKey,
                commentController: _commentController,
                commentCount: _commentCount,
                serviceRequest: serviceRequestItem,
                navProvider: _navProvider,
                onClose: () {
                  _fetchServiceRequests();
                },
              );
            },
            onRefresh: () {
              _fetchServiceRequests();
            },
          ),
        );
      },
    );
  }

  Widget _buildServiceRequestsList(List<ServiceRequest> filteredRequests) {
    return RefreshIndicator(
      color: AppColorScheme.primaryColor,
      backgroundColor: AppColorScheme.backgroundGrey,
      onRefresh: _fetchServiceRequests,

      child: ScrollablePositionedList.builder(
        itemCount: filteredRequests.length + (_isLoadingMore ? 1 : 0),
        physics: const AlwaysScrollableScrollPhysics(),
        itemScrollController: _itemScrollController,
        itemBuilder: (context, index) {
          if (index >= filteredRequests.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(
                  color: AppColorScheme.primaryColor,
                ),
              ),
            );
          }
          ServiceRequest serviceRequestItem = filteredRequests[index];

          if (_ongoingServiceRequest?.id == serviceRequestItem.id) {
            return ValueListenableBuilder<latlong.LatLng?>(
              valueListenable: _trackingApiService.manongLatLngNotifier,
              builder: (BuildContext context, value, Widget? child) {
                meters = DistanceMatrix().calculateDistance(
                  startLat: serviceRequestItem.customerLat,
                  startLng: serviceRequestItem.customerLng,
                  endLat: value?.latitude ?? 0,
                  endLng: value?.longitude ?? 0,
                );

                return _buildServiceRequestCard(serviceRequestItem, meters);
              },
            );
          } else {
            logger.info(
              'This is not ongoing request ${_ongoingServiceRequest?.id} ${serviceRequestItem.id}',
            );
            return _buildServiceRequestCard(serviceRequestItem, null);
          }
        },
      ),
    );
  }

  Future<void> _scrollToServiceRequest(int requestId) async {
    final indexAll = _serviceRequest.indexWhere((r) => r.id == requestId);

    if (indexAll == -1) {
      logger.info(
        'Request $requestId not found in loaded list (maybe not fetched yet).',
      );
      return;
    }

    final targetReq = _serviceRequest[indexAll];

    if (targetReq.status == null) return;

    final int? targetTabIndex = getTabIndex(targetReq.status);
    logger.info('targetTabIndex $targetTabIndex ${targetReq.status?.value}');
    if (targetTabIndex == null) {
      logger.warning(
        'Unknown status ${targetReq.status} for request $requestId',
      );
      return;
    }

    setState(() {
      _statusIndex = targetTabIndex;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final filtered = _getFilteredRequests();
      final filteredIndex = filtered.indexWhere((r) => r.id == requestId);

      if (filteredIndex == -1) {
        logger.info(
          'Request $requestId not visible after switching tab (maybe filtered out by search).',
        );
        return;
      }

      _itemScrollController.scrollTo(
        index: filteredIndex,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );

      _highlightedId.value = requestId;

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && _highlightedId.value == requestId) {
          _highlightedId.value = null;
        }
        _navProvider.setServiceRequestId(null);
      });
    });
  }

  Widget _buildRatings() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        children: [
          if (_statusIndex == getTabIndex(ServiceRequestStatus.completed) &&
              _isManong == true)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Average Rating: ${_averageRating?.toStringAsFixed(1) ?? 'No Ratings yet'} ★',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _transactionTrailing() {
    return GestureDetector(
      onTap: () async {
        await Navigator.pushNamed(
          navigatorKey.currentContext!,
          '/transactions',
        );

        _countUnseenPaymentTransactions();
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(Icons.receipt_long, color: Colors.white),
          if (_transactionCount > 0) ...[
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                height: 15,
                width: 15,
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  _transactionCount.toString(),
                  style: TextStyle(color: Colors.white, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredRequests = _getFilteredRequests();

    return Scaffold(
      backgroundColor: AppColorScheme.backgroundGrey,
      appBar: AppBarSearch(
        title: 'My Requests',
        trailing: Row(
          children: [
            if (_isManong == true && _currentManong == null) ...[
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (_isManong == true &&
                _currentManong != null &&
                _currentManong!.profile != null)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: ManongStatusToggle(
                  status: _currentManong!
                      .profile!
                      .status, // Use 'status' not 'initialStatus'
                  isLoading: _isToggleLoading, // Pass loading state
                  onStatusChanged: (newStatus) async {
                    setState(() {
                      _isToggleLoading = true;
                    });

                    setState(() {
                      _currentManong = Manong(
                        appUser: _currentManong!.appUser,
                        profile: _currentManong!.profile!.copyWith(
                          status: newStatus,
                        ),
                      );
                      _isToggleLoading = false;
                    });
                  },
                  style: ToggleStyle.compact,
                ),
              ),
            _transactionTrailing(),
          ],
        ),
        controller: _searchController,
        onChanged: _onSearchChanged,
      ),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusRow(),
              const SizedBox(height: 2),
              _buildResultsInfo(filteredRequests.length),
              _buildRatings(),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColorScheme.primaryColor,
                            ),
                          )
                        : filteredRequests.isEmpty
                        ? _buildEmptyState()
                        : Padding(
                            padding: const EdgeInsets.all(12),
                            child: _buildServiceRequestsList(filteredRequests),
                          ),
                  ),
                ),
              ),
            ],
          ),
          _buildManongDailyLimitDraggableContainer(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _highlightedId.dispose();
    _searchController.dispose();
    if (_ongoingServiceRequest != null) {
      logger.info(
        'Disconnected with lat ${_trackingApiService.manongLatLngNotifier.value?.latitude} && Lng ${_trackingApiService.manongLatLngNotifier.value?.longitude}',
      );
      _trackingApiService.disconnect(
        manongId: _ongoingServiceRequest!.manongId.toString(),
        serviceRequestId: _ongoingServiceRequest!.id.toString(),
        lastKnownLat: _trackingApiService.manongLatLngNotifier.value?.latitude,
        lastKnownLng: _trackingApiService.manongLatLngNotifier.value?.longitude,
      );
    }
    super.dispose();
  }
}
