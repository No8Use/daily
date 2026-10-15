import 'dart:async';

import 'package:daily/cubits/habits/habits_state.dart';
import 'package:daily/data/repositories/habits_repository.dart';
import 'package:daily/utils/date_utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HabitsCubit extends Cubit<HabitsState> {
  final HabitsRepository repository;
  StreamSubscription? _habitsSub;
  StreamSubscription? _completionsSub;

  HabitsCubit(this.repository) : super(HabitsInitial());

  /// Initializes streams for habits and today's completions.
  void loadHabits() {
    emit(HabitsLoading());
    _subscribe();
  }

  void _subscribe() {
    _habitsSub?.cancel();
    _completionsSub?.cancel();

    final today = AppDateUtils.today;

    _habitsSub = repository.watchAllHabits().listen((allHabits) {
      _completionsSub?.cancel();
      _completionsSub = repository.watchCompletionsForDate(today).listen((completions) {
        final activeHabits = allHabits.where((h) => h.canceledAt == null).toList();
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

  Future<void> toggleCompletion(int habitId, DateTime date, bool currentCompleted) async {
    try {
      await repository.toggleHabitCompletion(habitId, date, !currentCompleted);
    } catch (e) {
      emit(HabitsError('Не удалось обновить статус привычки: $e'));
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
