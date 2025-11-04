import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/api/auth_service.dart';
import 'package:http/http.dart' as http;

class FeedbackApiService {
  final String? baseUrl = dotenv.env['APP_URL_API'];

  final Logger logger = Logger('FeedbackApiService');

  Future<Map<String, dynamic>?> createFeedback({
    required int serviceRequestId,
    required int revieweeId,
    required int rating,
    String? comment,
  }) async {
    try {
      if (baseUrl == null) {
        throw Exception('Base URL is not configured.');
      }

      final token = await AuthService().getNodeToken();

      final response = await http.post(
        Uri.parse('$baseUrl/feedback'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'serviceRequestId': serviceRequestId,
          'revieweeId': revieweeId,
          'rating': rating,
          'comment': comment,
        }),
      );

      final responseBody = response.body;
      final jsonData = jsonDecode(responseBody);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonData;
      } else {
        logger.warning(
          'Failed to create feedback ${response.statusCode} $responseBody',
        );
        return jsonData;
      }
    } catch (e) {
      logger.severe('Error creating feedback $e');
    }

    return null;
  }
}
