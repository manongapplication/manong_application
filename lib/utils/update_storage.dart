import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UpdateStorage with ChangeNotifier {
  static const String _keyLastUpdateCheck = 'last_update_check';
  static const String _keyHasCriticalUpdate = 'has_critical_update';
  static const String _keyCriticalUpdateStoreUrl = 'critical_update_store_url';
  static const String _keyCriticalUpdateMessage = 'critical_update_message';
  static const String _keySkippedVersion = 'skipped_version';

  static const _storage = FlutterSecureStorage();

  Future<bool> shouldCheckForUpdate() async {
    try {
      final String? lastCheckString = await _storage.read(
        key: _keyLastUpdateCheck,
      );

      if (lastCheckString == null) {
        return true;
      }

      final lastCheck = DateTime.parse(lastCheckString);
      final now = DateTime.now();

      // Check only once per day
      return now.difference(lastCheck) > const Duration(days: 1);
    } catch (e, st) {
      debugPrint('⚠️ Failed to read update check storage: $e\n$st');
      return true;
    }
  }

  Future<void> updateLastCheckTime() async {
    try {
      await _storage.write(
        key: _keyLastUpdateCheck,
        value: DateTime.now().toIso8601String(),
      );
    } catch (e, st) {
      debugPrint('⚠️ Failed to write update check storage: $e\n$st');
    }
  }

  Future<void> setCriticalUpdate({
    required String storeUrl,
    required String message,
  }) async {
    try {
      await _storage.write(key: _keyHasCriticalUpdate, value: 'true');
      await _storage.write(key: _keyCriticalUpdateStoreUrl, value: storeUrl);
      await _storage.write(key: _keyCriticalUpdateMessage, value: message);
    } catch (e, st) {
      debugPrint('⚠️ Failed to set critical update: $e\n$st');
    }
  }

  Future<Map<String, String>?> getCriticalUpdate() async {
    try {
      final String? hasCriticalUpdate = await _storage.read(
        key: _keyHasCriticalUpdate,
      );

      if (hasCriticalUpdate == 'true') {
        final String? storeUrl = await _storage.read(
          key: _keyCriticalUpdateStoreUrl,
        );
        final String? message = await _storage.read(
          key: _keyCriticalUpdateMessage,
        );

        if (storeUrl != null && message != null) {
          return {'storeUrl': storeUrl, 'message': message};
        }
      }
      return null;
    } catch (e, st) {
      debugPrint('⚠️ Failed to get critical update: $e\n$st');
      return null;
    }
  }

  Future<void> clearCriticalUpdate() async {
    try {
      await _storage.delete(key: _keyHasCriticalUpdate);
      await _storage.delete(key: _keyCriticalUpdateStoreUrl);
      await _storage.delete(key: _keyCriticalUpdateMessage);
    } catch (e, st) {
      debugPrint('⚠️ Failed to clear critical update: $e\n$st');
    }
  }

  Future<void> setSkippedVersion(String version) async {
    try {
      await _storage.write(key: _keySkippedVersion, value: version);
    } catch (e, st) {
      debugPrint('⚠️ Failed to set skipped version: $e\n$st');
    }
  }

  Future<String?> getSkippedVersion() async {
    try {
      return await _storage.read(key: _keySkippedVersion);
    } catch (e, st) {
      debugPrint('⚠️ Failed to get skipped version: $e\n$st');
      return null;
    }
  }

  Future<void> clearSkippedVersion() async {
    try {
      await _storage.delete(key: _keySkippedVersion);
    } catch (e, st) {
      debugPrint('⚠️ Failed to clear skipped version: $e\n$st');
    }
  }
}
