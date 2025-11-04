enum ServiceItemStatus { active, inactive, comingSoon, archived, deleted }

extension ServiceItemStatusExtension on ServiceItemStatus {
  String get value => toString().split('.').last;

  int get indexValue => index;
}
