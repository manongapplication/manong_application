enum ValidIdType { selfie, id }

extension ValidIdTypeExtension on ValidIdType {
  String get value => toString().split('.').last;

  int get indexValue => index;
}
