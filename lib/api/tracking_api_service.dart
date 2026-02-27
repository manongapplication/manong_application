import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/api/socket_api_service.dart';
import 'package:manong_application/utils/distance_matrix.dart';
// ignore: library_prefixes

class TrackingApiService {
  static final TrackingApiService _instance = TrackingApiService._internal();
  factory TrackingApiService() => _instance;
  TrackingApiService._internal();

  final Logger logger = Logger('TrackingApiService');
  final SocketApiService socketService = SocketApiService();
  StreamSubscription<Position>? positionStream;
  final DistanceMatrix _distanceMatrix = DistanceMatrix();
  ValueNotifier<LatLng?> manongLatLngNotifier = ValueNotifier(null);

  ValueNotifier<DateTime?> arrivalNotifier = ValueNotifier(null);
  ValueNotifier<double?> distanceNotifier = ValueNotifier(null);

  void joinRoom({required String manongId, required String serviceRequestId}) {
    final room = 'tracking:$manongId-$serviceRequestId';
    socketService.emit('joinTrackingRoom', {
      'manongId': manongId,
      'serviceRequestId': serviceRequestId,
    });

    _setupArrivalListener();
    logger.info('Joined room $room');
  }

  void _setupArrivalListener() {
    socketService.on('arrival:detected', (data) {
      logger.info('✅ ARRIVAL DETECTED via WebSocket');

      if (data['arrivedAt'] != null) {
        final arrivedAt = DateTime.parse(data['arrivedAt']);
        arrivalNotifier.value = arrivedAt;
      }
    });
  }

  void disconnect({
    required String manongId,
    required String serviceRequestId,
    double? lastKnownLat,
    double? lastKnownLng,
  }) {
    final room = 'tracking:$manongId-$serviceRequestId';
    socketService.emit('leaveTrackingRoom', {
      'manongId': manongId,
      'serviceRequestId': serviceRequestId,
      'lastKnownLat': lastKnownLat,
      'lastKnownLng': lastKnownLng,
    });

    socketService.off('arrival:detected');
    logger.info('Left room $room');
  }

  void sendLocation({
    required String manongId,
    required String serviceRequestId,
    required double lat,
    required double lng,
  }) {
    socketService.emit('sendLocation', {
      'manongId': manongId,
      'serviceRequestId': serviceRequestId,
      'lat': lat,
      'lng': lng,
    });
  }

  void startTracking({
    required String manongId,
    required String serviceRequestId,
    double? destinationLat,
    double? destinationLng,
  }) {
    positionStream?.cancel();

    positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen((Position position) {
          sendLocation(
            manongId: manongId,
            serviceRequestId: serviceRequestId,
            lat: position.latitude,
            lng: position.longitude,
          );

          // Update distance for UI
          if (destinationLat != null && destinationLng != null) {
            final distance = _distanceMatrix.calculateDistance(
              startLat: position.latitude,
              startLng: position.longitude,
              endLat: destinationLat,
              endLng: destinationLng,
            );

            if (distance != null) {
              distanceNotifier.value = distance;
            }
          }
        });
  }

  void onLocationUpdate(Function(Map<String, dynamic>) callback) {
    socketService.on('tracking:update', (data) {
      logger.info('Received location updates $data');
      manongLatLngNotifier.value = LatLng(data['lat'], data['lng']);
      callback(Map<String, dynamic>.from(data));
    });
  }

  void onArrivalDetected(Function(DateTime) callback) {
    arrivalNotifier.addListener(() {
      if (arrivalNotifier.value != null) {
        callback(arrivalNotifier.value!);
      }
    });
  }

  // Get estimated time string (matches your Flutter implementation)
  String? getEstimatedTime(double? meters) {
    if (meters == null) return null;
    return _distanceMatrix.estimateTime(meters);
  }

  // Get formatted distance string
  String? getFormattedDistance(double? meters) {
    if (meters == null) return null;
    return _distanceMatrix.formatDistance(meters);
  }

  void dispose() {
    stopTracking();
    socketService.dispose();
  }

  void stopTracking() {
    positionStream?.cancel();
    positionStream = null;
    logger.info('Stopped tracking');
  }
}
