enum TransactionType { payment, refund, adjustment }

extension TransactionTypeExtension on TransactionType {
  String get value => toString().split('.').last;

  int get indexValue => index;
}
