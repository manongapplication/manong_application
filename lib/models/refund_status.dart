enum RefundStatus {
  pending,
  approved,
  rejected,
  failed,
  requiresAction,
  processed,
}

extension RefundStatusExtension on RefundStatus {
  String get value => toString().split('.').last;

  int get indexValue => index;
}
