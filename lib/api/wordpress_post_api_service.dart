import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/models/wordpress_post.dart';
import 'package:http/http.dart' as http;

class WordpressPostApiService {
  final Logger logger = Logger('WordpressPostApiService');
  final String? baseUrl = dotenv.env['APP_URL_API'];

  Future<List<WordpressPost>?> fetchWordpressPosts() async {
    try {
      if (baseUrl == null) {
        throw Exception('Base URL is not configured.');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/wordpress-post'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      final responseBody = response.body;
      final jsonData = jsonDecode(responseBody);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return List<WordpressPost>.from(
          jsonData['data'].map((x) => WordpressPost.fromJson(x)),
        );
      } else {
        logger.warning(
          'Failed to fetch wordpress posts ${response.statusCode} $responseBody',
        );
      }
    } catch (e) {
      logger.severe('Error fetching wordpress posts $e');
    }

    return null;
  }
}
