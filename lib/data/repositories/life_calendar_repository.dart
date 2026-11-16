import 'package:daily/data/database/app_database.dart';
import 'package:daily/data/models/life_calendar_models.dart';
import 'package:daily/utils/date_utils.dart';
import 'package:drift/drift.dart';

class LifeCalendarRepository {
  LifeCalendarRepository(this.db);

  final AppDatabase db;

  Future<LifeCalendarSetting?> getSettings() {
    return db.select(db.lifeCalendarSettings).getSingleOrNull();
  }

  Future<void> saveSettings({
    required DateTime birthDate,
    required int targetAge,
  }) async {
    final existing = await getSettings();

    await db.into(db.lifeCalendarSettings).insertOnConflictUpdate(
      LifeCalendarSettingsCompanion(
        id: const Value(1),
        birthDate: Value(
          AppDateUtils.normalizeDate(birthDate),
        ),
        targetAge: Value(targetAge),
        startedAt: Value(
          existing?.startedAt ?? AppDateUtils.today,
        ),
      ),
    );
  }

  Future<void> updateTargetAge(int targetAge) async {
    await (db.update(db.lifeCalendarSettings)
      ..where((table) => table.id.equals(1)))
        .write(
      LifeCalendarSettingsCompanion(
        targetAge: Value(targetAge),
      ),
    );
  }

  Future<void> saveWeeklyReview({
    required DateTime weekStart,
    required int rating,
    required String description,
  }) async {
    final normalizedWeekStart =
    AppDateUtils.normalizeDate(weekStart);

    await db.into(db.weeklyReviews).insertOnConflictUpdate(
      WeeklyReviewsCompanion.insert(
        weekStart: normalizedWeekStart,
        rating: rating,
        description: Value(description.trim()),
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<LifeCalendarData> getCalendarData({
    required DateTime from,
    required DateTime to,
  }) async {
    final start = AppDateUtils.normalizeDate(from);
    final endExclusive = AppDateUtils.normalizeDate(to).add(
      const Duration(days: 1),
    );

    final firstWeekStart = _mondayOf(start);
    final lastWeekEndExclusive = _mondayOf(to).add(
      const Duration(days: 7),
    );

    final habitsFuture = (db.select(db.habits)
      ..where(
            (table) =>
        table.createdAt.isSmallerThanValue(endExclusive) &
        (
            table.canceledAt.isNull() |
            table.canceledAt.isBiggerOrEqualValue(start)
        ),
      ))
        .get();

    final completionsFuture = (db.select(db.habitCompletions)
      ..where(
            (table) =>
        table.date.isBiggerOrEqualValue(start) &
        table.date.isSmallerThanValue(endExclusive),
      ))
        .get();

    final tasksFuture = (db.select(db.tasks)
      ..where(
            (table) =>
        table.dueDate.isNotNull() &
        table.dueDate.isBiggerOrEqualValue(start) &
        table.dueDate.isSmallerThanValue(endExclusive),
      ))
        .get();

    final reviewsFuture = (db.select(db.weeklyReviews)
      ..where(
            (table) =>
        table.weekStart.isBiggerOrEqualValue(firstWeekStart) &
        table.weekStart.isSmallerThanValue(
          lastWeekEndExclusive,
        ),
      ))
        .get();

    final results = await Future.wait<Object>([
      habitsFuture,
      completionsFuture,
      tasksFuture,
      reviewsFuture,
    ]);

    final habits = results[0] as List<Habit>;
    final completions = results[1] as List<HabitCompletion>;
    final tasks = results[2] as List<Task>;
    final reviews = results[3] as List<WeeklyReview>;

    return LifeCalendarData(
      habits: habits
          .map(
            (habit) => HabitCalendarRecord(
          id: habit.id,
          createdAt: habit.createdAt,
          canceledAt: habit.canceledAt,
        ),
      )
          .toList(growable: false),
      completions: completions
          .map(
            (completion) => HabitCompletionCalendarRecord(
          habitId: completion.habitId,
          date: completion.date,
          isCompleted: completion.isCompleted,
        ),
      )
          .toList(growable: false),
      tasks: tasks
          .map(
            (task) => TaskCalendarRecord(
          dueDate: task.dueDate,
          isCompleted: task.isCompleted,
        ),
      )
          .toList(growable: false),
      reviews: reviews
          .map(
            (review) => WeeklyReviewData(
          weekStart: review.weekStart,
          description: review.description,
          rating: review.rating,
          createdAt: review.createdAt,
        ),
      )
          .toList(growable: false),
    );
  }

  DateTime _mondayOf(DateTime date) {
    final normalized = AppDateUtils.normalizeDate(date);

    return normalized.subtract(
      Duration(days: normalized.weekday - DateTime.monday),
    );
  }
}