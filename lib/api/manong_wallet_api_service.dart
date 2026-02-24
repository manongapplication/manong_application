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

  Future<Map<String, dynamic>?> cashInManongWallet({
    required double amount,
    required String provider,
  }) async {
    try {
      final token = await AuthService().getNodeToken();

      final response = await http.post(
        Uri.parse('$baseUrl/manong-wallet/cash-in'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'amount': amount, 'provider': provider}),
      );

      final responseBody = response.body;
      final jsonData = jsonDecode(responseBody);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonData;
      } else {
        logger.warning(
          'Failed to cash in manong wallet: ${response.statusCode} $responseBody',
        );
        return jsonData;
      }
    } catch (e, stacktrace) {
      logger.severe('Error cash in manong wallet', e, stacktrace);
    }

    return null;
  }

  Future<Map<String, dynamic>?> cashOutManongWallet({
    required double amount,
    required String bankCode,
    required String bankName,
    required String accountName,
    required int accountNumber,
  }) async {
    try {
      final token = await AuthService().getNodeToken();

      final response = await http.post(
        Uri.parse('$baseUrl/manong-wallet/cash-out'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'amount': amount,
          'bankCode': bankCode,
          'bankName': bankName,
          'accountName': accountName,
          'accountNumber': accountNumber,
        }),
      );

      final responseBody = response.body;
      final jsonData = jsonDecode(responseBody);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonData;
      } else {
        // Extract the error message from the response
        String errorMessage = 'Failed to cash out';

        if (jsonData['message'] != null) {
          errorMessage = jsonData['message'].toString();
        } else if (jsonData['error'] != null) {
          errorMessage = jsonData['error'].toString();
        } else if (responseBody.isNotEmpty) {
          // Try to parse the raw response
          try {
            final errorJson = jsonDecode(responseBody);
            if (errorJson is Map && errorJson['message'] != null) {
              errorMessage = errorJson['message'].toString();
            }
          } catch (e) {
            // If response is not JSON, use the raw response
            errorMessage = responseBody;
          }
        }

        logger.warning(
          'Failed to cash out manong wallet: ${response.statusCode} $errorMessage',
        );

        // Throw the error so it can be caught and displayed
        throw Exception(errorMessage);
      }
    } catch (e, stacktrace) {
      logger.severe('Error cash out manong wallet', e, stacktrace);

      // If it's already an Exception with a message, rethrow it
      if (e is Exception) {
        rethrow;
      }
      // Otherwise, wrap it in an Exception
      throw Exception('Failed to process cash out: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>?> fetchCashBookingReadiness() async {
    try {
      final token = await AuthService().getNodeToken();

      final response = await http.get(
        Uri.parse('$baseUrl/manong-wallet/booking-readiness'),
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
          'Failed to fetch booking readiness: ${response.statusCode} $responseBody',
        );

        return jsonData;
      }
    } catch (e, stacktrace) {
      logger.severe('Error fetching booking readiness', e, stacktrace);

      throw Exception('Error fetching booking readiness: ${e.toString()}');
    }
  }
}
