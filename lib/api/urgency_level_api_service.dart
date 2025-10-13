import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';
import 'package:http/http.dart' as http;
import 'package:manong_application/models/urgency_level.dart';

class UrgencyLevelApiService {
  final String? baseUrl = dotenv.env['APP_URL_API'];

  final Logger logger = Logger('UrgencyLevelApiService');

  Future<List<UrgencyLevel>?> fetchUrgencyLevels() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/urgency-level'),
        headers: {
          'Content-Type': 'applicaiton/json',
          'Accept': 'applicaiton/json',
        },
      );

      final responseBody = response.body;
      final jsonData = jsonDecode(responseBody);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final List<dynamic> data = jsonData['data'];

        return data.map((e) => UrgencyLevel.fromJson(e)).toList();
      } else {
        logger.warning(
          'Failed to fetch urgency levels ${response.statusCode} $responseBody',
        );

        return null;
      }
    } catch (e) {
      logger.severe('Error fetching urgency levels $e');
    }

    return null;
  }
}
