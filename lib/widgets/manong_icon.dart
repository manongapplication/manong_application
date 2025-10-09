import 'package:flutter/material.dart';

Widget manongIcon ({
  double size = 90,
  BoxFit fit = BoxFit.contain,
  EdgeInsetsGeometry padding = const EdgeInsets.all(8)
}) {
  return Image.asset(
      'assets/icon/logo.png',
      width: size,
      height: size,
      fit: fit,
  );
}