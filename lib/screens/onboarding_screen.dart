import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:manong_application/main.dart';
import 'package:manong_application/screens/main_screen.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:manong_application/utils/onboarding_storage.dart';
import 'package:manong_application/utils/permission_utils.dart';
import 'package:manong_application/widgets/modal_icon_overlay.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<StatefulWidget> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<StatefulWidget> {
  final PageController _pageController = PageController();
  late PermissionUtils? _permissionUtils;
  late FlutterSecureStorage _storage;
  int _currentPage = 0;
  late OnboardingStorage _onboardingStorage;

  // Track which dialogs have been shown
  bool _locationDialogShown = false;
  bool _notificationDialogShown = false;
  bool _isCheckingPermissions = false;

  final List<Map<String, String>> _instructions = [
    {
      'text': 'Welcome to Manong – Home services anytime you need.',
      'image': 'assets/icon/logo.png',
    },
    {
      'text': 'Enable location to find nearby professionals quickly.',
      'image': 'assets/icon/manong_oboarding_find_manong.png',
    },
    {
      'text': 'Get updates with notifications about your bookings.',
      'image': 'assets/icon/manong_oboarding_notification_manong.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeComponents();
  }

  void _initializeComponents() {
    _onboardingStorage = OnboardingStorage();
    _onboardingStorage.init();
    _storage = FlutterSecureStorage();
    _permissionUtils = PermissionUtils();
    _storage.write(key: 'is_first_time', value: '');
  }

  Future<void> _nextPage() async {
    if (_currentPage < _instructions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // On the last page, ensure permissions are checked
      await _ensurePermissions();

      await navigatorKey.currentContext!
          .read<OnboardingStorage>()
          .setNotFirstTime();
      Navigator.pushReplacement(
        navigatorKey.currentContext!,
        MaterialPageRoute(builder: (_) => MainScreen()),
      );
    }
  }

  Future<void> _ensurePermissions() async {
    if (_isCheckingPermissions || _permissionUtils == null) return;

    _isCheckingPermissions = true;

    try {
      // Ensure location permission if on location page
      if (_currentPage >= 1) {
        await _permissionUtils!.checkLocationPermission();
      }

      // Ensure notification permission if on notification page
      if (_currentPage >= 2) {
        await _permissionUtils!.checkNotificationPermission();
      }
    } finally {
      _isCheckingPermissions = false;
    }
  }

  Future<void> _showNotificationPermissionDialog() async {
    // Only show once and only if permission isn't already granted
    if (_notificationDialogShown || _permissionUtils == null) return;

    bool granted = await _permissionUtils!.isNotificationPermissionGranted();

    if (!granted && mounted) {
      _notificationDialogShown = true; // Mark as shown

      showDialog(
        context: navigatorKey.currentContext!,
        barrierDismissible: false,
        builder: (context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ModalIconOverlay(
              onPressed: () async {
                bool result = await _permissionUtils!
                    .checkNotificationPermission();

                if (mounted) {
                  Navigator.of(navigatorKey.currentContext!).pop();

                  // Show a follow-up message if on iOS and permission was denied
                  if (Platform.isIOS && !result) {
                    _showIOSNotificationInstructions();
                  }
                }
              },
              icons: Icons.notifications_active,
              description: Platform.isIOS
                  ? 'Enable notifications to get updates about your bookings and important alerts. You can manage this later in Settings.'
                  : 'We\'d like to send you notifications about updates, reminders, and important alerts.',
            ),
          );
        },
      );
    }
  }

  void _showIOSNotificationInstructions() {
    showDialog(
      context: navigatorKey.currentContext!,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enable Notifications'),
          content: const Text(
            'To enable notifications, please go to Settings > Manong > Notifications and turn on Allow Notifications.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showLocationPermissionDialog() async {
    // Only show once and only if permission isn't already granted
    if (_locationDialogShown || _permissionUtils == null) return;

    bool granted = await _permissionUtils!.isLocationPermissionGranted();

    if (!granted && mounted) {
      _locationDialogShown = true; // Mark as shown

      showDialog(
        context: navigatorKey.currentContext!,
        barrierDismissible: false, // Prevent dismissing by tapping outside
        builder: (context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ModalIconOverlay(
              icons: Icons.location_on,
              description:
                  'Location permission helps us show nearby service providers and improve your experience.',
              onPressed: () async {
                await _permissionUtils!.checkLocationPermission();
                if (mounted) Navigator.of(navigatorKey.currentContext!).pop();
              },
              text: 'Continue',
            ),
          );
        },
      );
    }
  }

  // Reset dialog flags when going back to previous pages
  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });

    // Reset dialog flags if user goes back to previous pages
    if (index < 1) {
      _locationDialogShown = false;
    }
    if (index < 2) {
      _notificationDialogShown = false;
    }

    // Show dialogs only when moving forward to specific pages
    if (index == 1 && !_locationDialogShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showLocationPermissionDialog();
      });
    } else if (index == 2 && !_notificationDialogShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showNotificationPermissionDialog();
      });
    }
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_instructions.length, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 12 : 8,
          height: _currentPage == index ? 12 : 8,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? AppColorScheme.primaryColor
                : Colors.grey.shade400,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }

  Widget _buildNextButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColorScheme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: _nextPage,
          child: Text(
            _currentPage == _instructions.length - 1 ? "Get Started" : "Next",
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _instructions.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  final item = _instructions[index];

                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            item['image']!,
                            width: 250,
                            height: 250,
                            filterQuality: FilterQuality.high,
                          ),
                          const SizedBox(height: 40),
                          Text(
                            item['text']!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 40),
            _buildPageIndicator(),
            const SizedBox(height: 20),
            _buildNextButton(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
