import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';
import 'package:http/http.dart' as http;
// ignore: depend_on_referenced_packages
import 'package:http_parser/http_parser.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as path;
import 'package:manong_application/api/auth_service.dart';

class ImageUploadApiService {
  final String? baseUrl = dotenv.env['APP_URL_API'];
  final Logger logger = Logger('ImageUploadApiService');

  Future<Map<String, dynamic>?> uploadImages({
    required int serviceRequestId,
    required int messageId,
    required List<File> images,
  }) async {
    try {
      // Validate inputs
      if (images.isEmpty || images.length > 3) {
        logger.warning('Invalid image count: ${images.length}');
        return null;
      }

      final token = await AuthService().getNodeToken();
      final uri = Uri.parse('$baseUrl/image-upload/');

      logger.info('Preparing request to: $uri');
      logger.info(
        'ServiceRequestId: $serviceRequestId (${serviceRequestId.runtimeType})',
      );
      logger.info('MessageId: $messageId (${messageId.runtimeType})');
      logger.info('Images count: ${images.length}');

      final request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
      request.headers['Content-Type'] = 'multipart/form-data';

      // Add fields
      request.fields['serviceRequestId'] = serviceRequestId.toString();
      request.fields['messageId'] = messageId.toString();

      logger.info('Request fields: ${request.fields}');

      // Add image files
      for (int i = 0; i < images.length; i++) {
        final img = images[i];
        final fileName = path.basename(img.path);
        final extension = path
            .extension(img.path)
            .replaceAll('.', '')
            .toLowerCase();

        // Ensure valid image extension
        final validExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
        final actualExtension = validExtensions.contains(extension)
            ? extension
            : 'jpg';

        final multipartFile = await http.MultipartFile.fromPath(
          'images', // Keep the same field name for all images
          img.path,
          filename: fileName,
          contentType: MediaType('image', actualExtension),
        );

        logger.info(
          'Adding file $i: ${multipartFile.filename} (${multipartFile.length} bytes)',
        );
        request.files.add(multipartFile);
      }

      logger.info('Final request files count: ${request.files.length}');
      logger.info('Final request fields: ${request.fields}');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      logger.info('Upload response: ${response.statusCode}');
      logger.info('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        logger.info('Images uploaded successfully');
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        logger.warning(
          'Upload failed: ${response.statusCode} ${response.body}',
        );
        return null;
      }
    } catch (e) {
      logger.severe('Error uploading images: $e');
      return null;
    }
  }
}
