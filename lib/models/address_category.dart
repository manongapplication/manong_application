enum AddressCategory { residential, appartment, condominium, commercial }

extension AddressCategoryExtension on AddressCategory {
  String get value => toString().split('.').last;

  int get indexValue => index;
}
