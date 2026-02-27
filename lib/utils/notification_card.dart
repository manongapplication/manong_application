import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:manong_application/main.dart';
import 'package:manong_application/models/service_request_status.dart';
import 'package:manong_application/models/user_notification.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:manong_application/utils/color_utils.dart';
import 'package:intl/intl.dart';

class NotificationCard extends StatelessWidget {
  final UserNotification notificationItem;
  final VoidCallback? onTap;
  const NotificationCard({
    super.key,
    required this.notificationItem,
    this.onTap,
  });

  Widget _buildData(String data) {
    final jsonData = jsonDecode(data);
    final String? status = jsonData['status'];

    return Row(
      children: [
        if (status != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: getStatusColor(status).withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: getStatusColor(status).withOpacity(0.2),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getStatusIcon(status),
                  size: 12,
                  color: getStatusColor(status),
                ),
                const SizedBox(width: 4),
                Text(
                  parseRequestStatus(status)?.readable ?? '',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: getStatusColor(status),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle_rounded;
      case 'inprogress':
        return Icons.autorenew_rounded;
      case 'pending':
        return Icons.hourglass_empty_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      case 'accepted':
        return Icons.check_circle_outline_rounded;
      case 'refunding':
        return Icons.undo_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours < 1) {
        if (difference.inMinutes < 1) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isUnread = notificationItem.seenAt == null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isUnread
            ? AppColorScheme.primaryColor.withOpacity(0.02)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUnread
              ? AppColorScheme.primaryColor.withOpacity(0.2)
              : Colors.grey.shade200,
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left icon with gradient background
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        isUnread
                            ? AppColorScheme.primaryColor
                            : Colors.grey.shade400,
                        isUnread
                            ? AppColorScheme.primaryColor.withOpacity(0.8)
                            : Colors.grey.shade300,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getStatusIcon(
                      notificationItem.data != null
                          ? jsonDecode(notificationItem.data!)['status'] ?? ''
                          : '',
                    ),
                    color: Colors.white,
                    size: 22,
                  ),
                ),

                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title with unread indicator
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notificationItem.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isUnread
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: isUnread
                                    ? AppColorScheme.primaryDark
                                    : Colors.grey.shade800,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppColorScheme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // Body
                      Text(
                        notificationItem.body,
                        style: TextStyle(
                          fontSize: 13,
                          color: isUnread
                              ? Colors.grey.shade800
                              : Colors.grey.shade600,
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Status chip
                      if (notificationItem.data != null) ...[
                        const SizedBox(height: 8),
                        _buildData(notificationItem.data!),
                      ],
                    ],
                  ),
                ),

                // Timestamp
                const SizedBox(width: 8),
                Text(
                  _formatDate(notificationItem.createdAt!),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w400,
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
