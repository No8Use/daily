import 'dart:async';

import 'package:daily/cubits/tasks/tasks_state.dart';
import 'package:daily/data/repositories/tasks_repository.dart';
import 'package:daily/utils/date_utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TasksCubit extends Cubit<TasksState> {
  final TasksRepository repository;
  StreamSubscription? _tasksSub;
  DateTime _currentDate = AppDateUtils.today;

  TasksCubit(this.repository) : super(TasksInitial());

  /// Loads tasks for today or a specific date.
  void loadTasksForDate([DateTime? date]) {
    _currentDate = date != null ? AppDateUtils.normalizeDate(date) : AppDateUtils.today;
    emit(TasksLoading());

    _tasksSub?.cancel();
    _tasksSub = repository.watchTasksForDate(_currentDate).listen((tasks) {
      emit(TasksLoaded(
        todayTasks: tasks,
        selectedDate: _currentDate,
      ));
    }, onError: (e) {
      emit(TasksError('Ошибка загрузки задач: $e'));
    });
  }

  Future<void> createTask(String title, String? description, DateTime? dueDate) async {
    try {
      await repository.createTask(title, description, dueDate ?? _currentDate);
    } catch (e) {
      emit(TasksError('Не удалось создать задачу: $e'));
    }
  }

  Future<void> toggleTask(int id, bool currentStatus) async {
    try {
      await repository.toggleTaskCompletion(id, !currentStatus);
    } catch (e) {
      emit(TasksError('Не удалось изменить статус задачи: $e'));
    }
  }

  Future<void> deleteTask(int id) async {
    try {
      await repository.deleteTask(id);
    } catch (e) {
      emit(TasksError('Не удалось удалить задачу: $e'));
    }
  }

  @override
  Future<void> close() {
    _tasksSub?.cancel();
    return super.close();
  }
}
