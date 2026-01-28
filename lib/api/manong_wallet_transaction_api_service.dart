import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/api/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:manong_application/models/manong_wallet_transaction.dart';

class ManongWalletTransactionApiService {
  final Logger logger = Logger('ManongWalletTransactionApiService');
  final baseUrl = dotenv.env['APP_URL_API'];

  Future<ManongWalletTransaction?> fetchWalletTransactionById(int id) async {
    try {
      final token = await AuthService().getNodeToken();

      final response = await http.get(
        Uri.parse('$baseUrl/manong-wallet-transaction/$id'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseBody = response.body;
      final jsonData = jsonDecode(responseBody);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ManongWalletTransaction.fromJson(jsonData['data']);
      } else {
        logger.warning(
          'Failed to fetch manong wallet transaction: ${response.statusCode} $responseBody',
        );
        return null;
      }
    } catch (e, stacktrace) {
      logger.severe('Error fetching manong wallet transaction', e, stacktrace);
    }

    return null;
  }

  Future<Map<String, dynamic>?> fetchWalletTransactionsByWalletId(
    int walletId,
  ) async {
    try {
      final token = await AuthService().getNodeToken();

      final response = await http.post(
        Uri.parse('$baseUrl/manong-wallet-transaction/all/$walletId'),
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
          'Failed to fetch manong wallet transactions: ${response.statusCode} $responseBody',
        );
        return jsonData;
      }
    } catch (e, stacktrace) {
      logger.severe('Error fetching manong wallet transactions', e, stacktrace);
    }

    return null;
  }
}
