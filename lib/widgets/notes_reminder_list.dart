
import 'package:daily/cubits/notes/notes_cubit.dart';
import 'package:daily/cubits/notes/notes_state.dart';
import 'package:daily/data/database/app_database.dart';
import 'package:daily/utils/app_theme.dart';
import 'package:daily/utils/date_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NotesReminderList extends StatelessWidget {
  const NotesReminderList({
    required this.date,
    required this.onAdd,
    this.showHeader = true,
    super.key,
  });

  final DateTime date;
  final VoidCallback onAdd;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotesCubit, NotesState>(
      builder: (context, state) {
        final reminders = state is NotesLoaded
            ? state.notes.where((note) {
          return AppDateUtils.isSameDay(
            note.needCheckDate,
            date,
          );
        }).toList()
            : <Note>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeader)
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Заметки с напоминанием',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onAdd,
                    tooltip: 'Добавить заметку',
                    icon: const Icon(
                      Icons.add_circle,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              )
            else
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: onAdd,
                  tooltip: 'Добавить заметку',
                  icon: const Icon(
                    Icons.add_circle,
                    color: AppColors.primary,
                  ),
                ),
              ),
            if (state is NotesLoading || state is NotesInitial)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state is NotesError)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  state.message,
                  style: const TextStyle(color: AppColors.error),
                ),
              )
            else if (reminders.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'На эту дату напоминаний нет.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              else
                ...reminders.map(
                      (note) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.notifications_active_outlined,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      note.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      note.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    trailing: Text(
                      TimeOfDay.fromDateTime(note.needCheckDate!).format(context),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }
}
