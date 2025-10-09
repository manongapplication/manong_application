import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/api/auth_service.dart';
import 'package:http/http.dart' as http;

class PaymongoApiService {
  final Logger logger = Logger('PaymongoApiService');
  final baseUrl = dotenv.env['APP_URL_API'];

  Future<Map<String, dynamic>?> createCustomer({
    required String firstName,
    required String lastName,
    required String email,
    required String defaultDevice,
  }) async {
    try {
      final token = await AuthService().getNodeToken();
      final response = await http.post(
        Uri.parse('$baseUrl/paymongo/create-customer'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'defaultDevice': defaultDevice,
        }),
      );

      final responseBody = response.body;
      final jsonData = jsonDecode(responseBody);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonData;
      } else {
        logger.warning(
          'Failed creating customer ${response.statusCode} $responseBody',
        );
        return jsonData;
      }
    } catch (e) {
      logger.severe('Error creating customer!');
    }
  }
}
