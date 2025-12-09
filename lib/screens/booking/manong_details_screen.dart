import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iconify_design/iconify_design.dart';
import 'package:manong_application/main.dart';
import 'package:manong_application/models/bookmark_item_type.dart';
import 'package:manong_application/models/manong.dart';
import 'package:manong_application/models/service_request.dart';
import 'package:manong_application/screens/service_requests/route_tracking_screen.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:manong_application/utils/calculation_totals.dart';
import 'package:manong_application/utils/color_utils.dart';
import 'package:manong_application/utils/distance_matrix.dart';
import 'package:manong_application/widgets/instruction_steps.dart';
import 'package:manong_application/widgets/price_tag.dart';
import 'package:manong_application/api/bookmark_item_api_service.dart'; // Add this import

class ManongDetailsScreen extends StatefulWidget {
  final Manong? manong;
  final Color? iconColor;
  final ServiceRequest? serviceRequest;

  const ManongDetailsScreen({
    super.key,
    this.manong,
    this.iconColor,
    this.serviceRequest,
  });

  @override
  State<ManongDetailsScreen> createState() => _ManongDetailsScreenState();
}

class _ManongDetailsScreenState extends State<ManongDetailsScreen> {
  final distance = latlong.Distance();
  final storage = FlutterSecureStorage();
  bool checked = false;
  String hideInstructionKey = 'hide_instruction_manong_details_screen';
  late ServiceRequest? _serviceRequest;
  late Manong? _manong;

  // Bookmark state
  bool _isBookmarked = false;
  bool _isLoadingBookmark = false;

  @override
  void initState() {
    super.initState();
    _initializeComponents();
    showInstructionSheet(navigatorKey.currentContext!);
    _fetchBookmarkStatus();
  }

  void _initializeComponents() {
    _serviceRequest = widget.serviceRequest;
    _manong = widget.manong;
  }

  Future<void> _fetchBookmarkStatus() async {
    if (_manong == null) return;

    setState(() {
      _isLoadingBookmark = true;
    });

    try {
      final isBookmarked = await BookmarkItemApiService().isItemBookmarked(
        itemId: _manong!.appUser.id,
        type: BookmarkItemType.MANONG,
      );

      if (mounted) {
        setState(() {
          _isBookmarked = isBookmarked ?? false;
          _isLoadingBookmark = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isBookmarked = false;
          _isLoadingBookmark = false;
        });
      }
    }
  }

  Future<void> _toggleBookmark() async {
    if (_manong == null || _isLoadingBookmark) return;

    setState(() {
      _isLoadingBookmark = true;
    });

    try {
      if (_isBookmarked) {
        await BookmarkItemApiService().removeBookmark(
          itemId: _manong!.appUser.id,
          type: BookmarkItemType.MANONG,
        );
      } else {
        await BookmarkItemApiService().addBookmark(
          itemId: _manong!.appUser.id,
          type: BookmarkItemType.MANONG,
        );
      }

      if (mounted) {
        setState(() {
          _isBookmarked = !_isBookmarked;
          _isLoadingBookmark = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update bookmark'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoadingBookmark = false;
        });
      }
    }
  }

  Future<void> showInstructionSheet(BuildContext context) async {
    String? hideInstructions = await storage.read(key: hideInstructionKey);
    if (hideInstructions == 'true') return;

    showModalBottomSheet(
      context: navigatorKey.currentContext!,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: StatefulBuilder(
            builder: (context, setState) {
              return Padding(
                padding: const EdgeInsets.only(
                  top: 16,
                  left: 16,
                  right: 16,
                  bottom: 12,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 12),
                    Text(
                      'First time booking with Manong?',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Just a few reminders before you book!',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 24),
                    InstructionSteps(),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Checkbox(
                          activeColor: AppColorScheme.primaryDark,
                          value: checked,
                          onChanged: (value) {
                            setState(() => checked = value!);

                            storage.write(
                              key: hideInstructionKey,
                              value: checked.toString(),
                            );
                          },
                        ),
                        const Text('Don\'t show this again'),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDistanceFee(double? meters) {
    return Column(
      children: [
        if (_serviceRequest?.serviceItem?.ratePerKm != null &&
            meters != null) ...[
          Row(
            children: [
              Icon(Icons.drive_eta, color: Colors.grey.shade700),
              PriceTag(
                price: CalculationTotals().distanceFee(
                  meters: meters,
                  ratePerKm: _serviceRequest!.serviceItem!.ratePerKm,
                ),
                showDecimals: false,
              ),
              const SizedBox(width: 4),
              if (CalculationTotals().distanceFee(
                    meters: meters,
                    ratePerKm: _serviceRequest!.serviceItem!.ratePerKm,
                  ) ==
                  400) ...[
                Text('(capped)'),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildBookmarkButton() {
    if (_isLoadingBookmark) {
      return SizedBox(
        width: 32,
        height: 32,
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColorScheme.primaryColor,
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _toggleBookmark,
      child: Container(
        width: 32,
        height: 32,
        child: Center(
          child: Icon(
            _isBookmarked ? Icons.bookmark_added : Icons.bookmark_add_outlined,
            color: _isBookmarked ? Colors.amber : Colors.grey[600],
            size: 28,
          ),
        ),
      ),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      DistanceMatrix().formatDistance(meters ?? 0),
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.red.shade700,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '(${DistanceMatrix().formatDistance(meters ?? 0)})',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),

                // -- Distance Fee
                // _buildDistanceFee(meters),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // --- Accept Button
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/booking-summary',
                      arguments: {
                        'serviceRequest': _serviceRequest!,
                        'manong': _manong,
                        'meters': meters,
                      },
                    );
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
                  child: Text('Accept'),
                ),
              ),
            ],
          ),

          // -- More details
          Visibility(
            visible: true,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: Column(
              children: [
                const SizedBox(height: 3),
                Text(
                  "More details about the Manong...",
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          SizedBox(height: 12),

          // -- Manong Name with bookmark
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Name",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _manong?.appUser.firstName ?? "No name",
                            style: TextStyle(fontSize: 18, color: Colors.black),
                          ),
                        ),
                        if (_manong?.profile!.isProfessionallyVerified ==
                            true) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.verified_rounded,
                            size: 20,
                            color: Colors.lightBlue,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              _buildBookmarkButton(),
            ],
          ),
          SizedBox(height: 8),

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
                    _manong!.profile!.status.name,
                  ).withOpacity(0.1),
                  border: Border.all(
                    color: getStatusBorderColor(_manong!.profile!.status.name),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                child: Text(
                  _manong!.profile!.status.name,
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

          if (_manong!.profile!.specialities != null &&
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
              children: widget.manong!.profile!.specialities!.map((item) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _serviceRequest?.subServiceItem != null
                        ? item.subServiceItem.title.contains(
                                _serviceRequest!.subServiceItem!.title,
                              )
                              ? Colors.amber.withOpacity(0.7)
                              : AppColorScheme.primaryColor.withOpacity(0.1)
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
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final meters = DistanceMatrix().calculateDistance(
      startLat: _serviceRequest?.customerLat ?? 0,
      startLng: _serviceRequest?.customerLng ?? 0,
      endLat: _manong?.appUser.latitude,
      endLng: _manong?.appUser.longitude,
    );

    return Material(
      child: Stack(
        children: [
          Positioned.fill(
            child: RouteTrackingScreen(
              currentLatLng: LatLng(
                _serviceRequest?.customerLat ?? 0,
                _serviceRequest?.customerLng ?? 0,
              ),
              manongLatLng: LatLng(
                _manong?.appUser.latitude ?? 0,
                _manong?.appUser.longitude ?? 0,
              ),
              manongName: _manong?.appUser.firstName ?? '',
              serviceRequest: _serviceRequest,
              useManongAsTitle: true,
            ),
          ),
          SafeArea(
            child: DraggableScrollableSheet(
              initialChildSize: 0.20,
              minChildSize: 0.05,
              maxChildSize: _manong!.profile!.specialities!.length >= 6
                  ? 0.7
                  : 0.5,
              snap: true,
              snapSizes: [
                0.20,
                _manong!.profile!.specialities!.length >= 6 ? 0.7 : 0.5,
              ],
              builder: (context, scrollController) {
                return _buildBottomNav(meters, scrollController);
              },
            ),
          ),
        ],
      ),
    );
  }
}
