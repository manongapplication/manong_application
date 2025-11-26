import 'package:logging/logging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class PermissionUtils {
  static final PermissionUtils _instance = PermissionUtils._internal();
  factory PermissionUtils() => _instance;
  PermissionUtils._internal();

  final Logger logger = Logger('CheckLocationPermission');

  bool _locationPermissionGranted = false;
  bool get locationPermissionGranted => _locationPermissionGranted;
  
  bool _notificationPermissionGranted = false;
  bool get notificationPermissionGranted => _notificationPermissionGranted;

  // Cache the permission status to avoid repeated checks
  DateTime? _lastLocationCheck;
  DateTime? _lastNotificationCheck;
  static const Duration _cacheDuration = Duration(minutes: 5);

  Future<bool> isLocationPermissionGranted() async {
    // Return cached value if recent
    if (_lastLocationCheck != null && 
        DateTime.now().difference(_lastLocationCheck!) < _cacheDuration) {
      return _locationPermissionGranted;
    }

    var status = await Permission.location.status;
    _locationPermissionGranted = status.isGranted;
    _lastLocationCheck = DateTime.now();
    
    return _locationPermissionGranted;
  }

  Future<bool> isNotificationPermissionGranted() async {
    // Return cached value if recent
    if (_lastNotificationCheck != null && 
        DateTime.now().difference(_lastNotificationCheck!) < _cacheDuration) {
      return _notificationPermissionGranted;
    }

    if (Platform.isIOS) {
      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      logger.info('iOS Notification status: ${settings.authorizationStatus}');
      _notificationPermissionGranted = 
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } else {
      var status = await Permission.notification.status;
      _notificationPermissionGranted = status.isGranted;
    }
    
    _lastNotificationCheck = DateTime.now();
    return _notificationPermissionGranted;
  }

  Future<void> checkLocationPermission() async {
    logger.info('Location permission checked!');
    var status = await Permission.location.status;

    if (status.isDenied || status.isRestricted) {
      status = await Permission.location.request();
    }

    // Update the cached value
    _locationPermissionGranted = status.isGranted;
    _lastLocationCheck = DateTime.now();
  }

  Future<bool> checkNotificationPermission() async {
    logger.info('Notification permission checked!');
    
    bool result = false;
    
    if (Platform.isIOS) {
      // On iOS, we can't directly request notification permission again
      // if it was already denied. We can only guide users to settings.
      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      
      logger.info('Current iOS notification status: ${settings.authorizationStatus}');
      
      switch (settings.authorizationStatus) {
        case AuthorizationStatus.authorized:
        case AuthorizationStatus.provisional:
          _notificationPermissionGranted = true;
          result = true;
          logger.info('iOS notification permission already granted');
          break;
          
        case AuthorizationStatus.denied:
          // On iOS, if denied, we can only open app settings
          logger.info('iOS notification permission denied');
          _notificationPermissionGranted = false;
          result = false;
          break;
          
        case AuthorizationStatus.notDetermined:
          // Only request if not determined yet
          logger.info('iOS notification permission not determined, requesting...');
          final newSettings = await FirebaseMessaging.instance.requestPermission(
            alert: true,
            badge: true,
            sound: true,
          );
          
          _notificationPermissionGranted = 
              newSettings.authorizationStatus == AuthorizationStatus.authorized ||
              newSettings.authorizationStatus == AuthorizationStatus.provisional;
          result = _notificationPermissionGranted;
          break;
          
        default:
          _notificationPermissionGranted = false;
          result = false;
      }
    } else {
      // For Android and other platforms
      var status = await Permission.notification.status;

      if (status.isDenied || status.isRestricted) {
        status = await Permission.notification.request();
      }

      _notificationPermissionGranted = status.isGranted;
      result = _notificationPermissionGranted;
    }
    
    _lastNotificationCheck = DateTime.now();
    return result;
  }
}