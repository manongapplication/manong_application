import 'dart:async';
import 'dart:collection';
import 'package:manong_application/api/bookmark_item_api_service.dart';
import 'package:manong_application/models/bookmark_item_type.dart';

class BookmarkItemManager {
  static final BookmarkItemManager _instance = BookmarkItemManager._internal();
  factory BookmarkItemManager() => _instance;
  BookmarkItemManager._internal();

  // Use LinkedHashMap for LRU-like behavior
  final LinkedHashMap<String, bool> _cache = LinkedHashMap();

  Future<bool> getBookmarkStatus({
    required int itemId,
    required BookmarkItemType type,
  }) async {
    final cacheKey = '${type.value}_$itemId';

    if (_cache.containsKey(cacheKey)) {
      // Move to end (most recently used)
      final value = _cache.remove(cacheKey);
      _cache[cacheKey] = value!;
      return value;
    }

    try {
      final result = await BookmarkItemApiService().isItemBookmarked(
        itemId: itemId,
        type: type,
      );

      final isBookmarked = result ?? false;

      // Limit cache size to prevent memory issues
      if (_cache.length > 1000) {
        final firstKey = _cache.keys.first;
        _cache.remove(firstKey);
      }

      _cache[cacheKey] = isBookmarked;
      return isBookmarked;
    } catch (e) {
      return false;
    }
  }

  static bool? getCachedStatus(int itemId, BookmarkItemType type) {
    final cacheKey = '${type.value}_$itemId';
    return _instance._cache[cacheKey];
  }

  static void updateCache(
    int itemId,
    BookmarkItemType type,
    bool isBookmarked,
  ) {
    final cacheKey = '${type.value}_$itemId';
    _instance._cache[cacheKey] = isBookmarked;
  }

  void updateBookmarkStatus({
    required int itemId,
    required BookmarkItemType type,
    required bool isBookmarked,
  }) {
    final cacheKey = '${type.value}_$itemId';
    _cache[cacheKey] = isBookmarked;
  }

  void updateMultipleBookmarks(
    Map<int, bool> bookmarks,
    BookmarkItemType type,
  ) {
    bookmarks.forEach((id, isBookmarked) {
      final cacheKey = '${type.value}_$id';
      _cache[cacheKey] = isBookmarked;
    });
  }

  void clearCache({BookmarkItemType? type}) {
    if (type == null) {
      _cache.clear();
    } else {
      final prefix = '${type.value}_';
      _cache.removeWhere((key, _) => key.startsWith(prefix));
    }
  }
}
