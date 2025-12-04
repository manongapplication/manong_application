import 'package:manong_application/models/bookmark_item_type.dart';
import 'package:manong_application/models/sub_service_item.dart';
import 'package:manong_application/models/service_item.dart';
import 'package:manong_application/models/manong.dart';

class BookmarkItem {
  final int id;
  final int userId;
  final BookmarkItemType type;
  final int? serviceItemId;
  final int? subServiceItemId;
  final int? manongId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Optional related objects
  final ServiceItem? serviceItem;
  final SubServiceItem? subServiceItem;
  final Manong? manong;

  BookmarkItem({
    required this.id,
    required this.userId,
    required this.type,
    this.serviceItemId,
    this.subServiceItemId,
    this.manongId,
    this.createdAt,
    this.updatedAt,
    this.serviceItem,
    this.subServiceItem,
    this.manong,
  });

  factory BookmarkItem.fromJson(Map<String, dynamic> json) {
    // Parse BookmarkItemType from string using your enum pattern
    BookmarkItemType parseBookmarkType(String typeString) {
      return BookmarkItemType.values.firstWhere(
        (e) => e.toString() == 'BookmarkItemType.$typeString',
        orElse: () =>
            throw ArgumentError('Invalid BookmarkItemType: $typeString'),
      );
    }

    return BookmarkItem(
      id: json['id'],
      userId: json['userId'],
      type: parseBookmarkType(json['type']),
      serviceItemId: json['serviceItemId'],
      subServiceItemId: json['subServiceItemId'],
      manongId: json['manongId'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'].toString())
          : null,
      serviceItem: json['serviceItem'] != null
          ? ServiceItem.fromJson(json['serviceItem'])
          : null,
      subServiceItem: json['subServiceItem'] != null
          ? SubServiceItem.fromJson(json['subServiceItem'])
          : null,
      manong: json['manong'] != null ? Manong.fromJson(json['manong']) : null,
    );
  }

  // Helper getters
  bool get isServiceItem => type == BookmarkItemType.SERVICE_ITEM;
  bool get isSubServiceItem => type == BookmarkItemType.SUB_SERVICE_ITEM;
  bool get isManong => type == BookmarkItemType.MANONG;

  // Get the ID of the bookmarked item based on type
  int? get bookmarkedItemId {
    switch (type) {
      case BookmarkItemType.SERVICE_ITEM:
        return serviceItemId;
      case BookmarkItemType.SUB_SERVICE_ITEM:
        return subServiceItemId;
      case BookmarkItemType.MANONG:
        return manongId;
    }
  }

  // Get the bookmarked object based on type
  dynamic get bookmarkedItem {
    switch (type) {
      case BookmarkItemType.SERVICE_ITEM:
        return serviceItem;
      case BookmarkItemType.SUB_SERVICE_ITEM:
        return subServiceItem;
      case BookmarkItemType.MANONG:
        return manong;
    }
  }

  @override
  String toString() {
    return 'BookmarkItem(id: $id, userId: $userId, type: ${type.value}, bookmarkedItemId: $bookmarkedItemId)';
  }
}
