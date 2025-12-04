import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/main.dart';
import 'package:manong_application/models/service_request_status.dart';
import 'package:manong_application/models/service_request.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:manong_application/utils/distance_matrix.dart';
import 'package:manong_application/utils/permission_utils.dart';
import 'package:manong_application/widgets/my_app_bar.dart';
import 'package:manong_application/widgets/modal_icon_overlay.dart';
import 'package:latlong2/latlong.dart' as latlong;

class RouteTrackingScreen extends StatefulWidget {
  final LatLng? currentLatLng;
  final LatLng? manongLatLng;
  final String? manongName;
  final bool? isManong;
  final ValueNotifier<latlong.LatLng?>? manongLatLngNotifier;
  final ServiceRequest? serviceRequest;
  final bool? useManongAsTitle;
  final bool enableLocationFeatures;

  const RouteTrackingScreen({
    super.key,
    this.currentLatLng,
    this.manongLatLng,
    this.manongName,
    this.isManong,
    this.manongLatLngNotifier,
    this.serviceRequest,
    this.useManongAsTitle,
    this.enableLocationFeatures = false,
  });

  @override
  State<RouteTrackingScreen> createState() => _RouteTrackingScreenState();
}

class _RouteTrackingScreenState extends State<RouteTrackingScreen> {
  GoogleMapController? mapController;
  String? _manongName;
  LatLng? _currentLatLng;
  LatLng? _manongLatLng;
  final Logger logger = Logger('map_screen');

  List<LatLng> polylineCoordinates = [];
  Set<Polyline> polylines = {};
  late Set<Circle> circles;

  bool _isLoading = true;
  String? _error;
  late PermissionUtils? _permissionUtils;
  ValueNotifier<latlong.LatLng?>? _manongLatLngNotifier;
  late ServiceRequest? _serviceRequest;

  String googleAPIKey = dotenv.env['GOOGLE_API_KEY']!;

  @override
  void initState() {
    super.initState();
    _initializeComponents();
  }

  void _initializeComponents() {
    _serviceRequest = widget.serviceRequest;
    _permissionUtils = PermissionUtils();
    _currentLatLng = widget.currentLatLng;
    _manongLatLng = widget.manongLatLng;
    _manongName = widget.manongName;
    _manongLatLngNotifier = widget.manongLatLngNotifier;

    // OLD CODE: Circle setup
    if (_manongLatLng != null) {
      circles = {
        Circle(
          circleId: CircleId('manongCircle'),
          center: _manongLatLng!,
          radius: 30,
          strokeColor: AppColorScheme.primaryColor,
          strokeWidth: 2,
          fillColor: AppColorScheme.primaryColor.withOpacity(0.2),
        ),
      };
    } else {
      circles = {}; // Empty set if no manong location
    }
    // OLD CODE: Permission check and initialization
    _permissionUtils?.checkLocationPermission().then((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        setState(() {
          _isLoading = false;
        });
        if (_currentLatLng != null && _manongLatLng != null) {
          if (_serviceRequest?.status != ServiceRequestStatus.inProgress) {
            await _getPolyline();
          }
          _listenToManongMovement();
        } else {
          setState(() {
            _error = 'Invalid location data provided';
            _isLoading = false;
          });
        }
      });
    });
  }

  // NEW CODE: Better permission handling
  Future<void> _showPermissionDialog() async {
    if (_permissionUtils != null) {
      // NEW CODE: Check permission without requesting first
      bool granted = await _permissionUtils!.isLocationPermissionGranted();

      // NEW CODE: Only show dialog if features are enabled and no permission
      if (widget.enableLocationFeatures && !granted && mounted) {
        showDialog(
          context: navigatorKey.currentContext!,
          builder: (context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ModalIconOverlay(
                icons: Icons.location_off,
                description:
                    'Location permission is required to show your current position on the map',
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
  }

  // OLD CODE: Polyline update for manong movement
  Future<void> _updatePolylineForManong(LatLng manongPosition) async {
    _manongLatLng = manongPosition;
    try {
      PolylinePoints polylinePoints = PolylinePoints(apiKey: googleAPIKey);

      PolylineRequest request = PolylineRequest(
        origin: PointLatLng(manongPosition.latitude, manongPosition.longitude),
        destination: PointLatLng(
          _currentLatLng!.latitude,
          _currentLatLng!.longitude,
        ),
        mode: TravelMode.driving,
      );

      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        request: request,
      );

      if (result.points.isNotEmpty) {
        List<LatLng> newPolyline = result.points
            .map((p) => LatLng(p.latitude, p.longitude))
            .toList();

        setState(() {
          polylines = {
            Polyline(
              polylineId: const PolylineId('route'),
              points: newPolyline,
              color: AppColorScheme.primaryColor,
              width: 5,
            ),
          };

          circles = {
            Circle(
              circleId: CircleId('manongCircle'),
              center: manongPosition,
              radius: 30,
              strokeColor: AppColorScheme.primaryColor,
              strokeWidth: 2,
              fillColor: AppColorScheme.primaryColor.withOpacity(0.2),
            ),
          };
        });
      }
    } catch (e) {
      logger.severe('Error updating polyline for current Manong: $e');
    }
  }

  // OLD CODE: Listen to manong movement
  void _listenToManongMovement() {
    if (_manongLatLngNotifier != null &&
        _serviceRequest?.status == ServiceRequestStatus.inProgress) {
      _manongLatLngNotifier!.addListener(() {
        final value = _manongLatLngNotifier?.value;
        if (value == null) return;

        final newLatLng = DistanceMatrix().toGoogleLatLng(value);
        _manongLatLng = newLatLng;

        _updatePolylineForManong(newLatLng);

        mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: newLatLng, zoom: 18),
          ),
        );
      });
    }
  }

  // OLD CODE: Get polyline
  Future<void> _getPolyline() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      if (!mounted) return;

      logger.info('Manong $_manongName');

      PolylinePoints polylinePoints = PolylinePoints(apiKey: googleAPIKey);

      PolylineRequest request = PolylineRequest(
        origin: PointLatLng(
          _currentLatLng!.latitude,
          _currentLatLng!.longitude,
        ),
        destination: PointLatLng(
          _manongLatLng!.latitude,
          _manongLatLng!.longitude,
        ),
        mode: TravelMode.driving,
      );

      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        request: request,
      );

      if (result.points.isNotEmpty) {
        polylineCoordinates.clear();
        for (var point in result.points) {
          final latLng = LatLng(point.latitude, point.longitude);
          polylineCoordinates.add(latLng);
        }

        setState(() {
          polylines.add(
            Polyline(
              polylineId: const PolylineId('route'),
              points: polylineCoordinates,
              color: AppColorScheme.primaryColor,
              width: 5,
              patterns: [],
            ),
          );
        });

        // Adjust camera to show both markers
        _fitCameraToBounds();

        logger.info(
          'Polyline created with ${polylineCoordinates.length} points',
        );
      } else {
        logger.warning('No route found');
      }

      if (result.points.isEmpty) {
        logger.warning('No polyline points returned.');
        return;
      }
    } catch (e) {
      setState(() {
        _error = 'Error getting route: ${e.toString()}';
      });
      logger.severe('Error getting polyline: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // OLD CODE: Fit camera to bounds
  void _fitCameraToBounds() {
    if (mapController == null) return;

    double minLat = _currentLatLng!.latitude < _manongLatLng!.latitude
        ? _currentLatLng!.latitude
        : _manongLatLng!.latitude;
    double maxLat = _currentLatLng!.latitude > _manongLatLng!.latitude
        ? _currentLatLng!.latitude
        : _manongLatLng!.latitude;
    double minLng = _currentLatLng!.longitude < _manongLatLng!.longitude
        ? _currentLatLng!.longitude
        : _manongLatLng!.longitude;
    double maxLng = _currentLatLng!.longitude > _manongLatLng!.longitude
        ? _currentLatLng!.longitude
        : _manongLatLng!.longitude;

    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100.0));
  }

  // OLD CODE: Build Google Map
  Widget _buildGoogleMap() {
    if (_currentLatLng == null ||
        _manongLatLng == null ||
        _permissionUtils == null) {
      return const Center(child: Text('Location data not available'));
    }
    logger.info(
      'Swer 2 ${_manongLatLng?.latitude} ${_manongLatLng?.longitude}',
    );

    if (_manongLatLngNotifier != null &&
        _serviceRequest?.status == ServiceRequestStatus.inProgress) {
      return ValueListenableBuilder<latlong.LatLng?>(
        valueListenable: _manongLatLngNotifier!,
        builder: (context, value, child) {
          latlong.LatLng? newLatLng = value;
          if (value == null) {
            if (_manongLatLng != null) {
              newLatLng = latlong.LatLng(
                _manongLatLng!.latitude,
                _manongLatLng!.longitude,
              );
            }
          }

          return SafeArea(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentLatLng!,
                zoom: 12,
              ),
              onMapCreated: (controller) {
                mapController = controller;
                if (polylineCoordinates.isNotEmpty) {
                  _fitCameraToBounds();
                }
              },
              markers: {
                Marker(
                  markerId: MarkerId('origin'),
                  position: _currentLatLng!,
                  infoWindow: const InfoWindow(title: "You"),
                ),
                Marker(
                  markerId: MarkerId('destination'),
                  position: DistanceMatrix().toGoogleLatLng(newLatLng),
                  infoWindow: InfoWindow(title: "Manong $_manongName"),
                ),
              },
              polylines: polylines,
              circles: circles,
              myLocationEnabled: _permissionUtils!.locationPermissionGranted,
              myLocationButtonEnabled:
                  _permissionUtils!.locationPermissionGranted,
            ),
          );
        },
      );
    }

    return SafeArea(
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _currentLatLng!,
          zoom: 12,
        ),
        onMapCreated: (controller) {
          mapController = controller;
          if (polylineCoordinates.isNotEmpty) {
            _fitCameraToBounds();
          }
        },
        markers: {
          Marker(
            markerId: MarkerId('origin'),
            position: _currentLatLng!,
            infoWindow: const InfoWindow(title: "You"),
          ),
          Marker(
            markerId: MarkerId('destination'),
            position: _manongLatLng!,
            infoWindow: InfoWindow(title: "Manong $_manongName"),
          ),
        },
        polylines: polylines,
        circles: circles,
        myLocationEnabled: _permissionUtils!.locationPermissionGranted,
        myLocationButtonEnabled: _permissionUtils!.locationPermissionGranted,
      ),
    );
  }

  // MODIFIED: Loading overlay that doesn't block the map
  Widget _buildLoadingOverlay() {
    return Positioned(
      bottom: 200,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Loading route...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  _error ?? 'Unknown error occurred',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _getPolyline,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _centerOnManong() {
    LatLng? targetLocation;

    // Check if service is in progress and we have a notifier with value
    if (_serviceRequest?.status == ServiceRequestStatus.inProgress &&
        _manongLatLngNotifier != null &&
        _manongLatLngNotifier!.value != null) {
      // Service is in progress: use real-time location from notifier
      targetLocation = DistanceMatrix().toGoogleLatLng(
        _manongLatLngNotifier!.value!,
      );
      logger.info(
        'Service IN PROGRESS - Centering on manong using notifier: ${targetLocation.latitude}, ${targetLocation.longitude}',
      );
    } else {
      // Service is NOT in progress: use the base/stored location
      targetLocation = _manongLatLng;
      logger.info(
        'Service NOT in progress - Centering on manong using base location: ${targetLocation?.latitude}, ${targetLocation?.longitude}',
      );
    }

    if (mapController != null && targetLocation != null) {
      mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: targetLocation, zoom: 16),
        ),
      );
    } else {
      logger.warning(
        'Cannot center on manong - mapController: ${mapController != null}, targetLocation: $targetLocation',
      );
    }
  }

  void _centerOnUser() {
    if (mapController != null && _currentLatLng != null) {
      mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _currentLatLng!, zoom: 16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: myAppBar(
        title: widget.useManongAsTitle == true
            ? 'Manong ${_manongName.toString()}'
            : _serviceRequest?.status == ServiceRequestStatus.inProgress
            ? _serviceRequest?.arrivedAt != null
                  ? 'Manong has arrived!'
                  : 'Manong is on the way...'
            : '${_serviceRequest?.serviceItem?.title != null ? '${_serviceRequest?.serviceItem?.title} ->' : ''}  ${_serviceRequest!.otherServiceName.toString().trim().isNotEmpty ? _serviceRequest?.otherServiceName : _serviceRequest?.subServiceItem?.title ?? ''}',
        fontSize: 18,
      ),
      body: Stack(
        children: [
          _buildGoogleMap(),

          Positioned(
            top: 10,
            left: 10,
            child: Column(
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: FloatingActionButton(
                    onPressed: _centerOnManong,
                    backgroundColor: Colors.white.withOpacity(0.8),
                    foregroundColor: Colors.grey.shade600,
                    child: const Icon(Icons.directions_car),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: FloatingActionButton(
                    onPressed: _centerOnUser,
                    backgroundColor: Colors.white.withOpacity(0.8),
                    foregroundColor: Colors.grey.shade600,
                    child: const Icon(Icons.person),
                  ),
                ),
              ],
            ),
          ),

          // Non-blocking loading indicator - ONLY SHOW WHEN NO POLYLINES
          if (_isLoading && polylines.isEmpty) _buildLoadingOverlay(),

          if (_error != null && !_isLoading) _buildErrorOverlay(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    mapController?.dispose();
    super.dispose();
  }
}
