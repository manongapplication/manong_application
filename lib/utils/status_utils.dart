import 'package:manong_application/models/payment_status.dart';
import 'package:manong_application/models/service_request_status.dart';

String getStatusWithManongText(String manongName, String status) {
  String readableStatus;
  switch (status) {
    case 'awaitingAcceptance':
      readableStatus = 'Waiting';
      break;
    case 'accepted':
      readableStatus = 'Accepted';
      break;
    case 'inprogress':
      readableStatus = 'Ongoing';
      break;
    case 'completed':
      readableStatus = 'Completed';
      break;
    case 'failed':
      readableStatus = 'Failed';
      break;
    case 'cancelled':
      readableStatus = 'Cancelled';
      break;
    case 'expired':
      readableStatus = 'Expired';
      break;
    case 'pending':
    default:
      readableStatus = 'Pending';
      break;
  }

  if (manongName.isNotEmpty) {
    final firstName = manongName.split(' ').first;
    return 'Manong $firstName • $readableStatus';
  } else {
    return readableStatus;
  }
}

String getStatusText(String status) {
  String readableStatus;
  switch (status) {
    case 'awaitingAcceptance':
      readableStatus = 'Waiting';
      break;
    case 'accepted':
      readableStatus = 'Accepted';
      break;
    case 'inprogress':
      readableStatus = 'Ongoing';
      break;
    case 'completed':
      readableStatus = 'Completed';
      break;
    case 'failed':
      readableStatus = 'Failed';
      break;
    case 'cancelled':
      readableStatus = 'Cancelled';
      break;
    case 'pending':
    default:
      readableStatus = 'Pending';
      break;
  }

  return readableStatus;
}

final Map<String, List<dynamic>> tabStatuses = {
  'To Pay': [
    PaymentStatus.unpaid,
    PaymentStatus.pending,
    ServiceRequestStatus.pending,
  ],
  'Upcoming': [
    ServiceRequestStatus.awaitingAcceptance,
    ServiceRequestStatus.accepted,
    PaymentStatus.paid,
  ],
  'In Progress': [ServiceRequestStatus.inProgress],
  'Completed': [ServiceRequestStatus.completed],
  'Closed': [ServiceRequestStatus.cancelled, ServiceRequestStatus.expired],
};

int? getTabIndex(dynamic status) {
  for (int i = 0; i < tabStatuses.length; i++) {
    if (tabStatuses.values.elementAt(i).contains(status)) return i;
  }
  return null;
}
