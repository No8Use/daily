import 'package:equatable/equatable.dart';

class HabitCalendarRecord {
  const HabitCalendarRecord({
    required this.id,
    required this.createdAt,
    required this.canceledAt,
  });

  final int id;
  final DateTime createdAt;
  final DateTime? canceledAt;
}

class HabitCompletionCalendarRecord {
  const HabitCompletionCalendarRecord({
    required this.habitId,
    required this.date,
    required this.isCompleted,
  });

  final int habitId;
  final DateTime date;
  final bool isCompleted;
}

class TaskCalendarRecord {
  const TaskCalendarRecord({
    required this.dueDate,
    required this.isCompleted,
  });

  final DateTime? dueDate;
  final bool isCompleted;
}

class WeeklyReviewData extends Equatable {
  const WeeklyReviewData({
    required this.weekStart,
    required this.description,
    required this.rating,
    required this.createdAt,
  });

  final DateTime weekStart;
  final String description;
  final int rating;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
    weekStart,
    description,
    rating,
    createdAt,
  ];
}

class LifeCalendarData {
  const LifeCalendarData({
    required this.habits,
    required this.completions,
    required this.tasks,
    required this.reviews,
  });

  final List<HabitCalendarRecord> habits;
  final List<HabitCompletionCalendarRecord> completions;
  final List<TaskCalendarRecord> tasks;
  final List<WeeklyReviewData> reviews;
}

class WeekProductivity extends Equatable {
  const WeekProductivity({
    required this.completedHabits,
    required this.totalHabitOpportunities,
    required this.completedTasks,
    required this.totalTasks,
  });

  static const empty = WeekProductivity(
    completedHabits: 0,
    totalHabitOpportunities: 0,
    completedTasks: 0,
    totalTasks: 0,
  );

  final int completedHabits;
  final int totalHabitOpportunities;
  final int completedTasks;
  final int totalTasks;

  bool get hasData =>
      totalHabitOpportunities > 0 || totalTasks > 0;

  double get habitProgress {
    if (totalHabitOpportunities == 0) return 0;

    return (completedHabits / totalHabitOpportunities)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  double get taskProgress {
    if (totalTasks == 0) return 0;

    return (completedTasks / totalTasks)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  double get overallProgress {
    final total = totalHabitOpportunities + totalTasks;

    if (total == 0) return 0;

    return ((completedHabits + completedTasks) / total)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  @override
  List<Object?> get props => [
    completedHabits,
    totalHabitOpportunities,
    completedTasks,
    totalTasks,
  ];
}

class LifeCalendarCalculationResult {
  const LifeCalendarCalculationResult({
    required this.totalWeeks,
    required this.currentWeekIndex,
    required this.trackingStartWeekIndex,
    required this.weeklyScores,
    required this.weeklyProductivity,
    required this.weeklyReviews,
  });

  final int totalWeeks;
  final int currentWeekIndex;
  final int trackingStartWeekIndex;

  final Map<int, double?> weeklyScores;
  final Map<int, WeekProductivity> weeklyProductivity;
  final Map<int, WeeklyReviewData> weeklyReviews;
}