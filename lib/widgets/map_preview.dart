import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/main.dart';
import 'package:manong_application/models/location_result.dart';
import 'package:manong_application/utils/get_location.dart';

class MapPreview extends StatefulWidget {
  final bool? enableMarkers;
  final Function(LocationResult)? onLocationResult;
  final Function(double latitude, double longitude)? onPosition;
  final VoidCallback? onError;
  
  const MapPreview({
    super.key,
    this.enableMarkers,
    this.onLocationResult,
    this.onPosition,
    this.onError,
  });

  @override
  State<MapPreview> createState() => _MapPreviewState();
}

class _MapPreviewState extends State<MapPreview> {
  GoogleMapController? _mapController;
  LatLng? _currentLatLng;
  final Set<Marker> markers = {};
  final Logger logger = Logger('map_preview');
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

      final result = await GetLocation().getCurrentLocation(context);
      
      if (!mounted) return;
      
      if (result != null) {
        final position = result.position;
        final latLng = LatLng(position.latitude, position.longitude);
        
        setState(() {
          _currentLatLng = latLng;
          _isLoading = false;
          _hasError = false;

          if (widget.enableMarkers == true) {
            markers.clear(); // Clear existing markers
            markers.add(
              Marker(
                markerId: const MarkerId('current_location'),
                position: latLng,
                infoWindow: const InfoWindow(title: 'You are here'),
                icon: BitmapDescriptor.defaultMarker, // Ensure default marker
              ),
            );
          }
        });

        // Call callbacks
        widget.onPosition?.call(position.latitude, position.longitude);
        widget.onLocationResult?.call(result);
        
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

  void _handleLocationError() {
    if (!mounted) return;
    
    setState(() {
      _isLoading = false;
      _hasError = true;
    });
    
    widget.onError?.call();
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
              'Getting location...',
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _currentLatLng!,
        zoom: 15,
      ),
      zoomControlsEnabled: false,
      myLocationButtonEnabled: false,
      myLocationEnabled: false,
      onMapCreated: (controller) {
        _mapController = controller;
      },
      markers: markers,
      onTap: (latLng) {
        // Optional: handle map tap
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/location-map');
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: AbsorbPointer(
            child: _buildMapContent(),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}