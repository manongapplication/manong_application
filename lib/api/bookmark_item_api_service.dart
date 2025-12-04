import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/api/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:manong_application/models/bookmark_item.dart';
import 'package:manong_application/models/bookmark_item_type.dart';

class BookmarkItemApiService {
  final Logger logger = Logger('BookmarkItemApiService');
  final baseUrl = dotenv.env['APP_URL_API'];

  Future<Map<String, dynamic>?> addBookmarkSubServiceItem(
    int subServiceItemId,
  ) async {
    try {
      final token = await AuthService().getNodeToken();

      final response = await http.post(
        Uri.parse('$baseUrl/bookmark-item'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'subServiceItemId': subServiceItemId,
          'type': 'SUB_SERVICE_ITEM',
        }),
      );

      final responseBody = response.body;
      final jsonData = jsonDecode(responseBody);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonData;
      } else {
        logger.warning(
          'Failed to add bookmark sub service item: ${response.statusCode} $responseBody',
        );
        return jsonData;
      }
    } catch (e, stacktrace) {
      logger.severe('Error bookmarking sub service item', e, stacktrace);
    }

    return null;
  }

  Future<Map<String, dynamic>?> removeBookmarkSubServiceItem(
    int subServiceItemId,
  ) async {
    try {
      final token = await AuthService().getNodeToken();

      final response = await http.post(
        Uri.parse('$baseUrl/bookmark-item/remove'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'subServiceItemId': subServiceItemId,
          'type': 'SUB_SERVICE_ITEM',
        }),
      );

      final responseBody = response.body;
      final jsonData = jsonDecode(responseBody);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonData;
      } else {
        logger.warning(
          'Failed to add bookmark sub service item: ${response.statusCode} $responseBody',
        );
        return jsonData;
      }
    } catch (e, stacktrace) {
      logger.severe('Error bookmarking sub service item', e, stacktrace);
    }

    return null;
  }

  Future<bool?> isSubServiceItemBookmarked(int subServiceItemId) async {
    try {
      final token = await AuthService().getNodeToken();

      final response = await http.post(
        Uri.parse('$baseUrl/bookmark-item/is-bookmarked'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'subServiceItemId': subServiceItemId,
          'type': 'SUB_SERVICE_ITEM',
        }),
      );

      final responseBody = response.body;
      final jsonData = jsonDecode(responseBody);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonData['data'];
      } else {
        logger.warning(
          'Failed to check bookmark status: ${response.statusCode} $responseBody',
        );
        return null;
      }
    } catch (e, stacktrace) {
      logger.severe('Error checking bookmark status', e, stacktrace);
    }

    return null;
  }

  // Fetch all bookmarked sub-service items for the current user
  Future<List<BookmarkItem>?> fetchBookmarkSubServiceItems() async {
    try {
      final token = await AuthService().getNodeToken();

      final response = await http.get(
        Uri.parse('$baseUrl/bookmark-item/sub-service-item'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseBody = response.body;
      final jsonData = jsonDecode(responseBody);

      if (response.statusCode == 200) {
        if (jsonData['success'] == true && jsonData['data'] != null) {
          final List<dynamic> dataList = jsonData['data'];
          return dataList.map((item) => BookmarkItem.fromJson(item)).toList();
        } else {
          logger.warning('No data returned for bookmarked sub-service items');
          return [];
        }
      } else {
        logger.warning(
          'Failed to fetch bookmarked sub-service items: ${response.statusCode} $responseBody',
        );
        return null;
      }
    } catch (e, stacktrace) {
      logger.severe(
        'Error fetching bookmarked sub-service items',
        e,
        stacktrace,
      );
      return null;
    }
  }

  // Generic methods for all bookmark types

  Future<Map<String, dynamic>?> addBookmark({
    required int itemId,
    required BookmarkItemType type,
  }) async {
    try {
      final token = await AuthService().getNodeToken();

      final body = <String, dynamic>{'type': type.value};

      // Add the appropriate ID based on type
      switch (type) {
        case BookmarkItemType.SERVICE_ITEM:
          body['serviceItemId'] = itemId;
          break;
        case BookmarkItemType.SUB_SERVICE_ITEM:
          body['subServiceItemId'] = itemId;
          break;
        case BookmarkItemType.MANONG:
          body['manongId'] = itemId;
          break;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/bookmark-item'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      final responseBody = response.body;
      final jsonData = jsonDecode(responseBody);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonData;
      } else {
        logger.warning(
          'Failed to add bookmark: ${response.statusCode} $responseBody',
        );
        return jsonData;
      }
    } catch (e, stacktrace) {
      logger.severe('Error adding bookmark', e, stacktrace);
    }

    return null;
  }

  Future<Map<String, dynamic>?> removeBookmark({
    required int itemId,
    required BookmarkItemType type,
  }) async {
    try {
      final token = await AuthService().getNodeToken();

      final body = <String, dynamic>{'type': type.value};

      // Add the appropriate ID based on type
      switch (type) {
        case BookmarkItemType.SERVICE_ITEM:
          body['serviceItemId'] = itemId;
          break;
        case BookmarkItemType.SUB_SERVICE_ITEM:
          body['subServiceItemId'] = itemId;
          break;
        case BookmarkItemType.MANONG:
          body['manongId'] = itemId;
          break;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/bookmark-item/remove'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      final responseBody = response.body;
      final jsonData = jsonDecode(responseBody);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonData;
      } else {
        logger.warning(
          'Failed to remove bookmark: ${response.statusCode} $responseBody',
        );
        return jsonData;
      }
    } catch (e, stacktrace) {
      logger.severe('Error removing bookmark', e, stacktrace);
    }

    return null;
  }

  Future<bool?> isItemBookmarked({
    required int itemId,
    required BookmarkItemType type,
  }) async {
    try {
      final token = await AuthService().getNodeToken();

      final body = <String, dynamic>{'type': type.value};

      // Add the appropriate ID based on type
      switch (type) {
        case BookmarkItemType.SERVICE_ITEM:
          body['serviceItemId'] = itemId;
          break;
        case BookmarkItemType.SUB_SERVICE_ITEM:
          body['subServiceItemId'] = itemId;
          break;
        case BookmarkItemType.MANONG:
          body['manongId'] = itemId;
          break;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/bookmark-item/is-bookmarked'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      final responseBody = response.body;
      final jsonData = jsonDecode(responseBody);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonData['data'];
      } else {
        logger.warning(
          'Failed to check bookmark status: ${response.statusCode} $responseBody',
        );
        return null;
      }
    } catch (e, stacktrace) {
      logger.severe('Error checking bookmark status', e, stacktrace);
    }

    return null;
  }
}
