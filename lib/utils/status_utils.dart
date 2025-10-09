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

const Map<String, List<String>> tabStatuses = {
  'To Pay': ['unpaid', 'pending'],
  'Upcoming': ['accepted', 'paid', 'awaitingAcceptance'],
  'In Progress': ['inprogress'],
  'Completed': ['completed'],
  'Closed': ['cancelled', 'expired'],
};

int? getTabIndex(String status) {
  final entries = tabStatuses.entries.toList();

  for (int i = 0; i < entries.length; i++) {
    if (entries[i].value.contains(status)) {
      return i;
    }
  }
  return null;
}
