
import 'package:daily/cubits/habits/habits_cubit.dart';
import 'package:daily/cubits/habits/habits_state.dart';
import 'package:daily/cubits/heatmap/heatmap_cubit.dart';
import 'package:daily/cubits/reviews/reviews_cubit.dart';
import 'package:daily/cubits/reviews/reviews_state.dart';
import 'package:daily/cubits/tasks/tasks_cubit.dart';
import 'package:daily/cubits/tasks/tasks_state.dart';
import 'package:daily/data/database/app_database.dart';
import 'package:daily/dialogs/add_edit_task_dialog.dart';
import 'package:daily/utils/app_hints.dart';
import 'package:daily/utils/app_theme.dart';
import 'package:daily/utils/date_utils.dart';
import 'package:daily/utils/service_locator.dart';
import 'package:daily/widgets/task_card.dart';
import 'package:daily/widgets/tasks_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DayScreenBottomSheet extends StatefulWidget {
  final DateTime date;
  final HeatmapCubit heatmapCubit;

  const DayScreenBottomSheet({
    super.key,
    required this.date,
    required this.heatmapCubit,
  });

  static void show(BuildContext context, DateTime date) {
    final heatmapCubit = context.read<HeatmapCubit>();
    final targetDate = AppDateUtils.normalizeDate(date);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider<TasksCubit>(
            create: (_) => getIt<TasksCubit>()
              ..loadTasksForDate(targetDate),
          ),
          BlocProvider<HabitsCubit>(
            create: (_) => getIt<HabitsCubit>()
              ..loadHabits(targetDate),
          ),
          BlocProvider<ReviewsCubit>(
            create: (_) => getIt<ReviewsCubit>()
              ..loadReviewForDate(targetDate),
          ),
        ],
        child: DayScreenBottomSheet(
          date: targetDate,
          heatmapCubit: heatmapCubit,
        ),
      ),
    );
  }

  @override
  State<DayScreenBottomSheet> createState() =>
      _DayScreenBottomSheetState();
}

class _DayScreenBottomSheetState
    extends State<DayScreenBottomSheet> {
  bool _isEditingReview = false;
  bool _isSavingReview = false;

  late final TextEditingController _reviewController;
  int _reviewRating = 5;

  @override
  void initState() {
    super.initState();
    _reviewController = TextEditingController();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  double _calculateCompletionPercentage({
    required List<Task> tasks,
    required List<Habit> habits,
    required Map<int, bool> habitCompletions,
  }) {
    final totalItems = tasks.length + habits.length;

    if (totalItems == 0) return 0;

    final completedTasks =
        tasks.where((task) => task.isCompleted).length;

    final completedHabits = habits
        .where((habit) => habitCompletions[habit.id] == true)
        .length;

    return (completedTasks + completedHabits) /
        totalItems *
        100;
  }

  Future<void> _saveReview() async {
    if (_isSavingReview) return;

    if (!AppDateUtils.isSameDay(
      widget.date,
      AppDateUtils.today,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Отзыв можно редактировать только за сегодняшний день!',
          ),
        ),
      );
      return;
    }

    setState(() => _isSavingReview = true);

    try {
      await context.read<ReviewsCubit>().saveReview(
        widget.date,
        _reviewController.text.trim(),
        _reviewRating,
      );

      if (!mounted) return;

      // ReviewsCubit currently catches its own errors, so a successful
      // return from saveReview does not necessarily mean it was saved.
      // The ReviewsBlocBuilder below remains responsible for displaying
      // the latest state.
      setState(() => _isEditingReview = false);

      await widget.heatmapCubit.loadHeatmapData();
    } finally {
      if (mounted) {
        setState(() => _isSavingReview = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isToday = AppDateUtils.isSameDay(
      widget.date,
      AppDateUtils.today,
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Material(
          color: Colors.transparent,
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            child: ListView(
              controller: scrollController,
              children: [
                // Handle indicator
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Date header
                Text(
                  AppDateUtils.formatDateFullHeader(
                    widget.date,
                  ),
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 12),

                // Daily review
                BlocConsumer<ReviewsCubit, ReviewsState>(
                  listener: (context, state) {
                    if (state is ReviewsLoaded &&
                        !_isEditingReview &&
                        state.review != null) {
                      _reviewController.text =
                          state.review!.description;
                      _reviewRating = state.review!.rating;
                    }
                  },
                  builder: (context, state) {
                    if (state is ReviewsLoading ||
                        state is ReviewsInitial) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (state is ReviewsError) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(state.message),
                        ),
                      );
                    }

                    if (state is! ReviewsLoaded) {
                      return const SizedBox.shrink();
                    }

                    final review = state.review;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        vertical: 2,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Дневной отзыв',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                if (isToday && !_isEditingReview)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      size: 20,
                                      color: AppColors.primary,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isEditingReview = true;
                                        _reviewController.text =
                                            review?.description ?? '';
                                        _reviewRating =
                                            review?.rating ?? 5;
                                      });
                                    },
                                  ),
                              ],
                            ),
                            if (_isEditingReview) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    'Оценка (1-10): $_reviewRating',
                                  ),
                                  Expanded(
                                    child: Slider(
                                      value: _reviewRating
                                          .toDouble(),
                                      min: 1,
                                      max: 10,
                                      divisions: 9,
                                      activeColor:
                                      AppColors.primary,
                                      onChanged: (value) {
                                        setState(() {
                                          _reviewRating =
                                              value.round();
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              TextField(
                                controller: _reviewController,
                                maxLines: 2,
                                decoration:
                                const InputDecoration(
                                  hintText:
                                  'Как прошёл ваш день?',
                                ),
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment:
                                Alignment.centerRight,
                                child: ElevatedButton(
                                  onPressed: _isSavingReview
                                      ? null
                                      : _saveReview,
                                  style:
                                  ElevatedButton.styleFrom(
                                    backgroundColor:
                                    AppColors.primary,
                                    foregroundColor: Colors.black,
                                  ),
                                  child: _isSavingReview
                                      ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child:
                                    CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                      : const Text('Сохранить'),
                                ),
                              ),
                            ] else ...[
                              const SizedBox(height: 4),
                              if (review != null) ...[
                                Text(
                                  'Рейтинг: ${review.rating} / 10',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  review.description,
                                  style: const TextStyle(
                                    color:
                                    AppColors.textSecondary,
                                  ),
                                ),
                              ] else
                                const Text(
                                  'Отзыв за этот день отсутствует.',
                                  style: TextStyle(
                                    color:
                                    AppColors.textSecondary,
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 8),

                // Completion progress
                BlocBuilder<TasksCubit, TasksState>(
                  builder: (context, tasksState) {
                    return BlocBuilder<HabitsCubit, HabitsState>(
                      builder: (context, habitsState) {
                        if (tasksState is TasksError) {
                          return Text(tasksState.message);
                        }

                        if (habitsState is HabitsError) {
                          return Text(habitsState.message);
                        }

                        if (tasksState is! TasksLoaded ||
                            habitsState is! HabitsLoaded) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final completionPct =
                        _calculateCompletionPercentage(
                          tasks: tasksState.todayTasks,
                          habits: habitsState.activeHabits,
                          habitCompletions:
                          habitsState.todayCompletions,
                        );

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            vertical: 2,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Выполнено задач и привычек: '
                                      '${completionPct.toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: completionPct / 100,
                                  backgroundColor:
                                  Colors.grey[800],
                                  color: AppColors.primary,
                                  minHeight: 8,
                                  borderRadius:
                                  BorderRadius.circular(4),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 16),


                // Tasks
                const Text(
                  'Задачи',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                TasksList(
                  date: widget.date,
                  heatmapCubit: widget.heatmapCubit,
                  onLockedTap: () {
                    AppHints.showPastDayHint(context);
                  },
                  onEditTask: (dialogContext, task) {
                    AddEditTaskDialog.show(
                      dialogContext,
                      task: task,
                      initialDate: widget.date,
                      onSaved: () async {
                        if (!dialogContext.mounted) return;

                        dialogContext
                            .read<TasksCubit>()
                            .loadTasksForDate(widget.date);

                        await widget.heatmapCubit.loadHeatmapData();
                      },
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Habits
                const Text(
                  'Привычки',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                BlocBuilder<HabitsCubit, HabitsState>(
                  builder: (context, state) {
                    if (state is HabitsError) {
                      return Text(state.message);
                    }

                    if (state is! HabitsLoaded) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final habits = state.activeHabits;
                    final completions =
                        state.todayCompletions;

                    if (habits.isEmpty) {
                      return const Text(
                        'Активных привычек на эту дату не было.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                        ),
                      );
                    }

                    return Column(
                      children: habits.map((habit) {
                        final isCompleted =
                            completions[habit.id] ?? false;

                        return CheckboxListTile(
                          title: Text(
                            habit.title,
                            style: TextStyle(
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          subtitle: habit.description != null
                              ? Text(habit.description!)
                              : null,
                          value: isCompleted,
                          activeColor: AppColors.primary,
                          checkColor: Colors.transparent,
                          onChanged: (value) async {
                            final targetDate =
                            AppDateUtils.normalizeDate(
                              widget.date,
                            );

                            if (targetDate.isBefore(
                              AppDateUtils.today,
                            )) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Нельзя изменять задачи и привычки за прошлые дни',
                                  ),
                                ),
                              );
                              return;
                            }

                            await context
                                .read<HabitsCubit>()
                                .toggleCompletion(
                              habit.id,
                              targetDate,
                              value ?? false,
                            );

                            await widget.heatmapCubit
                                .loadHeatmapData();
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
