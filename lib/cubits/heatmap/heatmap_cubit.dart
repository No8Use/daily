import 'dart:async';

import 'package:contribution_heatmap/contribution_heatmap.dart';
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

  /// Aggregates habit completions and tasks into ContributionEntry list.
  Future<void> loadHeatmapData() async {
    emit(HeatmapLoading());
    try {
      final countsByDate = <DateTime, int>{};

      // 1. Fetch completed habit completions
      final completions = await habitsRepository.getAllCompletions();
      for (final c in completions) {
        if (c.isCompleted) {
          final normDate = AppDateUtils.normalizeDate(c.date);
          countsByDate[normDate] = (countsByDate[normDate] ?? 0) + 1;
        }
      }

      // 2. If mode == allTasks, fetch completed tasks with dueDates
      if (_currentMode == HeatmapMode.allTasks) {
        final tasks = await tasksRepository.getAllTasks();
        for (final t in tasks) {
          if (t.isCompleted && t.dueDate != null) {
            final normDate = AppDateUtils.normalizeDate(t.dueDate!);
            countsByDate[normDate] = (countsByDate[normDate] ?? 0) + 1;
          }
        }
      }

      final entries = countsByDate.entries
          .map((e) => ContributionEntry(e.key, e.value))
          .toList();

      final today = AppDateUtils.today;
      // Range: show last 6 months up to today by default
      final minDate = DateTime(today.year, today.month - 5, 1);
      final maxDate = today;

      emit(HeatmapLoaded(
        mode: _currentMode,
        entries: entries,
        minDate: minDate,
        maxDate: maxDate,
      ));
    } catch (e) {
      emit(HeatmapError('Ошибка расчет данных heatmap: $e'));
    }
  }
}
