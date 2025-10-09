import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';
import 'package:http/http.dart' as http;
import 'package:manong_application/api/auth_service.dart';
import 'package:manong_application/models/user_notification.dart';

class UserNotificationApiService {
  final Logger logger = Logger('NotificationApiService');
  final baseUrl = dotenv.env['APP_URL_API'];

  Future<List<UserNotification>?> fetchNotifications({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/notification').replace(
        queryParameters: {'page': page.toString(), 'limit': limit.toString()},
      );

      final token = await AuthService().getNodeToken();

      final response = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 30));

      final responseBody = response.body;
      final jsonData = jsonDecode(responseBody);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return List<UserNotification>.from(
          jsonData['data'].map((x) => UserNotification.fromJson(x)),
        );
      } else {
        logger.info(
          'Failed to fetch notifications ${response.statusCode} $responseBody',
        );
        return null;
      }
    } catch (e) {
      logger.info('Unable to fetch notifications $e');
    }

    return null;
  }

  Future<Map<String, dynamic>?> seenNotification(int id) async {
    try {
      final token = await AuthService().getNodeToken();

      final uri = Uri.parse('$baseUrl/notification/$id/seen');

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseBody = response.body;
      final jsonData = jsonDecode(responseBody);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonData;
      } else {
        logger.warning(
          'Failed to seen notification ${response.statusCode} ${jsonEncode(responseBody)} $uri',
        );
        return null;
      }
    } catch (e) {
      logger.severe('Error seen notificatication $e');
    }

    return null;
  }

  Future<Map<String, dynamic>?> getUnreadCount() async {
    try {
      final token = await AuthService().getNodeToken();
      final uri = Uri.parse('$baseUrl/notification/unread/count');
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseBody = response.body;
      final jsonData = jsonDecode(responseBody);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonData;
      } else {
        logger.warning(
          'Failed to get unread count ${response.statusCode} $responseBody',
        );

        return null;
      }
    } catch (e) {
      logger.severe('Error getting unread count $e');
    }

    return null;
  }
}
