enum ServiceRequestStatus {
  awaitingAcceptance,
  accepted,
  inProgress,
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

ServiceRequestStatus? parseRequestStatus(String? value) {
  if (value == null) return null;
  switch (value.toLowerCase()) {
    case 'awaitingAcceptance':
      return ServiceRequestStatus.awaitingAcceptance;
    case 'accepted':
      return ServiceRequestStatus.accepted;
    case 'inProgress':
      return ServiceRequestStatus.inProgress;
    case 'completed':
      return ServiceRequestStatus.completed;
    case 'failed':
      return ServiceRequestStatus.failed;
    case 'cancelled':
      return ServiceRequestStatus.cancelled;
    case 'pending':
      return ServiceRequestStatus.pending;
    case 'expired':
      return ServiceRequestStatus.expired;
    default:
      return null;
  }
}

StatusUpdateMessage getStatusUpdate(ServiceRequestStatus status) {
  switch (status) {
    case ServiceRequestStatus.awaitingAcceptance:
      return const StatusUpdateMessage(
        'Waiting',
        'Your request is waiting for a manong to accept.',
      );
    case ServiceRequestStatus.accepted:
      return const StatusUpdateMessage(
        'Accepted',
        'A manong has accepted your request!',
      );
    case ServiceRequestStatus.inProgress:
      return const StatusUpdateMessage(
        'Ongoing',
        'Your service is now in progress.',
      );
    case ServiceRequestStatus.completed:
      return const StatusUpdateMessage(
        'Completed',
        'The service has been completed successfully.',
      );
    case ServiceRequestStatus.failed:
      return const StatusUpdateMessage(
        'Failed',
        'Unfortunately, the service has failed. Please try again.',
      );
    case ServiceRequestStatus.cancelled:
      return const StatusUpdateMessage(
        'Cancelled',
        'Your request has been cancelled.',
      );
    case ServiceRequestStatus.pending:
      return const StatusUpdateMessage(
        'Pending',
        'Your request is pending and will be processed soon.',
      );
    case ServiceRequestStatus.expired:
      return const StatusUpdateMessage(
        'Expired',
        'Your request has now expired.',
      );
  }
}

extension RequestStatusExtension on ServiceRequestStatus {
  String get value => toString().split('.').last;

  String get readable {
    switch (this) {
      case ServiceRequestStatus.awaitingAcceptance:
        return 'Waiting';
      case ServiceRequestStatus.accepted:
        return 'Accepted';
      case ServiceRequestStatus.inProgress:
        return 'Ongoing';
      case ServiceRequestStatus.completed:
        return 'Completed';
      case ServiceRequestStatus.failed:
        return 'Failed';
      case ServiceRequestStatus.cancelled:
        return 'Cancelled';
      case ServiceRequestStatus.pending:
        return 'Pending';
      case ServiceRequestStatus.expired:
        return 'Expired';
    }
  }

  static ServiceRequestStatus? fromString(String status) {
    try {
      return ServiceRequestStatus.values.firstWhere(
        (e) => e.value == status.toLowerCase(),
      );
    } catch (_) {
      return null; // fallback if unknown
    }
  }
}
