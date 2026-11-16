import 'package:daily/utils/app_theme.dart';
import 'package:flutter/material.dart';

class WeekLifeCalendarGrid extends StatelessWidget {
  const WeekLifeCalendarGrid({
    super.key,
    required this.totalWeeks,
    required this.currentWeekIndex,
    required this.selectedWeekIndex,
    required this.onWeekTap,
    required this.targetAge,
  });

  final int totalWeeks;
  final int currentWeekIndex;
  final int? selectedWeekIndex;
  final int targetAge;

  final ValueChanged<int> onWeekTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const columns = 52;
        const spacing = 2.0;

        final cellWidth =
            (constraints.maxWidth - spacing * (columns - 1)) /
                columns;

        final rows = (totalWeeks / columns).ceil();

        final cellHeight = constraints.maxHeight / rows;

        final cellSize = cellWidth < cellHeight
            ? cellWidth
            : cellHeight;

        return Center(
          child: SizedBox(
            width: columns * cellSize +
                (columns - 1) * spacing,
            height: rows * cellSize +
                (rows - 1) * spacing,
            child: GridView.builder(
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: totalWeeks,
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
              ),
              itemBuilder: (context, index) {
                final isCurrent = index == currentWeekIndex;
                final isPast = index < currentWeekIndex;
                final isSelected = index == selectedWeekIndex;

                return RepaintBoundary(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onWeekTap(index),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? Colors.grey.shade700
                            : isPast
                            ? AppColors.primary.withValues(
                          alpha: 0.65,
                        )
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(
                          color: isSelected || isCurrent
                              ? AppColors.secondary
                              : Colors.transparent,
                          width: isSelected ? 1.2 : 0.7,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}