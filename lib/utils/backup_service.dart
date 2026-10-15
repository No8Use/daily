import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:daily/data/database/app_database.dart';
import 'package:daily/utils/date_utils.dart';
import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

enum ImportMode { merge, replace }

class BackupService {
  BackupService(this.db);

  final AppDatabase db;

  /// Exports the database to JSON and opens the system save dialog.
  Future<void> exportData() async {
    final habits = await db.select(db.habits).get();
    final completions = await db.select(db.habitCompletions).get();
    final tasks = await db.select(db.tasks).get();
    final notes = await db.select(db.notes).get();
    final reviews = await db.select(db.dailyReviews).get();

    final exportJson = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'habits': habits
          .map((h) => {
        'id': h.id,
        'title': h.title,
        'description': h.description,
        'createdAt': h.createdAt.toIso8601String(),
        'canceledAt': h.canceledAt?.toIso8601String(),
      })
          .toList(),
      'habitCompletions': completions
          .map((c) => {
        'id': c.id,
        'habitId': c.habitId,
        'date': AppDateUtils.toIsoDateString(c.date),
        'isCompleted': c.isCompleted,
      })
          .toList(),
      'tasks': tasks
          .map((t) => {
        'id': t.id,
        'title': t.title,
        'description': t.description,
        'createdAt': t.createdAt.toIso8601String(),
        'dueDate': t.dueDate == null
            ? null
            : AppDateUtils.toIsoDateString(t.dueDate!),
        'isCompleted': t.isCompleted,
      })
          .toList(),
      'notes': notes
          .map((n) => {
        'id': n.id,
        'title': n.title,
        'description': n.description,
        'createdAt': n.createdAt.toIso8601String(),
        'needCheckDate': n.needCheckDate?.toIso8601String(),
      })
          .toList(),
      'dailyReviews': reviews
          .map((r) => {
        'id': r.id,
        'date': AppDateUtils.toIsoDateString(r.date),
        'description': r.description,
        'rating': r.rating,
      })
          .toList(),
    };

    final timestamp = DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now());
    final fileName = 'daily_backup_$timestamp.json';
    final jsonString = const JsonEncoder.withIndent('  ').convert(exportJson);

    await FilePicker.saveFile(
      dialogTitle: 'Сохранить резервную копию Daily',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['json'],
      bytes: Uint8List.fromList(utf8.encode(jsonString)),
    );
  }

  /// Opens a system file picker and reads a JSON backup.
  Future<Map<String, dynamic>?> pickBackupFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      // withData: true,
    );

    if (result.length != 1) {
      return null;
    }

    final pickedFile = result.single;
    final bytes = await pickedFile.readAsBytes();

    final content = utf8.decode(bytes);
    final decoded = jsonDecode(content);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'Файл резервной копии должен содержать JSON-объект.',
      );
    }

    if (decoded['version'] != 1) {
      throw FormatException(
        'Неподдерживаемая версия резервной копии: ${decoded['version']}',
      );
    }

    return decoded;
  }

  /// Imports backup data using merge or replace mode.
  Future<void> importData(
      Map<String, dynamic> data,
      ImportMode mode,
      ) async {
    await db.transaction(() async {
      if (mode == ImportMode.replace) {
        // Delete dependent records before their parent records.
        await db.delete(db.habitCompletions).go();
        await db.delete(db.habits).go();
        await db.delete(db.tasks).go();
        await db.delete(db.notes).go();
        await db.delete(db.dailyReviews).go();
      }

      final habitsList = (data['habits'] as List?) ?? [];
      for (final item in habitsList) {
        final companion = HabitsCompanion(
          id: Value(item['id'] as int),
          title: Value(item['title'] as String),
          description: Value(item['description'] as String?),
          createdAt: Value(DateTime.parse(item['createdAt'] as String)),
          canceledAt: Value(
            item['canceledAt'] == null
                ? null
                : DateTime.parse(item['canceledAt'] as String),
          ),
        );

        await db.into(db.habits).insertOnConflictUpdate(companion);
      }

      final completionsList = (data['habitCompletions'] as List?) ?? [];
      for (final item in completionsList) {
        final companion = HabitCompletionsCompanion(
          id: Value(item['id'] as int),
          habitId: Value(item['habitId'] as int),
          date: Value(
            AppDateUtils.parseIsoDateString(item['date'] as String),
          ),
          isCompleted: Value(item['isCompleted'] as bool),
        );

        await db
            .into(db.habitCompletions)
            .insertOnConflictUpdate(companion);
      }

      final tasksList = (data['tasks'] as List?) ?? [];
      for (final item in tasksList) {
        final companion = TasksCompanion(
          id: Value(item['id'] as int),
          title: Value(item['title'] as String),
          description: Value(item['description'] as String?),
          createdAt: Value(DateTime.parse(item['createdAt'] as String)),
          dueDate: Value(
            item['dueDate'] == null
                ? null
                : AppDateUtils.parseIsoDateString(
              item['dueDate'] as String,
            ),
          ),
          isCompleted: Value(item['isCompleted'] as bool),
        );

        await db.into(db.tasks).insertOnConflictUpdate(companion);
      }

      final notesList = (data['notes'] as List?) ?? [];
      for (final item in notesList) {
        final companion = NotesCompanion(
          id: Value(item['id'] as int),
          title: Value(item['title'] as String),
          description: Value(item['description'] as String),
          createdAt: Value(DateTime.parse(item['createdAt'] as String)),
          needCheckDate: Value(
            item['needCheckDate'] == null
                ? null
                : DateTime.parse(item['needCheckDate'] as String),
          ),
        );

        await db.into(db.notes).insertOnConflictUpdate(companion);
      }

      final reviewsList = (data['dailyReviews'] as List?) ?? [];
      for (final item in reviewsList) {
        final companion = DailyReviewsCompanion(
          id: Value(item['id'] as int),
          date: Value(
            AppDateUtils.parseIsoDateString(item['date'] as String),
          ),
          description: Value(item['description'] as String),
          rating: Value(item['rating'] as int),
        );

        await db.into(db.dailyReviews).insertOnConflictUpdate(companion);
      }
    });
  }
}