import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:manong_application/main.dart';
import 'package:manong_application/screens/main_screen.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:manong_application/utils/onboarding_storage.dart';
import 'package:manong_application/utils/permission_utils.dart';
import 'package:manong_application/utils/url_utils.dart';
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

      // Store the showDialog result to control navigation
      await showDialog<void>(
        context: navigatorKey.currentContext!,
        barrierDismissible: false, // Prevent dismissing by tapping outside
        builder: (context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            insetPadding: const EdgeInsets.all(
              20,
            ), // Add padding from screen edges
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight:
                    MediaQuery.of(context).size.height * 0.8, // Limit height
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // SCROLLABLE CONTENT AREA
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 60,
                            color: AppColorScheme.primaryColor,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Location Access Required',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColorScheme.deepTeal,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Manong collects location data to:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColorScheme.tealDark,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildBulletPoint(
                                  'Show nearby service providers',
                                ),
                                _buildBulletPoint(
                                  'Calculate accurate service distances',
                                ),
                                _buildBulletPoint(
                                  'Enable real-time service tracking',
                                ),
                                _buildBulletPoint(
                                  'Match you with closest professionals',
                                ),
                                _buildBulletPoint(
                                  'Share location with assigned Manong during active services',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInfoPoint(
                                  'Location data is collected only for the purposes listed above',
                                ),
                                _buildInfoPoint(
                                  'Your location is accessed when using the app for booking services',
                                ),
                                _buildInfoPoint(
                                  'Background location may be used during active services for real-time tracking',
                                ),
                                _buildInfoPoint(
                                  'Your location is shared ONLY with the assigned service professional',
                                ),
                                _buildInfoPoint(
                                  'Live location data is deleted within 24 hours after service completion',
                                ),
                                _buildInfoPoint(
                                  'We do not share your location with third parties',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),

                  // FIXED BOTTOM BUTTONS AREA (NON-SCROLLABLE)
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(
                                      color: AppColorScheme.primaryColor,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'Not Now',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppColorScheme.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColorScheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 2,
                                ),
                                onPressed: () async {
                                  Navigator.of(context).pop();
                                  await _permissionUtils!
                                      .checkLocationPermission();
                                },
                                child: const Text(
                                  'Continue',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () async {
                            await launchUrlScreen(
                              navigatorKey.currentContext!,
                              'https://manongapp.com/index.php/privacy-policy/',
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.privacy_tip_outlined,
                                  size: 16,
                                  color: Colors.blue,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Learn more in our Privacy Policy',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            // Don't close current dialog, show details on top
                            _showDataUsageDetails(
                              context,
                              maintainMainDialog: true,
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              'What data do we collect and why?',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  void _showDataUsageDetails(
    BuildContext context, {
    bool maintainMainDialog = false,
  }) async {
    // Store the result so we can show location dialog again if needed
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // HEADER
                Container(
                  padding: const EdgeInsets.all(24),
                  child: const Text(
                    'Data Collection Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColorScheme.deepTeal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                // SCROLLABLE CONTENT
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Location Data Usage:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColorScheme.tealDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildDetailPoint(
                          'Foreground Access: When actively using the app for booking',
                        ),
                        _buildDetailPoint(
                          'Background Access: During active services for real-time tracking',
                        ),
                        _buildDetailPoint(
                          'Precise location for accurate matching and routing',
                        ),
                        _buildDetailPoint(
                          'Live tracking of service professionals en route',
                        ),
                        _buildDetailPoint(
                          'Location sharing with assigned Manong during service',
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Service-Specific Usage:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColorScheme.tealDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildDetailPoint(
                          'Booking Phase: Find nearby professionals, calculate ETAs',
                        ),
                        _buildDetailPoint(
                          'Service Phase: Real-time tracking, location sharing',
                        ),
                        _buildDetailPoint(
                          'Completion: Location data anonymized/deleted',
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Data Security:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColorScheme.tealDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildDetailPoint('End-to-end encrypted transmission'),
                        _buildDetailPoint(
                          'Access limited to assigned service professional only',
                        ),
                        _buildDetailPoint(
                          'Automatic deletion within 24 hours after service',
                        ),
                        _buildDetailPoint(
                          'No sharing with third-party advertisers',
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'User Control:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColorScheme.tealDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildDetailPoint(
                          'Manage permissions anytime in device settings',
                        ),
                        _buildDetailPoint(
                          'Background tracking only during active services',
                        ),
                        _buildDetailPoint(
                          'Can disable location access at any time',
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () async {
                            Navigator.of(
                              context,
                            ).pop(false); // Don't close completely
                            await launchUrlScreen(
                              navigatorKey.currentContext!,
                              'https://manongapp.com/index.php/privacy-policy/',
                            );
                            // Show data details again after web view
                            if (mounted) {
                              _showDataUsageDetails(
                                context,
                                maintainMainDialog: maintainMainDialog,
                              );
                            }
                          },
                          child: const Text(
                            'View full Privacy Policy for complete details',
                            style: TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // CLOSE BUTTON (FIXED AT BOTTOM)
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColorScheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text(
                            'Close',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    // If we need to show main dialog again after closing details
    if (maintainMainDialog && result == true && mounted) {
      // The details dialog is closed, main location dialog is still in stack
      // No need to show again as it's already there
    }
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.circle, size: 8, color: AppColorScheme.primaryColor),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildInfoPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 14, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.arrow_right, size: 16, color: Colors.grey),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
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
