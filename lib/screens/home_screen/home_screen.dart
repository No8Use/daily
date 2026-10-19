import 'package:contribution_heatmap/contribution_heatmap.dart';
import 'package:daily/cubits/habits/habits_cubit.dart';
import 'package:daily/cubits/habits/habits_state.dart';
import 'package:daily/cubits/heatmap/heatmap_cubit.dart';
import 'package:daily/cubits/heatmap/heatmap_state.dart';
import 'package:daily/cubits/notes/notes_cubit.dart';
import 'package:daily/cubits/notes/notes_state.dart';
import 'package:daily/cubits/reviews/reviews_cubit.dart';
import 'package:daily/cubits/reviews/reviews_state.dart';
import 'package:daily/cubits/tasks/tasks_cubit.dart';
import 'package:daily/cubits/tasks/tasks_state.dart';
import 'package:daily/screens/day_screen/day_screen.dart';
import 'package:daily/screens/habits_screen/habits_screen.dart';
import 'package:daily/screens/notes_screen/notes_screen.dart';
import 'package:daily/utils/app_theme.dart';
import 'package:daily/utils/backup_service.dart';
import 'package:daily/utils/date_utils.dart';
import 'package:daily/utils/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HeatmapCubit _heatmapCubit;
  late final TasksCubit _tasksCubit;
  late final HabitsCubit _habitsCubit;
  late final NotesCubit _notesCubit;
  late final ReviewsCubit _reviewsCubit;

  @override
  void initState() {
    super.initState();
    _heatmapCubit = getIt<HeatmapCubit>()..loadHeatmapData();
    _tasksCubit = getIt<TasksCubit>()..loadTasksForDate(AppDateUtils.today);
    _habitsCubit = getIt<HabitsCubit>()..loadHabits();
    _notesCubit = getIt<NotesCubit>()..loadNotes();
    _reviewsCubit = getIt<ReviewsCubit>()..loadReviewForDate(AppDateUtils.today);
  }

  @override
  void dispose() {
    _heatmapCubit.close();
    _tasksCubit.close();
    _habitsCubit.close();
    _notesCubit.close();
    _reviewsCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<HeatmapCubit>.value(value: _heatmapCubit),
        BlocProvider<TasksCubit>.value(value: _tasksCubit),
        BlocProvider<HabitsCubit>.value(value: _habitsCubit),
        BlocProvider<NotesCubit>.value(value: _notesCubit),
        BlocProvider<ReviewsCubit>.value(value: _reviewsCubit),
      ],
      child: const HomeView(),
    );
  }
}

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  bool _isTasksExpanded = true;
  bool _isHabitsExpanded = true;

  // Review editing state
  bool _isEditingReview = false;
  late TextEditingController _reviewDescController;
  int _reviewRating = 5;
  late final ScrollController _heatmapScrollController;

  @override
  void initState() {
    super.initState();
    _reviewDescController = TextEditingController();
    _heatmapScrollController = ScrollController();
  }

  @override
  void dispose() {
    _reviewDescController.dispose();
    _heatmapScrollController.dispose();
    super.dispose();
  }

  void _reloadAllCubits(BuildContext context) {
    context.read<HeatmapCubit>().loadHeatmapData();
    context.read<TasksCubit>().loadTasksForDate(AppDateUtils.today);
    context.read<HabitsCubit>().loadHabits();
    context.read<NotesCubit>().loadNotes();
    context.read<ReviewsCubit>().loadReviewForDate(AppDateUtils.today);
    setState(() {
      _isEditingReview = false;
    });
  }

  Future<void> _handleExport(BuildContext context) async {
    try {
      await getIt<BackupService>().exportData();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка экспорта: $e')),
        );
      }
    }
  }

  Future<void> _handleImport(BuildContext context) async {
    try {
      final backupData = await getIt<BackupService>().pickBackupFile();
      if (backupData == null) return;

      if (!context.mounted) return;

      final mode = await showDialog<ImportMode>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Режим импорта'),
            content: const Text(
              'Выберите способ импорта данных:\n\n'
              '• Объединить (Merge): добавить/обновить существующие записи.\n'
              '• Заменить (Replace): полностью очистить базу данных перед импортом.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, ImportMode.merge),
                child: const Text('Объединить'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, ImportMode.replace),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Заменить'),
              ),
            ],
          );
        },
      );

      if (mode != null && context.mounted) {
        await getIt<BackupService>().importData(backupData, mode);
        if (context.mounted) {
          _reloadAllCubits(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Данные успешно импортированы!')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка импорта: $e')),
        );
      }
    }
  }

  void _showAddTaskDialog(BuildContext parentContext) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    DateTime selectedDueDate = AppDateUtils.today;

    showDialog(
      context: parentContext,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Новая задача на сегодня'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      autofocus: true,
                      decoration: const InputDecoration(labelText: 'Название задачи'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      minLines: 1,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Описание (опционально)'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Дата: ${AppDateUtils.formatDateDisplay(selectedDueDate)}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.calendar_month, color: AppColors.primary),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDueDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setDialogState(() => selectedDueDate = picked);
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
                    final desc = descController.text.trim().isEmpty ? null : descController.text.trim();
                    if (title.isNotEmpty) {
                      parentContext.read<TasksCubit>().createTask(title, desc, selectedDueDate);
                      parentContext.read<HeatmapCubit>().loadHeatmapData();
                      Navigator.pop(dialogContext);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Создать'),
                ),
              ],
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
        title: const Text('Daily', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'export') {
                _handleExport(context);
              } else if (value == 'import') {
                _handleImport(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.upload, size: 20, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Экспорт данных'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.download, size: 20, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Импорт данных'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _reloadAllCubits(context),
        child: ListView(
          padding: const EdgeInsets.all(8),
          children: [
            // ================= 1. HEATMAP SECTION =================
            BlocBuilder<HeatmapCubit, HeatmapState>(
              builder: (context, state) {
                if (state is HeatmapLoading) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }

                if (state is HeatmapLoaded) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_heatmapScrollController.hasClients) {
                      _heatmapScrollController.jumpTo(_heatmapScrollController.position.maxScrollExtent);
                    }
                  });

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: SegmentedButton<HeatmapMode>(
                              segments: const [
                                ButtonSegment(
                                  value: HeatmapMode.habitsOnly,
                                  label: Text('Только привычки'),
                                ),
                                ButtonSegment(
                                  value: HeatmapMode.allTasks,
                                  label: Text('Все задачи'),
                                ),
                              ],
                              selected: {state.mode},
                              onSelectionChanged: (newSelection) {
                                context.read<HeatmapCubit>().setMode(newSelection.first);
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            controller: _heatmapScrollController,
                            scrollDirection: Axis.horizontal,
                            child: ContributionHeatmap(
                              entries: state.entries,
                              minDate: state.minDate,
                              maxDate: state.maxDate,
                              cellSize: 12,
                              cellSpacing: 3,
                              cellRadius: 2,
                              heatmapColor: HeatmapColor.green,
                              weekdayLabel: WeekdayLabel.none,
                              onCellTap: (date, value) {
                                DayScreenBottomSheet.show(context, date);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),

            const SizedBox(height: 8),

            // ================= 2. TASKS SECTION =================
            BlocBuilder<TasksCubit, TasksState>(
              builder: (context, state) {
                return Card(
                  child: Column(
                    children: [
                      ListTile(
                        title: Row(
                          children: [
                            const Text('Задачи на сегодня',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.add_circle, color: AppColors.primary),
                              onPressed: () => _showAddTaskDialog(context),
                            ),
                            IconButton(
                              icon: Icon(_isTasksExpanded ? Icons.expand_less : Icons.expand_more),
                              onPressed: () {
                                setState(() => _isTasksExpanded = !_isTasksExpanded);
                              },
                            ),
                          ],
                        ),
                      ),
                      if (_isTasksExpanded) ...[
                        if (state is TasksLoading)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          )
                        else if (state is TasksLoaded) ...[
                          if (state.todayTasks.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('На сегодня задач нет.', style: TextStyle(color: AppColors.textSecondary)),
                            )
                          else
                            ...state.todayTasks.map((task) => CheckboxListTile(
                                  title: Text(
                                    task.title,
                                    style: TextStyle(
                                      decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                  subtitle: task.description != null ? Text(task.description!) : null,
                                  value: task.isCompleted,
                                  activeColor: AppColors.primary,
                                  checkColor: Colors.transparent,
                                  onChanged: (val) {
                                    context.read<TasksCubit>().toggleTask(task.id, task.isCompleted);
                                  },
                                )),
                        ],
                        const SizedBox(height: 4),
                      ],
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 8),

            // ================= 3. HABITS SECTION =================
            BlocBuilder<HabitsCubit, HabitsState>(
              builder: (context, state) {
                return Card(
                  child: Column(
                    children: [
                      ListTile(
                        title: Row(
                          children: [
                            const Text('Привычки на сегодня',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.add_circle, color: AppColors.primary),
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const HabitsScreen()),
                                );
                                if (context.mounted) {
                                  _reloadAllCubits(context);
                                }
                              },
                            ),
                            IconButton(
                              icon: Icon(_isHabitsExpanded ? Icons.expand_less : Icons.expand_more),
                              onPressed: () {
                                setState(() => _isHabitsExpanded = !_isHabitsExpanded);
                              },
                            ),
                          ],
                        ),
                      ),
                      if (_isHabitsExpanded) ...[
                        if (state is HabitsLoading)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          )
                        else if (state is HabitsLoaded) ...[
                          if (state.activeHabits.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('Активных привычек нет.', style: TextStyle(color: AppColors.textSecondary)),
                            )
                          else
                            ...state.activeHabits.map((habit) {
                              final isCompleted = state.todayCompletions[habit.id] ?? false;
                              return CheckboxListTile(
                                title: Text(
                                  habit.title,
                                  style: TextStyle(
                                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                                value: isCompleted,
                                activeColor: AppColors.primary,
                                checkColor: Colors.transparent,
                                onChanged: (val) {
                                  context.read<HabitsCubit>().toggleCompletion(
                                        habit.id,
                                        AppDateUtils.today,
                                        val ?? false,
                                      );
                                },
                              );
                            }),
                        ],
                        const SizedBox(height: 4),
                      ],
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 8),

            // ================= 4. NOTES PREVIEW SECTION =================
            BlocBuilder<NotesCubit, NotesState>(
              builder: (context, state) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Заметки', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.add_circle, color: AppColors.primary),
                                  tooltip: 'Быстро создать заметку',
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const NotesScreen()),
                                    );
                                    if (context.mounted) {
                                      _reloadAllCubits(context);
                                    }
                                  },
                                ),
                                TextButton(
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const NotesScreen()),
                                    );
                                    if (context.mounted) {
                                      _reloadAllCubits(context);
                                    }
                                  },
                                  child: const Text('Все заметки', style: TextStyle(color: AppColors.primary)),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (state is NotesLoaded) ...[
                          if (state.recentNotes.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text('Заметок пока нет.', style: TextStyle(color: AppColors.textSecondary)),
                            )
                          else
                            ...state.recentNotes.map((note) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(note.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text(
                                    note.description,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: AppColors.textSecondary),
                                  ),
                                  trailing: Text(
                                    AppDateUtils.formatDateDisplay(note.createdAt),
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                )),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 8),

            // ================= 5. DAILY REVIEW SECTION =================
            BlocBuilder<ReviewsCubit, ReviewsState>(
              builder: (context, state) {
                if (state is ReviewsLoaded) {
                  final review = state.review;
                  final showEditor = review == null || _isEditingReview;

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Дневной отзыв за сегодня',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 12),
                          if (showEditor) ...[
                            Row(
                              children: [
                                Text('Оценка дня: $_reviewRating'),
                                Expanded(
                                  child: Slider(
                                    value: _reviewRating.toDouble(),
                                    min: 1,
                                    max: 10,
                                    divisions: 9,
                                    activeColor: AppColors.primary,
                                    onChanged: (val) {
                                      setState(() => _reviewRating = val.round());
                                    },
                                  ),
                                ),
                              ],
                            ),
                            TextField(
                              controller: _reviewDescController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                hintText: 'Опишите, как прошёл ваш день...',
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () async {
                                  final desc = _reviewDescController.text.trim();
                                  await context.read<ReviewsCubit>().saveReview(
                                        AppDateUtils.today,
                                        desc,
                                        _reviewRating,
                                      );
                                  setState(() => _isEditingReview = false);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.black,
                                ),
                                child: const Text('Сохранить отзыв'),
                              ),
                            ),
                          ] else ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Оценка: ${review.rating} / 10',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary)),
                                if (state.isEditable)
                                  TextButton.icon(
                                    icon: const Icon(Icons.edit, size: 16, color: AppColors.primary),
                                    label: const Text('Редактировать', style: TextStyle(color: AppColors.primary)),
                                    onPressed: () {
                                      setState(() {
                                        _reviewRating = review.rating;
                                        _reviewDescController.text = review.description;
                                        _isEditingReview = true;
                                      });
                                    },
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(review.description,
                                style: const TextStyle(color: AppColors.textPrimary)),
                          ],
                        ],
                      ),
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}
