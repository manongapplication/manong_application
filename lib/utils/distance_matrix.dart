import 'package:latlong2/latlong.dart' as latlong;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as latlong;

class DistanceMatrix {
  final distance = latlong.Distance();

  double? calculateDistance({
    required double? startLat,
    required double? startLng,
    required double? endLat,
    required double? endLng,
  }) {
    if (startLat == null ||
        startLng == null ||
        endLat == null ||
        endLng == null) {
      return null;
    }

    return distance.as(
      latlong.LengthUnit.Meter,
      latlong.LatLng(startLat, startLng),
      latlong.LatLng(endLat, endLng),
    );
  }

  String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()}m';
    } else {
      final km = meters / 1000;
      return '${km.toStringAsFixed(1)}km';
    }
  }

  String estimateTime(double meters, {double speedKmh = 30}) {
    // convert km/h → m/s
    const arrivalThreshold = 50;

    if (meters <= arrivalThreshold) {
      return 'Arrived';
    }

    // adjust assumed speed by distance
    double speedKmh;
    if (meters < 2000) {
      speedKmh = 20; // city traffic
    } else if (meters < 10000) {
      speedKmh = 30; // mixed
    } else {
      speedKmh = 60; // highway
    }

    final speedMs = speedKmh * 1000 / 3600;
    final seconds = meters / speedMs;
    final minutes = seconds / 60;

    if (minutes < 1) return "${seconds.round()} sec";
    if (minutes < 60) return "${minutes.round()} min";

    final hours = minutes / 60;
    return hours == hours.roundToDouble()
        ? "${hours.toInt()} hr"
        : "${hours.toStringAsFixed(1)} hr";
  }

  LatLng toGoogleLatLng(latlong.LatLng? ll) {
    if (ll == null) {
      throw Exception('ll is required!');
    }
    return LatLng(ll.latitude, ll.longitude);
  }
}
