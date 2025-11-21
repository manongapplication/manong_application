import 'package:logging/logging.dart';
import 'package:manong_application/api/refund_request_api_service.dart';
import 'package:manong_application/models/refund_request.dart';
import 'package:manong_application/models/service_request.dart';

class RefundUtils {
  final Logger logger = Logger('RefundUtils');

  Future<List<RefundRequest>?> fetchRequests(
    ServiceRequest serviceRequest,
  ) async {
    try {
      final response = await RefundRequestApiService()
          .fetchRefundRequestsByServiceRequestId(serviceRequest);

      if (response != null) {
        return response;
      } else {
        logger.warning('Failed fetching refund requests');
      }
    } catch (e) {
      logger.severe('Error fetching refund requests ${e.toString()}');
    }

    return null;
  }

  Future<Map<String, dynamic>?> create(
    ServiceRequest serviceRequest,
    String reason,
  ) async {
    try {
      final response = await RefundRequestApiService().createRefundRequest(
        serviceRequest,
        reason,
      );

      if (response != null) {
        return response;
      }
    } catch (e) {
      logger.severe('Error creating refund request ${e.toString()}');
    }

    return null;
  }
}
