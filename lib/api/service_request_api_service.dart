import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:manong_application/api/auth_service.dart';
import 'package:manong_application/models/service_request.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ServiceRequestApiService {
  final String? baseUrl = dotenv.env['APP_URL_API'];

  final Logger logger = Logger('ServiceRequestApiService');

  Future<Map<String, dynamic>?> uploadServiceRequest(
    ServiceRequest details,
  ) async {
    try {
      if (baseUrl == null) {
        throw Exception('Base URL is not configured.');
      }

      final token = await AuthService().getNodeToken();

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/service-requests'),
      );

      request.fields['serviceItemId'] = details.serviceItemId.toString();
      if (details.subServiceItemId != null) {
        request.fields['subServiceItemId'] = details.subServiceItemId
            .toString();
      }
      if (details.otherServiceName != null) {
        request.fields['otherServiceName'] = details.otherServiceName!;
      }
      if (details.paymentMethodId != null) {
        request.fields['paymentMethodId'] = details.paymentMethodId.toString();
      }

      request.fields['serviceDetails'] = details.serviceDetails ?? '';
      request.fields['urgencyLevelId'] = (details.urgencyLevelIndex + 1)
          .toString();

      for (var i = 0; i < details.images.length; i++) {
        var imageFile = details.images[i];
        var stream = http.ByteStream(imageFile.openRead().cast());
        var length = await imageFile.length();

        var multipartFile = http.MultipartFile(
          'images',
          stream,
          length,
          filename: imageFile.path.split('/').last,
        );

        request.files.add(multipartFile);
      }

      request.fields['customerLat'] = details.customerLat.toString();
      request.fields['customerLng'] = details.customerLng.toString();

      // Headers
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      logger.info(request.fields);
      logger.info(request.fields.entries);

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(responseBody);

        if (jsonData['warning'] != null) {
          logger.warning('Warning from server: ${jsonData['warning']}');
        }

        return jsonData['data'];
      } else {
        logger.warning('Upload failed with status: ${response.statusCode}');
        logger.warning('Response: $responseBody');
        throw Exception(
          'Upload failed with status ${response.statusCode}: $responseBody',
        );
      }
    } catch (e) {
      logger.severe('Error upload problem $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> fetchServiceRequests({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      if (baseUrl == null) {
        throw Exception('Base URL is not configured.');
      }

      final token = await AuthService().getNodeToken();

      final uri = Uri.parse('$baseUrl/service-requests').replace(
        queryParameters: {'page': page.toString(), 'limit': limit.toString()},
      );

      final response = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 30));

      final responseBody = response.body;
      final jsonData = jsonDecode(responseBody);

      if (response.statusCode == 200) {
        return jsonData;
      } else {
        throw Exception(
          'Failed to load service requests: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      logger.severe('Error fetching service requests $e');
    }
    return null;
  }

  Future<ServiceRequest?> fetchUserServiceRequest(int id) async {
    try {
      if (baseUrl == null) {
        throw Exception('Base URL is not configured.');
      }

      final token = await AuthService().getNodeToken();

      final response = await http.get(
        Uri.parse('$baseUrl/service-requests/$id'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseBody = response.body;

      final jsonData = jsonDecode(responseBody);

      if (response.statusCode == 200) {
        return ServiceRequest.fromJson(jsonData['data']);
      } else {
        throw Exception(
          'Failed to load user service request: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      logger.severe('Error fetching user service request $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> chooseManong(int id, int manongId) async {
    try {
      final token = await AuthService().getNodeToken();
      final response = await http.post(
        Uri.parse('$baseUrl/service-requests/$id/choose-manong'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'manongId': manongId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        logger.warning('Can\'t choose manong. Please Try again later.');
      }
    } catch (e) {
      logger.severe('Error updating service request $e');
    }

    return null;
  }

  Future<Map<String, dynamic>?> updatePaymentMethodId(
    int serviceRequestId,
    int paymentMethodId,
  ) async {
    try {
      if (baseUrl == null) {
        throw Exception('Base URL is not configured.');
      }

      final token = await AuthService().getNodeToken();

      final response = await http.post(
        Uri.parse('$baseUrl/service-requests/$serviceRequestId'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'paymentMethodId': paymentMethodId + 1}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        logger.warning('Can\'t update payment method. Please Try again later.');
      }
    } catch (e) {
      logger.severe('Error updating service request $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> updateServiceRequest(
    int id,
    Map<String, dynamic> updates,
  ) async {
    try {
      if (baseUrl == null) {
        throw Exception('Base URL is not configured.');
      }

      final token = await AuthService().getNodeToken();

      final response = await http.post(
        Uri.parse('$baseUrl/service-requests/$id'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'id': id, ...updates}),
      );

      final responseBody = response.body;
      final jsonData = jsonDecode(responseBody);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonData;
      } else {
        logger.warning(
          'Failed updating service request ${response.statusCode} $responseBody',
        );
        return null;
      }
    } catch (e) {
      logger.severe('Failed updating service request $e');
    }

    return null;
  }

  Future<Map<String, dynamic>?> completeRequest(int id, int manongId) async {
    try {
      if (baseUrl == null) {
        throw Exception('Base URL is not configured.');
      }

      final token = await AuthService().getNodeToken();

      final response = await http.post(
        Uri.parse('$baseUrl/service-requests/$id/complete'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'manongId': manongId, 'currency': 'PHP'}),
      );

      final responseBody = response.body;
      final jsonData = jsonDecode(responseBody);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonData;
      } else {
        logger.warning(
          'Failed to complete service request. ${response.statusCode} $responseBody',
        );
        return jsonData;
      }
    } catch (e) {
      logger.severe('Error completing service request $e');
    }

    return null;
  }

  Future<Map<String, dynamic>?> acceptServiceRequest(int id) async {
    try {
      if (baseUrl == null) {
        throw Exception('Base URL is not configured.');
      }

      final token = await AuthService().getNodeToken();

      final response = await http.post(
        Uri.parse('$baseUrl/service-requests/$id/accept'),
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
          'Failed to accept service request. ${response.statusCode} $responseBody',
        );
        return null;
      }
    } catch (e) {
      logger.severe('Error accepting service request $e');
    }

    return null;
  }

  Future<Map<String, dynamic>?> cancelServiceRequest(int id) async {
    try {
      if (baseUrl == null) {
        throw Exception('Base URL is not configured.');
      }

      final token = await AuthService().getNodeToken();

      final response = await http.post(
        Uri.parse('$baseUrl/service-requests/$id/cancel'),
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
          'Failed to cancel service request. ${response.statusCode} $responseBody',
        );
        return null;
      }
    } catch (e) {
      logger.severe('Error cancelling service request $e');
    }

    return null;
  }

  Future<Map<String, dynamic>?> expiredServiceRequest(int id) async {
    try {
      if (baseUrl == null) {
        throw Exception('Base URL is not configured.');
      }

      final token = await AuthService().getNodeToken();

      final response = await http.post(
        Uri.parse('$baseUrl/service-requests/$id/expired'),
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
          'Failed to set expired the service request. ${response.statusCode} $responseBody',
        );
        return null;
      }
    } catch (e) {
      logger.severe('Error expiring service request $e');
    }

    return null;
  }

  Future<Map<String, dynamic>?> startServiceRequest(int id) async {
    try {
      if (baseUrl == null) {
        throw Exception('Base URL is not configured.');
      }

      final token = await AuthService().getNodeToken();

      final response = await http.post(
        Uri.parse('$baseUrl/service-requests/$id/start'),
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
          'Failed to start service request. ${response.statusCode} $responseBody',
        );
        return null;
      }
    } catch (e) {
      logger.severe('Error starting service request $e');
    }

    return null;
  }

  Future<Map<String, dynamic>?> getOngoingServiceRequest() async {
    try {
      if (baseUrl == null) {
        throw Exception('Base URL is not configured.');
      }

      final token = await AuthService().getNodeToken();

      final response = await http.get(
        Uri.parse('$baseUrl/service-requests/ongoing'),
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
          'Failed to ongoing service request. ${response.statusCode} $responseBody',
        );
        return null;
      }
    } catch (e) {
      logger.severe('Error ongoing service request $e');
    }

    return null;
  }
}
