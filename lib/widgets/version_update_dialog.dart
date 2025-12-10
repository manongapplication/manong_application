import 'package:flutter/material.dart';
import 'package:manong_application/models/app_service.dart';
import 'package:manong_application/theme/colors.dart';

class VersionUpdateDialog extends StatelessWidget {
  final AppVersion versionInfo;
  final String currentVersion;
  final VoidCallback onUpdatePressed;
  final VoidCallback? onLaterPressed;

  const VersionUpdateDialog({
    super.key,
    required this.versionInfo,
    required this.currentVersion,
    required this.onUpdatePressed,
    this.onLaterPressed,
  });

  bool get isMandatory =>
      versionInfo.isMandatory || versionInfo.forceUpdateRequired;
  bool get isCritical => versionInfo.priority == 'CRITICAL';
  bool get isHigh => versionInfo.priority == 'HIGH';

  Color _getPriorityColor() {
    if (isCritical) return Colors.red;
    if (isHigh) return AppColorScheme.orangeAccent;
    return AppColorScheme.primaryColor;
  }

  IconData _getPriorityIcon() {
    if (isCritical) return Icons.warning;
    if (isHigh) return Icons.priority_high;
    return Icons.system_update;
  }

  String _getPriorityText() {
    if (isCritical) return 'Critical Update';
    if (isHigh) return 'Important Update';
    return 'Update Available';
  }

  @override
  Widget build(BuildContext context) {
    final priorityColor = _getPriorityColor();
    final priorityIcon = _getPriorityIcon();
    final priorityText = _getPriorityText();

    return WillPopScope(
      onWillPop: () async => !isMandatory,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: priorityColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          priorityIcon,
                          color: priorityColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              priorityText,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: priorityColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Version ${versionInfo.latestVersion}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (versionInfo.whatsNew?.isNotEmpty == true) ...[
                        const Text(
                          "What's New",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColorScheme.deepTeal,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          versionInfo.whatsNew!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Version Info
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColorScheme.backgroundGrey,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildInfoRow('Your Version', currentVersion),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              'Latest Version',
                              versionInfo.latestVersion,
                              isHighlighted: true,
                            ),
                            if (versionInfo.minVersion != null) ...[
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                'Minimum Required',
                                versionInfo.minVersion!,
                                isImportant: true,
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Warning for mandatory updates
                      if (isMandatory) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isCritical
                                ? Colors.red.shade50
                                : AppColorScheme.orangeAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isCritical
                                  ? Colors.red.shade200
                                  : AppColorScheme.orangeAccent,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info,
                                color: isCritical
                                    ? Colors.red
                                    : AppColorScheme.orangeAccent,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  isCritical
                                      ? 'Critical security update required'
                                      : 'This update is mandatory for continued use',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isCritical
                                        ? Colors.red.shade700
                                        : AppColorScheme.deepTeal,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Buttons
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: AppColorScheme.backgroundGrey,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (!isMandatory && onLaterPressed != null) ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onLaterPressed,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: Colors.grey),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Later',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onUpdatePressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: priorityColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Update Now',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool isImportant = false,
    bool isHighlighted = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            fontWeight: isImportant ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isImportant
                ? AppColorScheme.orangeAccent
                : isHighlighted
                ? AppColorScheme.primaryColor
                : AppColorScheme.deepTeal,
          ),
        ),
      ],
    );
  }
}
