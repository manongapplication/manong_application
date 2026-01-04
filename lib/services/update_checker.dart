import 'dart:io';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/api/app_version_api_service.dart';
import 'package:manong_application/models/app_service.dart';
import 'package:manong_application/utils/update_storage.dart';
import 'package:manong_application/widgets/version_update_dialog.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateChecker {
  final Logger logger = Logger('UpdateChecker');
  final UpdateStorage _updateStorage = UpdateStorage();
  final AppVersionApiService _apiService = AppVersionApiService();

  Future<void> checkAndShowUpdate({
    required BuildContext context,
    required int? userId,
    bool forceCheck = false,
  }) async {
    try {
      // Check if we should skip this check
      if (!forceCheck) {
        final shouldCheck = await _updateStorage.shouldCheckForUpdate();
        if (!shouldCheck) {
          return;
        }
      }

      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // Get skipped version
      final skippedVersion = await _updateStorage.getSkippedVersion();
      if (skippedVersion == currentVersion) {
        logger.info('User skipped update for version $currentVersion');
        return;
      }

      // Check for critical update from storage first
      final criticalUpdate = await _updateStorage.getCriticalUpdate();
      if (criticalUpdate != null && context.mounted) {
        await _showCriticalUpdateDialog(
          context: context,
          storeUrl: criticalUpdate['storeUrl']!,
          message: criticalUpdate['message']!,
        );
        await _updateStorage.clearCriticalUpdate();
        return;
      }

      // Check with API
      final versionInfo = await _apiService.checkForUpdate();

      // Update last check time
      await _updateStorage.updateLastCheckTime();

      // Track user version if logged in
      if (userId != null) {
        await _apiService.trackUserVersion(userId);
      }

      // Show update dialog if needed
      if (versionInfo.updateAvailable && context.mounted) {
        await _showUpdateDialog(
          context: context,
          versionInfo: versionInfo,
          currentVersion: currentVersion,
        );
      }
    } catch (e, stackTrace) {
      logger.severe('Error checking for updates', e, stackTrace);
    }
  }

  Future<void> _showUpdateDialog({
    required BuildContext context,
    required AppVersion versionInfo,
    required String currentVersion,
  }) async {
    final bool isMandatory =
        versionInfo.isMandatory || versionInfo.forceUpdateRequired;
    final bool isCritical = versionInfo.priority == 'CRITICAL';

    await showDialog(
      context: context,
      barrierDismissible: !isMandatory,
      builder: (context) => VersionUpdateDialog(
        versionInfo: versionInfo,
        currentVersion: currentVersion,
        onUpdatePressed: () => _launchStore(versionInfo.storeUrl),
        onLaterPressed: isMandatory
            ? null
            : () async {
                // Store skipped version
                await _updateStorage.setSkippedVersion(
                  versionInfo.latestVersion,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
      ),
    );
  }

  Future<void> _showCriticalUpdateDialog({
    required BuildContext context,
    required String storeUrl,
    required String message,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.orange, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Critical Update Required',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You must update to continue using the app.',
                      style: TextStyle(color: Colors.orange, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => _launchStore(storeUrl),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Update Now'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchStore(String url) async {
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        // Fallback to default store URLs
        final fallbackUrl = Platform.isAndroid
            ? 'https://play.google.com/store/apps/details?id=com.yourapp'
            : 'https://apps.apple.com/app/idYOUR_APP_ID';

        if (await canLaunchUrl(Uri.parse(fallbackUrl))) {
          await launchUrl(Uri.parse(fallbackUrl));
        }
      }
    } catch (e) {
      logger.severe('Failed to launch store: $e');
    }
  }
}
