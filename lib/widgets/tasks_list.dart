
import 'package:daily/cubits/heatmap/heatmap_cubit.dart';
import 'package:daily/cubits/tasks/tasks_cubit.dart';
import 'package:daily/cubits/tasks/tasks_state.dart';
import 'package:daily/data/database/app_database.dart';
import 'package:daily/utils/app_theme.dart';
import 'package:daily/widgets/task_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TasksList extends StatelessWidget {
  const TasksList({
    required this.date,
    required this.heatmapCubit,
    this.onEditTask,
    this.onLockedTap,
    super.key,
  });

  final DateTime date;
  final HeatmapCubit heatmapCubit;

  /// Callback экрана, который отвечает за открытие редактора задачи.
  final void Function(BuildContext context, Task task)? onEditTask;

  /// Дополнительное действие при попытке изменить задачу за прошлый день.
  final VoidCallback? onLockedTap;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        if (state is TasksLoading || state is TasksInitial) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (state is TasksError) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              state.message,
              style: const TextStyle(color: AppColors.error),
            ),
          );
        }

        if (state is! TasksLoaded) {
          return const SizedBox.shrink();
        }

        final tasks = state.todayTasks;

        if (tasks.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Задач на эту дату не было.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }

        return Column(
          children: tasks.map((task) {
            return TaskCard(
              key: ValueKey('task-${task.id}'),
              task: task,
              date: date,
              onLockedTap: onLockedTap ??
                      () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Нельзя изменять задачи за прошедшие дни.',
                        ),
                      ),
                    );
                  },
              onChanged: (previousStateForToggle) async {
                final result = await context.read<TasksCubit>().toggleTask(
                  task.id,
                  previousStateForToggle,
                );

                if (result.ok) {
                  await heatmapCubit.loadHeatmapData();
                }

                return result;
              },
              onEdit: onEditTask == null
                  ? null
                  : () => onEditTask!(context, task),
            );
          }).toList(),
        );
      },
    );
  }
}
