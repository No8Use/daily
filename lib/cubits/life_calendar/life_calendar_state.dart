import 'package:daily/data/database/app_database.dart';
import 'package:daily/data/models/life_calendar_models.dart';
import 'package:equatable/equatable.dart';

abstract class LifeCalendarState extends Equatable {
  const LifeCalendarState();

  @override
  List<Object?> get props => [];
}

class LifeCalendarInitial extends LifeCalendarState {
  const LifeCalendarInitial();
}

class LifeCalendarLoading extends LifeCalendarState {
  const LifeCalendarLoading();
}

class LifeCalendarSetupRequired extends LifeCalendarState {
  const LifeCalendarSetupRequired();
}

class LifeCalendarLoaded extends LifeCalendarState {
  const LifeCalendarLoaded({
    required this.settings,
    required this.totalWeeks,
    required this.currentWeekIndex,
    required this.trackingStartWeekIndex,
    required this.weeklyScores,
    required this.weeklyProductivity,
    required this.weeklyReviews,
  });

  final LifeCalendarSetting settings;

  final int totalWeeks;
  final int currentWeekIndex;
  final int trackingStartWeekIndex;

  final Map<int, double?> weeklyScores;
  final Map<int, WeekProductivity> weeklyProductivity;
  final Map<int, WeeklyReviewData> weeklyReviews;

  @override
  List<Object?> get props => [
    settings,
    totalWeeks,
    currentWeekIndex,
    trackingStartWeekIndex,
    weeklyScores,
    weeklyProductivity,
    weeklyReviews,
  ];
}

class LifeCalendarError extends LifeCalendarState {
  const LifeCalendarError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}