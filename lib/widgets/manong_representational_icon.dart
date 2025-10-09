import 'package:flutter/material.dart';

Widget manongRepresentationalIcon ({
  double size = 130,
  BoxFit fit = BoxFit.contain,
  EdgeInsetsGeometry padding = const EdgeInsets.all(12)
}) {
  return Image.asset(
      'assets/icon/manong_representational_logo.png',
      width: size,
      height: size,
      fit: fit,
  );
}