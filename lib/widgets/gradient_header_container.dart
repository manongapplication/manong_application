import 'package:flutter/material.dart';
import 'package:manong_application/theme/colors.dart';

class GradientHeaderContainer extends StatelessWidget {
  final EdgeInsetsGeometry? padding;
  final MainAxisAlignment? mainAxisAlignment;
  final CrossAxisAlignment? crossAxisAlignment;
  final List<Widget> children;
  final BorderRadiusGeometry? borderRadius;
  final double? height;
  final double? width;

  const GradientHeaderContainer({
    super.key,
    this.padding,
    this.mainAxisAlignment,
    this.crossAxisAlignment,
    this.borderRadius,
    required this.children,
    this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          color: AppColorScheme.backgroundGrey,
          height: double.infinity,
        ),
        Container(
          width: width ?? double.infinity,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColorScheme.primaryColor, Colors.white],
              stops: [0.4, 1],
            ),
            borderRadius: borderRadius ?? BorderRadius.zero,
          ),

          child: SafeArea(
            child: Padding(
              padding: padding ?? EdgeInsets.zero,
              child: Column(
                mainAxisAlignment: mainAxisAlignment ?? MainAxisAlignment.start,
                crossAxisAlignment:
                    crossAxisAlignment ?? CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
