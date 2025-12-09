enum ManongStatus { available, busy, offline, inactive, suspended, deleted }

extension ManongStatusExtension on ManongStatus {
  String get value => toString().split('.').last;

  int get indexValue => index;
}
