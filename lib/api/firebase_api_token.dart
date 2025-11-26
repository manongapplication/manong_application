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

    try {
      _fcmToken = await _firebaseMessaging.getToken();
      
      if (_fcmToken != null) {
        await _secureStorage.write(key: 'fcm_token', value: _fcmToken);
        logger.info('FCM Token retrieved and saved: $_fcmToken');
      } else {
        logger.warning('FCM Token is null');
      }
      
      return _fcmToken;
    } catch (e) {
      // Don't crash if APNS token isn't ready yet (common on iOS)
      logger.warning('Failed to get FCM token (APNS may not be ready): $e');
      return null;
    }
  }

  Future<void> refreshTokenListener() async {
    _firebaseMessaging.onTokenRefresh.listen((newToken) async {
      _fcmToken = newToken;
      await _secureStorage.write(key: 'fcm_token', value: _fcmToken);
      logger.info('New FCM Token saved via refresh: $newToken');
      
      // Try to save to database when token refreshes
      await _saveTokenToDatabaseSafely(newToken);
    });
  }

  Future<void> saveFcmTokenToDatabase() async {
    logger.info('saveFcmTokenToDatabase()');
    try {
      final fcmToken = await getToken(); // Use the safe getToken method
      if (fcmToken != null && fcmToken.isNotEmpty) {
        logger.info('saveFcmTokenToDatabase() saving token: $fcmToken');
        await AuthService().saveFcmToken(fcmToken);
        logger.info('saveFcmTokenToDatabase() saved successfully');
      } else {
        logger.warning('saveFcmTokenToDatabase() no token available to save');
      }
    } catch (e) {
      logger.warning('saveFcmTokenToDatabase() failed: $e');
      // Don't rethrow - this shouldn't break the app
    }
  }

  // Helper method to safely save token to database
  Future<void> _saveTokenToDatabaseSafely(String token) async {
    try {
      await AuthService().saveFcmToken(token);
      logger.info('Token saved to database via refresh: $token');
    } catch (e) {
      logger.warning('Failed to save token to database: $e');
    }
  }

  // Method to get stored token without making API call
  Future<String?> getStoredToken() async {
    if (_fcmToken != null) return _fcmToken;
    _fcmToken = await _secureStorage.read(key: 'fcm_token');
    return _fcmToken;
  }
}