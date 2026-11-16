import 'package:daily/data/database/app_database.dart';
import 'package:daily/utils/app_theme.dart';
import 'package:flutter/material.dart';

class SetupHabitCard extends StatelessWidget {
  const SetupHabitCard({
    super.key,
    required this.habit,
    required this.isCanceled,
    required this.onEdit,
    required this.onCancel,
    required this.onRestore,
  });

  final Habit habit;
  final bool isCanceled;

  final VoidCallback onEdit;
  final VoidCallback onCancel;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: isCanceled
            ? Colors.grey.shade900
            : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.title,
                  style: TextStyle(
                    color: isCanceled
                        ? Colors.grey
                        : AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    decoration: isCanceled
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
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
          if (isCanceled)
            IconButton(
              onPressed: onRestore,
              tooltip: 'Восстановить привычку',
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),
              icon: const Icon(
                Icons.restore_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            )
          else ...[
            IconButton(
              onPressed: onEdit,
              tooltip: 'Редактировать',
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),
              icon: const Icon(
                Icons.edit_rounded,
                size: 20,
              ),
            ),
            IconButton(
              onPressed: onCancel,
              tooltip: 'Отменить привычку',
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),
              icon: const Icon(
                Icons.archive_outlined,
                color: Colors.orangeAccent,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }
}