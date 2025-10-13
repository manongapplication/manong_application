import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/models/service_settings.dart';
import 'package:http/http.dart' as http;

class ServiceSettingsApiService {
  final String? baseUrl = dotenv.env['APP_URL_API'];

  final Logger logger = Logger('ServiceSettingsApiService');

  Future<ServiceSettings?> fetchServiceSettings() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/service-settings'),
        headers: {
          'Content-Type': 'applicaiton/json',
          'Accept': 'applicaiton/json',
        },
      );

      final responseBody = response.body;
      final jsonData = jsonDecode(responseBody);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ServiceSettings.fromJson(jsonData['data']);
      } else {
        logger.warning(
          'Failed to fetch service settings ${response.statusCode} $responseBody',
        );

        return null;
      }
    } catch (e) {
      logger.severe('Error fetching service settings $e');
    }

    return null;
  }
}
