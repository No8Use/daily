import 'package:equatable/equatable.dart';

enum HeatmapMode { habitsOnly, allTasks }

class HeatmapDayData extends Equatable {
  final DateTime date;
  final int targetCount;
  final int actualCount;

  const HeatmapDayData({
    required this.date,
    required this.targetCount,
    required this.actualCount,
  });

  @override
  List<Object?> get props => [date, targetCount, actualCount];
}

abstract class HeatmapState extends Equatable {
  const HeatmapState();

  @override
  List<Object?> get props => [];
}

class HeatmapInitial extends HeatmapState {}

class HeatmapLoading extends HeatmapState {}

class HeatmapLoaded extends HeatmapState {
  final HeatmapMode mode;
  final Map<DateTime, HeatmapDayData> dayDataMap;
  final DateTime minDate;
  final DateTime maxDate;
  final DateTime today;

  const HeatmapLoaded({
    required this.mode,
    required this.dayDataMap,
    required this.minDate,
    required this.maxDate,
    required this.today,
  });

  @override
  List<Object?> get props => [mode, dayDataMap, minDate, maxDate, today];
}

class HeatmapError extends HeatmapState {
  final String message;

  const HeatmapError(this.message);

  @override
  List<Object?> get props => [message];
}
