
import 'package:daily/data/database/app_database.dart';
import 'package:daily/utils/app_theme.dart';
import 'package:daily/utils/date_utils.dart';
import 'package:daily/utils/models/operation_result.dart';
import 'package:daily/widgets/completion_card_shell.dart';
import 'package:flutter/material.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    required this.task,
    required this.date,
    required this.onChanged,
    this.onEdit,
    this.onLockedTap,
    super.key,
  });

  final Task task;
  final DateTime date;
  final Future<OperationResult> Function(bool previousStateForToggle)
  onChanged;
  final VoidCallback? onEdit;
  final VoidCallback? onLockedTap;

  @override
  Widget build(BuildContext context) {
    final isPastDay = AppDateUtils.normalizeDate(date)
        .isBefore(AppDateUtils.today);

    return CompletionCardShell(
      key: ValueKey('task-shell-${task.id}'),
      initialCompleted: task.isCompleted,
      date: date,
      onChanged: onChanged,
      onLockedTap: onLockedTap,
      childBuilder: (context, isCompleted, isSaving) {
        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 180),
                    style: TextStyle(
                      color: isCompleted
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      decorationColor: AppColors.primary,
                    ),
                    child: Text(task.title),
                  ),
                  if (task.description != null &&
                      task.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      task.description!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (isPastDay && !isCompleted) ...[
                    const SizedBox(height: 5),
                    const Text(
                      'День завершён',
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!isPastDay && onEdit != null) ...[
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Редактировать задачу',
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
                onPressed: isSaving ? null : onEdit,
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 19,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
