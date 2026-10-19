import 'package:daily/cubits/notes/notes_cubit.dart';
import 'package:daily/cubits/notes/notes_state.dart';
import 'package:daily/data/database/app_database.dart';
import 'package:daily/utils/app_theme.dart';
import 'package:daily/utils/date_utils.dart';
import 'package:daily/utils/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NotesCubit>(
      create: (context) => getIt<NotesCubit>()..loadNotes(),
      child: const NotesView(),
    );
  }
}

class NotesView extends StatefulWidget {
  const NotesView({super.key});

  @override
  State<NotesView> createState() => _NotesViewState();
}

class _NotesViewState extends State<NotesView> {
  DateTime? _filterCreatedAfter;
  DateTime? _filterCreatedBefore;
  bool? _filterHasCheckDate;

  void _showAddEditDialog(BuildContext context, {Note? note}) {
    final titleController = TextEditingController(text: note?.title ?? '');
    final descController = TextEditingController(text: note?.description ?? '');
    DateTime? needCheckDate = note?.needCheckDate;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(note == null ? 'Новая заметка' : 'Редактировать заметку'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Заголовок'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: 'Текст заметки'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            needCheckDate == null
                                ? 'Дата напоминания: не задана'
                                : 'Напоминание: ${AppDateUtils.formatDateDisplay(needCheckDate!)}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            needCheckDate == null ? Icons.event_available : Icons.event_busy,
                            color: AppColors.primary,
                          ),
                          onPressed: () async {
                            if (needCheckDate != null) {
                              setDialogState(() => needCheckDate = null);
                            } else {
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now().add(const Duration(days: 1)),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (pickedDate != null && context.mounted) {
                                final pickedTime = await showTimePicker(
                                  context: context,
                                  initialTime: const TimeOfDay(hour: 9, minute: 0),
                                );
                                if (pickedTime != null) {
                                  setDialogState(() {
                                    needCheckDate = DateTime(
                                      pickedDate.year,
                                      pickedDate.month,
                                      pickedDate.day,
                                      pickedTime.hour,
                                      pickedTime.minute,
                                    );
                                  });
                                }
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Отмена'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final title = titleController.text.trim();
                    final desc = descController.text.trim();

                    if (title.isNotEmpty) {
                      final cubit = context.read<NotesCubit>();
                      if (note == null) {
                        cubit.createNote(title, desc, needCheckDate);
                      } else {
                        cubit.updateNote(note.id, title, desc, needCheckDate);
                      }
                      Navigator.pop(dialogContext);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Сохранить'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Фильтры заметок',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Напоминание:'),
                      const SizedBox(width: 12),
                      DropdownButton<bool?>(
                        value: _filterHasCheckDate,
                        items: const [
                          DropdownMenuItem(value: null, child: Text('Все')),
                          DropdownMenuItem(value: true, child: Text('Есть напоминание')),
                          DropdownMenuItem(value: false, child: Text('Без напоминания')),
                        ],
                        onChanged: (val) {
                          setSheetState(() => _filterHasCheckDate = val);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(_filterCreatedAfter == null
                            ? 'Дата создания с: Все'
                            : 'С: ${AppDateUtils.formatDateDisplay(_filterCreatedAfter!)}'),
                      ),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setSheetState(() => _filterCreatedAfter = picked);
                          }
                        },
                        child: const Text('Выбрать'),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _filterCreatedAfter = null;
                            _filterCreatedBefore = null;
                            _filterHasCheckDate = null;
                          });
                          context.read<NotesCubit>().clearFilters();
                          Navigator.pop(sheetContext);
                        },
                        child: const Text('Сбросить'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {});
                          context.read<NotesCubit>().loadNotes(
                                createdAfter: _filterCreatedAfter,
                                createdBefore: _filterCreatedBefore,
                                hasNeedCheckDate: _filterHasCheckDate,
                              );
                          Navigator.pop(sheetContext);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('Применить'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Заметки'),
        actions: [
          BlocBuilder<NotesCubit, NotesState>(
            builder: (context, state) {
              final sortByReminder = state is NotesLoaded && state.sortByReminder;
              return IconButton(
                icon: Icon(
                  sortByReminder ? Icons.event : Icons.access_time,
                  color: AppColors.primary,
                ),
                tooltip: sortByReminder ? 'Сортировка: по дате напоминания' : 'Сортировка: по дате создания',
                onPressed: () {
                  context.read<NotesCubit>().toggleSort();
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(context),
        child: const Icon(Icons.add),
      ),
      body: BlocConsumer<NotesCubit, NotesState>(
        listener: (context, state) {
          if (state is NotesError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is NotesLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is NotesLoaded) {
            if (state.notes.isEmpty) {
              return const Center(
                child: Text('Заметок пока нет.', style: TextStyle(color: AppColors.textSecondary)),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.notes.length,
              itemBuilder: (context, index) {
                final note = state.notes[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(note.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          note.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              'Создано: ${AppDateUtils.formatDateDisplay(note.createdAt)}',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                            if (note.needCheckDate != null) ...[
                              const Spacer(),
                              const Icon(Icons.notifications_active, size: 14, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(
                                AppDateUtils.formatDateDisplay(note.needCheckDate!),
                                style: const TextStyle(fontSize: 11, color: AppColors.primary),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (val) {
                        if (val == 'edit') {
                          _showAddEditDialog(context, note: note);
                        } else if (val == 'delete') {
                          context.read<NotesCubit>().deleteNote(note.id);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Редактировать')),
                        const PopupMenuItem(value: 'delete', child: Text('Удалить', style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  ),
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
