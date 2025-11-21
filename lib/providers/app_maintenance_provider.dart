import 'package:flutter/material.dart';
import 'package:manong_application/api/app_maintenance_api_service.dart';
import 'package:manong_application/models/app_maintenance.dart';

class AppMaintenanceProvider extends ChangeNotifier {
  bool isMaintenance = false;
  AppMaintenance? appMaintenance;

  bool get hasMaintenance => isMaintenance && appMaintenance != null;

  Future<void> fetchMaintenance() async {
    try {
      final response = await AppMaintenanceApiService().fetchAppMaintenance();
      if (response != null && response['data'] != null) {
        final data = AppMaintenance.fromJson(response['data']);
        isMaintenance = data.isActive;
        appMaintenance = data;
      } else {
        isMaintenance = false;
        appMaintenance = null;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching maintenance: $e');
    }
  }
}
