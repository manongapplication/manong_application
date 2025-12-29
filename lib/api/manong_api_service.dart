import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/api/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:manong_application/models/manong.dart';

class ManongApiService {
  final String? baseUrl = dotenv.env['APP_URL_API'];
  final Logger logger = Logger('ManongApiService');

  Future<List<dynamic>> fetchManongs({
    required int serviceItemId,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      if (baseUrl == null) {
        throw Exception('Base URL is not configured.');
      }

      final token = await AuthService().getNodeToken();

      final uri = Uri.parse('$baseUrl/manongs').replace(
        queryParameters: {'page': page.toString(), 'limit': limit.toString()},
      );

      final response = await http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'serviceItemId': serviceItemId}),
      );

      final responseBody = response.body;
      final jsonData = jsonDecode(responseBody);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonData['data'];
      } else {
        logger.warning('Fetch manongs failed: ${response.statusCode}');
        logger.warning('Response: $responseBody');
        throw Exception(
          'Manongs failed with status ${response.statusCode}: $responseBody',
        );
      }
    } catch (e) {
      logger.severe('Error getting manongs $e');
      rethrow;
    }
  }

  Future<Manong?> fetchAManong(int id) async {
    try {
      if (baseUrl == null) throw Exception('Base URL is not configured.');

      final token = await AuthService().getNodeToken();

      final response = await http.get(
        Uri.parse('$baseUrl/manongs/$id'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseBody = response.body;
      final jsonData = jsonDecode(responseBody);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonData['data'];
        if (data == null) {
          logger.warning('No manong found for id $id.');
          return null;
        }
        return Manong.fromJson(data as Map<String, dynamic>);
      } else {
        logger.warning('Fetch the manong failed: ${response.statusCode}');
        logger.warning('Response: $responseBody');
        throw Exception(
          'Manong failed with status ${response.statusCode}: $responseBody',
        );
      }
    } catch (e) {
      logger.severe('Error getting the manong $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> chooseManong(int id, int manongId) async {
    try {
      if (baseUrl == null) {
        throw Exception('Base URL is not configured.');
      }

      final token = await AuthService().getNodeToken();

      final response = await http.post(
        Uri.parse('$baseUrl/service-requests/$id/choose-manong'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'manongId': manongId, 'status': 'pending'}),
      );

      final responseBody = response.body;

      if (response.statusCode == 200) {
        return jsonDecode(responseBody);
      } else {
        logger.warning('Response: $responseBody');
        throw Exception(
          'Manong failed to update with status ${response.statusCode}: $responseBody',
        );
      }
    } catch (e) {
      logger.severe('Error choosing manong $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> updateManongStatus(String status) async {
    try {
      if (baseUrl == null) {
        throw Exception('Base URL is not configured.');
      }

      final token = await AuthService().getNodeToken();

      final response = await http.post(
        Uri.parse('$baseUrl/manongs/status-update'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'status': status}),
      );

      final responseBody = response.body;
      final jsonData = jsonDecode(responseBody);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonData;
      } else {
        logger.warning(
          'Failed to update manong status. ${response.statusCode} $responseBody',
        );
        return jsonData;
      }
    } catch (e) {
      logger.severe('Error updating manong status $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> checkDailyLimit() async {
    try {
      final token = await AuthService().getNodeToken();

      final response = await http.get(
        Uri.parse('$baseUrl/manongs/daily-limit/check'),
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
          'Failed to fetch daily limit: ${response.statusCode} $responseBody',
        );
        return jsonData;
      }
    } catch (e, stacktrace) {
      logger.severe('Error fetching daily limit', e, stacktrace);
    }

    return null;
  }
}
