import 'package:flutter/material.dart';

class DashedDivider extends StatelessWidget {
  final double height;
  final double dashWidth;
  final double dashSpace;
  final Color color;

  const DashedDivider({
    super.key,
    this.height = 1,
    this.dashWidth = 6,
    this.dashSpace = 4, // Space between dashes
    this.color = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 100.0;

        // Calculate how many complete dash+space pairs we can fit
        final dashUnit = dashWidth + dashSpace;
        final dashCount = (availableWidth / dashUnit).floor();

        // If we can't fit at least one dash, show nothing
        if (dashCount <= 0 || availableWidth < dashWidth) {
          return SizedBox(height: height);
        }

        return SizedBox(
          height: height,
          width: availableWidth,
          child: Row(
            children: List.generate(dashCount * 2 - 1, (index) {
              // Even indices are dashes, odd indices are spaces
              if (index.isEven) {
                return Container(
                  width: dashWidth,
                  height: height,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(height / 2),
                  ),
                );
              } else {
                return SizedBox(width: dashSpace);
              }
            }),
          ),
        );
      },
    );
  }
}

// Alternative implementation using CustomPainter for better performance
class DashedDividerPainter extends StatelessWidget {
  final double height;
  final double dashWidth;
  final double dashSpace;
  final Color color;

  const DashedDividerPainter({
    super.key,
    this.height = 1,
    this.dashWidth = 6,
    this.dashSpace = 4,
    this.color = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _DashedLinePainter(
          color: color,
          dashWidth: dashWidth,
          dashSpace: dashSpace,
          strokeWidth: height,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  final double dashWidth;
  final double dashSpace;
  final double strokeWidth;

  _DashedLinePainter({
    required this.color,
    required this.dashWidth,
    required this.dashSpace,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    double startX = 0;
    final y = size.height / 2;

    while (startX < size.width) {
      final endX = (startX + dashWidth).clamp(0.0, size.width);

      if (endX > startX) {
        canvas.drawLine(Offset(startX, y), Offset(endX, y), paint);
      }

      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
