
import 'package:daily/cubits/habits/habits_cubit.dart';
import 'package:daily/cubits/habits/habits_state.dart';
import 'package:daily/cubits/heatmap/heatmap_cubit.dart';
import 'package:daily/utils/app_hints.dart';
import 'package:daily/utils/app_theme.dart';
import 'package:daily/utils/date_utils.dart';
import 'package:daily/widgets/habit_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HabitsList extends StatelessWidget {
  const HabitsList({
    required this.date,
    required this.heatmapCubit,
    super.key,
  });

  final DateTime date;
  final HeatmapCubit heatmapCubit;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HabitsCubit, HabitsState>(
      builder: (context, state) {
        if (state is HabitsLoading || state is HabitsInitial) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (state is HabitsError) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              state.message,
              style: const TextStyle(color: AppColors.error),
            ),
          );
        }

        if (state is! HabitsLoaded) {
          return const SizedBox.shrink();
        }

        final habits = state.activeHabits;
        final completions = state.todayCompletions;

        if (habits.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Активных привычек на эту дату не было.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }

        final targetDate = AppDateUtils.normalizeDate(date);

        return Column(
          children: habits.map((habit) {
            final isCompleted = completions[habit.id] ?? false;

            return HabitCard(
              key: ValueKey('habit-${habit.id}'),
              habit: habit,
              date: targetDate,
              isCompleted: isCompleted,
              onLockedTap: () => AppHints.showPastDayHint(context),
              onChanged: (previousState) async {
                final result = await context
                    .read<HabitsCubit>()
                    .toggleCompletion(
                  habit.id,
                  targetDate,
                  !previousState,
                );

                if (result.ok) {
                  await heatmapCubit.loadHeatmapData();
                }

                return result;
              },
            );
          }).toList(),
        );
      },
    );
  }
}
