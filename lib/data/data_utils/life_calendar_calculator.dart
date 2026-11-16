import 'package:daily/data/models/life_calendar_models.dart';

class LifeCalendarCalculator {
  DateTime normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  DateTime mondayOf(DateTime date) {
    final normalized = normalizeDate(date);

    return normalized.subtract(
      Duration(days: normalized.weekday - DateTime.monday),
    );
  }

  DateTime addYearsClamped(DateTime date, int years) {
    final targetYear = date.year + years;

    final lastDay = DateTime(
      targetYear,
      date.month + 1,
      0,
    ).day;

    final targetDay = date.day > lastDay
        ? lastDay
        : date.day;

    return DateTime(
      targetYear,
      date.month,
      targetDay,
    );
  }

  int calculateAge({
    required DateTime birthDate,
    required DateTime date,
  }) {
    final birth = normalizeDate(birthDate);
    final target = normalizeDate(date);

    var age = target.year - birth.year;

    final birthdayThisYear = addYearsClamped(
      birth,
      age,
    );

    if (target.isBefore(birthdayThisYear)) {
      age--;
    }

    return age;
  }

  int calculateTotalWeeks({
    required DateTime birthDate,
    required int targetAge,
  }) {
    final firstWeek = mondayOf(birthDate);

    final targetDate = addYearsClamped(
      birthDate,
      targetAge,
    );

    final days = targetDate.difference(firstWeek).inDays;

    return ((days + 6) ~/ 7).clamp(1, 10000).toInt();
  }

  int calculateWeekIndex({
    required DateTime birthDate,
    required DateTime date,
  }) {
    final firstWeek = mondayOf(birthDate);
    final targetWeek = mondayOf(date);

    return targetWeek.difference(firstWeek).inDays ~/ 7;
  }

  DateTime getWeekStart({
    required DateTime birthDate,
    required int weekIndex,
  }) {
    return mondayOf(birthDate).add(
      Duration(days: weekIndex * 7),
    );
  }

  void validateConfiguration({
    required DateTime birthDate,
    required int targetAge,
    required DateTime today,
  }) {
    final birth = normalizeDate(birthDate);
    final currentDate = normalizeDate(today);

    if (birth.isAfter(currentDate)) {
      throw ArgumentError(
        'Дата рождения не может быть в будущем.',
      );
    }

    if (targetAge < 1 || targetAge > 120) {
      throw ArgumentError(
        'Целевой возраст должен быть от 1 до 120 лет.',
      );
    }

    final currentAge = calculateAge(
      birthDate: birth,
      date: currentDate,
    );

    if (targetAge <= currentAge) {
      throw ArgumentError(
        'Целевой возраст должен быть больше текущего возраста.',
      );
    }
  }

  void validateTargetAge({
    required DateTime birthDate,
    required int targetAge,
    required DateTime today,
  }) {
    if (targetAge < 1 || targetAge > 120) {
      throw ArgumentError(
        'Целевой возраст должен быть от 1 до 120 лет.',
      );
    }

    final currentAge = calculateAge(
      birthDate: birthDate,
      date: today,
    );

    if (targetAge <= currentAge) {
      throw ArgumentError(
        'Целевой возраст должен быть больше текущего возраста.',
      );
    }
  }

  bool isReviewAvailable({
    required DateTime weekStart,
    required DateTime startedAt,
    required DateTime today,
  }) {
    final normalizedStart = normalizeDate(weekStart);
    final trackingStart = mondayOf(startedAt);
    final normalizedToday = normalizeDate(today);

    if (normalizedStart.weekday != DateTime.monday) {
      return false;
    }

    if (normalizedStart.isBefore(trackingStart)) {
      return false;
    }

    final weekEnd = normalizedStart.add(
      const Duration(days: 6),
    );

    return !weekEnd.isAfter(normalizedToday);
  }

  LifeCalendarCalculationResult calculate({
    required DateTime birthDate,
    required DateTime startedAt,
    required int targetAge,
    required DateTime today,
    required LifeCalendarData data,
  }) {
    final birth = normalizeDate(birthDate);
    final trackingStart = normalizeDate(startedAt);
    final currentDate = normalizeDate(today);

    final firstWeek = mondayOf(birth);

    final totalWeeks = calculateTotalWeeks(
      birthDate: birth,
      targetAge: targetAge,
    );

    final currentWeekIndex = calculateWeekIndex(
      birthDate: birth,
      date: currentDate,
    ).clamp(0, totalWeeks - 1).toInt();

    final trackingStartWeekIndex = calculateWeekIndex(
      birthDate: birth,
      date: trackingStart,
    ).clamp(0, totalWeeks).toInt();

    final completedHabitDates = <String>{};

    for (final completion in data.completions) {
      if (!completion.isCompleted) continue;

      final date = normalizeDate(completion.date);

      if (date.isBefore(trackingStart) ||
          date.isAfter(currentDate)) {
        continue;
      }

      completedHabitDates.add(
        _habitDateKey(completion.habitId, date),
      );
    }

    final tasksByWeek = <int, List<TaskCalendarRecord>>{};

    for (final task in data.tasks) {
      final dueDate = task.dueDate;

      if (dueDate == null) continue;

      final normalizedDate = normalizeDate(dueDate);

      final weekIndex = calculateWeekIndex(
        birthDate: birth,
        date: normalizedDate,
      );

      tasksByWeek.putIfAbsent(
        weekIndex,
            () => [],
      ).add(task);
    }

    final reviewsByWeek = <int, WeeklyReviewData>{};

    for (final review in data.reviews) {
      final weekIndex = calculateWeekIndex(
        birthDate: birth,
        date: review.weekStart,
      );

      if (weekIndex < trackingStartWeekIndex ||
          weekIndex > currentWeekIndex) {
        continue;
      }

      reviewsByWeek[weekIndex] = review;
    }

    final weeklyScores = <int, double?>{};
    final weeklyProductivity = <int, WeekProductivity>{};

    for (
    var weekIndex = trackingStartWeekIndex;
    weekIndex <= currentWeekIndex;
    weekIndex++
    ) {
      final weekStart = firstWeek.add(
        Duration(days: weekIndex * 7),
      );

      final productivity = _calculateWeekProductivity(
        weekStart: weekStart,
        startedAt: trackingStart,
        today: currentDate,
        habits: data.habits,
        tasks: tasksByWeek[weekIndex] ?? const [],
        completedHabitDates: completedHabitDates,
      );

      weeklyProductivity[weekIndex] = productivity;

      final review = reviewsByWeek[weekIndex];

      final productivityScore = productivity.hasData
          ? productivity.overallProgress
          : null;

      final reviewScore = review == null
          ? null
          : review.rating.clamp(1, 10) / 10;

      if (productivityScore != null && reviewScore != null) {
        weeklyScores[weekIndex] =
            (productivityScore + reviewScore) / 2;
      } else {
        weeklyScores[weekIndex] =
            productivityScore ?? reviewScore;
      }
    }

    return LifeCalendarCalculationResult(
      totalWeeks: totalWeeks,
      currentWeekIndex: currentWeekIndex,
      trackingStartWeekIndex: trackingStartWeekIndex,
      weeklyScores: Map.unmodifiable(weeklyScores),
      weeklyProductivity: Map.unmodifiable(weeklyProductivity),
      weeklyReviews: Map.unmodifiable(reviewsByWeek),
    );
  }

  WeekProductivity _calculateWeekProductivity({
    required DateTime weekStart,
    required DateTime startedAt,
    required DateTime today,
    required List<HabitCalendarRecord> habits,
    required List<TaskCalendarRecord> tasks,
    required Set<String> completedHabitDates,
  }) {
    final weekEnd = weekStart.add(
      const Duration(days: 6),
    );

    final calculationStart = weekStart.isBefore(startedAt)
        ? startedAt
        : weekStart;

    final calculationEnd = weekEnd.isAfter(today)
        ? today
        : weekEnd;

    var completedHabits = 0;
    var totalHabitOpportunities = 0;

    if (!calculationStart.isAfter(calculationEnd)) {
      for (
      var date = calculationStart;
      !date.isAfter(calculationEnd);
      date = date.add(const Duration(days: 1))
      ) {
        for (final habit in habits) {
          final createdAt = normalizeDate(habit.createdAt);

          final canceledAt = habit.canceledAt == null
              ? null
              : normalizeDate(habit.canceledAt!);

          final isActive = !date.isBefore(createdAt) &&
              (canceledAt == null || date.isBefore(canceledAt));

          if (!isActive) continue;

          totalHabitOpportunities++;

          if (completedHabitDates.contains(
            _habitDateKey(habit.id, date),
          )) {
            completedHabits++;
          }
        }
      }
    }

    final completedTasks = tasks
        .where((task) => task.isCompleted)
        .length;

    return WeekProductivity(
      completedHabits: completedHabits,
      totalHabitOpportunities: totalHabitOpportunities,
      completedTasks: completedTasks,
      totalTasks: tasks.length,
    );
  }

  String _habitDateKey(int habitId, DateTime date) {
    return '$habitId:${date.year}-${date.month}-${date.day}';
  }
}