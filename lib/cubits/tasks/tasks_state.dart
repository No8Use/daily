import 'package:daily/data/database/app_database.dart';
import 'package:equatable/equatable.dart';

abstract class TasksState extends Equatable {
  const TasksState();

  @override
  List<Object?> get props => [];
}

class TasksInitial extends TasksState {}

class TasksLoading extends TasksState {}

class TasksLoaded extends TasksState {
  final List<Task> todayTasks;
  final DateTime selectedDate;

  const TasksLoaded({
    required this.todayTasks,
    required this.selectedDate,
  });

  @override
  List<Object?> get props => [todayTasks, selectedDate];
}

class TasksError extends TasksState {
  final String message;

  const TasksError(this.message);

  @override
  List<Object?> get props => [message];
}
