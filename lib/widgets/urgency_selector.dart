import 'package:flutter/material.dart';
import 'package:manong_application/models/urgency_level.dart';
import 'package:manong_application/theme/colors.dart';

class UrgencySelector extends StatelessWidget {
  final List<UrgencyLevel> levels;
  final int activeIndex;
  final Function(int) onSelected;

  const UrgencySelector({
    super.key,
    required this.levels,
    required this.activeIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 12,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: levels.asMap().entries.map((entry) {
        final index = entry.key;
        UrgencyLevel level = entry.value;

        return Material(
          color: activeIndex == index
              ? AppColorScheme.primaryLight
              : Colors.white60,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => onSelected(index),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                border: activeIndex == index
                    ? Border.all(color: AppColorScheme.primaryDark, width: 3)
                    : Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        level.level,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        level.time,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),

                  Text(
                    level.price != null
                        ? '₱ ${level.price!.toStringAsFixed(2)}'
                        : '',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
