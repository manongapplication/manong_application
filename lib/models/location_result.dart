import 'package:geolocator/geolocator.dart';

class LocationResult {
  final Position position;
  final String? locationName;

  LocationResult({required this.position, required this.locationName});
}