import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/api/auth_service.dart';
import 'package:http/http.dart' as http;

class UserApiService {
  final Logger logger = Logger('UserApiService');
  final baseUrl = dotenv.env['APP_URL_API'];
  final storage = FlutterSecureStorage();
  FirebaseAuth auth = FirebaseAuth.instance;

  Future<Map<String, dynamic>?> changePassword({
    required String password,
    required String newPassword,
  }) async {
    try {
      final token = await AuthService().getNodeToken();

      final response = await http.post(
        Uri.parse('$baseUrl/user/change-password'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'password': password, 'newPassword': newPassword}),
      );

      final responseBody = response.body;
      final jsonData = jsonDecode(responseBody);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonData;
      } else {
        logger.warning(
          'Failed to change password: ${response.statusCode} $responseBody',
        );
        return jsonData;
      }
    } catch (e, stacktrace) {
      logger.severe('Error changing password', e, stacktrace);
    }

    return null;
  }

  Future<Map<String, dynamic>?> deleteUserdata(String password) async {
    try {
      final token = await AuthService().getNodeToken();

      final response = await http.post(
        Uri.parse('$baseUrl/user/delete-data'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'password': password}),
      );

      final responseBody = response.body;
      final jsonData = jsonDecode(responseBody);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Clear Storage Header
        try {
          await storage.delete(key: 'node_token');
          await storage.delete(key: 'token');
        } catch (e) {
          logger.severe('Failed to clear local tokens: $e');
        }

        try {
          await auth.signOut();
        } catch (e) {
          logger.severe('Firebase sign out failed: $e');
        }

        return jsonData;
      } else {
        logger.warning(
          'Failed to delete user: ${response.statusCode} $responseBody',
        );
        return jsonData;
      }
    } catch (e, stacktrace) {
      logger.severe('Error deleting user', e, stacktrace);
    }

    return null;
  }
}
