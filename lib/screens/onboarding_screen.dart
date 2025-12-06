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
      await navigatorKey.currentContext!
          .read<OnboardingStorage>()
          .setNotFirstTime();
      Navigator.pushReplacement(
        navigatorKey.currentContext!,
        MaterialPageRoute(builder: (_) => MainScreen()),
      );
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
                await _permissionUtils!.checkNotificationPermission();

                // Check if permission was granted after the action
                bool newStatus = await _permissionUtils!
                    .isNotificationPermissionGranted();

                if (mounted) {
                  Navigator.of(navigatorKey.currentContext!).pop();

                  // Show a follow-up message if on iOS and permission was denied
                  if (Platform.isIOS && !newStatus) {
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
          title: Text('Enable Notifications'),
          content: Text(
            'To enable notifications, please go to Settings > Manong > Notifications and turn on Allow Notifications.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: Text('Open Settings'),
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
              icons: Icons.location_off,
              description:
                  'Location permission is required to show your position',
              onPressed: () async {
                await _permissionUtils!.checkLocationPermission();
                if (mounted) Navigator.of(navigatorKey.currentContext!).pop();
              },
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
      _showLocationPermissionDialog();
    } else if (index == 2 && !_notificationDialogShown) {
      _showNotificationPermissionDialog();
    }
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
                onPageChanged: _onPageChanged, // Use the updated method
                itemBuilder: (context, index) {
                  final item = _instructions[index];

                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            item['image'] ?? '',
                            width: 250,
                            height: 250,
                          ),
                          const SizedBox(height: 40),
                          Text(
                            item['text'] ?? '',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
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
            Row(
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
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColorScheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _nextPage,
                  child: Text(
                    _currentPage == _instructions.length - 1
                        ? "Get Started"
                        : "Next",
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
