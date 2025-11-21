import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:manong_application/main.dart';
import 'package:manong_application/models/app_maintenance.dart';
import 'package:manong_application/providers/app_maintenance_provider.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:provider/provider.dart';

class AppMaintenanceScreen extends StatelessWidget {
  final AppMaintenance appMaintenance;
  final VoidCallback? onRefresh;
  const AppMaintenanceScreen({
    super.key,
    required this.appMaintenance,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final dateTimeFormat = DateFormat('MMM d, yyyy h:mm a');
    final provider = context.read<AppMaintenanceProvider>();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo with maintenance icon overlay
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Image.asset(
                        'assets/icon/logo.png',
                        width: 180,
                        height: 180,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Icon(
                        Icons.build,
                        size: 100,
                        color: AppColorScheme.primaryColor.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Maintenance period
                if (appMaintenance.startTime != null &&
                    appMaintenance.endTime != null)
                  Text(
                    '${dateTimeFormat.format(appMaintenance.startTime!)} - ${dateTimeFormat.format(appMaintenance.endTime!)}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                const SizedBox(height: 24),

                // Message
                Text(
                  appMaintenance.message ?? 'The app is under maintenance.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 32),

                ElevatedButton.icon(
                  onPressed: () async {
                    await provider.fetchMaintenance();

                    if (!provider.hasMaintenance) {
                      Navigator.of(
                        navigatorKey.currentContext!,
                      ).pushReplacementNamed('/');
                    }
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Check Again'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: AppColorScheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
