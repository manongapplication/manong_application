import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/api/auth_service.dart';
import 'package:manong_application/models/payment_method.dart';
import 'package:http/http.dart' as http;

class PaymentMethodApiService {
  final Logger logger = Logger('PaymentMethodApiService');
  final baseUrl = dotenv.env['APP_URL_API'];

  Future<List<PaymentMethod>> fetchPaymentMethods() async {
    try {
      final token = await AuthService().getNodeToken();

      final response = await http.get(
        Uri.parse('$baseUrl/payment-methods'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return List<PaymentMethod>.from(
          responseBody['data'].map((x) => PaymentMethod.fromJson(x)),
        );
      } else {
        logger.warning(
          'Failed to fetch payment methods: ${response.statusCode} $responseBody',
        );
        return [];
      }
    } catch (e, stacktrace) {
      logger.severe('Error fetching payment methods', e, stacktrace);
      return [];
    }
  }

  Future<Map<String, dynamic>?> createCard({
    String? number,
    String? expMonth,
    String? expYear,
    String? cvc,
    String? cardHolderName,
    String? email,
    required String type,
  }) async {
    try {
      final token = await AuthService().getNodeToken();

      final response = await http.post(
        Uri.parse('$baseUrl/paymongo/create-payment-method'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'number': number,
          'expMonth': expMonth,
          'expYear': expYear,
          'cvc': cvc,
          'cardHolderName': cardHolderName,
          'email': email,
          'type': type,
        }),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return responseBody;
      } else {
        logger.warning(
          'Failed to create card: ${response.statusCode} ${response.body}',
        );
        return responseBody;
      }
    } catch (e, stracktrace) {
      logger.severe('Error creating card', e, stracktrace);
      return null;
    }
  }
}
