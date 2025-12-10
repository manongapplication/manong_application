import 'package:flutter/material.dart';
import 'package:manong_application/theme/colors.dart';

PreferredSizeWidget myAppBar({
  required String title,
  String? subtitle,
  double? fontSize = 22,
  double? subtitleFontSize = 14,
  Widget? leading,
  Widget? trailing,
  VoidCallback? onBackPressed,
}) {
  return PreferredSize(
    preferredSize: subtitle != null
        ? const Size.fromHeight(
            kToolbarHeight + 20,
          ) // Increased height for subtitle
        : const Size.fromHeight(kToolbarHeight + 4),
    child: AppBar(
      iconTheme: const IconThemeData(color: Colors.white),
      leading: onBackPressed != null
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: onBackPressed,
            )
          : null,
      title: Row(
        children: [
          if (leading != null) ...[leading, const SizedBox(width: 8)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: subtitleFontSize,
                      fontWeight: FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      backgroundColor: AppColorScheme.primaryColor,
      actions: trailing != null
          ? [
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Row(children: [trailing]),
              ),
            ]
          : null,
    ),
  );
}
