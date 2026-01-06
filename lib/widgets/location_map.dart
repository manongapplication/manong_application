import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/main.dart';
import 'package:manong_application/utils/get_location.dart';
import 'package:manong_application/widgets/my_app_bar.dart';

class LocationMap extends StatefulWidget {
  const LocationMap({super.key});

  @override
  _LocationMapState createState() => _LocationMapState();
}

class _LocationMapState extends State<LocationMap> {
  GoogleMapController? _mapController;
  LatLng? _currentLatLng;
  final Set<Marker> _markers = {};
  final Logger logger = Logger('location_map');
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    if (!mounted) return;

    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final result = await GetLocation().getCurrentLocation(
        navigatorKey.currentContext!,
      );

      if (!mounted) return;

      if (result != null) {
        final position = result.position;
        final latLng = LatLng(position.latitude, position.longitude);

        setState(() {
          _currentLatLng = latLng;
          _isLoading = false;
          _hasError = false;

          // Add the red pinpoint marker
          _markers.clear();
          _markers.add(
            Marker(
              markerId: const MarkerId('current_location'),
              position: latLng,
              infoWindow: const InfoWindow(title: 'Your Home Address'),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed, // This makes it a RED pinpoint
              ),
              anchor: const Offset(0.5, 0.5), // Center the marker on the point
            ),
          );
        });

        // Center the map on the location
        _centerMapOnLocation(latLng);
      } else {
        _handleLocationError();
      }
    } catch (e) {
      logger.severe('Error getting location: $e');
      if (mounted) {
        _handleLocationError();
      }
    }
  }

  void _centerMapOnLocation(LatLng latLng) {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: latLng, zoom: 16),
        ),
      );
    }
  }

  void _handleLocationError() {
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _hasError = true;
    });
  }

  void _retryLocation() {
    _getCurrentLocation();
  }

  Widget _buildMapContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(height: 8),
            Text(
              'Getting your location...',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_hasError || _currentLatLng == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off, color: Colors.red, size: 24),
            const SizedBox(height: 8),
            const Text(
              'Location unavailable',
              style: TextStyle(fontSize: 12, color: Colors.red),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _retryLocation,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: const Text('Retry', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      );
    }

    return GoogleMap(
      onMapCreated: (controller) => _mapController = controller,
      initialCameraPosition: CameraPosition(target: _currentLatLng!, zoom: 16),
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      markers: _markers, // Add the markers set to the map
      onTap: (_) {}, // Optional: Handle map taps if needed
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: myAppBar(title: 'Home Address'),
      body: SafeArea(child: _buildMapContent()),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
