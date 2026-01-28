enum WalletTransactionStatus { pending, completed, failed }

extension WalletTransactionStatusExtension on WalletTransactionStatus {
  String get value => toString().split('.').last;

  int get indexValue => index;
}
