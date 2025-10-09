import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:manong_application/api/fcm_api_service.dart';
import 'package:manong_application/models/request_status.dart';

class NotificationUtils {
  static final Logger logger = Logger('NotificationUtils');
  static final FcmApiService _fcmApiService = FcmApiService();

  static Future<void> sendStatusUpdateNotification({
    required RequestStatus status,
    required String token,
    String? serviceRequestId,
    required int userId,
  }) async {
    try {
      final statusUpdate = getStatusUpdate(status);
      final response = await _fcmApiService.sendNotification(
        title: statusUpdate.title,
        body: statusUpdate.body,
        fcmToken: token,
        json: {'serviceRequestId': serviceRequestId, 'status': status.value},
        userId: userId,
      );

      logger.info('sendNotifcation: ${jsonEncode(response)}');
    } catch (e) {
      logger.severe('Error sending status update notification ${e.toString()}');
      rethrow;
    }
  }
}
