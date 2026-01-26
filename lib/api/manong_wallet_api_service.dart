import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/api/auth_service.dart';
import 'package:http/http.dart' as http;

class ManongWalletApiService {
  final Logger logger = Logger('ManongWalletApiService');
  final baseUrl = dotenv.env['APP_URL_API'];

  Future<Map<String, dynamic>?> fetchManongWalletService() async {
    try {
      final token = await AuthService().getNodeToken();

      final response = await http.get(
        Uri.parse('$baseUrl/manong-wallet'),
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
          'Failed to fetch manong wallet: ${response.statusCode} $responseBody',
        );
        return jsonData;
      }
    } catch (e, stacktrace) {
      logger.severe('Error fetching manong wallet', e, stacktrace);
    }

    return null;
  }

  Future<Map<String, dynamic>?> createManongWalletService() async {
    try {
      final token = await AuthService().getNodeToken();

      final response = await http.post(
        Uri.parse('$baseUrl/manong-wallet'),
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
          'Failed to create manong wallet: ${response.statusCode} $responseBody',
        );
        return jsonData;
      }
    } catch (e, stacktrace) {
      logger.severe('Error creating manong wallet', e, stacktrace);
    }

    return null;
  }
}
