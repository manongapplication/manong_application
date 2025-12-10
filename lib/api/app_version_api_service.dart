import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:manong_application/api/auth_service.dart';
import 'package:manong_application/models/app_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppVersionApiService {
  final Logger logger = Logger('AppVersionApiService');
  final baseUrl = dotenv.env['APP_URL_API'];

  Future<AppVersion> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final platform = Platform.isAndroid ? 'android' : 'ios';

      logger.info('Checking update for:');
      logger.info('  Platform: $platform');
      logger.info('  Current version: ${packageInfo.version}');
      logger.info('  Current build: ${packageInfo.buildNumber}');

      final response = await http.get(
        Uri.parse('$baseUrl/app-version/check').replace(
          queryParameters: {
            'platform': platform,
            'currentVersion': packageInfo.version,
            'currentBuild': packageInfo.buildNumber,
          },
        ),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      logger.info('API Response status: ${response.statusCode}');
      logger.info('API Response body: ${response.body}');

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final versionInfo = AppVersion.fromJson(responseBody);
        logger.info('Parsed version info:');
        logger.info('  Update available: ${versionInfo.updateAvailable}');
        logger.info('  Latest version: ${versionInfo.latestVersion}');
        logger.info('  Is mandatory: ${versionInfo.isMandatory}');
        logger.info('  Priority: ${versionInfo.priority}');
        return versionInfo;
      } else {
        logger.warning(
          'Failed to check for update: ${response.statusCode} $responseBody',
        );

        // Return default on failure
        return AppVersion(
          updateAvailable: false,
          isMandatory: false,
          forceUpdateRequired: false,
          priority: 'NORMAL',
          latestVersion: packageInfo.version,
          latestBuild: int.tryParse(packageInfo.buildNumber) ?? 0,
          storeUrl: Platform.isAndroid
              ? 'market://details?id=com.yourapp'
              : 'https://apps.apple.com/app/idYOUR_APP_ID',
          releaseDate: DateTime.now(),
        );
      }
    } catch (e, stacktrace) {
      logger.severe('Error checking for update', e, stacktrace);

      // Return default on error
      final packageInfo = await PackageInfo.fromPlatform();
      return AppVersion(
        updateAvailable: false,
        isMandatory: false,
        forceUpdateRequired: false,
        priority: 'NORMAL',
        latestVersion: packageInfo.version,
        latestBuild: int.tryParse(packageInfo.buildNumber) ?? 0,
        storeUrl: Platform.isAndroid
            ? 'market://details?id=com.yourapp'
            : 'https://apps.apple.com/app/idYOUR_APP_ID',
        releaseDate: DateTime.now(),
      );
    }
  }

  Future<bool> trackUserVersion(int userId) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final platform = Platform.isAndroid ? 'android' : 'ios';

      final token = await AuthService().getNodeToken();

      final response = await http.post(
        Uri.parse('$baseUrl/app-version/track'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'userId': userId,
          'platform': platform,
          'version': packageInfo.version,
          'buildNumber': int.tryParse(packageInfo.buildNumber) ?? 0,
        }),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return true;
      } else {
        logger.warning(
          'Failed to track user version: ${response.statusCode} $responseBody',
        );
        return false;
      }
    } catch (e, stacktrace) {
      logger.severe('Error tracking user version', e, stacktrace);
      return false;
    }
  }
}
