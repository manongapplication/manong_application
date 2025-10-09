import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:manong_application/main.dart';
import 'package:manong_application/screens/main_screen.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:manong_application/utils/onboarding_storage.dart';
import 'package:manong_application/utils/permission_utils.dart';
import 'package:manong_application/widgets/modal_icon_overlay.dart';
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
    if (_permissionUtils != null) {
      bool granted = await _permissionUtils!.isNotificationPermissionGranted();
      if (!granted && mounted) {
        showDialog(
          context: navigatorKey.currentContext!,
          builder: (context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ModalIconOverlay(
                onPressed: () async {
                  await _permissionUtils!.checkNotificationPermission();
                  if (mounted) Navigator.of(navigatorKey.currentContext!).pop();
                },
                icons: Icons.notifications_active,
                description:
                    'We’d like to send you notifications about updates, reminders, and important alerts.',
              ),
            );
          },
        );
      }
    }
  }

  Future<void> _showLocationPermissionDialog() async {
    if (_permissionUtils != null) {
      bool granted = await _permissionUtils!.isLocationPermissionGranted();
      if (!granted && mounted) {
        showDialog(
          context: navigatorKey.currentContext!,
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
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });

                  if (index == 1) {
                    _showLocationPermissionDialog();
                  } else if (index == 2) {
                    _showNotificationPermissionDialog();
                  }
                },
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
