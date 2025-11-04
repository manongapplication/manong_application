enum AccountStatus { pending, onHold, verified, rejected, suspended }

extension AccountStatusExtension on AccountStatus {
  String get value => toString().split('.').last;

  int get indexValue => index;
}
