
import 'package:daily/data/database/app_database.dart';
import 'package:daily/utils/app_theme.dart';
import 'package:daily/utils/models/operation_result.dart';
import 'package:daily/widgets/completion_card_shell.dart';
import 'package:flutter/material.dart';

class HabitCard extends StatelessWidget {
  const HabitCard({
    required this.habit,
    required this.date,
    required this.isCompleted,
    required this.onChanged,
    this.onLockedTap,
    super.key,
  });

  final Habit habit;
  final DateTime date;
  final bool isCompleted;

  final Future<OperationResult> Function(bool previousStateForToggle)
  onChanged;

  final VoidCallback? onLockedTap;

  @override
  Widget build(BuildContext context) {
    return CompletionCardShell(
      key: ValueKey('habit-shell-${habit.id}'),
      initialCompleted: isCompleted,
      date: date,
      onChanged: onChanged,
      onLockedTap: onLockedTap,
      childBuilder: (context, completed, isSaving) {
        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 180),
                    style: TextStyle(
                      color: completed
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      decoration: completed
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      decorationColor: AppColors.primary,
                    ),
                    child: Text(habit.title),
                  ),
                  if (habit.description != null &&
                      habit.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      habit.description!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
