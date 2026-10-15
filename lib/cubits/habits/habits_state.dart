import 'package:daily/data/database/app_database.dart';
import 'package:equatable/equatable.dart';

abstract class HabitsState extends Equatable {
  const HabitsState();

  @override
  List<Object?> get props => [];
}

class HabitsInitial extends HabitsState {}

class HabitsLoading extends HabitsState {}

class HabitsLoaded extends HabitsState {
  final List<Habit> activeHabits;
  final List<Habit> allHabits;
  /// Map of habitId -> completion status for today (or loaded date)
  final Map<int, bool> todayCompletions;

  const HabitsLoaded({
    required this.activeHabits,
    required this.allHabits,
    required this.todayCompletions,
  });

  @override
  List<Object?> get props => [activeHabits, allHabits, todayCompletions];
}

class HabitsError extends HabitsState {
  final String message;

  const HabitsError(this.message);

  @override
  List<Object?> get props => [message];
}
