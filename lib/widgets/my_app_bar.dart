import 'package:flutter/material.dart';
import 'package:manong_application/theme/colors.dart';

PreferredSizeWidget myAppBar({
  required String title,
  double? fontSize = 22,
  Widget? leading,
  Widget? trailing,
}) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(kToolbarHeight + 4),
    child: AppBar(
      iconTheme: IconThemeData(color: Colors.white),
      title: leading != null
          ? Row(
              children: [
                leading,
                const SizedBox(width: 8),
                Text(title, style: TextStyle(color: Colors.white)),
              ],
            )
          : Text(
              title,
              style: TextStyle(color: Colors.white, fontSize: fontSize),
            ),
      backgroundColor: AppColorScheme.primaryColor,
      actions: trailing != null
          ? [
              Padding(
                padding: EdgeInsets.only(right: 20),
                child: Row(children: [trailing]),
              ),
            ]
          : null,
    ),
  );
}
