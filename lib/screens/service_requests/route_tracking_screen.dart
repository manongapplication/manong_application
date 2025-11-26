import 'dart:math';

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
  late PermissionUtils _permissionUtils;
  ValueNotifier<latlong.LatLng?>? _manongLatLngNotifier;
  late ServiceRequest? _serviceRequest;
  bool _locationPermissionGranted = false;
  bool _showFarApartDialog = false;

  String googleAPIKey = dotenv.env['GOOGLE_API_KEY']!;

  @override
  void initState() {
    super.initState();
    _initializeComponents();
    _initializePermission();
  }

  void _initializeComponents() {
    _serviceRequest = widget.serviceRequest;
    _permissionUtils = PermissionUtils();
    _currentLatLng = widget.currentLatLng;
    _manongLatLng = widget.manongLatLng;
    _manongName = widget.manongName;
    _manongLatLngNotifier = widget.manongLatLngNotifier;

    circles = {
      if (_manongLatLng != null)
        Circle(
          circleId: const CircleId('manongCircle'),
          center: _manongLatLng!,
          radius: 30,
          strokeColor: AppColorScheme.primaryColor,
          strokeWidth: 2,
          fillColor: AppColorScheme.primaryColor.withOpacity(0.2),
        ),
    };
  }

  Future<void> _initializePermission() async {
    try {
      // Check current permission status without requesting
      _locationPermissionGranted = await _permissionUtils.isLocationPermissionGranted();
      
      // Only request permission if features are enabled and we don't have permission
      if (widget.enableLocationFeatures && !_locationPermissionGranted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showPermissionDialog();
        });
      }

      // Load map data regardless of permission
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (_currentLatLng != null && _manongLatLng != null) {
          // Check if coordinates are valid and not too far apart
          if (_areCoordinatesValid()) {
            if (_serviceRequest?.status != ServiceRequestStatus.inProgress) {
              await _getPolyline();
            }
            _listenToManongMovement();
          } else {
            // Show dialog for far apart locations instead of error
            setState(() {
              _showFarApartDialog = true;
              _isLoading = false;
            });
            _showFarApartLocationDialog();
          }
        } else {
          setState(() {
            _error = 'Location data not available';
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      logger.severe('Error initializing permissions: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _areCoordinatesValid() {
    if (_currentLatLng == null || _manongLatLng == null) return false;
    
    // Check if coordinates are within reasonable distance (same country/city)
    // Calculate approximate distance in kilometers
    double distance = _calculateDistance(
      _currentLatLng!.latitude,
      _currentLatLng!.longitude,
      _manongLatLng!.latitude,
      _manongLatLng!.longitude,
    );
    
    logger.info('Distance between points: ${distance.toStringAsFixed(2)} km');
    
    // If distance is more than 500km, likely invalid for driving
    return distance < 500;
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);
    
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * pi / 180;
  }

  // Convert latlong2.LatLng to Google Maps LatLng
  LatLng _toGoogleLatLng(latlong.LatLng latLng) {
    return LatLng(latLng.latitude, latLng.longitude);
  }

  Future<void> _showFarApartLocationDialog() async {
    if (!mounted || !_showFarApartDialog) return;

    double distance = _calculateDistance(
      _currentLatLng!.latitude,
      _currentLatLng!.longitude,
      _manongLatLng!.latitude,
      _manongLatLng!.longitude,
    );

    showDialog(
      context: navigatorKey.currentContext!,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 48,
                  color: Colors.orange,
                ),
                const SizedBox(height: 16),
                Text(
                  'Locations Are Far Apart',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'The driver is approximately ${distance.toStringAsFixed(0)} km away. '
                  'You can still view their location on the map.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _showFarApartDialog = false;
                          });
                          Navigator.of(context).pop();
                        },
                        child: const Text('Close'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _showFarApartDialog = false;
                          });
                          Navigator.of(context).pop();
                          _centerOnManong();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColorScheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('View Driver'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

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
              circleId: const CircleId('manongCircle'),
              center: manongPosition,
              radius: 30,
              strokeColor: AppColorScheme.primaryColor,
              strokeWidth: 2,
              fillColor: AppColorScheme.primaryColor.withOpacity(0.2),
            ),
          };
        });
      } else {
        logger.warning('No route found for updated manong position');
      }
    } catch (e) {
      logger.severe('Error updating polyline for current Manong: $e');
    }
  }

  void _listenToManongMovement() {
    if (_manongLatLngNotifier != null &&
        _serviceRequest?.status == ServiceRequestStatus.inProgress) {
      _manongLatLngNotifier!.addListener(() {
        final value = _manongLatLngNotifier?.value;
        if (value == null) return;

        final newLatLng = _toGoogleLatLng(value);
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

  Future<void> _getPolyline() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      if (!mounted) return;

      logger.info('Getting route for Manong $_manongName');

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

      logger.info('Requesting route from (${_currentLatLng!.latitude}, ${_currentLatLng!.longitude}) to (${_manongLatLng!.latitude}, ${_manongLatLng!.longitude})');

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
          polylines = {
            Polyline(
              polylineId: const PolylineId('route'),
              points: polylineCoordinates,
              color: AppColorScheme.primaryColor,
              width: 5,
            ),
          };
        });

        // Adjust camera to show both markers
        _fitCameraToBounds();

        logger.info(
          'Polyline created with ${polylineCoordinates.length} points',
        );
      } else {
        logger.warning('No route found - result: ${result.errorMessage}');
        // Don't show error for far apart locations, just show markers
        _fitCameraToBounds();
      }
    } catch (e) {
      logger.severe('Error getting polyline: $e');
      // Don't show error for far apart locations, just show markers
      _fitCameraToBounds();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _fitCameraToBounds() {
    if (mapController == null || _currentLatLng == null || _manongLatLng == null) return;

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

  Widget _buildGoogleMap() {
    if (_currentLatLng == null || _manongLatLng == null) {
      return const Center(
        child: Text(
          'Location data not available',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    logger.info(
      'Map coordinates - Current: ${_currentLatLng?.latitude}, ${_currentLatLng?.longitude} | Manong: ${_manongLatLng?.latitude}, ${_manongLatLng?.longitude}',
    );

    // Only enable location features if permission is granted AND explicitly enabled
    bool enableLocation = widget.enableLocationFeatures && _locationPermissionGranted;

    if (_manongLatLngNotifier != null &&
        _serviceRequest?.status == ServiceRequestStatus.inProgress) {
      return ValueListenableBuilder<latlong.LatLng?>(
        valueListenable: _manongLatLngNotifier!,
        builder: (context, value, child) {
          LatLng? newLatLng;
          if (value != null) {
            newLatLng = _toGoogleLatLng(value);
          } else {
            newLatLng = _manongLatLng;
          }

          if (newLatLng == null) {
            return const Center(child: Text('No manong location available'));
          }

          return SafeArea(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentLatLng!,
                zoom: _getInitialZoomLevel(),
              ),
              onMapCreated: (controller) {
                mapController = controller;
                if (polylineCoordinates.isNotEmpty) {
                  _fitCameraToBounds();
                } else {
                  // If no polyline, still fit bounds
                  _fitCameraToBounds();
                }
              },
              markers: _buildMarkers(newLatLng),
              polylines: polylines,
              circles: circles,
              myLocationEnabled: enableLocation,
              myLocationButtonEnabled: enableLocation,
              zoomControlsEnabled: false,
            ),
          );
        },
      );
    }

    return SafeArea(
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _currentLatLng!,
          zoom: _getInitialZoomLevel(),
        ),
        onMapCreated: (controller) {
          mapController = controller;
          if (polylineCoordinates.isNotEmpty) {
            _fitCameraToBounds();
          } else {
            // If no polyline, still fit bounds
            _fitCameraToBounds();
          }
        },
        markers: _buildMarkers(_manongLatLng!),
        polylines: polylines,
        circles: circles,
        myLocationEnabled: enableLocation,
        myLocationButtonEnabled: enableLocation,
        zoomControlsEnabled: false,
      ),
    );
  }

  double _getInitialZoomLevel() {
    if (_currentLatLng == null || _manongLatLng == null) return 12;
    
    double distance = _calculateDistance(
      _currentLatLng!.latitude,
      _currentLatLng!.longitude,
      _manongLatLng!.latitude,
      _manongLatLng!.longitude,
    );
    
    // Adjust zoom based on distance
    if (distance > 1000) return 4;   // Country level
    if (distance > 100) return 8;    // Regional level
    if (distance > 10) return 10;    // City level
    return 12;                       // Local level
  }

  Set<Marker> _buildMarkers(LatLng manongPosition) {
    return {
      Marker(
        markerId: const MarkerId('origin'),
        position: _currentLatLng!,
        infoWindow: const InfoWindow(title: "You"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
      Marker(
        markerId: const MarkerId('destination'),
        position: manongPosition,
        infoWindow: InfoWindow(title: "Manong $_manongName"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    };
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 16),
            Text(
              'Loading route...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
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
                const Icon(Icons.warning, color: Colors.orange, size: 48),
                const SizedBox(height: 16),
                Text(
                  _error ?? 'Unable to calculate route',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Showing locations without route',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _getPolyline,
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _centerOnManong() {
    if (mapController != null && _manongLatLng != null) {
      mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _manongLatLng!, zoom: 16),
        ),
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

  Future<void> _requestLocationPermission() async {
    try {
      await _permissionUtils.checkLocationPermission();
      bool granted = await _permissionUtils.isLocationPermissionGranted();
      
      setState(() {
        _locationPermissionGranted = granted;
      });
      
      if (!granted && mounted) {
        _showPermissionDialog();
      }
    } catch (e) {
      logger.severe('Error requesting location permission: $e');
    }
  }

  Future<void> _showPermissionDialog() async {
    if (!mounted) return;

    showDialog(
      context: navigatorKey.currentContext!,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ModalIconOverlay(
            icons: Icons.location_off,
            description: 'Location permission is required to show your current position on the map',
            onPressed: () async {
              await _requestLocationPermission();
              if (mounted) Navigator.of(navigatorKey.currentContext!).pop();
            },
          ),
        );
      },
    );
  }

  Widget _buildLocationRequestButton() {
    if (_locationPermissionGranted || !widget.enableLocationFeatures) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 80,
      right: 10,
      child: Material(
        elevation: 4,
        shape: const CircleBorder(),
        child: IconButton(
          onPressed: _requestLocationPermission,
          icon: const Icon(Icons.my_location),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.blue,
          ),
        ),
      ),
    );
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

          // Navigation buttons
          if (_currentLatLng != null && _manongLatLng != null)
            Positioned(
              top: 10,
              left: 10,
              child: Column(
                children: [
                  Material(
                    elevation: 4,
                    shape: const CircleBorder(),
                    child: IconButton(
                      onPressed: _centerOnManong,
                      icon: const Icon(Icons.directions_car),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Material(
                    elevation: 4,
                    shape: const CircleBorder(),
                    child: IconButton(
                      onPressed: _centerOnUser,
                      icon: const Icon(Icons.person),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Location request button
          _buildLocationRequestButton(),

          if (_isLoading) _buildLoadingOverlay(),

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