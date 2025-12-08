import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class OnboardingStorage with ChangeNotifier {
  static const String _keyFirstTime = 'is_first_time';
  static const _storage = FlutterSecureStorage();

  bool? _isFirstTime;

  bool? get isFirstTimeValue => _isFirstTime;

  Future<void> init() async {
    try {
      String? value = await _storage.read(key: _keyFirstTime);
      _isFirstTime = value == null || value == 'true';
    } catch (e, st) {
      debugPrint('⚠️ Failed to read onboarding storage: $e\n$st');
      // fallback to first time true
      _isFirstTime = true;
      try {
        await _storage.deleteAll(); // optional: reset storage
      } catch (_) {}
    }
  }

  Future<void> setNotFirstTime() async {
    await _storage.write(key: _keyFirstTime, value: 'false');
    _isFirstTime = false;
    notifyListeners();
  }
}
