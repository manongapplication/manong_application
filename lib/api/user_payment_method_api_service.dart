import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';
import 'package:http/http.dart' as http;
import 'package:manong_application/api/auth_service.dart';
import 'package:manong_application/models/payment_method.dart';

class UserPaymentMethodApiService {
  final Logger logger = Logger('UserPaymentMethodApiService');
  final String? baseUrl = dotenv.env['APP_URL_API'];

  Future<Map<String, dynamic>?> saveUserPaymentMethod(
    int paymentMethodId,
    String paymentMethodCode,
  ) async {
    try {
      if (baseUrl == null) {
        throw Exception('Base URL is not configured.');
      }

      final token = await AuthService().getNodeToken();

      final response = await http.post(
        Uri.parse('$baseUrl/user-payment-methods'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'paymentMethodId': (paymentMethodId + 1),
          'provider': paymentMethodCode,
        }),
      );

      final responseBody = response.body;
      final jsonData = jsonDecode(responseBody);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonData;
      } else {
        logger.warning(
          'Failed to save card ${response.statusCode} $responseBody',
        );

        return null;
      }
    } catch (e) {
      logger.severe('Error saving payment method $e');
    }

    return null;
  }

  Future<Map<String, dynamic>?> fetchDefaultUserPaymentMethod() async {
    try {
      final token = await AuthService().getNodeToken();

      final response = await http.get(
        Uri.parse('$baseUrl/user-payment-methods/default'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseBody = response.body;
      final jsonData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonData;
      } else {
        logger.warning(
          'Failed to fetch default payment methods: ${response.statusCode} $responseBody',
        );
        return null;
      }
    } catch (e, stacktrace) {
      logger.severe('Error fetching default payment methods', e, stacktrace);
      return null;
    }
  }

  Future<Map<String, dynamic>?> saveCardAsDefault(
    String paymentMethodIdOnGateway,
  ) async {
    try {
      if (baseUrl == null) {
        throw Exception('Base URL is not configured.');
      }

      final token = await AuthService().getNodeToken();

      final response = await http.post(
        Uri.parse('$baseUrl/user-payment-methods/card'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'paymentMethodIdOnGateway': paymentMethodIdOnGateway,
        }),
      );

      final responseBody = response.body;
      final jsonData = jsonDecode(responseBody);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonData;
      } else {
        logger.warning(
          'Failed setting card as default ${response.statusCode} $responseBody',
        );
      }
    } catch (e) {
      logger.severe('Error setting card as default $e');
    }

    return null;
  }

  Future<List<dynamic>?> fetchUserPaymentMethods() async {
    try {
      if (baseUrl == null) {
        throw Exception('Base URL is not configured.');
      }

      final token = await AuthService().getNodeToken();

      final response = await http.get(
        Uri.parse('$baseUrl/user-payment-methods'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseBody = response.body;
      final jsonData = jsonDecode(responseBody);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonData['data'];
      } else {
        logger.warning(
          'Failed to fetching user payment methods ${response.statusCode} $responseBody',
        );

        return null;
      }
    } catch (e) {
      logger.severe('Error fetching user payment methods $e');
    }

    return null;
  }

  Future<String?> deleteUserPaymentCard(String paymentMethodIdOnGateway) async {
    try {
      if (baseUrl == null) {
        throw Exception('Base URL is not configured.');
      }

      final token = await AuthService().getNodeToken();

      final response = await http.post(
        Uri.parse('$baseUrl/paymongo/delete-card'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'paymentMethodIdOnGateway': paymentMethodIdOnGateway,
        }),
      );

      final responseBody = response.body;
      final jsonData = jsonDecode(responseBody);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonData['message'];
      } else {
        logger.warning(
          'Failed deleting payment card ${response.statusCode} $responseBody',
        );
        return null;
      }
    } catch (e) {
      logger.severe('Error deleting user payment card $e');
    }
    return null;
  }
}
