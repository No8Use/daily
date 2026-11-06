import 'package:daily/data/database/app_database.dart';
import 'package:daily/data/repositories/life_calendar_repository.dart';
import 'package:equatable/equatable.dart';

abstract class LifeCalendarState extends Equatable {
  const LifeCalendarState();

  @override
  List<Object?> get props => [];
}

class LifeCalendarInitial extends LifeCalendarState {}

class LifeCalendarLoading extends LifeCalendarState {}

class LifeCalendarSetupRequired extends LifeCalendarState {}

class LifeCalendarLoaded extends LifeCalendarState {
  const LifeCalendarLoaded({
    required this.settings,
  });

  final LifeCalendarSetting settings;

  @override
  List<Object?> get props => [settings];
}

class LifeCalendarError extends LifeCalendarState {
  const LifeCalendarError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}