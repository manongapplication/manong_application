import 'package:flutter/material.dart';
import 'package:manong_application/theme/colors.dart';

PreferredSizeWidget myAppBar({
  required String title,
  double? fontSize = 22,
  Widget? leading,
  Widget? trailing,
  VoidCallback? onBackPressed,
}) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(kToolbarHeight + 4),
    child: AppBar(
      iconTheme: IconThemeData(color: Colors.white),
      leading: onBackPressed != null
          ? IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: onBackPressed,
            )
          : null,
      title: leading != null
          ? Row(
              children: [
                leading,
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(color: Colors.white, fontSize: fontSize),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            )
          : Text(
              title,
              style: TextStyle(color: Colors.white, fontSize: fontSize),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
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
