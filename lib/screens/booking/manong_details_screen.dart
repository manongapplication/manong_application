import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:manong_application/main.dart';
import 'package:manong_application/models/manong.dart';
import 'package:manong_application/models/service_request.dart';
import 'package:manong_application/models/sub_service_item.dart';
import 'package:manong_application/screens/service_requests/route_tracking_screen.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:manong_application/utils/color_utils.dart';
import 'package:manong_application/utils/distance_matrix.dart';
import 'package:manong_application/utils/icon_mapper.dart';
import 'package:manong_application/widgets/instruction_steps.dart';

class ManongDetailsScreen extends StatefulWidget {
  final LatLng? currentLatLng;
  final LatLng? manongLatLng;
  final String? manongName;
  final Manong? manong;
  final Color? iconColor;
  final ServiceRequest? serviceRequest;
  final SubServiceItem? subServiceItem;

  const ManongDetailsScreen({
    super.key,
    this.currentLatLng,
    this.manongLatLng,
    this.manongName,
    this.manong,
    this.iconColor,
    this.serviceRequest,
    this.subServiceItem,
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

  @override
  void initState() {
    super.initState();
    _initializeComponents();
    showInstructionSheet(navigatorKey.currentContext!);
  }

  void _initializeComponents() {
    _serviceRequest = widget.serviceRequest;
    _manong = widget.manong;
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

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()}m';
    } else {
      final km = meters / 1000;
      return '${km.toStringAsFixed(1)}km';
    }
  }

  String _estimateTime(double meters, {double speedKmh = 30}) {
    // convert km/h → m/s
    final speedMs = speedKmh * 1000 / 3600;

    final seconds = meters / speedMs;
    final minutes = seconds / 60;

    if (minutes < 1) {
      return "${seconds.round()} sec";
    } else if (minutes < 60) {
      return "${minutes.round()} min";
    } else {
      final hours = minutes / 60;
      // ✅ if whole number, show as int, else 1 decimal
      return hours == hours.roundToDouble()
          ? "${hours.toInt()} hr"
          : "${hours.toStringAsFixed(1)} hr";
    }
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
          Row(
            children: [
              SizedBox(width: 10),
              Text(
                _estimateTime(meters ?? 0),
                style: TextStyle(fontSize: 18, color: Colors.red.shade700),
              ),
              SizedBox(width: 8),
              Text(
                '(${_formatDistance(meters ?? 0)})',
                style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
              ),
              Spacer(),
            ],
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

          // -- Manong Name
          Text(
            "Name",
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
          SizedBox(height: 4),

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
                    _manong!.profile!.status,
                  ).withOpacity(0.1),
                  border: Border.all(
                    color: getStatusBorderColor(_manong!.profile!.status),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                child: Text(
                  _manong!.profile!.status,
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
                    color: widget.subServiceItem != null
                        ? item.subServiceItem.title.contains(
                                widget.subServiceItem!.title,
                              )
                              ? Colors.amber.withOpacity(0.7)
                              : AppColorScheme.primaryColor.withOpacity(0.1)
                        : AppColorScheme.primaryColor.withOpacity(0.1),
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
      endLat: widget.manongLatLng!.latitude,
      endLng: widget.manongLatLng!.longitude,
    );

    return Material(
      child: Stack(
        children: [
          Positioned.fill(
            child: RouteTrackingScreen(
              currentLatLng: widget.currentLatLng,
              manongLatLng: widget.manongLatLng,
              manongName: widget.manongName,
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
