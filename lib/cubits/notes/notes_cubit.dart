import 'dart:async';

import 'package:daily/cubits/notes/notes_state.dart';
import 'package:daily/data/repositories/notes_repository.dart';
import 'package:daily/utils/notification_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NotesCubit extends Cubit<NotesState> {
  final NotesRepository repository;
  final NotificationService notificationService;
  StreamSubscription? _notesSub;
  StreamSubscription? _recentSub;

  DateTime? _createdAfter;
  DateTime? _createdBefore;
  bool? _hasNeedCheckDate;
  DateTime? _checkAfter;
  DateTime? _checkBefore;
  bool _sortByReminder = false;

  NotesCubit(this.repository, this.notificationService) : super(NotesInitial());

  /// Loads notes with optional filters and sorting.
  void loadNotes({
    DateTime? createdAfter,
    DateTime? createdBefore,
    bool? hasNeedCheckDate,
    DateTime? checkAfter,
    DateTime? checkBefore,
    bool? sortByReminder,
  }) {
    _createdAfter = createdAfter ?? _createdAfter;
    _createdBefore = createdBefore ?? _createdBefore;
    _hasNeedCheckDate = hasNeedCheckDate ?? _hasNeedCheckDate;
    _checkAfter = checkAfter ?? _checkAfter;
    _checkBefore = checkBefore ?? _checkBefore;
    if (sortByReminder != null) {
      _sortByReminder = sortByReminder;
    }

    emit(NotesLoading());
    _subscribe();
  }

  void toggleSort() {
    _sortByReminder = !_sortByReminder;
    loadNotes();
  }

  void _subscribe() {
    _notesSub?.cancel();
    _recentSub?.cancel();

    _recentSub = repository.watchRecentNotes(3).listen((recent) {
      _notesSub?.cancel();
      _notesSub = repository.watchNotes(
        createdAfter: _createdAfter,
        createdBefore: _createdBefore,
        hasNeedCheckDate: _hasNeedCheckDate,
        checkAfter: _checkAfter,
        checkBefore: _checkBefore,
        sortByReminder: _sortByReminder,
      ).listen((notes) {
        emit(NotesLoaded(
          notes: notes,
          recentNotes: recent,
          createdAfter: _createdAfter,
          createdBefore: _createdBefore,
          hasNeedCheckDate: _hasNeedCheckDate,
          checkAfter: _checkAfter,
          checkBefore: _checkBefore,
          sortByReminder: _sortByReminder,
        ));
      }, onError: (e) {
        emit(NotesError('Ошибка загрузки заметок: $e'));
      });
    }, onError: (e) {
      emit(NotesError('Ошибка загрузки последних заметок: $e'));
    });
  }

  void clearFilters() {
    _createdAfter = null;
    _createdBefore = null;
    _hasNeedCheckDate = null;
    _checkAfter = null;
    _checkBefore = null;
    loadNotes();
  }

  Future<void> createNote(String title, String description, DateTime? needCheckDate) async {
    try {
      final noteId = await repository.createNote(title, description, needCheckDate);
      if (needCheckDate != null) {
        await notificationService.scheduleNoteNotification(
          noteId: noteId,
          title: 'Напоминание: $title',
          body: description,
          scheduledDate: needCheckDate,
        );
      }
    } catch (e) {
      emit(NotesError('Не удалось создать заметку: $e'));
    }
  }

  Future<void> updateNote(int id, String title, String description, DateTime? needCheckDate) async {
    try {
      await repository.updateNote(id, title, description, needCheckDate);
      await notificationService.cancelNoteNotification(id);
      if (needCheckDate != null) {
        await notificationService.scheduleNoteNotification(
          noteId: id,
          title: 'Напоминание: $title',
          body: description,
          scheduledDate: needCheckDate,
        );
      }
    } catch (e) {
      emit(NotesError('Не удалось обновить заметку: $e'));
    }
  }

  Future<void> deleteNote(int id) async {
    try {
      await repository.deleteNote(id);
      await notificationService.cancelNoteNotification(id);
    } catch (e) {
      emit(NotesError('Не удалось удалить заметку: $e'));
    }
  }

  @override
  Future<void> close() {
    _notesSub?.cancel();
    _recentSub?.cancel();
    return super.close();
  }
}
