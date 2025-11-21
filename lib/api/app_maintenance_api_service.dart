import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';
import 'package:http/http.dart' as http;

class AppMaintenanceApiService {
  final String? baseUrl = dotenv.env['APP_URL_API'];

  final Logger logger = Logger('AppMaintenanceApiService');

  Future<Map<String, dynamic>?> fetchAppMaintenance() async {
    try {
      if (baseUrl == null) {
        throw Exception('Base URL is not configured.');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/app-maintenance'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      final responseBody = response.body;
      final jsonData = jsonDecode(responseBody);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonData;
      } else {
        logger.warning(
          'Failed to get app maintenance status ${response.statusCode} $responseBody',
        );
        return jsonData;
      }
    } catch (e) {
      logger.severe('Error getting app maintenance status $e');
    }

    return null;
  }
}
