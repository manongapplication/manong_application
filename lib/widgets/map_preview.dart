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
  const MapPreview({
    super.key,
    this.enableMarkers,
    this.onLocationResult,
    this.onPosition,
  });

  @override
  State<MapPreview> createState() => _MapPreviewState();
}

class _MapPreviewState extends State<MapPreview> {
  GoogleMapController? _mapController;
  LatLng? _currentLatLng;
  final Set<Marker> markers = {};
  final Logger logger = Logger('map_preview');

  @override
  void initState() {
    super.initState();

    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final result = await GetLocation().getCurrentLocation(
        navigatorKey.currentContext!,
      );
      if (result != null && mounted) {
        final position = result.position;
        final latLng = LatLng(position.latitude, position.longitude);
        widget.onPosition!(position.latitude, position.longitude);
        setState(() {
          _currentLatLng = latLng;

          if (widget.enableMarkers == true) {
            markers.add(
              Marker(
                markerId: const MarkerId('current_location'),
                position: latLng,
                infoWindow: const InfoWindow(title: 'You are here'),
              ),
            );
          }
        });

        if (widget.onLocationResult != null) {
          widget.onLocationResult!(result);
        }
      }
    } catch (e) {
      logger.severe('Error getting location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(navigatorKey.currentContext!, '/location-map');
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 100,
          child: AbsorbPointer(
            child: _currentLatLng == null
                ? Center(child: CircularProgressIndicator())
                : GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _currentLatLng!,
                      zoom: 15,
                    ),
                    zoomControlsEnabled: false,
                    myLocationButtonEnabled: false,
                    onMapCreated: (controller) {},
                    markers: markers,
                  ),
          ),
        ),
      ),
    );
  }
}
