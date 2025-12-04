// ignore: constant_identifier_names
enum BookmarkItemType { SERVICE_ITEM, SUB_SERVICE_ITEM, MANONG }

extension BookmarkItemTypeExtension on BookmarkItemType {
  String get value => toString().split('.').last;

  int get indexValue => index;
}
