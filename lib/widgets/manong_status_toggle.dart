// widgets/manong_status_toggle.dart
import 'package:flutter/material.dart';
import 'package:manong_application/api/manong_api_service.dart';
import 'package:manong_application/models/manong_status.dart';
import 'package:manong_application/utils/snackbar_utils.dart';

enum ToggleStyle { compact, expanded }

class ManongStatusToggle extends StatelessWidget {
  final ManongStatus status;
  final ValueChanged<ManongStatus>? onStatusChanged;
  final ToggleStyle style;
  final bool isLoading;

  const ManongStatusToggle({
    super.key,
    required this.status,
    this.onStatusChanged,
    this.style = ToggleStyle.compact,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case ToggleStyle.compact:
        return _buildCompactToggle(context);
      case ToggleStyle.expanded:
        return _buildExpandedToggle(context);
    }
  }

  Widget _buildCompactToggle(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : () => _showStatusSelection(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _getStatusColor(status),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_getStatusIcon(status), size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              _getStatusText(status),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            if (!isLoading)
              const Icon(Icons.arrow_drop_down, size: 16, color: Colors.white),
            if (isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedToggle(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            'Status:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: isLoading ? null : () => _showStatusSelection(context),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _getStatusText(status),
                  style: TextStyle(
                    color: _getStatusColor(status),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                if (!isLoading) const Icon(Icons.arrow_drop_down, size: 18),
                if (isLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ManongStatus status) {
    switch (status) {
      case ManongStatus.available:
        return Colors.green;
      case ManongStatus.busy:
        return Colors.orange;
      case ManongStatus.offline:
        return Colors.grey;
      case ManongStatus.inactive:
        return Colors.blueGrey;
      case ManongStatus.suspended:
        return Colors.red;
      case ManongStatus.deleted:
        return Colors.black;
    }
  }

  IconData _getStatusIcon(ManongStatus status) {
    switch (status) {
      case ManongStatus.available:
        return Icons.person;
      case ManongStatus.busy:
        return Icons.person_off;
      case ManongStatus.offline:
        return Icons.wifi_off;
      case ManongStatus.inactive:
        return Icons.pause_circle;
      case ManongStatus.suspended:
        return Icons.block;
      case ManongStatus.deleted:
        return Icons.delete;
    }
  }

  String _getStatusText(ManongStatus status) {
    return status.value[0].toUpperCase() + status.value.substring(1);
  }

  void _showStatusSelection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Set Availability',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ..._getAvailableStatuses().map((optionStatus) {
                  return ListTile(
                    leading: Icon(_getStatusIconForOption(optionStatus)),
                    title: Text(
                      _getStatusTextForOption(optionStatus),
                      style: TextStyle(
                        color: _getStatusColorForOption(optionStatus),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: status == optionStatus
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                    onTap: () async {
                      Navigator.pop(context);
                      await _updateStatus(context, optionStatus);
                    },
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  List<ManongStatus> _getAvailableStatuses() {
    // Manongs can only set these statuses themselves
    return [
      ManongStatus.available,
      ManongStatus.busy,
      ManongStatus.offline,
      ManongStatus.inactive,
    ];
  }

  IconData _getStatusIconForOption(ManongStatus status) {
    switch (status) {
      case ManongStatus.available:
        return Icons.person;
      case ManongStatus.busy:
        return Icons.person_off;
      case ManongStatus.offline:
        return Icons.wifi_off;
      case ManongStatus.inactive:
        return Icons.pause_circle;
      default:
        return Icons.person;
    }
  }

  String _getStatusTextForOption(ManongStatus status) {
    switch (status) {
      case ManongStatus.available:
        return 'Available - Ready for new requests';
      case ManongStatus.busy:
        return 'Busy - Currently on a job';
      case ManongStatus.offline:
        return 'Offline - Not taking requests';
      case ManongStatus.inactive:
        return 'Inactive - Taking a break';
      default:
        return status.value;
    }
  }

  Color _getStatusColorForOption(ManongStatus status) {
    switch (status) {
      case ManongStatus.available:
        return Colors.green;
      case ManongStatus.busy:
        return Colors.orange;
      case ManongStatus.offline:
        return Colors.grey;
      case ManongStatus.inactive:
        return Colors.blueGrey;
      default:
        return Colors.black;
    }
  }

  Future<void> _updateStatus(
    BuildContext context,
    ManongStatus newStatus,
  ) async {
    if (onStatusChanged == null) return;

    try {
      // Call API to update status
      final response = await ManongApiService().updateManongStatus(
        newStatus.value,
      );

      if (response?['success'] == true) {
        // Notify parent widget of the status change
        onStatusChanged?.call(newStatus);

        SnackBarUtils.showSuccess(
          context,
          'Status updated to ${_getStatusText(newStatus)}',
        );
      } else {
        SnackBarUtils.showError(
          context,
          response?['message'] ?? 'Failed to update status',
        );
      }
    } catch (e) {
      SnackBarUtils.showError(context, 'Failed to update status');
    }
  }
}
