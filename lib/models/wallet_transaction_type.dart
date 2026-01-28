enum WalletTransactionType { topup, job_fee, payout, adjustment, refund }

extension WalletTransactionTypeExtension on WalletTransactionType {
  String get value => toString().split('.').last;

  int get indexValue => index;
}
