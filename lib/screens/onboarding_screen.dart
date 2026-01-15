import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:manong_application/main.dart';
import 'package:manong_application/screens/main_screen.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:manong_application/utils/onboarding_storage.dart';
import 'package:manong_application/utils/permission_utils.dart';
import 'package:manong_application/utils/tutorial_utils.dart';
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
  final PageController _galleryController = PageController(
    viewportFraction: 0.8,
  );
  late PermissionUtils? _permissionUtils;
  late FlutterSecureStorage _storage;
  int _currentPage = 0;
  int _galleryPage = 0;
  late OnboardingStorage _onboardingStorage;

  // Track which dialogs have been shown
  bool _locationDialogShown = false;
  bool _notificationDialogShown = false;
  bool _isCheckingPermissions = false;

  bool _userAcceptedLocationDisclosure = false;
  bool _isRequestingLocation = false;

  // Add privacy policy page as first item
  final List<Map<String, dynamic>> _instructions = [
    {'type': 'location_disclosure', 'title': 'Location Data Collection'},
    {'type': 'privacy_policy', 'title': 'Privacy Policy'},
    {
      'type': 'gallery',
      'text': 'Welcome to Manong – Home services anytime you need.',
      'image': 'assets/icon/logo.png',
    },
    {
      'type': 'normal',
      'text': 'Connect with experienced local professionals.',
      'image': 'assets/icon/manong_oboarding_find_manong.png',
    },
    {
      'type': 'normal',
      'text': 'Get updates with notifications about your bookings.',
      'image': 'assets/icon/manong_oboarding_notification_manong.png',
    },
  ];

  final List<Map<String, dynamic>> _galleryItems = TutorialUtils().galleryItems;

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

    _loadUserConsent();
  }

  Future<void> _loadUserConsent() async {
    final value = await _storage.read(key: 'location_disclosure_accepted');
    if (mounted) {
      setState(() {
        _userAcceptedLocationDisclosure = value == 'true';
      });
    }
  }

  Widget _buildDisclosurePoint(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColorScheme.tealDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationDisclosurePage() {
    final isAndroid = Platform.isAndroid;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Main Content
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 40,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColorScheme.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.location_on_rounded,
                          size: 40,
                          color: AppColorScheme.primaryColor,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Main Title
                    Text(
                      'Location Access',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColorScheme.deepTeal,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),

                    // Subtitle
                    Text(
                      'To provide the best service experience',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 24),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 18,
                                color: Colors.blue[700],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Location Data Collection',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue[800],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            Platform.isAndroid
                                ? 'Manong collects location data to enable real-time service tracking, including in the background when the app is closed or not in use.'
                                : 'Manong uses location data to find nearby service professionals and enable real-time tracking during active services. Location access depends on the permission you choose.',

                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Key Benefits
                    _buildBenefitCard(
                      icon: Icons.pin_drop_rounded,
                      title: 'Find Nearby Professionals',
                      description: 'See available Manongs in your area',
                    ),

                    const SizedBox(height: 12),

                    _buildBenefitCard(
                      icon: Icons.track_changes_rounded,
                      title: 'Real-Time Tracking',
                      description: 'Track your Manong\'s arrival in real-time',
                    ),

                    const SizedBox(height: 12),

                    _buildBenefitCard(
                      icon: Icons.timer_rounded,
                      title: 'Accurate ETAs',
                      description: 'Get precise arrival time estimates',
                    ),

                    const SizedBox(height: 28),

                    // Privacy Note
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.shield_rounded,
                            size: 20,
                            color: Colors.green[600],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your privacy matters',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '• Location shared only with your assigned Manong\n'
                                  '• Data deleted within 24 hours after service\n'
                                  '• Manage permissions anytime in Settings',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Simple fade effect at bottom to indicate more content
                    Container(
                      height: 60,
                      margin: const EdgeInsets.only(top: 20, bottom: 40),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.white.withOpacity(0),
                            Colors.white.withOpacity(0.3),
                            Colors.white.withOpacity(0.7),
                            Colors.white,
                          ],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.expand_more_rounded,
                          size: 24,
                          color: Colors.grey[400],
                        ),
                      ),
                    ),

                    // Extra space for buttons
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),

            // Fixed Bottom Buttons
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 14,
                  bottom: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Simple scroll hint text
                    Container(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.swipe_up_rounded,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Swipe up for more details',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Accept Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isRequestingLocation
                            ? null
                            : () async {
                                if (_isRequestingLocation) return;

                                setState(() {
                                  _isRequestingLocation = true;
                                });

                                try {
                                  // Save acceptance
                                  _storage.write(
                                    key: 'location_disclosure_accepted',
                                    value: 'true',
                                  );
                                  setState(() {
                                    _userAcceptedLocationDisclosure = true;
                                  });

                                  if (Platform.isAndroid) {
                                    // CRITICAL: ALWAYS reset before showing
                                    _locationDialogShown = false;

                                    await _showLocationPermissionDialog();

                                    // Button will be reset in the dialog logic
                                  } else {
                                    // For iOS, show dialog too (but with iOS-specific options)
                                    _locationDialogShown = false;
                                    await _showLocationPermissionDialog();
                                  }
                                } catch (e) {
                                  // Handle error
                                  if (mounted) {
                                    setState(() {
                                      _isRequestingLocation = false;
                                    });
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isRequestingLocation
                              ? Colors.grey[400]
                              : AppColorScheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isRequestingLocation
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Allow Location Access',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Skip Option
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {
                            _storage.write(
                              key: 'location_disclosure_accepted',
                              value: 'false',
                            );
                            setState(() {
                              _userAcceptedLocationDisclosure = false;
                            });
                            _nextPage();
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          child: Text(
                            'Skip for now',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Privacy Policy Link
                        TextButton(
                          onPressed: () async {
                            await launchUrlScreen(
                              navigatorKey.currentContext!,
                              'https://manongapp.com/index.php/privacy-policy/',
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.privacy_tip_outlined,
                                size: 14,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Privacy',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14), // Reduced from 16
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14), // Slightly reduced
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02), // Reduced opacity
            blurRadius: 8, // Reduced from 12
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44, // Reduced from 48
            height: 44, // Reduced from 48
            decoration: BoxDecoration(
              color: AppColorScheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10), // Reduced from 12
            ),
            child: Center(
              child: Icon(
                icon,
                size: 22, // Reduced from 24
                color: AppColorScheme.primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 14), // Reduced from 16
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15, // Reduced from 16
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 3), // Reduced from 4
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13, // Reduced from 14
                    color: Colors.grey[600],
                    height: 1.3, // Reduced from 1.4
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _nextPage() async {
    if (_currentPage < _instructions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
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
      if (_currentPage == 3 && _userAcceptedLocationDisclosure) {
        await _permissionUtils!.checkLocationPermission();
      }
      if (_currentPage >= 4) {
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
    // Check if already showing or permission already granted
    if (_locationDialogShown || _permissionUtils == null) return;

    // Also check if permission is already granted
    bool granted = await _permissionUtils!.isLocationPermissionGranted();
    if (granted) {
      // Already have permission, skip dialog AND GO TO NEXT PAGE
      _isRequestingLocation = false; // Reset button
      print('DEBUG: Permission already granted, going to next page');
      if (mounted) {
        _nextPage(); // ADD THIS LINE
      }
      return;
    }

    if (mounted) {
      _locationDialogShown = true; // Mark as shown immediately

      await showDialog<void>(
        context: navigatorKey.currentContext!,
        barrierDismissible: false,
        builder: (context) {
          final isAndroid = Platform.isAndroid;

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
                  // Platform-specific icon
                  Icon(
                    isAndroid ? Icons.location_on : Icons.location_on_outlined,
                    size: 60,
                    color: AppColorScheme.primaryColor,
                  ),
                  const SizedBox(height: 20),

                  // Platform-specific title
                  Text(
                    isAndroid
                        ? 'Location Access Required'
                        : 'Allow "Manong" to access your location?',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColorScheme.deepTeal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Platform-specific description
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      isAndroid
                          ? 'Manong collects location data in the background to enable real-time service tracking when the app is closed or not in use.'
                          : 'This allows Manong to show nearby service professionals and enable real-time tracking during service delivery.',
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColorScheme.tealDark,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Platform-specific iOS note
                  if (!isAndroid) ...[
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[100]!),
                      ),
                      child: const Text(
                        'On iOS, you can choose:\n• "Allow While Using App" (recommended)\n• "Allow Once"\n• "Don\'t Allow"',
                        style: TextStyle(fontSize: 13, color: Colors.blue),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // FIXED BOTTOM BUTTONS
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
                                  // CRITICAL: Reset flags when user says "Not Now"
                                  _locationDialogShown = false;
                                  _isRequestingLocation = false;

                                  // GO TO NEXT PAGE even when user says "Not Now"
                                  if (mounted) {
                                    _nextPage();
                                  }
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
                                  isAndroid ? 'Not Now' : 'Don\'t Allow',
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
                                  _locationDialogShown = false;
                                  _isRequestingLocation = false;
                                  await _permissionUtils!
                                      .checkLocationPermission();

                                  // GO TO NEXT PAGE after requesting permission
                                  if (mounted) {
                                    _nextPage();
                                  }
                                },
                                child: Text(
                                  isAndroid ? 'Continue' : 'Allow',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ).then((_) {
        // Always reset flags when dialog closes
        _locationDialogShown = false;
        _isRequestingLocation = false;
      });
    }
  }

  // Reset dialog flags when going back to previous pages
  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });

    // Permission is now requested ON THE DISCLOSURE PAGE ITSELF

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      // Only show notification permission on its page
      if (index == 4 && !_notificationDialogShown) {
        await _showNotificationPermissionDialog();
      }
    });
  }

  Future<void> requestLocationForActiveService() async {
    // STEP 1: Foreground first
    if (await Permission.locationWhenInUse.isDenied) {
      await Permission.locationWhenInUse.request();
      return;
    }

    // STEP 2: Background ONLY when service is active
    if (await Permission.locationAlways.isDenied) {
      await Permission.locationAlways.request();
    }
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_instructions.length, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? AppColorScheme.primaryColor
                : Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildNextButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20), // Reduced
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColorScheme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16), // Reduced
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          onPressed: _nextPage,
          child: Text(
            _currentPage == _instructions.length - 1
                ? "Get Started"
                : "Continue",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  // Privacy policy page
  Widget _buildPrivacyPolicyPage() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.privacy_tip_outlined,
                    size: 32,
                    color: AppColorScheme.primaryColor,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Privacy Policy',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColorScheme.deepTeal,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPrivacySection(
                      title: 'Welcome to Manong',
                      content:
                          'By using our Service, you agree to the collection and use of information in accordance with this Privacy Policy.',
                    ),

                    const SizedBox(height: 24),

                    _buildPrivacySection(
                      title: 'Information We Collect',
                      content:
                          'We collect personal information like your name, contact details, and location data to provide you with better services.',
                    ),

                    const SizedBox(height: 24),

                    _buildPrivacySection(
                      title: 'Location Data',
                      content: 'We collect location data to:',
                      points: [
                        'Find nearby service professionals',
                        'Calculate accurate travel times',
                        'Enable real-time service tracking',
                        'Share your location with assigned Manong during active services',
                      ],
                    ),

                    const SizedBox(height: 24),

                    _buildPrivacySection(
                      title: 'How We Use Your Information',
                      content: 'Your information is used to:',
                      points: [
                        'Connect you with service providers',
                        'Process bookings and payments',
                        'Send service updates and notifications',
                        'Improve our app features',
                      ],
                    ),

                    const SizedBox(height: 24),

                    _buildPrivacySection(
                      title: 'Data Security',
                      content:
                          'We implement security measures to protect your data. Location data is automatically deleted within 24 hours after service completion.',
                    ),

                    const SizedBox(height: 24),

                    _buildPrivacySection(
                      title: 'Your Rights',
                      content:
                          'You can manage location permissions anytime in your device settings.',
                    ),

                    const SizedBox(height: 32),

                    GestureDetector(
                      onTap: () async {
                        await launchUrlScreen(
                          navigatorKey.currentContext!,
                          'https://manongapp.com/index.php/privacy-policy/',
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.open_in_browser,
                              color: Colors.blue,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'View Full Privacy Policy Online',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacySection({
    required String title,
    required String content,
    List<String>? points,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColorScheme.tealDark,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: const TextStyle(
            fontSize: 16,
            height: 1.5,
            color: Colors.black87,
          ),
        ),
        if (title == 'Location Data') const SizedBox(height: 16),
        if (title == 'Location Data')
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.yellow[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange),
            ),
            child: Text(
              Platform.isAndroid
                  ? 'Google Play Prominent Disclosure: "Manong collects location data in the background to enable real-time service tracking when the app is closed or not in use."'
                  : 'iOS Location Disclosure: "Manong uses location data during active services to show nearby professionals and provide real-time tracking, depending on your permission settings."',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.brown,
              ),
            ),
          ),
        if (points != null) ...[
          const SizedBox(height: 12),
          ...points.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.circle,
                    size: 8,
                    color: AppColorScheme.primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      point,
                      style: const TextStyle(fontSize: 15, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _onGalleryPageChanged(int index) {
    setState(() {
      _galleryPage = index;
    });
  }

  Widget _buildGalleryPage() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Column(
                children: [
                  // Header row with centered logo
                  Stack(
                    children: [
                      // Logo centered
                      Center(
                        child: Image.asset(
                          'assets/icon/logo.png',
                          width: 48,
                          height: 48,
                        ),
                      ),
                      // Skip button aligned to the right
                      if (_galleryPage < _galleryItems.length - 1)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _nextPage,
                            child: Text(
                              'Skip',
                              style: TextStyle(
                                color: AppColorScheme.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'How Manong Works',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColorScheme.deepTeal,
                    ),
                  ),
                  Text(
                    'Your trusted home service partner',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            // Gallery with larger images
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: PageView.builder(
                  controller: _galleryController,
                  itemCount: _galleryItems.length,
                  onPageChanged: _onGalleryPageChanged,
                  itemBuilder: (context, index) {
                    final item = _galleryItems[index];
                    final isLastGalleryItem = index == _galleryItems.length - 1;

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        children: [
                          // Feature indicator - compact
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: AppColorScheme.primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    item['title']!,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: AppColorScheme.deepTeal,
                                    ),
                                    maxLines: 2,
                                    textAlign: TextAlign.left,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Image - MAXIMUM SIZE
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  item['image']!,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),

                          // Description with optional "Get Started" button
                          Container(
                            margin: const EdgeInsets.only(top: 12),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Column(
                              children: [
                                Text(
                                  item['description']!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.4,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 3,
                                ),
                                if (isLastGalleryItem) ...[
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            AppColorScheme.primaryColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                          horizontal: 32,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        elevation: 4,
                                      ),
                                      onPressed: _nextPage,
                                      child: const Text(
                                        'Get Started',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            // Compact navigation - Hide on last gallery screen
            if (_galleryPage < _galleryItems.length - 1)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  children: [
                    // Progress dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _galleryItems.length,
                        (dotIndex) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: _galleryPage == dotIndex ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _galleryPage == dotIndex
                                ? AppColorScheme.primaryColor
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Simple instruction
                    Text(
                      'Swipe to continue',
                      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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

                  if (item['type'] == 'location_disclosure') {
                    return _buildLocationDisclosurePage();
                  } else if (item['type'] == 'privacy_policy') {
                    return _buildPrivacyPolicyPage();
                  } else if (item['type'] == 'gallery') {
                    return _buildGalleryPage();
                  } else {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20), // Reduced from 24
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              item['image']!,
                              width: 220, // Reduced from 250
                              height: 220, // Reduced from 250
                            ),
                            const SizedBox(height: 32), // Reduced from 40
                            Text(
                              item['text']!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 18, // Reduced from 20
                                fontWeight: FontWeight.bold,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 24), // Reduced from 40
            _buildPageIndicator(),
            const SizedBox(height: 16), // Reduced from 20
            _buildNextButton(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _galleryController.dispose();
    super.dispose();
  }
}
