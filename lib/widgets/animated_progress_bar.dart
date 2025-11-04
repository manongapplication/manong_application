import 'package:flutter/material.dart';
import 'package:manong_application/theme/colors.dart';

/// Animated stacked progress bar widget
///
/// Usage example:
/// ```dart
/// AnimatedStackProgressBar(
///   percent: 0.7, // 70%
///   height: 24,
///   duration: Duration(milliseconds: 800),
/// )
/// ```
///
/// This widget shows a layered progress bar with a smooth fill animation
/// and a stacked percentage badge on top.
class AnimatedStackProgressBar extends StatefulWidget {
  final double percent; // 0.0 - 1.0
  final double height;
  final Duration duration;
  final BorderRadiusGeometry borderRadius;
  final Color backgroundColor;
  final Color trackColor;
  final Color fillColor;
  final TextStyle? percentTextStyle;
  final bool showPercentageBadge;

  const AnimatedStackProgressBar({
    super.key,
    required this.percent,
    this.height = 20,
    this.duration = const Duration(milliseconds: 600),
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.backgroundColor = const Color(0xFFECEFF1),
    this.trackColor = AppColorScheme.primaryLight,
    this.fillColor = AppColorScheme.primaryColor,
    this.percentTextStyle,
    this.showPercentageBadge = true,
  }) : assert(
         percent >= 0 && percent <= 1,
         'percent must be between 0.0 and 1.0',
       );

  @override
  State<AnimatedStackProgressBar> createState() =>
      _AnimatedStackProgressBarState();
}

class _AnimatedStackProgressBarState extends State<AnimatedStackProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _animation;
  double _oldPercent = 0.0;

  @override
  void initState() {
    super.initState();
    _oldPercent = widget.percent;
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _animation = Tween<double>(
      begin: 0.0,
      end: widget.percent,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedStackProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.percent != widget.percent) {
      _oldPercent = oldWidget.percent;
      _animation = Tween<double>(
        begin: _oldPercent,
        end: widget.percent,
      ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
      _ctrl
        ..duration = widget.duration
        ..forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final percentTextStyle =
        widget.percentTextStyle ??
        const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        return SizedBox(
          height: widget.height + 14, // extra space for badge
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Background track
              Positioned.fill(
                top: 7,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.backgroundColor,
                    borderRadius: widget.borderRadius,
                  ),
                ),
              ),

              // Secondary track (slightly inset to create stacked look)
              Positioned(
                left: 6,
                right: 6,
                top: 9,
                bottom: 2,
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.trackColor.withOpacity(0.25),
                    borderRadius: widget.borderRadius,
                  ),
                ),
              ),

              // Animated primary fill
              Positioned(
                left: 6,
                top: 9,
                bottom: 2,
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    final fillWidth =
                        (width - 12).clamp(0.0, double.infinity) *
                        (_animation.value.clamp(0.0, 1.0));

                    return Container(
                      width: fillWidth,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            widget.fillColor.withOpacity(0.8),
                            widget.fillColor.withOpacity(0.9),
                          ],
                        ),
                        borderRadius: widget.borderRadius,
                        boxShadow: [
                          BoxShadow(
                            color: widget.fillColor.withOpacity(0.25),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: widget.borderRadius,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: 1.0,
                            child: Container(),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Centered label: show text over the bar (adaptive color)
              Positioned.fill(
                top: 9,
                bottom: 2,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      // Decide text color depending on fill coverage.
                      final isOnFill = _animation.value >= 0.5;
                      final textColor = isOnFill
                          ? Colors.white
                          : Colors.black87;
                      return Text(
                        '${(_animation.value * 100).round()}% Complete',
                        style: percentTextStyle.copyWith(color: textColor),
                      );
                    },
                  ),
                ),
              ),

              // Percentage badge stacked on top-right of the bar
              // if (widget.showPercentageBadge)
              //   Positioned(
              //     right: 0,
              //     top: 0,
              //     child: AnimatedBuilder(
              //       animation: _animation,
              //       builder: (context, child) {
              //         final percent = (_animation.value * 100).round();
              //         return Container(
              //           padding: const EdgeInsets.symmetric(
              //             horizontal: 10,
              //             vertical: 6,
              //           ),
              //           decoration: BoxDecoration(
              //             color: Colors.white,
              //             borderRadius: BorderRadius.circular(20),
              //             boxShadow: [
              //               BoxShadow(
              //                 color: Colors.black12,
              //                 blurRadius: 6,
              //                 offset: Offset(0, 2),
              //               ),
              //             ],
              //           ),
              //           child: Row(
              //             mainAxisSize: MainAxisSize.min,
              //             children: [
              //               Text(
              //                 '$percent%',
              //                 style: TextStyle(
              //                   fontWeight: FontWeight.bold,
              //                   color: widget.fillColor,
              //                 ),
              //               ),
              //               const SizedBox(width: 6),
              //               Icon(
              //                 Icons.check_circle,
              //                 size: 16,
              //                 color: widget.fillColor,
              //               ),
              //             ],
              //           ),
              //         );
              //       },
              //     ),
              //   ),
            ],
          ),
        );
      },
    );
  }
}
