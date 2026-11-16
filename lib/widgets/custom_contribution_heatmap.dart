import 'package:daily/cubits/heatmap/heatmap_state.dart';
import 'package:daily/utils/app_theme.dart';
import 'package:daily/utils/date_utils.dart';
import 'package:flutter/material.dart';

class CustomContributionHeatmap extends StatefulWidget {
  final Map<DateTime, HeatmapDayData> dayDataMap;
  final DateTime minDate;
  final DateTime maxDate;
  final DateTime today;
  final void Function(DateTime date)? onCellTap;

  const CustomContributionHeatmap({
    super.key,
    required this.dayDataMap,
    required this.minDate,
    required this.maxDate,
    required this.today,
    this.onCellTap,
  });

  @override
  State<CustomContributionHeatmap> createState() => _CustomContributionHeatmapState();
}

class _CustomContributionHeatmapState extends State<CustomContributionHeatmap> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToToday());
  }

  @override
  void didUpdateWidget(covariant CustomContributionHeatmap oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToToday());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToToday() {
    if (!_scrollController.hasClients) return;
    final startDate = AppDateUtils.normalizeDate(widget.minDate);
    final alignedStart = startDate.subtract(Duration(days: startDate.weekday - 1));
    final todayNorm = AppDateUtils.normalizeDate(widget.today);
    final daysDiff = todayNorm.difference(alignedStart).inDays;
    final weekIndex = daysDiff ~/ 7;
    const colWidth = 20.0; // cellWidth (16) + spacing (4)
    final targetOffset = (weekIndex * colWidth) - 150;
    _scrollController.jumpTo(targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent));
  }

  String _getMonthName(int month) {
    const months = ['Янв', 'Фев', 'Мар', 'Апр', 'Май', 'Июн', 'Июл', 'Авг', 'Сен', 'Окт', 'Ноя', 'Дек'];
    return months[(month - 1).clamp(0, 11)];
  }

  @override
  Widget build(BuildContext context) {
    const double cellSize = 16.0;
    const double cellSpacing = 4.0;
    const double colWidth = cellSize + cellSpacing;

    final startDate = AppDateUtils.normalizeDate(widget.minDate);
    final alignedStart = startDate.subtract(Duration(days: startDate.weekday - 1));
    final endDate = AppDateUtils.normalizeDate(widget.maxDate);

    final List<List<DateTime?>> weeks = [];
    DateTime current = alignedStart;

    while (!current.isAfter(endDate) || weeks.length * 7 < (endDate.difference(alignedStart).inDays + 7)) {
      final List<DateTime?> week = [];
      for (int i = 0; i < 7; i++) {
        week.add(current);
        current = current.add(const Duration(days: 1));
      }
      weeks.add(week);
      if (current.isAfter(endDate) && weeks.length * 7 >= endDate.difference(alignedStart).inDays + 7) {
        break;
      }
    }

    int? lastMonth;
    int? lastYear;

    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: weeks.map((week) {
          final firstDay = week.firstWhere((d) => d != null, orElse: () => null);
          String headerLabel = '';
          bool isYearLabel = false;
          if (firstDay != null) {
            if (firstDay.month == 1) {
              if (lastYear == null || firstDay.year != lastYear) {
                headerLabel = '${firstDay.year}';
                lastYear = firstDay.year;
                lastMonth = 1;
                isYearLabel = true;
              }
            } else {
              if (lastMonth == null || firstDay.month != lastMonth) {
                lastMonth = firstDay.month;
                headerLabel = _getMonthName(firstDay.month);
                if (lastYear == null || firstDay.year != lastYear) {
                  headerLabel = '${firstDay.year}';
                  lastYear = firstDay.year;
                  lastMonth = 1;
                  isYearLabel = true;
                }
              }
            }
          }

          return Container(
            width: colWidth,
            margin: const EdgeInsets.only(right: cellSpacing),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Single-line header label (Year for January, Month for Feb-Dec)
                SizedBox(
                  height: 16,
                  child: Text(
                    headerLabel,
                    style: TextStyle(
                      fontSize: isYearLabel ? 10 : 9,
                      fontWeight: isYearLabel ? FontWeight.bold : FontWeight.normal,
                      color: isYearLabel ? AppColors.textPrimary : AppColors.textSecondary,
                      height: 1.0,
                    ),
                    overflow: TextOverflow.visible,
                    softWrap: false,
                  ),
                ),
                const SizedBox(height: 2),
                // 7 Day square cells
                ...week.map((date) {
                  if (date == null) {
                    return Container(
                      width: cellSize,
                      height: cellSize,
                      margin: const EdgeInsets.only(bottom: cellSpacing),
                    );
                  }

                  final normDate = AppDateUtils.normalizeDate(date);
                  final dayData = widget.dayDataMap[normDate];
                  final target = dayData?.targetCount ?? 0;
                  final actual = dayData?.actualCount ?? 0;
                  final isToday = AppDateUtils.isSameDay(normDate, widget.today);

                  // Completion fraction (bottom to top fill)
                  final double fraction = target > 0
                      ? (actual / target).clamp(0.0, 1.0)
                      : (actual > 0 ? 1.0 : 0.0);

                  return GestureDetector(
                    onTap: widget.onCellTap != null ? () => widget.onCellTap!(normDate) : null,
                    child: Tooltip(
                      message: '${AppDateUtils.formatDateDisplay(normDate)}\nПлан: $target, Выполнено: $actual',
                      child: Container(
                        width: cellSize,
                        height: cellSize,
                        margin: const EdgeInsets.only(bottom: cellSpacing),
                        decoration: BoxDecoration(
                          color: const Color(0xFF858585),
                          border: isToday
                              ? Border.all(color: AppColors.secondary, width: 1.5)
                              : null,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(isToday ? 2.5 : 4),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: fraction,
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
