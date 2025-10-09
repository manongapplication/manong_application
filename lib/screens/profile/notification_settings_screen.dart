import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:manong_application/utils/permission_utils.dart';
import 'package:manong_application/widgets/card_container_2.dart';
import 'package:manong_application/widgets/my_app_bar.dart';

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
    await _permissionUtils.isNotificationPermissionGranted();
    final isGranted = _permissionUtils.locationPermissionGranted;

    setState(() {
      _notificationOn = isGranted;
    });
  }

  Widget _buildSwitchBtn() {
    if (_notificationOn == null) return SizedBox.shrink();
    return Switch(
      activeColor: AppColorScheme.primaryColor,
      inactiveTrackColor: AppColorScheme.backgroundGrey,
      value: _notificationOn!,
      onChanged: (value) {
        logger.info('Notification Status $value');
        setState(() {
          _notificationOn = value;
        });
        _permissionUtils.setLocationPermissionGranted(value);
      },
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
