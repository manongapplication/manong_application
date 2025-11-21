import "package:flutter/material.dart";
import "package:manong_application/theme/colors.dart";
import "package:manong_application/widgets/search_input.dart";

class AppBarSearch extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final Function()? onBackTap;
  final TextEditingController controller;
  final Function(String) onChanged;
  final Widget? trailing;

  const AppBarSearch({
    super.key,
    required this.title,
    this.onBackTap,
    required this.controller,
    required this.onChanged,
    this.trailing,
  });

  @override
  State<AppBarSearch> createState() => _AppBarSearchState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 4);
}

class _AppBarSearchState extends State<AppBarSearch> {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColorScheme.primaryColor,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (widget.onBackTap != null) ...[
            GestureDetector(
              onTap: widget.onBackTap,
              child: Icon(
                Icons.arrow_back_ios_new_sharp,
                color: Colors.white,
                size: 20,
              ),
            ),
            SizedBox(width: 18),
          ],

          Expanded(
            child: SizedBox(
              height: 36,
              child: SearchInput(
                controller: widget.controller,
                onChanged: widget.onChanged,
              ),
            ),
          ),
          SizedBox(width: 18),
          if (widget.trailing != null) ...[widget.trailing!],
        ],
      ),
    );
  }
}
