import 'package:daily/data/database/app_database.dart';
import 'package:daily/utils/date_utils.dart';
import 'package:drift/drift.dart';

class TasksRepository {
  final AppDatabase db;

  TasksRepository(this.db);

  /// Streams tasks with due date matching the specified date.
  Stream<List<Task>> watchTasksForDate(DateTime date) {
    final normalizedDate = AppDateUtils.normalizeDate(date);
    return (db.select(db.tasks)
          ..where((tbl) => tbl.dueDate.equals(normalizedDate))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.isCompleted)]))
        .watch();
  }

  /// Streams all tasks in the database.
  Stream<List<Task>> watchAllTasks() {
    return (db.select(db.tasks)
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
        .watch();
  }

  /// Gets tasks for a specific date.
  Future<List<Task>> getTasksForDate(DateTime date) {
    final normalizedDate = AppDateUtils.normalizeDate(date);
    return (db.select(db.tasks)
          ..where((tbl) => tbl.dueDate.equals(normalizedDate)))
        .get();
  }

  /// Gets completed tasks within a date range for heatmap calculation.
  Future<List<Task>> getCompletedTasksInRange(DateTime start, DateTime end) {
    final normStart = AppDateUtils.normalizeDate(start);
    final normEnd = AppDateUtils.normalizeDate(end);
    return (db.select(db.tasks)
          ..where((tbl) =>
              tbl.isCompleted.equals(true) &
              tbl.dueDate.isNotNull() &
              tbl.dueDate.isBetweenValues(normStart, normEnd)))
        .get();
  }

  /// Gets all tasks.
  Future<List<Task>> getAllTasks() {
    return db.select(db.tasks).get();
  }

  /// Creates a new task.
  Future<int> createTask(String title, String? description, DateTime? dueDate) {
    final normalizedDueDate = dueDate != null ? AppDateUtils.normalizeDate(dueDate) : null;
    return db.into(db.tasks).insert(
          TasksCompanion.insert(
            title: title,
            description: Value(description),
            createdAt: DateTime.now(),
            dueDate: Value(normalizedDueDate),
            isCompleted: const Value(false),
          ),
        );
  }

  /// Updates task details.
  Future<bool> updateTask(int id, String title, String? description, DateTime? dueDate) {
    final normalizedDueDate = dueDate != null ? AppDateUtils.normalizeDate(dueDate) : null;
    return (db.update(db.tasks)..where((tbl) => tbl.id.equals(id))).write(
      TasksCompanion(
        title: Value(title),
        description: Value(description),
        dueDate: Value(normalizedDueDate),
      ),
    ).then((rows) => rows > 0);
  }

  /// Toggles completion state of a task.
  Future<bool> toggleTaskCompletion(int id, bool isCompleted) {
    return (db.update(db.tasks)..where((tbl) => tbl.id.equals(id))).write(
      TasksCompanion(
        isCompleted: Value(isCompleted),
      ),
    ).then((rows) => rows > 0);
  }

  /// Deletes a task.
  Future<bool> deleteTask(int id) {
    return (db.delete(db.tasks)..where((tbl) => tbl.id.equals(id))).go().then((rows) => rows > 0);
  }
}
