// lib/services/device_id_service.dart
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';

class DeviceIdService {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  static final FlutterSecureStorage _secureStorage =
      const FlutterSecureStorage();
  static final Uuid _uuid = Uuid();

  // Key for secure storage
  static const String _deviceIdKey = 'persistent_device_id';
  static const String _backupDeviceIdKey = 'backup_device_id';

  /// Get the most reliable device identifier
  static Future<String> getDeviceIdentifier() async {
    try {
      // 1. Try to get platform-specific ID first
      final String? platformId = await _getPlatformDeviceId();
      if (_isValidPlatformId(platformId)) {
        await _storeDeviceId(platformId!);
        return platformId;
      }

      // 2. Check if we have a stored ID in secure storage
      final String? storedId = await _secureStorage.read(key: _deviceIdKey);
      if (storedId != null && storedId.isNotEmpty) {
        return storedId;
      }

      // 3. Generate and store a new persistent ID
      final String newDeviceId = await _generateAndStoreDeviceId();
      return newDeviceId;
    } catch (e) {
      // 4. Final fallback with backup check
      return await _getFallbackDeviceId();
    }
  }

  /// Get platform-specific device ID using available properties
  static Future<String?> _getPlatformDeviceId() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return _getAndroidIdentifier(androidInfo);
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.identifierForVendor;
      } else if (Platform.isWindows) {
        final windowsInfo = await _deviceInfo.windowsInfo;
        return windowsInfo.deviceId;
      } else if (Platform.isLinux) {
        final linuxInfo = await _deviceInfo.linuxInfo;
        return linuxInfo.machineId;
      } else if (Platform.isMacOS) {
        final macosInfo = await _deviceInfo.macOsInfo;
        return macosInfo.systemGUID;
      }
    } catch (e) {
      debugPrint('Error getting platform device ID: $e');
    }
    return null;
  }

  /// Get Android identifier from available properties
  static String? _getAndroidIdentifier(AndroidDeviceInfo androidInfo) {
    // Try different available properties in order of preference
    final String? fingerprint = androidInfo.fingerprint;
    if (fingerprint != null && fingerprint.isNotEmpty) {
      return 'android_${_hashString(fingerprint)}';
    }

    final String? board = androidInfo.board;
    if (board != null && board.isNotEmpty) {
      return 'android_${_hashString(board)}';
    }

    final String? model = androidInfo.model;
    final String? brand = androidInfo.brand;
    if (model != null && brand != null) {
      return 'android_${_hashString('$brand$model')}';
    }

    return null;
  }

  /// Create a hash from string for consistent ID
  static String _hashString(String input) {
    int hash = 0;
    for (int i = 0; i < input.length; i++) {
      hash = (hash << 5) - hash + input.codeUnitAt(i);
      hash = hash & hash; // Convert to 32-bit integer
    }
    return hash.abs().toRadixString(16).padLeft(8, '0');
  }

  /// Validate platform ID
  static bool _isValidPlatformId(String? id) {
    if (id == null || id.isEmpty) return false;
    if (id == 'unknown' || id.toLowerCase().contains('unknown')) return false;
    if (id.length < 4) return false;
    return true;
  }

  /// Generate and store a new device ID
  static Future<String> _generateAndStoreDeviceId() async {
    final String newId =
        'device_${_uuid.v4()}_${DateTime.now().millisecondsSinceEpoch}';

    // Store in both primary and backup locations
    await _storeDeviceId(newId);

    return newId;
  }

  /// Store device ID securely
  static Future<void> _storeDeviceId(String deviceId) async {
    try {
      await _secureStorage.write(key: _deviceIdKey, value: deviceId);
      await _secureStorage.write(key: _backupDeviceIdKey, value: deviceId);
    } catch (e) {
      debugPrint('Error storing device ID: $e');
    }
  }

  /// Fallback method with backup check
  static Future<String> _getFallbackDeviceId() async {
    try {
      // Check backup storage first
      final String? backupId = await _secureStorage.read(
        key: _backupDeviceIdKey,
      );
      if (backupId != null && backupId.isNotEmpty) {
        return backupId;
      }

      // Generate emergency ID
      final String emergencyId = 'emergency_${_uuid.v4()}';
      await _secureStorage.write(key: _backupDeviceIdKey, value: emergencyId);
      return emergencyId;
    } catch (e) {
      // Ultimate fallback - in-memory only
      return 'fallback_${_uuid.v4()}_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Clear stored device IDs (for logout/testing)
  static Future<void> clearDeviceId() async {
    try {
      await _secureStorage.delete(key: _deviceIdKey);
      await _secureStorage.delete(key: _backupDeviceIdKey);
    } catch (e) {
      debugPrint('Error clearing device ID: $e');
    }
  }

  /// Check if device ID exists in secure storage
  static Future<bool> hasStoredDeviceId() async {
    try {
      final String? id = await _secureStorage.read(key: _deviceIdKey);
      return id != null && id.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get device info for debugging
  static Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return {
          'platform': 'Android',
          'fingerprint': androidInfo.fingerprint,
          'board': androidInfo.board,
          'brand': androidInfo.brand,
          'model': androidInfo.model,
          'device': androidInfo.device,
          'product': androidInfo.product,
          'hardware': androidInfo.hardware,
          'version': androidInfo.version.release,
          'sdkVersion': androidInfo.version.sdkInt,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return {
          'platform': 'iOS',
          'identifierForVendor': iosInfo.identifierForVendor,
          'model': iosInfo.model,
          'systemVersion': iosInfo.systemVersion,
          'name': iosInfo.name,
          'utsname': {
            'machine': iosInfo.utsname.machine,
            'release': iosInfo.utsname.release,
            'version': iosInfo.utsname.version,
          },
        };
      } else if (Platform.isWindows) {
        final windowsInfo = await _deviceInfo.windowsInfo;
        return {
          'platform': 'Windows',
          'deviceId': windowsInfo.deviceId,
          'productId': windowsInfo.productId,
          'computerName': windowsInfo.computerName,
        };
      } else if (Platform.isLinux) {
        final linuxInfo = await _deviceInfo.linuxInfo;
        return {
          'platform': 'Linux',
          'machineId': linuxInfo.machineId,
          'name': linuxInfo.name,
          'version': linuxInfo.version,
        };
      } else if (Platform.isMacOS) {
        final macosInfo = await _deviceInfo.macOsInfo;
        return {
          'platform': 'macOS',
          'systemGUID': macosInfo.systemGUID,
          'computerName': macosInfo.computerName,
          'model': macosInfo.model,
        };
      }
    } catch (e) {
      debugPrint('Error getting device info: $e');
    }
    return {'platform': 'unknown', 'error': 'Unable to get device info'};
  }

  /// Get a simplified device identifier for API calls
  static Future<Map<String, String>> getDeviceIdentifierForApi() async {
    final String deviceId = await getDeviceIdentifier();
    final Map<String, dynamic> deviceInfo = await getDeviceInfo();

    return {
      'deviceId': deviceId,
      'platform': deviceInfo['platform'] ?? 'unknown',
      'model': deviceInfo['model']?.toString() ?? 'unknown',
      'version': deviceInfo['version']?.toString() ?? 'unknown',
    };
  }
}
