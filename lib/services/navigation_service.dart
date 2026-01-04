import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

class NavigationService {
  static final Logger _logger = Logger('NavigationService');
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static Map<String, dynamic>? _pendingNotificationData;
  static bool _isInitialized = false;

  static void init() {
    _isInitialized = true;
    _executePendingNavigation();
  }

  static void handleNotificationTap(
    Map<String, dynamic> data, {
    bool isInitial = false,
  }) {
    _logger.info('👆 handleNotificationTap called with isInitial: $isInitial');

    if (isInitial) {
      _pendingNotificationData = data;
      _logger.info('📱 Stored pending notification data: $data');
      return;
    }

    // If app is already running, navigate immediately
    _navigateFromNotification(data);
  }

  static void _executePendingNavigation() {
    if (_pendingNotificationData != null && _isInitialized) {
      _logger.info('🚀 Executing pending notification navigation');

      // Wait for navigator to be ready
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (_pendingNotificationData != null &&
            navigatorKey.currentState != null) {
          _logger.info(
            '🎯 Navigating with pending data: $_pendingNotificationData',
          );
          _navigateFromNotification(_pendingNotificationData!);
          _pendingNotificationData = null;
        }
      });
    }
  }

  static void _navigateFromNotification(Map<String, dynamic> data) {
    _logger.info('🧭 Navigating from notification: $data');

    if (data['serviceRequestId'] != null) {
      navigatorKey.currentState?.pushNamed(
        '/service-request-details',
        arguments: {
          'serviceRequestId': int.tryParse(data['serviceRequestId'].toString()),
        },
      );
    } else if (data['type'] == 'chat') {
      if (data['serviceRequestIdForChat'] != null) {
        navigatorKey.currentState?.pushNamed(
          '/service-request-details',
          arguments: {
            'serviceRequestId': int.tryParse(
              data['serviceRequestIdForChat'].toString(),
            ),
            'goToChat': true,
          },
        );
      }
    }
  }

  static void clearPendingNavigation() {
    _pendingNotificationData = null;
  }
}
