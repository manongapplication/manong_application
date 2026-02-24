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

  Future<Map<String, dynamic>?> fetchWalletTransactionsByWalletId({
    required int walletId,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final token = await AuthService().getNodeToken();

      final queryParams = {'page': page.toString(), 'limit': limit.toString()};

      final uri = Uri.parse(
        '$baseUrl/manong-wallet-transaction/all/$walletId',
      ).replace(queryParameters: queryParams);

      final response = await http.post(
        uri,
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

  // Helper method to extract just the transactions
  Future<List<ManongWalletTransaction>> fetchTransactionsList({
    required int walletId,
    int page = 1,
    int limit = 10,
  }) async {
    final response = await fetchWalletTransactionsByWalletId(
      walletId: walletId,
      page: page,
      limit: limit,
    );

    if (response != null && response['data'] != null) {
      final List<dynamic> transactionData = response['data'];
      return transactionData
          .map((json) => ManongWalletTransaction.fromJson(json))
          .toList();
    }

    return [];
  }

  Future<Map<String, dynamic>?> fetchPendingJobFees({
    required int walletId,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final token = await AuthService().getNodeToken();

      final queryParams = {'page': page.toString(), 'limit': limit.toString()};

      final uri = Uri.parse(
        '$baseUrl/manong-wallet-transaction/pending-job-fee/$walletId',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
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
      logger.severe(
        'Error fetching manong wallet transactions job fee',
        e,
        stacktrace,
      );
    }

    return null;
  }

  Future<Map<String, dynamic>?> payPendingJobFees({
    required int walletId,
    required List<int> ids,
    required String provider,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final token = await AuthService().getNodeToken();

      final queryParams = {'page': page.toString(), 'limit': limit.toString()};

      final uri = Uri.parse(
        '$baseUrl/manong-wallet-transaction/pay-pending-job-fees/$walletId',
      ).replace(queryParameters: queryParams);

      final response = await http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({'ids': ids, 'provider': provider}),
      );

      final responseBody = response.body;
      final jsonData = jsonDecode(responseBody);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonData;
      } else {
        logger.warning(
          'Failed to pay manong job fees: ${response.statusCode} $responseBody',
        );
        return jsonData;
      }
    } catch (e, stacktrace) {
      logger.severe('Error paying manong job fees', e, stacktrace);
    }

    return null;
  }

  Future<Map<String, dynamic>?> getJobFeesPaymentStatus(List<int> ids) async {
    try {
      final token = await AuthService().getNodeToken();

      final uri = Uri.parse(
        '$baseUrl/manong-wallet-transaction/job-fees/payment-status',
      );

      // CHANGE THIS TO POST
      final response = await http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({'ids': ids}), // Send IDs in the body
      );

      final responseBody = response.body;
      final jsonData = jsonDecode(responseBody);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonData;
      } else {
        logger.warning(
          'Failed to get job fees payment status: ${response.statusCode} $responseBody',
        );
        return jsonData;
      }
    } catch (e, stacktrace) {
      logger.severe('Error getting job fees payment status', e, stacktrace);
      return null;
    }
  }
}
