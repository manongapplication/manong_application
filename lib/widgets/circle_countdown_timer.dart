import 'package:flutter/material.dart';
import 'dart:async';

import 'package:manong_application/theme/colors.dart';

class CircleCountdownTimer extends StatefulWidget {
  final Duration duration;
  final double size;
  final Color progressColor;
  final Color backgroundColor;
  final double strokeWidth;
  final TextStyle? textStyle;
  final VoidCallback? onComplete;

  const CircleCountdownTimer({
    super.key,
    required this.duration,
    this.size = 200.0,
    this.progressColor = AppColorScheme.primaryColor,
    this.backgroundColor = Colors.grey,
    this.strokeWidth = 8.0,
    this.textStyle,
    this.onComplete,
  });

  @override
  State<CircleCountdownTimer> createState() => _CircleCountdownTimerState();
}

class _CircleCountdownTimerState extends State<CircleCountdownTimer>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  late Timer _timer;
  late Duration _remainingTime;

  @override
  void initState() {
    super.initState();
    _remainingTime = widget.duration;

    _animationController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.linear),
    );

    _startTimer();
  }

  void _startTimer() {
    _animationController.forward();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingTime = Duration(seconds: _remainingTime.inSeconds - 1);

        if (_remainingTime.inSeconds <= 0) {
          _timer.cancel();
          _animationController.stop();
          widget.onComplete?.call();
        }
      });
    });
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    int totalSeconds = duration.inSeconds;

    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    } else if (duration.inMinutes > 0) {
      return "$twoDigitMinutes:$twoDigitSeconds";
    } else {
      // For seconds only, show single digit if <= 9
      return totalSeconds <= 9
          ? totalSeconds.toString()
          : totalSeconds.toString();
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: widget.strokeWidth,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(widget.backgroundColor),
            ),
          ),
          // Animated progress circle
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return SizedBox(
                width: widget.size,
                height: widget.size,
                child: CircularProgressIndicator(
                  value: _animation.value,
                  strokeWidth: widget.strokeWidth,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.progressColor,
                  ),
                ),
              );
            },
          ),
          // Time text in center
          Text(
            _formatTime(_remainingTime),
            style:
                widget.textStyle ??
                TextStyle(
                  fontSize: widget.size * 0.15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
          ),
        ],
      ),
    );
  }
}
