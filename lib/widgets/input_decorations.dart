import 'package:flutter/material.dart';
import 'package:manong_application/theme/colors.dart';

InputDecoration inputDecoration(
  String hint, {
  Widget? suffixIcon,
  Widget? prefixIcon,
  String? labelText,
  TextStyle? labelStyle,
  FloatingLabelBehavior? floatingLabelBehavior,
  EdgeInsetsGeometry? contentPadding,
}) {
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    contentPadding:
        contentPadding ??
        const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColorScheme.primaryColor, width: 2),
    ),
    suffixIcon: suffixIcon,
    prefixIcon: prefixIcon,
    labelText: labelText,
    labelStyle: labelStyle ?? TextStyle(color: AppColorScheme.primaryDark),
    floatingLabelBehavior: floatingLabelBehavior,
  );
}
