import 'package:flutter/material.dart';

class CardContainer2 extends StatelessWidget {
  final List<Widget>? children;
  final Decoration? decoration;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final MainAxisAlignment? mainAxisAlignment;
  const CardContainer2({
    super.key,
    this.children,
    this.decoration,
    this.margin,
    this.padding,
    this.mainAxisAlignment,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.only(top: 24),
      padding: padding ?? const EdgeInsets.all(24),
      decoration:
          decoration ??
          BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
      child: Column(
        mainAxisAlignment: mainAxisAlignment ?? MainAxisAlignment.start,
        children: children ?? [],
      ),
    );
  }
}
