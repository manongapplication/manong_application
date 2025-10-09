import 'package:flutter/material.dart';
import 'package:manong_application/theme/colors.dart';

class StepIndicator extends StatelessWidget {
  final int totalSteps;
  final int currentStep;
  final Color activeColor;
  final Color selectedColor;
  final Color inactiveColor;
  final List<String>? stepLabels;
  final EdgeInsetsGeometry padding;

  const StepIndicator({
    super.key,
    required this.totalSteps,
    required this.currentStep,
    this.activeColor = AppColorScheme.deepTeal,
    this.selectedColor = AppColorScheme.primaryDark,
    this.inactiveColor = Colors.transparent,
    this.stepLabels,
    this.padding = const EdgeInsets.all(0),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: padding,
      child: Row(
        children: List.generate(totalSteps, (index) {
          final stepIndex = index ~/ 2;
          final isCompleted = stepIndex < currentStep;
          final isActive = index < currentStep;

          return Expanded(
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 4,
                      margin: EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: isActive ? activeColor : inactiveColor,
                      ),
                    ),

                    Container(
                      padding: EdgeInsets.zero,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: activeColor,
                      ),

                      child: isActive && currentStep - 1 != index
                          ? Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                Icons.check,
                                size: 24,
                                color: Colors.white,
                              ),
                            )
                          : currentStep - 1 == index
                          ? Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: selectedColor,
                                  width: 2,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                (index + 1).toString(),
                                style: TextStyle(color: Colors.white),
                              ),
                            )
                          : Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                (index + 1).toString(),
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                    ),
                  ],
                ),

                if (stepLabels != null && index < stepLabels!.length) ...[
                  const SizedBox(height: 2),
                  Text(
                    stepLabels![index],
                    style: TextStyle(fontSize: 12, color: Colors.black),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }
}
