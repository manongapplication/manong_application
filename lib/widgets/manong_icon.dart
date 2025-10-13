import 'package:flutter/material.dart';

Widget manongIcon({
  double size = 90,
  BoxFit fit = BoxFit.cover,
  EdgeInsetsGeometry padding = const EdgeInsets.all(8),
}) {
  return Padding(
    padding: padding,
    child: ClipOval(
      child: Image.asset(
        'assets/icon/logo.png',
        width: size,
        height: size,
        fit: fit,
      ),
    ),
  );
}
