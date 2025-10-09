import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/api/auth_service.dart';

class FirebaseApiToken {
  static final FirebaseApiToken _instance = FirebaseApiToken._internal();
  factory FirebaseApiToken() => _instance;
  FirebaseApiToken._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final Logger logger = Logger('FirebaseApiToken');
  String? _fcmToken;

  Future<String?> getToken() async {
    if (_fcmToken != null) return _fcmToken;

    _fcmToken = await _firebaseMessaging.getToken();

    if (_fcmToken != null) {
      await _secureStorage.write(key: 'fcm_token', value: _fcmToken);
    }

    return _fcmToken;
  }

  Future<void> refreshTokenListener() async {
    _firebaseMessaging.onTokenRefresh.listen((newToken) async {
      _fcmToken = newToken;

      await _secureStorage.write(key: 'fcm_token', value: _fcmToken);

      logger.info('New FCM Token saved: $newToken');
    });
  }

  Future<void> saveFcmTokenToDatabase() async {
    logger.info('saveFcmTokenToDatabase()');
    final fcmToken = await FirebaseApiToken().getToken();
    if (fcmToken != null) {
      logger.info('saveFcmTokenToDatabase() saved');
      logger.info('saveFcmTokenToDatabase() saved $fcmToken');
      await AuthService().saveFcmToken(fcmToken);
    }
  }
}
