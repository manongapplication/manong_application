import 'package:logging/logging.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionUtils {
  static final PermissionUtils _instance = PermissionUtils._internal();
  factory PermissionUtils() => _instance;
  PermissionUtils._internal();

  final Logger logger = Logger('CheckLocationPermission');

  bool _locationPermissionGranted = false;
  bool get locationPermissionGranted => _locationPermissionGranted;
  void setLocationPermissionGranted(bool newValue) {
    _locationPermissionGranted = newValue;
  }

  Future<bool> isLocationPermissionGranted() async {
    var status = await Permission.location.status;
    return status.isGranted;
  }

  bool _notificationPermissionGranted = false;
  bool get notificationPermissionGranted => _notificationPermissionGranted;
  void setNotificationPermissionGratend(bool newValue) {
    _notificationPermissionGranted = newValue;
  }

  Future<bool> isNotificationPermissionGranted() async {
    var status = await Permission.notification.status;
    return status.isGranted;
  }

  Future<void> checkLocationPermission() async {
    logger.info('Location permission checked!');
    var status = await Permission.location.status;

    if (status.isDenied || status.isRestricted) {
      status = await Permission.location.request();
    }

    if (status.isGranted) {
      _locationPermissionGranted = true;
    } else {
      _locationPermissionGranted = false;
    }
  }

  Future<void> checkNotificationPermission() async {
    logger.info('Notification permission checked!');
    var status = await Permission.notification.status;

    if (status.isDenied || status.isRestricted) {
      status = await Permission.notification.request();
    }

    if (status.isGranted) {
      _notificationPermissionGranted = true;
    } else {
      _notificationPermissionGranted = false;
    }
  }
}
