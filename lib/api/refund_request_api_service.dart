import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/api/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:manong_application/models/refund_request.dart';
import 'package:manong_application/models/service_request.dart';

class RefundRequestApiService {
  final Logger logger = Logger('RefundRequestApiService');
  final baseUrl = dotenv.env['APP_URL_API'];

  Future<List<RefundRequest>?> fetchRefundRequestsByServiceRequestId(
    ServiceRequest serviceRequest,
  ) async {
    try {
      final token = await AuthService().getNodeToken();

      final response = await http.post(
        Uri.parse('$baseUrl/refund-request/get'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'serviceRequestId': serviceRequest.id}),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return responseBody['data'] != null
            ? (responseBody['data'] as List<dynamic>)
                  .map((e) => RefundRequest.fromJson(e as Map<String, dynamic>))
                  .toList()
            : null;
      } else {
        logger.warning(
          'Failed to create refund request: ${response.statusCode} $responseBody',
        );
        return null;
      }
    } catch (e, stacktrace) {
      logger.severe('Error creating refund request', e, stacktrace);
      return null;
    }
  }

  Future<Map<String, dynamic>?> createRefundRequest(
    ServiceRequest serviceRequest,
    String reason,
  ) async {
    try {
      final token = await AuthService().getNodeToken();

      final response = await http.post(
        Uri.parse('$baseUrl/refund-request'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'serviceRequestId': serviceRequest.id,
          'reason': reason,
        }),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return responseBody;
      } else {
        logger.warning(
          'Failed to create refund request: ${response.statusCode} $responseBody',
        );
        return null;
      }
    } catch (e, stacktrace) {
      logger.severe('Error creating refund request', e, stacktrace);
      return null;
    }
  }
}
