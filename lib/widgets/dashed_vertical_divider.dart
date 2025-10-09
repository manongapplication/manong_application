import 'package:flutter/material.dart';

class DashedVerticalDivider extends StatelessWidget {
  final double height;
  final double dashHeight;
  final double width;
  final Color color;

  const DashedVerticalDivider({
    super.key,
    this.height = 50, // default height
    this.dashHeight = 6,
    this.width = 1,
    this.color = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dashCount = (constraints.maxHeight / (2 * dashHeight)).floor();
          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(dashCount, (_) {
              return SizedBox(
                width: width,
                height: dashHeight,
                child: DecoratedBox(decoration: BoxDecoration(color: color)),
              );
            }),
          );
        },
      ),
    );
  }
}
