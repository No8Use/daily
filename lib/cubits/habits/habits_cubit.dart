import 'dart:async';

import 'package:daily/cubits/habits/habits_state.dart';
import 'package:daily/data/repositories/habits_repository.dart';
import 'package:daily/utils/date_utils.dart';
import 'package:daily/utils/models/operation_result.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HabitsCubit extends Cubit<HabitsState> {
  final HabitsRepository repository;
  StreamSubscription? _habitsSub;
  StreamSubscription? _completionsSub;
  DateTime? _currentDate;

  HabitsCubit(this.repository) : super(HabitsInitial());

  /// Initializes streams for habits and completions for a specific date (defaults to today).
  void loadHabits([DateTime? date]) {
    _currentDate = date != null ? AppDateUtils.normalizeDate(date) : AppDateUtils.today;
    emit(HabitsLoading());
    _subscribe(_currentDate!);
  }

  void _subscribe(DateTime targetDate) {
    _habitsSub?.cancel();
    _completionsSub?.cancel();

    _habitsSub = repository.watchAllHabits().listen((allHabits) {
      final activeHabits = allHabits.where((h) => h.canceledAt == null).toList();

      _completionsSub?.cancel();
      _completionsSub = repository.watchCompletionsForDate(targetDate).listen((completions) {
        final completionsMap = <int, bool>{};
        for (final c in completions) {
          completionsMap[c.habitId] = c.isCompleted;
        }

        emit(HabitsLoaded(
          activeHabits: activeHabits,
          allHabits: allHabits,
          todayCompletions: completionsMap,
        ));
      }, onError: (e) {
        emit(HabitsError('Ошибка загрузки статуса привычек: $e'));
      });
    }, onError: (e) {
      emit(HabitsError('Ошибка загрузки привычек: $e'));
    });
  }

  Future<OperationResult> toggleCompletion(
      int habitId,
      DateTime date,
      bool isCompleted,
      ) async {
    try {
      final normalizedDate = AppDateUtils.normalizeDate(date);

      await repository.toggleHabitCompletion(
        habitId,
        normalizedDate,
        isCompleted,
      );

      return const OperationResult.success();
    } catch (error) {
      final message = 'Не удалось обновить статус привычки: $error';
      emit(HabitsError(message));

      return OperationResult.failure(message);
    }
  }

  Future<void> createHabit(String title, String? description) async {
    try {
      await repository.createHabit(title, description);
    } catch (e) {
      emit(HabitsError('Не удалось создать привычку: $e'));
    }
  }

  Future<void> updateHabit(int id, String title, String? description) async {
    try {
      await repository.updateHabit(id, title, description);
    } catch (e) {
      emit(HabitsError('Не удалось обновить привычку: $e'));
    }
  }

  Future<void> cancelHabit(int id) async {
    try {
      await repository.cancelHabit(id);
    } catch (e) {
      emit(HabitsError('Не удалось отменить привычку: $e'));
    }
  }

  Future<void> restoreHabit(int id) async {
    try {
      await repository.restoreHabit(id);
    } catch (e) {
      emit(HabitsError('Не удалось восстановить привычку: $e'));
    }
  }

  @override
  Future<void> close() {
    _habitsSub?.cancel();
    _completionsSub?.cancel();
    return super.close();
  }
}
