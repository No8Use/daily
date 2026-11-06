import 'package:daily/data/database/app_database.dart';
import 'package:daily/utils/date_utils.dart';
import 'package:drift/drift.dart';

class LifeCalendarRepository {
  LifeCalendarRepository(this.db);

  final AppDatabase db;

  Future<LifeCalendarSetting?> getSettings() {
    return db.select(db.lifeCalendarSettings).getSingleOrNull();
  }

  Future<void> saveSettings({
    required int startAge,
    required int targetAge,
  }) async {
    if (startAge < 0 || targetAge <= startAge) {
      throw ArgumentError('Invalid calendar ages.');
    }

    final existing = await getSettings();

    await db.into(db.lifeCalendarSettings).insertOnConflictUpdate(
      LifeCalendarSettingsCompanion(
        id: const Value(1),
        startAge: Value(startAge),
        targetAge: Value(targetAge),
        startedAt: Value(
          existing?.startedAt ?? AppDateUtils.today,
        ),
      ),
    );
  }

  Future<void> updateTargetAge(int targetAge) async {
    final settings = await getSettings();

    if (settings == null) {
      throw StateError('Life calendar has not been configured.');
    }

    if (targetAge <= settings.startAge) {
      throw ArgumentError('Target age must exceed start age.');
    }

    await (db.update(db.lifeCalendarSettings)
      ..where((table) => table.id.equals(1)))
        .write(
      LifeCalendarSettingsCompanion(
        targetAge: Value(targetAge),
      ),
    );
  }

  Future<WeeklyReview?> getWeeklyReview(DateTime weekStart) {
    final normalized = AppDateUtils.normalizeDate(weekStart);

    return (db.select(db.weeklyReviews)
      ..where((table) => table.weekStart.equals(normalized)))
        .getSingleOrNull();
  }

  Future<void> saveWeeklyReview({
    required DateTime weekStart,
    required int rating,
    required String description,
  }) async {
    final normalized = AppDateUtils.normalizeDate(weekStart);
    final today = AppDateUtils.today;

    // A review is only allowed after the week has ended.
    final weekEnd = normalized.add(const Duration(days: 6));

    if (weekEnd.isAfter(today) ||
        weekEnd.isAtSameMomentAs(today) &&
            today.weekday != DateTime.sunday) {
      throw StateError('This week has not finished.');
    }

    await db.into(db.weeklyReviews).insertOnConflictUpdate(
      WeeklyReviewsCompanion.insert(
        weekStart: normalized,
        rating: rating.clamp(1, 10),
        description: Value(description),
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<WeekProductivity> getWeekProductivity(
      DateTime weekStart,
      ) async {
    final start = AppDateUtils.normalizeDate(weekStart);
    final end = start.add(const Duration(days: 6));
    final today = AppDateUtils.today;

    final habits = await db.select(db.habits).get();

    final completions = await (db.select(db.habitCompletions)
      ..where(
            (table) => table.date.isBetweenValues(start, end),
      )).get();

    final tasks = await (db.select(db.tasks)
      ..where(
            (table) =>
        table.dueDate.isNotNull() &
        table.dueDate.isBetweenValues(start, end),
      )).get();

    var expectedHabitCompletions = 0;

    for (final habit in habits) {
      for (var day = 0; day < 7; day++) {
        final date = start.add(Duration(days: day));

        final createdAt = AppDateUtils.normalizeDate(habit.createdAt);

        final isActive = !date.isBefore(createdAt) &&
            (habit.canceledAt == null ||
                date.isBefore(
                  AppDateUtils.normalizeDate(habit.canceledAt!),
                ));

        if (isActive && !date.isAfter(today)) {
          expectedHabitCompletions++;
        }
      }
    }

    final completedHabits = completions
        .where((completion) => completion.isCompleted)
        .length;

    final completedTasks = tasks
        .where((task) => task.isCompleted)
        .length;

    final totalTasks = tasks.length;

    return WeekProductivity(
      completedHabits: completedHabits,
      totalHabitOpportunities: expectedHabitCompletions,
      completedTasks: completedTasks,
      totalTasks: totalTasks,
    );
  }
}

class WeekProductivity {
  const WeekProductivity({
    required this.completedHabits,
    required this.totalHabitOpportunities,
    required this.completedTasks,
    required this.totalTasks,
  });

  final int completedHabits;
  final int totalHabitOpportunities;

  final int completedTasks;
  final int totalTasks;

  double get habitProgress {
    if (totalHabitOpportunities == 0) return 0;

    return (completedHabits / totalHabitOpportunities)
        .clamp(0.0, 1.0);
  }

  double get taskProgress {
    if (totalTasks == 0) return 0;

    return (completedTasks / totalTasks).clamp(0.0, 1.0);
  }

  double get overallProgress {
    final total = totalHabitOpportunities + totalTasks;

    if (total == 0) return 0;

    return (completedHabits + completedTasks) / total;
  }
}