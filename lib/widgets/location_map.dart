import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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

  final Logger logger = Logger('location_map');

  @override
  void initState() {
    super.initState();
    _initializeComponents();
  }

  void _initializeComponents() {
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final result = await GetLocation().getCurrentLocation(
        navigatorKey.currentContext!,
      );

      if (result != null && mounted) {
        final position = result.position;

        setState(() {
          _currentLatLng = LatLng(position.latitude, position.longitude);
        });
      }
    } catch (e) {
      logger.severe('Error getting location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: myAppBar(title: 'Home Address'),
      body: _currentLatLng == null
          ? Center(child: CircularProgressIndicator())
          : SafeArea(
              child: GoogleMap(
                onMapCreated: (controller) => _mapController = controller,
                initialCameraPosition: CameraPosition(
                  target: _currentLatLng!,
                  zoom: 16,
                ),
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
              ),
            ),
    );
  }
}
