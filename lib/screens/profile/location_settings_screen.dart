import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:manong_application/utils/permission_utils.dart';
import 'package:manong_application/widgets/card_container_2.dart';
import 'package:manong_application/widgets/my_app_bar.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationSettingsScreen extends StatefulWidget {
  const LocationSettingsScreen({super.key});

  @override
  State<LocationSettingsScreen> createState() => _LocationSettingsScreenState();
}

class _LocationSettingsScreenState extends State<LocationSettingsScreen> {
  final Logger logger = Logger('LocationSettingsScreen');
  late PermissionUtils _permissionUtils;
  bool? _locationOn;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeComponents();
  }

  Future<void> _initializeComponents() async {
    _permissionUtils = PermissionUtils();
    bool isGranted = await _permissionUtils.isLocationPermissionGranted();

    setState(() {
      _locationOn = isGranted;
    });
  }

  Future<void> _toggleLocation(bool value) async {
    logger.info('Location Status $value');

    if (_isLoading) return;

    setState(() {
      _locationOn = value;
      _isLoading = true;
    });

    if (value) {
      // If turning on, check and request permission
      await _permissionUtils.checkLocationPermission();

      // Update state based on actual permission result
      bool actualPermission = await _permissionUtils
          .isLocationPermissionGranted();
      setState(() {
        _locationOn = actualPermission;
        _isLoading = false;
      });

      if (actualPermission) {
        logger.info('Location permission granted');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location permission granted successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        logger.info('Location permission not granted');
        // Show a message to the user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Location permission is required to find nearby services',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } else {
      // If turning off, guide user to app settings
      await openAppSettings();

      // After returning from settings, check the current status
      bool currentPermission = await _permissionUtils
          .isLocationPermissionGranted();
      setState(() {
        _locationOn = currentPermission;
        _isLoading = false;
      });

      if (!currentPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location access has been disabled'),
            backgroundColor: Colors.grey,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _buildSwitchBtn() {
    if (_locationOn == null || _isLoading) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColorScheme.primaryColor,
        ),
      );
    }

    return Switch(
      activeColor: AppColorScheme.primaryColor,
      inactiveTrackColor: AppColorScheme.backgroundGrey,
      value: _locationOn!,
      onChanged: _toggleLocation,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorScheme.backgroundGrey,
      appBar: myAppBar(title: 'Location Settings'),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              CardContainer2(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: AppColorScheme.primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Location Access',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      _buildSwitchBtn(),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              CardContainer2(
                children: [
                  // Privacy Policy text for Location
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

                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.yellow[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: Text(
                      'Location Disclosure: "Manong collects location data to enable real-time service tracking and to show nearby service providers, depending on your permission settings."',
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: Colors.brown,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  _buildPrivacySection(
                    title: 'Data Security',
                    content:
                        'We implement security measures to protect your data. Location data is automatically deleted within 24 hours after service completion.',
                  ),

                  const SizedBox(height: 16),

                  _buildPrivacySection(
                    title: 'Your Rights',
                    content:
                        'You can manage location permissions anytime in your device settings. Location is only used when you actively use location-based features.',
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Location permission allows the app to find nearby service providers and show you relevant services in your area. If location access is off, you can still use the app but you\'ll need to manually enter your location for services.',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                  ),

                  const SizedBox(height: 24),

                  // Third slide image from onboarding
                  Image.asset(
                    'assets/icon/manong_oboarding_find_manong.png',
                    width: 250,
                    height: 250,
                    fit: BoxFit.contain,
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Connect with experienced local professionals',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ],
          ),
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
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColorScheme.deepTeal,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
        ),
        if (points != null) ...[
          const SizedBox(height: 8),
          ...points.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 6, left: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.circle,
                    size: 6,
                    color: AppColorScheme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      point,
                      style: TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
      ],
    );
  }
}
