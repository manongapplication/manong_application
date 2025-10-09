import 'package:flutter/material.dart';
import 'package:manong_application/theme/colors.dart';

class SelectableItemWidget extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool? selected;

  const SelectableItemWidget({
    super.key,
    required this.title,
    this.icon,
    this.trailing,
    this.onTap,
    this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (icon != null)
                CircleAvatar(
                  backgroundColor: AppColorScheme.primaryLight,
                  foregroundColor: AppColorScheme.primaryColor,
                  child: Icon(icon, size: 18),
                ),
              SizedBox(width: 12),
              Expanded(child: Text(title, style: TextStyle(fontSize: 16))),
              if (trailing != null) ...[trailing!],
              if (selected == true)
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColorScheme.primaryColor,
                  ),
                  child: Icon(Icons.circle, color: Colors.white, size: 8),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
