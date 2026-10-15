import 'package:contribution_heatmap/contribution_heatmap.dart';
import 'package:equatable/equatable.dart';

enum HeatmapMode { habitsOnly, allTasks }

abstract class HeatmapState extends Equatable {
  const HeatmapState();

  @override
  List<Object?> get props => [];
}

class HeatmapInitial extends HeatmapState {}

class HeatmapLoading extends HeatmapState {}

class HeatmapLoaded extends HeatmapState {
  final HeatmapMode mode;
  final List<ContributionEntry> entries;
  final DateTime minDate;
  final DateTime maxDate;

  const HeatmapLoaded({
    required this.mode,
    required this.entries,
    required this.minDate,
    required this.maxDate,
  });

  @override
  List<Object?> get props => [mode, entries, minDate, maxDate];
}

class HeatmapError extends HeatmapState {
  final String message;

  const HeatmapError(this.message);

  @override
  List<Object?> get props => [message];
}
