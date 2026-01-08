import 'package:logging/logging.dart';
import 'package:manong_application/main.dart';
import 'package:manong_application/utils/snackbar_utils.dart';
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
      final settings = await FirebaseMessaging.instance
          .getNotificationSettings();
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
      final settings = await FirebaseMessaging.instance
          .getNotificationSettings();

      logger.info(
        'Current iOS notification status: ${settings.authorizationStatus}',
      );

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
          logger.info(
            'iOS notification permission not determined, requesting...',
          );
          final newSettings = await FirebaseMessaging.instance
              .requestPermission(alert: true, badge: true, sound: true);

          _notificationPermissionGranted =
              newSettings.authorizationStatus ==
                  AuthorizationStatus.authorized ||
              newSettings.authorizationStatus ==
                  AuthorizationStatus.provisional;
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

  // FIXED: Add proper platform check and remove recursive call
  Future<bool> isGalleryPermissionGranted() async {
    if (Platform.isAndroid) {
      // For Android 13+, check photos permission
      var status = await Permission.photos.status;
      return status.isGranted || status.isLimited;
    } else if (Platform.isIOS) {
      // For iOS, check photos permission
      var status = await Permission.photos.status;
      return status.isGranted || status.isLimited;
    }
    return false; // For web or other platforms
  }

  // FIXED: Proper permission checking and requesting
  Future<bool> checkCameraPermission() async {
    logger.info('Checking camera permission...');

    try {
      var status = await Permission.camera.status;
      logger.info('Camera permission status: $status');

      switch (status) {
        case PermissionStatus.granted:
        case PermissionStatus.limited:
          logger.info('Camera permission already granted/limited');
          return true;

        case PermissionStatus.denied:
          logger.info('Camera permission denied, requesting...');
          final newStatus = await Permission.camera.request();
          logger.info('Camera permission after request: $newStatus');
          return newStatus.isGranted || newStatus.isLimited;

        case PermissionStatus.permanentlyDenied:
          logger.info('Camera permission permanently denied');
          // Don't return false yet - let user try again
          final newStatus = await Permission.camera.request();
          logger.info(
            'Camera permission after permanent denial request: $newStatus',
          );
          return newStatus.isGranted || newStatus.isLimited;

        case PermissionStatus.restricted:
          logger.info('Camera permission restricted');
          return false;

        default:
          return false;
      }
    } catch (e) {
      logger.severe('Error checking camera permission: $e');
      return false;
    }
  }

  // FIXED: Proper gallery permission checking
  Future<bool> checkGalleryPermission() async {
    logger.info('Checking gallery permission...');

    try {
      Permission permission;

      if (Platform.isAndroid) {
        permission = Permission.photos;
      } else if (Platform.isIOS) {
        permission = Permission.photos;
      } else {
        // For web or other platforms
        return false;
      }

      var status = await permission.status;
      logger.info('Gallery permission status: $status');

      switch (status) {
        case PermissionStatus.granted:
        case PermissionStatus.limited:
          logger.info('Gallery permission already granted/limited');
          return true;

        case PermissionStatus.denied:
          logger.info('Gallery permission denied, requesting...');
          final newStatus = await permission.request();
          logger.info('Gallery permission after request: $newStatus');
          return newStatus.isGranted || newStatus.isLimited;

        case PermissionStatus.permanentlyDenied:
          logger.info('Gallery permission permanently denied');
          // Let user try again
          final newStatus = await permission.request();
          logger.info(
            'Gallery permission after permanent denial request: $newStatus',
          );
          return newStatus.isGranted || newStatus.isLimited;

        case PermissionStatus.restricted:
          logger.info('Gallery permission restricted');
          return false;

        default:
          return false;
      }
    } catch (e) {
      logger.severe('Error checking gallery permission: $e');
      return false;
    }
  }

  // FIXED: Remove recursive call
  Future<void> openAppSettings() async {
    try {
      // Call the package function, not the method itself
      await openAppSettings(); // This calls the package function
      logger.info('Opened app settings');
    } catch (e) {
      logger.severe('Error opening app settings: $e');
      // Show a helpful message
      SnackBarUtils.showWarning(
        navigatorKey.currentContext!,
        'Unable to open settings. Please go to Settings > Apps > [Your App] > Permissions.',
      );
    }
  }
}
