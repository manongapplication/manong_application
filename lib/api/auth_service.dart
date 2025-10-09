import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/api/firebase_api_token.dart';
import 'package:manong_application/models/app_user.dart';

class AuthService {
  final storage = FlutterSecureStorage();
  final String? baseUrl = dotenv.env['APP_URL_API'];

  final Logger logger = Logger('auth_service');

  FirebaseAuth auth = FirebaseAuth.instance;

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(PhoneAuthCredential credential) onAutoVerified,
    required Function(FirebaseAuthException error) onFailed,
    required Function(String verificationId) onCodeSent,
  }) async {
    await auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) {
        onAutoVerified(credential);
      },
      verificationFailed: (FirebaseAuthException error) {
        onFailed(error);
      },
      codeSent: (String verificationId, int? forceResendingToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (verificationId) {},
    );
  }

  Future<String?> signInWithCredential(
    String? verificationId,
    String? smsCode,
  ) async {
    if (verificationId == null || smsCode == null) {
      throw Exception('Verification ID and SMS code must not be null');
    }

    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );

    final response = await auth.signInWithCredential(credential);
    return response.user?.phoneNumber;
  }

  Future<bool> isTokenSet() async {
    String? token = await storage.read(key: 'token');
    return token != null && token.isNotEmpty;
  }

  Future<Map<String, dynamic>?> registerOrLoginUser(String phoneNumber) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/register-instant'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode({'phone': phoneNumber}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        await storage.write(key: 'node_token', value: data['token']);
        if (data != null) {
          await FirebaseApiToken().saveFcmTokenToDatabase();
        }
        return data;
      } else if (response.statusCode == 422) {
        final errors = json.decode(response.body);
        throw Exception(
          'Validation failed: ${errors['errors']['phone']?[0] ?? 'Invalid phone number'}',
        );
      } else {
        throw Exception('Registration failed ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> completePhoneAuth(
    String verificationId,
    String smsCode,
  ) async {
    try {
      final verifiedPhone = await signInWithCredential(verificationId, smsCode);
      final result = await registerOrLoginUser(verifiedPhone!);
      return result ?? {};
    } catch (e) {
      throw Exception('Phone authentication failed: $e');
    }
  }

  Future<String?> getNodeToken() async {
    return await storage.read(key: 'node_token');
  }

  Future<bool> isLoggedIn() async {
    final token = await getNodeToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    Exception? lastException;

    try {
      final token = await getNodeToken();

      if (token != null && baseUrl != null) {
        final response = await http
            .post(
              Uri.parse('$baseUrl/logout'),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'Authorization': 'Bearer $token',
              },
            )
            .timeout(const Duration(seconds: 15));

        // Log the response for debugging
        if (response.statusCode != 200) {
          logger.warning(
            'Node logout warning: ${response.statusCode} - ${response.body}',
          );
        }
      }
    } catch (e) {
      logger.severe('Node logout failed: $e');
      lastException = Exception('Server logout failed: $e');
    }

    // Always clear local storage regardless of server response
    try {
      await storage.delete(key: 'node_token');
      await storage.delete(
        key: 'token',
      ); // Also clear the old token if it exists
    } catch (e) {
      logger.severe('Failed to clear local tokens: $e');
      lastException = Exception('Failed to clear local data: $e');
    }

    // Always sign out from Firebase
    try {
      await auth.signOut();
    } catch (e) {
      logger.severe('Firebase sign out failed: $e');
      lastException = Exception('Firebase sign out failed: $e');
    }

    // If there were any critical errors, throw the last one
    if (lastException != null) {
      throw lastException;
    }
  }

  Future<AppUser> getMyProfile() async {
    try {
      final token = await getNodeToken();

      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http
          .get(
            Uri.parse('$baseUrl/me'),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return AppUser.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 401) {
        // Token might be expired, clear it
        await storage.delete(key: 'node_token');
        throw Exception('Session expired. Please log in again.');
      } else {
        throw Exception(
          'Failed to load profile: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error getting profile: $e');
    }
  }

  // Helper method to clear all stored data (useful for complete reset)
  Future<void> clearAllData() async {
    try {
      await storage.deleteAll();
      await auth.signOut();
    } catch (e) {
      logger.severe('Error clearing all data: $e');
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
  }) async {
    try {
      final token = await getNodeToken();

      final response = await http
          .post(
            Uri.parse('$baseUrl/edit-profile'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'firstName': firstName,
              'lastName': lastName,
              'email': email,
            }),
          )
          .timeout(Duration(seconds: 30));

      final responseBody = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return responseBody;
      } else {
        logger.warning(
          'Failed to update profile: ${response.statusCode} $responseBody',
        );
        return responseBody;
      }
    } catch (e) {
      logger.severe('Error to update profile $e');
      return {};
    }
  }

  Future<Map<String, dynamic>?> sendVerificationTwilio(String smsNumber) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'phone': smsNumber}),
      );

      final responseBody = response.body;
      final jsonData = jsonDecode(responseBody);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonData;
      } else {
        logger.warning(
          'Failed to send sms ${response.statusCode} $responseBody',
        );
      }
      return null;
    } catch (e) {
      logger.severe('Error sending sms $e');
    }

    return null;
  }

  Future<Map<String, dynamic>?> verifySmsCodeTwilio(
    String smsNumber,
    String code,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verify-sms'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'phone': smsNumber, 'code': code}),
      );

      final responseBody = response.body;
      final jsonData = jsonDecode(responseBody);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (jsonData['token'] == null) return null;
        await storage.write(key: 'node_token', value: jsonData['token']);
        return jsonData;
      } else {
        logger.warning(
          'Failed verifying sms code ${response.statusCode} $responseBody',
        );

        return null;
      }
    } catch (e) {
      logger.severe('Error verifying sms code $e');
    }

    return null;
  }

  Future<Map<String, dynamic>?> saveFcmToken(String fcmToken) async {
    try {
      final token = await getNodeToken();
      logger.warning('Grud $token');
      final response = await http.post(
        Uri.parse('$baseUrl/fcmToken'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'fcmToken': fcmToken}),
      );

      final responseBody = response.body;
      final jsonData = jsonDecode(responseBody);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonData;
      } else {
        logger.warning(
          'Failed to save fcmToken ${response.statusCode} $responseBody',
        );
      }
    } catch (e) {
      logger.severe('Error to save fcmToken $e');
    }

    return null;
  }
}
