import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import '../models/service_item.dart';

class ServiceItemApiService {
  final Logger logger = Logger('ServiceItemApiService');

  List<ServiceItem> parseToJsonServiceItems(String data) {
    final decoded = json.decode(data);

    final List<dynamic> jsonData = decoded is Map<String, dynamic>
        ? decoded['data']
        : decoded;

    return jsonData.map((item) => ServiceItem.fromJson(item)).toList();
  }

  Future<List<ServiceItem>> fetchServiceItems() async {
    // Use cache-first approach by default
    return fetchServiceItemsCacheFirst();
  }

  Future<List<ServiceItem>> fetchServiceItemsNetworkFirst() async {
    final box = GetStorage();
    const cacheKey = 'cached_service_items';
    const cacheTimestampKey = 'cache_timestamp';
    const cacheValidityDuration = Duration(hours: 1); // Adjust as needed

    // Check if we have valid cached data
    String? cachedData = box.read(cacheKey);
    int? cacheTimestamp = box.read(cacheTimestampKey);

    bool hasCachedData = cachedData != null;
    bool isCacheValid =
        hasCachedData &&
        cacheTimestamp != null &&
        DateTime.now().millisecondsSinceEpoch - cacheTimestamp <
            cacheValidityDuration.inMilliseconds;

    // If cache is valid, return it immediately
    if (isCacheValid) {
      logger.info('Using valid cached data');
      return parseToJsonServiceItems(cachedData);
    }

    try {
      final baseUrl = Uri.parse('${dotenv.env['APP_URL_API']}/service-items');

      // Set a reasonable timeout (3-5 seconds)
      final response = await http
          .get(baseUrl)
          .timeout(
            const Duration(seconds: 4),
            onTimeout: () {
              throw SocketException('Request timeout');
            },
          );

      if (response.statusCode == 200) {
        logger.info('Fetched fresh data from API');

        // Cache the new data with timestamp
        await box.write(cacheKey, response.body);
        await box.write(
          cacheTimestampKey,
          DateTime.now().millisecondsSinceEpoch,
        );

        return parseToJsonServiceItems(response.body);
      } else {
        throw HttpException(
          'HTTP ${response.statusCode}: Failed to load services',
        );
      }
    } catch (e) {
      logger.severe('Error fetching from API: $e');

      // Fall back to cached data if available (even if expired)
      if (hasCachedData) {
        logger.info('Using cached data as fallback');
        return parseToJsonServiceItems(cachedData);
      }

      // No cache available, throw error
      throw Exception('No internet connection and no cached data available');
    }
  }

  // Alternative approach: Cache-first with background refresh
  Future<List<ServiceItem>> fetchServiceItemsCacheFirst() async {
    final box = GetStorage();
    const cacheKey = 'cached_service_items';
    const cacheTimestampKey = 'cache_timestamp';
    const cacheValidityDuration = Duration(minutes: 30);

    String? cachedData = box.read(cacheKey);
    int? cacheTimestamp = box.read(cacheTimestampKey);

    // If we have cached data, return it immediately
    if (cachedData != null) {
      List<ServiceItem> cachedItems = parseToJsonServiceItems(cachedData);

      // Check if cache needs refresh
      bool needsRefresh =
          cacheTimestamp == null ||
          DateTime.now().millisecondsSinceEpoch - cacheTimestamp >
              cacheValidityDuration.inMilliseconds;

      if (needsRefresh) {
        // Refresh in background (fire and forget)
        _refreshCacheInBackground();
      }

      return cachedItems;
    }

    // No cached data, must fetch from network
    return _fetchFromNetwork();
  }

  Future<void> _refreshCacheInBackground() async {
    try {
      final box = GetStorage();
      final response = await http
          .get(Uri.parse('${dotenv.env['APP_URL_API']}/service-items'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        await box.write('cached_service_items', response.body);
        await box.write(
          'cache_timestamp',
          DateTime.now().millisecondsSinceEpoch,
        );
        logger.info('Cache refreshed in background');
      }
    } catch (e) {
      logger.severe('Background cache refresh failed: $e');
    }
  }

  Future<List<ServiceItem>> _fetchFromNetwork() async {
    final box = GetStorage();

    try {
      final response = await http
          .get(Uri.parse('${dotenv.env['APP_URL_API']}/service-items'))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        await box.write('cached_service_items', response.body);
        await box.write(
          'cache_timestamp',
          DateTime.now().millisecondsSinceEpoch,
        );

        return parseToJsonServiceItems(response.body);
      } else {
        throw HttpException(
          'HTTP ${response.statusCode}: Failed to load services',
        );
      }
    } catch (e) {
      throw Exception('Failed to fetch data: $e');
    }
  }
}
