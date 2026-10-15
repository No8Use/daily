import 'package:daily/data/database/app_database.dart';
import 'package:daily/data/repositories/habits_repository.dart';
import 'package:daily/data/repositories/reviews_repository.dart';
import 'package:daily/data/repositories/tasks_repository.dart';
import 'package:daily/utils/app_theme.dart';
import 'package:daily/utils/date_utils.dart';
import 'package:daily/utils/service_locator.dart';
import 'package:flutter/material.dart';

class DayScreenBottomSheet extends StatefulWidget {
  final DateTime date;

  const DayScreenBottomSheet({super.key, required this.date});

  static void show(BuildContext context, DateTime date) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DayScreenBottomSheet(date: date),
    );
  }

  @override
  State<DayScreenBottomSheet> createState() => _DayScreenBottomSheetState();
}

class _DayScreenBottomSheetState extends State<DayScreenBottomSheet> {
  final _reviewsRepo = getIt<ReviewsRepository>();
  final _tasksRepo = getIt<TasksRepository>();
  final _habitsRepo = getIt<HabitsRepository>();

  DailyReview? _review;
  List<Task> _tasks = [];
  List<Habit> _activeHabits = [];
  Map<int, bool> _habitCompletions = {};
  bool _isLoading = true;

  // Review editing state
  bool _isEditingReview = false;
  late TextEditingController _reviewController;
  int _reviewRating = 5;

  @override
  void initState() {
    super.initState();
    _reviewController = TextEditingController();
    _loadData();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final review = await _reviewsRepo.getReviewForDate(widget.date);
    final tasks = await _tasksRepo.getTasksForDate(widget.date);
    final allHabits = await _habitsRepo.watchAllHabits().first;
    final completions = await _habitsRepo.getCompletionsForDate(widget.date);

    // Active habits on widget.date: created <= date && (canceledAt == null || canceledAt > date)
    final activeOnDate = allHabits.where((h) {
      final isCreated = AppDateUtils.normalizeDate(h.createdAt).isBefore(widget.date) ||
          AppDateUtils.isSameDay(h.createdAt, widget.date);
      final isNotCanceled = h.canceledAt == null ||
          AppDateUtils.normalizeDate(h.canceledAt!).isAfter(widget.date);
      return isCreated && isNotCanceled;
    }).toList();

    final completionsMap = <int, bool>{};
    for (final c in completions) {
      completionsMap[c.habitId] = c.isCompleted;
    }

    if (review != null) {
      _reviewController.text = review.description;
      _reviewRating = review.rating;
    }

    if (mounted) {
      setState(() {
        _review = review;
        _tasks = tasks;
        _activeHabits = activeOnDate;
        _habitCompletions = completionsMap;
        _isLoading = false;
      });
    }
  }

  double _calculateCompletionPercentage() {
    int totalItems = _tasks.length + _activeHabits.length;
    if (totalItems == 0) return 0.0;

    int completedCount = 0;
    for (final task in _tasks) {
      if (task.isCompleted) completedCount++;
    }
    for (final habit in _activeHabits) {
      if (_habitCompletions[habit.id] == true) completedCount++;
    }

    return (completedCount / totalItems) * 100;
  }

  Future<void> _saveReview() async {
    if (!AppDateUtils.isSameDay(widget.date, AppDateUtils.today)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Отзыв можно редактировать только за сегодняшний день!')),
      );
      return;
    }

    try {
      await _reviewsRepo.saveReview(widget.date, _reviewController.text.trim(), _reviewRating);
      setState(() => _isEditingReview = false);
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сохранения отзыва: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isToday = AppDateUtils.isSameDay(widget.date, AppDateUtils.today);
    final completionPct = _calculateCompletionPercentage();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
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

                    // Date Header
                    Text(
                      AppDateUtils.formatDateFullHeader(widget.date),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 12),

                    // Daily Review Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Дневной отзыв',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                if (isToday && !_isEditingReview)
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20, color: AppColors.primary),
                                    onPressed: () => setState(() => _isEditingReview = true),
                                  ),
                              ],
                            ),
                            if (_isEditingReview) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text('Оценка (1-10): $_reviewRating'),
                                  Expanded(
                                    child: Slider(
                                      value: _reviewRating.toDouble(),
                                      min: 1,
                                      max: 10,
                                      divisions: 9,
                                      activeColor: AppColors.primary,
                                      onChanged: (val) =>
                                          setState(() => _reviewRating = val.round()),
                                    ),
                                  ),
                                ],
                              ),
                              TextField(
                                controller: _reviewController,
                                maxLines: 2,
                                decoration: const InputDecoration(
                                  hintText: 'Как прошёл ваш день?',
                                ),
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton(
                                  onPressed: _saveReview,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.black,
                                  ),
                                  child: const Text('Сохранить'),
                                ),
                              ),
                            ] else ...[
                              const SizedBox(height: 4),
                              if (_review != null) ...[
                                Text('Рейтинг: ${_review!.rating} / 10',
                                    style: const TextStyle(color: AppColors.primary)),
                                const SizedBox(height: 4),
                                Text(_review!.description,
                                    style: const TextStyle(color: AppColors.textSecondary)),
                              ] else
                                const Text('Отзыв за этот день отсутствует.',
                                    style: TextStyle(color: AppColors.textSecondary)),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Completion progress bar
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Выполнено задач и привычек: ${completionPct.toStringAsFixed(0)}%',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: completionPct / 100,
                              backgroundColor: Colors.grey[800],
                              color: AppColors.primary,
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tasks Section
                    const Text('Задачи',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (_tasks.isEmpty)
                      const Text('Задач на эту дату не было.',
                          style: TextStyle(color: AppColors.textSecondary))
                    else
                      ..._tasks.map((task) => CheckboxListTile(
                            title: Text(task.title,
                                style: TextStyle(
                                  decoration: task.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                )),
                            subtitle: task.description != null ? Text(task.description!) : null,
                            value: task.isCompleted,
                            activeColor: AppColors.primary,
                            checkColor: Colors.black,
                            onChanged: (val) async {
                              await _tasksRepo.toggleTaskCompletion(task.id, val ?? false);
                              _loadData();
                            },
                          )),
                    const SizedBox(height: 16),

                    // Habits Section
                    const Text('Привычки',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (_activeHabits.isEmpty)
                      const Text('Активных привычек на эту дату не было.',
                          style: TextStyle(color: AppColors.textSecondary))
                    else
                      ..._activeHabits.map((habit) {
                        final isCompleted = _habitCompletions[habit.id] ?? false;
                        return CheckboxListTile(
                          title: Text(habit.title,
                              style: TextStyle(
                                decoration: isCompleted ? TextDecoration.lineThrough : null,
                              )),
                          subtitle:
                              habit.description != null ? Text(habit.description!) : null,
                          value: isCompleted,
                          activeColor: AppColors.primary,
                          checkColor: Colors.black,
                          onChanged: (val) async {
                            await _habitsRepo.toggleHabitCompletion(
                              habit.id,
                              widget.date,
                              val ?? false,
                            );
                            _loadData();
                          },
                        );
                      }),
                  ],
                ),
        );
      },
    );
  }
}
