enum RequestStatus {
  awaitingAcceptance,
  accepted,
  inprogress,
  completed,
  failed,
  cancelled,
  pending,
  expired,
}

class StatusUpdateMessage {
  final String title;
  final String body;

  const StatusUpdateMessage(this.title, this.body);
}

RequestStatus? parseRequestStatus(String? value) {
  if (value == null) return null;
  switch (value.toLowerCase()) {
    case 'awaitingAcceptance':
      return RequestStatus.awaitingAcceptance;
    case 'accepted':
      return RequestStatus.accepted;
    case 'inprogress':
      return RequestStatus.inprogress;
    case 'completed':
      return RequestStatus.completed;
    case 'failed':
      return RequestStatus.failed;
    case 'cancelled':
      return RequestStatus.cancelled;
    case 'pending':
      return RequestStatus.pending;
    case 'expired':
      return RequestStatus.expired;
    default:
      return null;
  }
}

StatusUpdateMessage getStatusUpdate(RequestStatus status) {
  switch (status) {
    case RequestStatus.awaitingAcceptance:
      return const StatusUpdateMessage(
        'Waiting',
        'Your request is waiting for a manong to accept.',
      );
    case RequestStatus.accepted:
      return const StatusUpdateMessage(
        'Accepted',
        'A manong has accepted your request!',
      );
    case RequestStatus.inprogress:
      return const StatusUpdateMessage(
        'Ongoing',
        'Your service is now in progress.',
      );
    case RequestStatus.completed:
      return const StatusUpdateMessage(
        'Completed',
        'The service has been completed successfully.',
      );
    case RequestStatus.failed:
      return const StatusUpdateMessage(
        'Failed',
        'Unfortunately, the service has failed. Please try again.',
      );
    case RequestStatus.cancelled:
      return const StatusUpdateMessage(
        'Cancelled',
        'Your request has been cancelled.',
      );
    case RequestStatus.pending:
      return const StatusUpdateMessage(
        'Pending',
        'Your request is pending and will be processed soon.',
      );
    case RequestStatus.expired:
      return const StatusUpdateMessage(
        'Expired',
        'Your request has now expired.',
      );
  }
}

extension RequestStatusExtension on RequestStatus {
  String get value => toString().split('.').last;

  String get readable {
    switch (this) {
      case RequestStatus.awaitingAcceptance:
        return 'Waiting';
      case RequestStatus.accepted:
        return 'Accepted';
      case RequestStatus.inprogress:
        return 'Ongoing';
      case RequestStatus.completed:
        return 'Completed';
      case RequestStatus.failed:
        return 'Failed';
      case RequestStatus.cancelled:
        return 'Cancelled';
      case RequestStatus.pending:
        return 'Pending';
      case RequestStatus.expired:
        return 'Expired';
    }
  }

  static RequestStatus? fromString(String status) {
    try {
      return RequestStatus.values.firstWhere(
        (e) => e.value == status.toLowerCase(),
      );
    } catch (_) {
      return null; // fallback if unknown
    }
  }
}
