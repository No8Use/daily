import 'package:daily/cubits/habits/habits_cubit.dart';
import 'package:daily/cubits/habits/habits_state.dart';
import 'package:daily/data/database/app_database.dart';
import 'package:daily/utils/app_theme.dart';
import 'package:daily/utils/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HabitsScreen extends StatelessWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HabitsCubit>(
      create: (context) => getIt<HabitsCubit>()..loadHabits(),
      child: const HabitsView(),
    );
  }
}

class HabitsView extends StatelessWidget {
  const HabitsView({super.key});

  void _showAddEditDialog(BuildContext context, {Habit? habit}) {
    final titleController = TextEditingController(text: habit?.title ?? '');
    final descController = TextEditingController(text: habit?.description ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(habit == null ? 'Создать привычку' : 'Редактировать привычку'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Название'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Описание (опционально)'),
              ),
            ],
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
                  final cubit = context.read<HabitsCubit>();
                  if (habit == null) {
                    cubit.createHabit(title, desc);
                  } else {
                    cubit.updateHabit(habit.id, title, desc);
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление привычками'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(context),
        child: const Icon(Icons.add),
      ),
      body: BlocConsumer<HabitsCubit, HabitsState>(
        listener: (context, state) {
          if (state is HabitsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is HabitsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is HabitsLoaded) {
            final activeList = state.allHabits.where((h) => h.canceledAt == null).toList();
            final canceledList = state.allHabits.where((h) => h.canceledAt != null).toList();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Активные привычки',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                const SizedBox(height: 8),
                if (activeList.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('Нет активных привычек.', style: TextStyle(color: AppColors.textSecondary)),
                  )
                else
                  ...activeList.map((habit) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(habit.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: habit.description != null ? Text(habit.description!) : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                onPressed: () => _showAddEditDialog(context, habit: habit),
                              ),
                              IconButton(
                                icon: const Icon(Icons.archive, size: 20, color: Colors.orangeAccent),
                                tooltip: 'Отменить привычку',
                                onPressed: () {
                                  context.read<HabitsCubit>().cancelHabit(habit.id);
                                },
                              ),
                            ],
                          ),
                        ),
                      )),

                const SizedBox(height: 24),
                const Text(
                  'Отменённые привычки',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                if (canceledList.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('Нет отменённых привычек.', style: TextStyle(color: AppColors.textSecondary)),
                  )
                else
                  ...canceledList.map((habit) => Card(
                        color: Colors.grey[900],
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            habit.title,
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                            ),
                          ),
                          subtitle: habit.description != null
                              ? Text(habit.description!, style: const TextStyle(color: Colors.grey))
                              : null,
                          trailing: IconButton(
                            icon: const Icon(Icons.restore, color: AppColors.primary),
                            tooltip: 'Восстановить привычку',
                            onPressed: () {
                              context.read<HabitsCubit>().restoreHabit(habit.id);
                            },
                          ),
                        ),
                      )),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
