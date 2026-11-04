import 'package:daily/cubits/habits/habits_cubit.dart';
import 'package:daily/cubits/habits/habits_state.dart';
import 'package:daily/dialogs/add_edit_habit_dialog.dart';
import 'package:daily/dialogs/setup_habit_card.dart';
import 'package:daily/utils/app_theme.dart';
import 'package:daily/utils/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HabitsScreen extends StatelessWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HabitsCubit>(
      create: (_) => getIt<HabitsCubit>()..loadHabits(),
      child: const HabitsView(),
    );
  }
}

class HabitsView extends StatelessWidget {
  const HabitsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление привычками'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => AddEditHabitDialog.show(context),
        child: const Icon(Icons.add),
      ),
      body: BlocConsumer<HabitsCubit, HabitsState>(
        listener: (context, state) {
          if (state is HabitsError) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text(state.message)),
              );
          }
        },
        builder: (context, state) {
          if (state is HabitsLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is! HabitsLoaded) {
            return const SizedBox.shrink();
          }

          final activeHabits = state.allHabits
              .where((habit) => habit.canceledAt == null)
              .toList();

          final canceledHabits = state.allHabits
              .where((habit) => habit.canceledAt != null)
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Активные привычки',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              if (activeHabits.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Нет активных привычек.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              else
                ...activeHabits.map(
                      (habit) => SetupHabitCard(
                    habit: habit,
                    isCanceled: false,
                    onEdit: () => AddEditHabitDialog.show(
                      context,
                      habit: habit,
                    ),
                    onCancel: () {
                      context.read<HabitsCubit>().cancelHabit(habit.id);
                    },
                    onRestore: () {},
                  ),
                ),
              const SizedBox(height: 24),
              const Text(
                'Отменённые привычки',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              if (canceledHabits.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Нет отменённых привычек.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              else
                ...canceledHabits.map(
                      (habit) => SetupHabitCard(
                    habit: habit,
                    isCanceled: true,
                    onEdit: () {},
                    onCancel: () {},
                    onRestore: () {
                      context.read<HabitsCubit>().restoreHabit(habit.id);
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}