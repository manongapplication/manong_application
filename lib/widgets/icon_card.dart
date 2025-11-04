import 'package:flutter/material.dart';
import 'package:iconify_design/iconify_design.dart';

Widget iconCard({
  required Color iconColor,
  required String iconName,
  required Color iconTextColor,
  double? size,
}) {
  return Container(
    width: size ?? 48,
    height: size ?? 48,
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: iconColor,
      borderRadius: BorderRadius.circular(12),
    ),
    child: IconifyIcon(icon: iconName, size: 24, color: iconTextColor),
  );
}
