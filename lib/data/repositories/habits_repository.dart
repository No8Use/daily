import 'package:daily/data/database/app_database.dart';
import 'package:daily/utils/date_utils.dart';
import 'package:drift/drift.dart';

class HabitsRepository {
  final AppDatabase db;

  HabitsRepository(this.db);

  /// Streams active habits (canceledAt is null).
  Stream<List<Habit>> watchActiveHabits() {
    return (db.select(db.habits)
          ..where((tbl) => tbl.canceledAt.isNull())
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
        .watch();
  }

  /// Streams all habits (both active and soft-deleted).
  Stream<List<Habit>> watchAllHabits() {
    return (db.select(db.habits)
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
        .watch();
  }

  /// Creates a new habit template.
  Future<int> createHabit(String title, String? description) {
    return db.into(db.habits).insert(
          HabitsCompanion.insert(
            title: title,
            description: Value(description),
            createdAt: DateTime.now(),
          ),
        );
  }

  /// Updates an existing habit template.
  Future<bool> updateHabit(int id, String title, String? description) {
    return (db.update(db.habits)..where((tbl) => tbl.id.equals(id))).write(
      HabitsCompanion(
        title: Value(title),
        description: Value(description),
      ),
    ).then((rows) => rows > 0);
  }

  /// Soft deletes a habit (sets canceledAt to current time).
  Future<bool> cancelHabit(int id) {
    return (db.update(db.habits)..where((tbl) => tbl.id.equals(id))).write(
      HabitsCompanion(
        canceledAt: Value(DateTime.now()),
      ),
    ).then((rows) => rows > 0);
  }

  /// Restores a soft-deleted habit (clears canceledAt).
  Future<bool> restoreHabit(int id) {
    return (db.update(db.habits)..where((tbl) => tbl.id.equals(id))).write(
      const HabitsCompanion(
        canceledAt: Value(null),
      ),
    ).then((rows) => rows > 0);
  }

  /// Streams completions for a given date.
  Stream<List<HabitCompletion>> watchCompletionsForDate(DateTime date) {
    final normalizedDate = AppDateUtils.normalizeDate(date);
    return (db.select(db.habitCompletions)
          ..where((tbl) => tbl.date.equals(normalizedDate)))
        .watch();
  }

  /// Returns completions for a given date.
  Future<List<HabitCompletion>> getCompletionsForDate(DateTime date) {
    final normalizedDate = AppDateUtils.normalizeDate(date);
    return (db.select(db.habitCompletions)
          ..where((tbl) => tbl.date.equals(normalizedDate)))
        .get();
  }

  /// Returns completions in a date range.
  Future<List<HabitCompletion>> getCompletionsInRange(DateTime start, DateTime end) {
    final normStart = AppDateUtils.normalizeDate(start);
    final normEnd = AppDateUtils.normalizeDate(end);
    return (db.select(db.habitCompletions)
          ..where((tbl) => tbl.date.isBetweenValues(normStart, normEnd)))
        .get();
  }

  /// Returns all completions across all history.
  Future<List<HabitCompletion>> getAllCompletions() {
    return db.select(db.habitCompletions).get();
  }

  /// Toggles habit completion status for a specific date (Upsert with proper existence check).
  Future<void> toggleHabitCompletion(int habitId, DateTime date, bool isCompleted) async {
    final normalizedDate = AppDateUtils.normalizeDate(date);

    final existing = await (db.select(db.habitCompletions)
          ..where((tbl) => tbl.habitId.equals(habitId) & tbl.date.equals(normalizedDate)))
        .getSingleOrNull();

    if (existing != null) {
      await (db.update(db.habitCompletions)
            ..where((tbl) => tbl.id.equals(existing.id)))
          .write(HabitCompletionsCompanion(
        isCompleted: Value(isCompleted),
      ));
    } else {
      await db.into(db.habitCompletions).insert(
            HabitCompletionsCompanion.insert(
              habitId: habitId,
              date: normalizedDate,
              isCompleted: Value(isCompleted),
            ),
          );
    }
  }
}
