enum PaymentStatus { unpaid, pending, paid, failed, refunded }

extension PaymentStatusExtension on PaymentStatus {
  String get value => toString().split('.').last;

  int get indexValue => index;
}
