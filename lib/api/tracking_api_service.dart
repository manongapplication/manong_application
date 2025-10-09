import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/api/socket_api_service.dart';
// ignore: library_prefixes

class TrackingApiService {
  static final TrackingApiService _instance = TrackingApiService._internal();
  factory TrackingApiService() => _instance;
  TrackingApiService._internal();

  final Logger logger = Logger('TrackingApiService');
  final SocketApiService socketService = SocketApiService();
  StreamSubscription<Position>? positionStream;
  ValueNotifier<LatLng?> manongLatLngNotifier = ValueNotifier(null);

  void joinRoom({required String manongId, required String serviceRequestId}) {
    final room = 'tracking:$manongId-$serviceRequestId';
    socketService.emit('joinTrackingRoom', {
      'manongId': manongId,
      'serviceRequestId': serviceRequestId,
    });
    logger.info('Joined room $room');
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

          logger.info(
            'Location now: ${position.latitude} + ${position.longitude}',
          );
        });
  }

  void onLocationUpdate(Function(Map<String, dynamic>) callback) {
    socketService.on('tracking:update', (data) {
      logger.info('Received location updates $data');
      manongLatLngNotifier.value = LatLng(data['lat'], data['lng']);
      callback(Map<String, dynamic>.from(data));
    });
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
