import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('🔔 Notification tapped: ${response.payload}');
      },
    );
  }

  static Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    print('DEBUG: showNotification called with title: $title, body: $body');

    try {
      const androidDetails = AndroidNotificationDetails(
        'manong_default_channel',
        'Manong Notifications',
        channelDescription: 'Used for service updates',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      const notificationDetails = NotificationDetails(android: androidDetails);

      await _notifications.show(0, title, body, notificationDetails);
      print('DEBUG: Notification show() completed successfully');
    } catch (e) {
      print('ERROR: Failed to show notification: $e');
    }
  }
}
