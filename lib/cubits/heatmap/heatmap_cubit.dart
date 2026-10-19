import 'dart:async';

import 'package:daily/cubits/heatmap/heatmap_state.dart';
import 'package:daily/data/repositories/habits_repository.dart';
import 'package:daily/data/repositories/tasks_repository.dart';
import 'package:daily/utils/date_utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HeatmapCubit extends Cubit<HeatmapState> {
  final HabitsRepository habitsRepository;
  final TasksRepository tasksRepository;

  HeatmapMode _currentMode = HeatmapMode.habitsOnly;

  HeatmapCubit({
    required this.habitsRepository,
    required this.tasksRepository,
  }) : super(HeatmapInitial());

  /// Sets active heatmap display mode.
  void setMode(HeatmapMode mode) {
    _currentMode = mode;
    loadHeatmapData();
  }

  /// Calculates target vs actual day data for habits and tasks from minDate to future maxDate.
  Future<void> loadHeatmapData() async {
    if (state is! HeatmapLoaded) {
      emit(HeatmapLoading());
    }
    try {
      final today = AppDateUtils.today;
      final minDate = DateTime(today.year, today.month - 5, 1);

      final allHabits = await habitsRepository.watchAllHabits().first;
      final allCompletions = await habitsRepository.getAllCompletions();
      final allTasks = await tasksRepository.getAllTasks();

      // Determine max date: at least today + 14 days, or max task dueDate / future date up to 2 years
      DateTime maxDate = today.add(const Duration(days: 14));
      for (final t in allTasks) {
        if (t.dueDate != null) {
          final normDue = AppDateUtils.normalizeDate(t.dueDate!);
          if (normDue.isAfter(maxDate)) {
            maxDate = normDue;
          }
        }
      }
      final twoYearsLater = DateTime(today.year + 2, today.month, today.day);
      if (maxDate.isAfter(twoYearsLater)) {
        maxDate = twoYearsLater;
      }

      // Build completions lookup: habitId_dateIso -> isCompleted
      final completionsMap = <String, bool>{};
      for (final c in allCompletions) {
        if (c.isCompleted) {
          final key = '${c.habitId}_${AppDateUtils.normalizeDate(c.date).toIso8601String()}';
          completionsMap[key] = true;
        }
      }

      // Build tasks lookup: date -> target/actual counts
      final taskTargetsMap = <DateTime, int>{};
      final taskActualsMap = <DateTime, int>{};
      for (final t in allTasks) {
        if (t.dueDate != null) {
          final normDue = AppDateUtils.normalizeDate(t.dueDate!);
          taskTargetsMap[normDue] = (taskTargetsMap[normDue] ?? 0) + 1;
          if (t.isCompleted) {
            taskActualsMap[normDue] = (taskActualsMap[normDue] ?? 0) + 1;
          }
        }
      }

      final dayDataMap = <DateTime, HeatmapDayData>{};
      DateTime current = AppDateUtils.normalizeDate(minDate);
      final normMax = AppDateUtils.normalizeDate(maxDate);

      while (!current.isAfter(normMax)) {
        final activeHabitsForDay = allHabits.where((h) {
          final isCreated = AppDateUtils.normalizeDate(h.createdAt).isBefore(current) ||
              AppDateUtils.isSameDay(h.createdAt, current);
          final isNotCanceled = h.canceledAt == null ||
              AppDateUtils.normalizeDate(h.canceledAt!).isAfter(current);
          return isCreated && isNotCanceled;
        }).toList();

        int target = activeHabitsForDay.length;
        int actual = 0;

        for (final h in activeHabitsForDay) {
          final key = '${h.id}_${current.toIso8601String()}';
          if (completionsMap[key] == true) {
            actual++;
          }
        }

        if (_currentMode == HeatmapMode.allTasks) {
          target += taskTargetsMap[current] ?? 0;
          actual += taskActualsMap[current] ?? 0;
        }

        dayDataMap[current] = HeatmapDayData(
          date: current,
          targetCount: target,
          actualCount: actual,
        );

        current = current.add(const Duration(days: 1));
      }

      emit(HeatmapLoaded(
        mode: _currentMode,
        dayDataMap: dayDataMap,
        minDate: minDate,
        maxDate: maxDate,
        today: today,
      ));
    } catch (e) {
      emit(HeatmapError('Ошибка расчета heatmap: $e'));
    }
  }
}
