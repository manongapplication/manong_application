import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';
import 'package:http/http.dart' as http;
import 'package:manong_application/api/auth_service.dart';

class FcmApiService {
  final Logger logger = Logger('FcmApiService');
  final String? baseUrl = dotenv.env['APP_URL_API'];

  Future<Map<String, dynamic>?> sendNotification({
    required String title,
    required String body,
    required String fcmToken,
    required int userId,
    Map<String, dynamic>? json,
  }) async {
    try {
      if (baseUrl == null) {
        throw Exception('Base URL is not configured.');
      }

      logger.info('Notification $title sent to $fcmToken');

      final token = await AuthService().getNodeToken();

      final Map<String, dynamic> data = {
        'title': title,
        'body': body,
        'token': fcmToken,
        'userId': userId,
      };

      if (json != null) {
        data.addAll(json);
      }

      final response = await http.post(
        Uri.parse('$baseUrl/notifications/push'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      logger.info('Notification data $data');

      final responseBody = response.body;
      final jsonData = jsonDecode(responseBody);

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          return jsonDecode(responseBody); // only if JSON
        } catch (_) {
          return {'messageId': responseBody}; // wrap the raw string
        }
      } else {
        logger.warning(
          'Failed to send notification ${response.statusCode} $responseBody',
        );
      }
    } catch (e) {
      logger.severe('Error to send notifaction $e');
    }

    return null;
  }
}
