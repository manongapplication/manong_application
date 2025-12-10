import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/api/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DirectionsApiService {
  final Logger logger = Logger('DirectionsApiService');
  final baseUrl = dotenv.env['APP_URL_API'];

  Future<Map<String, dynamic>> fetchDirections({
    required LatLng currentLatLng,
    required LatLng manongLatLng,
  }) async {
    final url = '$baseUrl/directions';

    try {
      final token = await AuthService().getNodeToken();

      final payload = {
        'origin': '${currentLatLng.latitude},${currentLatLng.longitude}',
        'destination': '${manongLatLng.latitude},${manongLatLng.longitude}',
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      if (response.body.isEmpty) {
        logger.severe('Directions API empty response');
        return {'error': true, 'message': 'Empty server response'};
      }

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return responseBody;
      } else {
        logger.warning(
          'Failed directions request (${response.statusCode}): $responseBody',
        );
        return {
          'error': true,
          'status': response.statusCode,
          'data': responseBody,
        };
      }
    } catch (e, stacktrace) {
      logger.severe('Exception on /directions: $e', stacktrace);
      return {'error': true, 'message': e.toString()};
    }
  }
}
