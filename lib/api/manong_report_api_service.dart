import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/api/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:manong_application/models/manong_report.dart';
import 'package:manong_application/models/payment_transaction.dart';

class ManongReportApiService {
  final Logger logger = Logger('ManongReportApiService');
  final baseUrl = dotenv.env['APP_URL_API'];

  Future<Map<String, dynamic>?> createManongReport({
    required ManongReport details,
    bool? servicePaid,
  }) async {
    try {
      logger.info('SQ $servicePaid');
      final token = await AuthService().getNodeToken();

      final uri = Uri.parse('$baseUrl/manong-report');

      final serviceRequestId = details.serviceRequestId.toString();
      final manongId = details.manongId.toString();
      final summary = details.summary.toString();

      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..headers['Accept'] = 'application/json'
        ..fields['serviceRequestId'] = serviceRequestId
        ..fields['manongId'] = manongId
        ..fields['summary'] = summary;

      if (servicePaid != null) {
        request.fields['servicePaid'] = servicePaid.toString();
      }

      if (details.details != null) {
        request.fields['details'] = details.details.toString();
      }
      if (details.materialsUsed != null) {
        request.fields['materialsUsed'] = details.materialsUsed.toString();
      }
      if (details.laborDuration != null) {
        request.fields['laborDuration'] = details.laborDuration.toString();
      }
      if (details.issuesFound != null) {
        request.fields['issuesFound'] = details.issuesFound.toString();
      }
      if (details.customerPresent != null) {
        request.fields['customerPresent'] = details.customerPresent.toString();
      }
      if (details.verifiedByUser != null) {
        request.fields['verifiedByUser'] = details.verifiedByUser.toString();
      }
      if (details.totalCost != null) {
        request.fields['totalCost'] = details.totalCost.toString();
      }
      if (details.warrantyInfo != null) {
        request.fields['warrantyInfo'] = details.warrantyInfo.toString();
      }
      if (details.recommendations != null) {
        request.fields['recommendations'] = details.recommendations.toString();
      }

      if (details.images != null) {
        for (var i = 0; i < details.images!.length; i++) {
          var imageFile = details.images![i];
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
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      logger.info('Response body: $responseBody');

      final jsonData = jsonDecode(responseBody);

      if (response.statusCode == 200 || response.statusCode == 201) {
        logger.info('Manong report created successfully.');
        return jsonData;
      } else {
        logger.warning(
          'Failed to create manong report: ${response.statusCode} $responseBody',
        );
        return jsonData;
      }
    } catch (e, stacktrace) {
      logger.severe('Error creating manong report', e, stacktrace);
    }

    return null;
  }

  Future<Map<String, dynamic>?> updateManongReport({
    required int id,
    required ManongReport details,
  }) async {
    try {
      final token = await AuthService().getNodeToken();

      logger.info('UPDATE REPORT ${details.summary}');

      final uri = Uri.parse('$baseUrl/manong-report/$id');

      final serviceRequestId = details.serviceRequestId.toString();
      final manongId = details.manongId.toString();
      final summary = details.summary.toString();

      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..headers['Accept'] = 'application/json'
        ..fields['serviceRequestId'] = serviceRequestId
        ..fields['manongId'] = manongId
        ..fields['summary'] = summary;

      if (details.details != null) {
        request.fields['details'] = details.details.toString();
      }
      if (details.materialsUsed != null) {
        request.fields['materialsUsed'] = details.materialsUsed.toString();
      }
      if (details.laborDuration != null) {
        request.fields['laborDuration'] = details.laborDuration.toString();
      }
      if (details.issuesFound != null) {
        request.fields['issuesFound'] = details.issuesFound.toString();
      }
      if (details.customerPresent != null) {
        request.fields['customerPresent'] = details.customerPresent.toString();
      }
      if (details.verifiedByUser != null) {
        request.fields['verifiedByUser'] = details.verifiedByUser.toString();
      }
      if (details.totalCost != null) {
        request.fields['totalCost'] = details.totalCost.toString();
      }
      if (details.warrantyInfo != null) {
        request.fields['warrantyInfo'] = details.warrantyInfo.toString();
      }
      if (details.recommendations != null) {
        request.fields['recommendations'] = details.recommendations.toString();
      }

      if (details.images != null && details.images!.isNotEmpty) {
        // Filter out server file paths and only include actual local files
        final validImageFiles = details.images!.where((file) {
          final path = file.path;
          // Check if this is NOT a server file path
          // Server file paths will typically look like "uploads/manong_reports/..." or JSON arrays
          final isServerPath =
              path.startsWith('uploads') ||
              path.startsWith('[') ||
              path.contains('manong_reports');

          return !isServerPath;
        }).toList();

        logger.info(
          'Found ${validImageFiles.length} valid local image files to upload',
        );

        for (var i = 0; i < validImageFiles.length; i++) {
          var imageFile = validImageFiles[i];
          try {
            var stream = http.ByteStream(imageFile.openRead().cast());
            var length = await imageFile.length();

            var multipartFile = http.MultipartFile(
              'images',
              stream,
              length,
              filename: imageFile.path.split('/').last,
            );

            request.files.add(multipartFile);
            logger.info('Added image: ${imageFile.path}');
          } catch (e) {
            logger.warning('Failed to add image ${imageFile.path}: $e');
            // Skip this file and continue with others
          }
        }
      } else {
        logger.info('No new images to upload');
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      logger.info('Response body: $responseBody');

      final jsonData = jsonDecode(responseBody);

      if (response.statusCode == 200 || response.statusCode == 201) {
        logger.info('Manong report updated successfully.');
        return jsonData;
      } else {
        logger.warning(
          'Failed to update manong report: ${response.statusCode} $responseBody',
        );
        return jsonData;
      }
    } catch (e, stacktrace) {
      logger.severe(
        'Error updating manong report ${e.toString()}',
        e.toString(),
        stacktrace,
      );
    }

    return null;
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
