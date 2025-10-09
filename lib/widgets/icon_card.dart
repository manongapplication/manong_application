import 'package:flutter/material.dart';
import 'package:manong_application/utils/icon_mapper.dart';

Widget iconCard({
  required Color iconColor,
  required String iconName,
  double? size,
}) {
  return Container(
    width: size ?? 48,
    height: size ?? 48,
    decoration: BoxDecoration(
      color: iconColor,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(getIconFromName(iconName), color: Colors.white, size: 24),
  );
}
