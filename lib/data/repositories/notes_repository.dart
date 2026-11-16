import 'package:daily/data/database/app_database.dart';
import 'package:daily/utils/date_utils.dart';
import 'package:drift/drift.dart';

class NotesRepository {
  final AppDatabase db;

  NotesRepository(this.db);

  /// Streams notes with optional filtering and sorting options.
  Stream<List<Note>> watchNotes({
    DateTime? createdAfter,
    DateTime? createdBefore,
    bool? hasNeedCheckDate,
    DateTime? checkAfter,
    DateTime? checkBefore,
    bool sortByReminder = false,
  }) {
    final query = db.select(db.notes);

    if (sortByReminder) {
      query.orderBy([
        (tbl) => OrderingTerm.desc(tbl.needCheckDate),
        (tbl) => OrderingTerm.desc(tbl.createdAt),
      ]);
    } else {
      query.orderBy([
        (tbl) => OrderingTerm.desc(tbl.createdAt),
      ]);
    }

    if (createdAfter != null) {
      final normAfter = AppDateUtils.normalizeDate(createdAfter);
      query.where((tbl) => tbl.createdAt.isBiggerOrEqualValue(normAfter));
    }
    if (createdBefore != null) {
      final normBefore = AppDateUtils.normalizeDate(createdBefore).add(const Duration(days: 1));
      query.where((tbl) => tbl.createdAt.isSmallerThanValue(normBefore));
    }
    if (hasNeedCheckDate != null) {
      if (hasNeedCheckDate) {
        query.where((tbl) => tbl.needCheckDate.isNotNull());
      } else {
        query.where((tbl) => tbl.needCheckDate.isNull());
      }
    }
    if (checkAfter != null) {
      final normCheckAfter = AppDateUtils.normalizeDate(checkAfter);
      query.where((tbl) => tbl.needCheckDate.isBiggerOrEqualValue(normCheckAfter));
    }
    if (checkBefore != null) {
      final normCheckBefore = AppDateUtils.normalizeDate(checkBefore);
      query.where((tbl) => tbl.needCheckDate.isSmallerOrEqualValue(normCheckBefore));
    }

    return query.watch();
  }

  /// Gets all notes.
  Future<List<Note>> getAllNotes() {
    return (db.select(db.notes)..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)])).get();
  }

  /// Gets recent notes limit by [count].
  Future<List<Note>> getRecentNotes(int count) {
    return (db.select(db.notes)
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)])
          ..limit(count))
        .get();
  }

  /// Streams recent notes limit by [count].
  Stream<List<Note>> watchRecentNotes(int count) {
    return (db.select(db.notes)
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)])
          ..limit(count))
        .watch();
  }

  /// Creates a new note.
  Future<int> createNote(String title, String description, DateTime? needCheckDate) {
    return db.into(db.notes).insert(
          NotesCompanion.insert(
            title: title,
            description: description,
            createdAt: DateTime.now(),
            needCheckDate: Value(needCheckDate),
          ),
        );
  }

  /// Updates an existing note.
  Future<bool> updateNote(int id, String title, String description, DateTime? needCheckDate) {
    return (db.update(db.notes)..where((tbl) => tbl.id.equals(id))).write(
      NotesCompanion(
        title: Value(title),
        description: Value(description),
        needCheckDate: Value(needCheckDate),
      ),
    ).then((rows) => rows > 0);
  }

  /// Deletes a note by id.
  Future<bool> deleteNote(int id) {
    return (db.delete(db.notes)..where((tbl) => tbl.id.equals(id))).go().then((rows) => rows > 0);
  }
}
