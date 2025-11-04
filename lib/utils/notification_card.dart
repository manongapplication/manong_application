import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:manong_application/main.dart';
import 'package:manong_application/models/service_request_status.dart';
import 'package:manong_application/models/user_notification.dart';
import 'package:manong_application/utils/color_utils.dart';

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
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: getStatusColor(status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: getStatusBorderColor(status), width: 1),
            ),
            child: Text(
              parseRequestStatus(status)?.readable ?? '',
              style: TextStyle(color: getStatusBorderColor(status)),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: notificationItem.seenAt == null
          ? const Color.fromARGB(255, 240, 240, 240)
          : Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notificationItem.title,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(notificationItem.body),
              if (notificationItem.data != null) ...[
                const SizedBox(height: 8),
                _buildData(notificationItem.data!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
