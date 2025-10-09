import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/main.dart';
import 'package:manong_application/models/location_result.dart';

class GetLocation {
  final Logger logger = Logger('get_location');

  Future<LocationResult?> getCurrentLocation(BuildContext context) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      showDialog(
        context: navigatorKey.currentContext!,
        builder: (context) => AlertDialog(
          title: Text('Location Disabled'),
          content: Text(
            'Please enable location services to use this feauture.',
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await Geolocator.openLocationSettings();
                await Future.delayed(Duration(seconds: 2));
                Navigator.of(
                  navigatorKey.currentContext!,
                ).pushNamedAndRemoveUntil('/', (route) => false);
              },
              child: Text('Open Settings'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
          ],
        ),
      );

      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied');
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    String? locationName;
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        locationName =
            place.locality ?? // City/Town
            place.subAdministrativeArea ?? // Province/District
            place.administrativeArea ?? // Region
            place.subLocality ?? // Barangay/District
            place.thoroughfare ?? // Street
            place.name ?? // POI/Address
            place.country ?? // Country
            '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}'; // Coordinates as fallback

        logger.info("Placemark details:");
        logger.info("Name: ${place.name}");
        logger.info("Street: ${place.street}");
        logger.info("Thoroughfare: ${place.thoroughfare}");
        logger.info("SubThoroughfare: ${place.subThoroughfare}");
        logger.info("Locality: ${place.locality}");
        logger.info("SubLocality: ${place.subLocality}");
        logger.info("SubAdministrativeArea: ${place.subAdministrativeArea}");
        logger.info("AdministrativeArea: ${place.administrativeArea}");
        logger.info("PostalCode: ${place.postalCode}");
        logger.info("Country: ${place.country}");
        logger.info("IsoCountryCode: ${place.isoCountryCode}");
        logger.info("Final location name: $locationName");
      } else {
        locationName =
            '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      }
    } catch (e) {
      logger.severe("Geolocator error $e");
    }

    return LocationResult(position: position, locationName: locationName);
  }

  String displayDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    } else {
      return '${meters.toStringAsFixed(0)} m';
    }
  }

  Future<String> testGeocoding() async {
    try {
      // Test with a known location in Philippines (Angeles City coordinates)
      double lat = 15.1394;
      double lng = 120.5883;

      logger.info("Testing geocoding for Angeles City coordinates...");
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        logger.info("Test geocoding successful!");
        logger.info("Locality: ${place.locality}");
        logger.info("Administrative Area: ${place.administrativeArea}");
        logger.info("Country: ${place.country}");

        String locationName =
            place.locality ??
            place.subAdministrativeArea ??
            place.administrativeArea ??
            place.subLocality ??
            place.thoroughfare ??
            place.name ??
            place.country ??
            'Lat: $lat, Lng: $lng';

        return "Success: $locationName";
      } else {
        return "No placemarks found for test coordinates";
      }
    } catch (e) {
      return "Test geocoding failed: $e";
    }
  }
}
