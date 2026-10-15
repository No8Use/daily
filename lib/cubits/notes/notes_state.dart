import 'package:daily/data/database/app_database.dart';
import 'package:equatable/equatable.dart';

abstract class NotesState extends Equatable {
  const NotesState();

  @override
  List<Object?> get props => [];
}

class NotesInitial extends NotesState {}

class NotesLoading extends NotesState {}

class NotesLoaded extends NotesState {
  final List<Note> notes;
  final List<Note> recentNotes;

  // Filter criteria
  final DateTime? createdAfter;
  final DateTime? createdBefore;
  final bool? hasNeedCheckDate;
  final DateTime? checkAfter;
  final DateTime? checkBefore;

  const NotesLoaded({
    required this.notes,
    required this.recentNotes,
    this.createdAfter,
    this.createdBefore,
    this.hasNeedCheckDate,
    this.checkAfter,
    this.checkBefore,
  });

  NotesLoaded copyWith({
    List<Note>? notes,
    List<Note>? recentNotes,
    DateTime? createdAfter,
    DateTime? createdBefore,
    bool? hasNeedCheckDate,
    DateTime? checkAfter,
    DateTime? checkBefore,
    bool clearFilters = false,
  }) {
    return NotesLoaded(
      notes: notes ?? this.notes,
      recentNotes: recentNotes ?? this.recentNotes,
      createdAfter: clearFilters ? null : (createdAfter ?? this.createdAfter),
      createdBefore: clearFilters ? null : (createdBefore ?? this.createdBefore),
      hasNeedCheckDate: clearFilters ? null : (hasNeedCheckDate ?? this.hasNeedCheckDate),
      checkAfter: clearFilters ? null : (checkAfter ?? this.checkAfter),
      checkBefore: clearFilters ? null : (checkBefore ?? this.checkBefore),
    );
  }

  @override
  List<Object?> get props => [
        notes,
        recentNotes,
        createdAfter,
        createdBefore,
        hasNeedCheckDate,
        checkAfter,
        checkBefore,
      ];
}

class NotesError extends NotesState {
  final String message;

  const NotesError(this.message);

  @override
  List<Object?> get props => [message];
}
