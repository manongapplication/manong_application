import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/api/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:manong_application/models/payment_transaction.dart';

class PaymentTransactionApiService {
  final Logger logger = Logger('PaymentTransactionApiService');
  final baseUrl = dotenv.env['APP_URL_API'];

  Future<List<PaymentTransaction>> fetchPaymentTransaction({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final token = await AuthService().getNodeToken();

      final uri = Uri.parse('$baseUrl/payment-transaction').replace(
        queryParameters: {'page': page.toString(), 'limit': limit.toString()},
      );

      final response = await http
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 30));

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return List<PaymentTransaction>.from(
          responseBody['data'].map((x) => PaymentTransaction.fromJson(x)),
        );
      } else {
        logger.warning(
          'Failed to fetch payment transactions: ${response.statusCode} $responseBody',
        );
        return [];
      }
    } catch (e, stacktrace) {
      logger.severe('Error fetching payment transactions', e, stacktrace);
      return [];
    }
  }

  Future<int?> countUnseenPaymentTransactions() async {
    try {
      final token = await AuthService().getNodeToken();

      final response = await http.get(
        Uri.parse('$baseUrl/payment-transaction/user/unseen-count'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return responseBody['data'];
      } else {
        logger.warning(
          'Failed to fetch payment transactions: ${response.statusCode} $responseBody',
        );
        return null;
      }
    } catch (e, stacktrace) {
      logger.severe('Error fetching payment transactions', e, stacktrace);
      return null;
    }
  }

  Future<void> seenAllPaymentTransactions() async {
    try {
      final token = await AuthService().getNodeToken();

      await http.get(
        Uri.parse('$baseUrl/payment-transaction/user/seenAll'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e, stacktrace) {
      logger.severe('Error fetching payment transactions', e, stacktrace);
    }
  }
}
