import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';
import 'package:http/http.dart' as http;
import 'package:manong_application/services/notification_service/device_id_service.dart';

class ReferralCodeApiService {
  final Logger logger = Logger('ReferralCodeApiService');
  final baseUrl = dotenv.env['APP_URL_API'];

  Future<Map<String, dynamic>?> validateCode(String code) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/referral-code/validate'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'code': code,
          'deviceId': await DeviceIdService.getDeviceIdentifier(),
        }),
      );

      final responseBody = response.body;
      final jsonData = jsonDecode(responseBody);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonData;
      } else {
        logger.warning(
          'Failed to validate referral code: ${response.statusCode} $responseBody',
        );
        return jsonData;
      }
    } catch (e) {
      logger.severe('Error validating referral code ${e.toString()}');
    }
    return null;
  }
}
