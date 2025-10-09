import 'package:flutter/material.dart';
import 'package:manong_application/theme/colors.dart';

class SearchInput extends StatelessWidget {
  final TextEditingController controller;
  final Function(String)? onChanged;

  const SearchInput({super.key, required this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: AppColorScheme.primaryColor,
          selectionHandleColor: AppColorScheme.primaryColor,
        ),
      ),
      child: TextField(
        cursorColor: AppColorScheme.primaryColor,
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.search),
          hintText: 'Search...',
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 0,
            horizontal: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
