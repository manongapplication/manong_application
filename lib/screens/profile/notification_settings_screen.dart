import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:manong_application/utils/permission_utils.dart';
import 'package:manong_application/widgets/card_container_2.dart';
import 'package:manong_application/widgets/my_app_bar.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<StatefulWidget> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<StatefulWidget> {
  final Logger logger = Logger('NotificationScreen');
  late PermissionUtils _permissionUtils;
  bool? _notificationOn;

  @override
  void initState() {
    super.initState();
    _initializeComponents();
  }

  Future<void> _initializeComponents() async {
    _permissionUtils = PermissionUtils();
    bool isGranted = await _permissionUtils.isNotificationPermissionGranted();

    setState(() {
      _notificationOn = isGranted;
    });
  }

  Future<void> _toggleNotification(bool value) async {
    logger.info('Notification Status $value');
    
    setState(() {
      _notificationOn = value;
    });

    if (value) {
      // If turning on, check and request permission
      await _permissionUtils.checkNotificationPermission();
      
      // Update state based on actual permission result
      bool actualPermission = await _permissionUtils.isNotificationPermissionGranted();
      setState(() {
        _notificationOn = actualPermission;
      });
      
      if (actualPermission) {
        logger.info('Notification permission granted');
      } else {
        logger.info('Notification permission not granted');
        // Show a message to the user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notification permission is required to receive alerts'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } else {
      // If turning off, guide user to app settings
      await openAppSettings();
      
      // After returning from settings, check the current status
      bool currentPermission = await _permissionUtils.isNotificationPermissionGranted();
      setState(() {
        _notificationOn = currentPermission;
      });
    }
  }

  Widget _buildSwitchBtn() {
    if (_notificationOn == null) {
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
      value: _notificationOn!,
      onChanged: _toggleNotification,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorScheme.backgroundGrey,
      appBar: myAppBar(title: 'Notification Settings'),
      body: Padding(
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
                          Icons.notifications,
                          color: AppColorScheme.primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Notification',
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
                const Text(
                  'Notification permission lets the app send you alerts and updates. You can turn notifications on or off here. If notifications are off, you may not receive reminders about service requests or important updates.',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                ),
                const SizedBox(height: 8),
                Image.asset(
                  'assets/icon/manong_oboarding_notification_manong.png',
                  width: 250,
                  height: 250,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}