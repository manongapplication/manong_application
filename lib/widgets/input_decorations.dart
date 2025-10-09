import 'package:flutter/material.dart';
import 'package:manong_application/theme/colors.dart';

InputDecoration inputDecoration(
  String hint, {
  Widget? suffixIcon,
  String? labelText,
  TextStyle? labelStyle,
  FloatingLabelBehavior? floatingLabelBehavior,
}) {
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
    labelText: labelText,
    labelStyle: labelStyle,
    floatingLabelBehavior: floatingLabelBehavior,
  );
}
