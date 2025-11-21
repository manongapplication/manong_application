import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:manong_application/main.dart';
import 'package:manong_application/providers/app_maintenance_provider.dart';
import 'package:manong_application/screens/app_maintenance_screen.dart';
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
    final box = GetStorage();
    const cacheKey = 'cached_service_items';
    const cacheTimestampKey = 'cache_timestamp';

    try {
      // Always try to fetch fresh data first
      final url = Uri.parse('${dotenv.env['APP_URL_API']}/service-items');

      logger.info('Fetching fresh data from API...');

      final response = await http.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        logger.info('Successfully fetched fresh data');

        // Parse the response
        final jsonBody = json.decode(response.body);
        final items = parseToJsonServiceItems(json.encode(jsonBody['data']));

        // Cache the new data
        await box.write(cacheKey, json.encode(jsonBody['data']));
        await box.write(
          cacheTimestampKey,
          DateTime.now().millisecondsSinceEpoch,
        );

        return items;
      } else if (response.statusCode == 403) {
        logger.warning('Received 403: Unauthorized. Refreshing app...');
        // Clear cached user/session data if needed
        await box.erase();

        final maintenanceProvider = AppMaintenanceProvider();
        await maintenanceProvider.fetchMaintenance();

        if (navigatorKey.currentState != null) {
          navigatorKey.currentState!.pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => AppMaintenanceScreen(
                appMaintenance: maintenanceProvider.appMaintenance!,
                onRefresh: () async {
                  await maintenanceProvider.fetchMaintenance();
                },
              ),
            ),
            (route) => false,
          );
        }
        // Throw to stop further processing
        throw HttpException('HTTP 403: Unauthorized. App refreshed.');
      } else {
        throw HttpException(
          'HTTP ${response.statusCode}: Failed to load services',
        );
      }
    } catch (e) {
      // Network error - fall back to cache
      logger.warning('Network fetch failed: $e');

      final cachedData = box.read(cacheKey);

      if (cachedData != null && cachedData.trim().isNotEmpty) {
        logger.info('Using cached data (offline mode)');
        return parseToJsonServiceItems(cachedData);
      }

      // No cache available
      logger.severe('No cached data available');
      throw Exception('No internet connection and no cached data available');
    }
  }

  // Keep these methods for backward compatibility if needed elsewhere
  Future<List<ServiceItem>> fetchServiceItemsNetworkFirst() async {
    return fetchServiceItems();
  }

  Future<List<ServiceItem>> fetchServiceItemsCacheFirst() async {
    return fetchServiceItems();
  }
}
