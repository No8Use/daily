import 'package:daily/data/repositories/life_calendar_repository.dart';
import 'package:daily/utils/app_theme.dart';
import 'package:flutter/material.dart';

class WeekInfoExpansion extends StatelessWidget {
  const WeekInfoExpansion({
    super.key,
    required this.weekNumber,
    required this.startDate,
    required this.productivity,
    required this.isReviewAvailable,
    required this.hasReview,
    required this.onAddReview,
  });

  final int weekNumber;
  final DateTime startDate;
  final WeekProductivity productivity;

  final bool isReviewAvailable;
  final bool hasReview;

  final VoidCallback onAddReview;

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final endDate = startDate.add(const Duration(days: 6));

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 2,
        vertical: 6,
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_month_rounded,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Неделя $weekNumber',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                '${_formatDate(startDate)} — ${_formatDate(endDate)}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          _ProgressItem(
            title: 'Привычки',
            completed: productivity.completedHabits,
            total: productivity.totalHabitOpportunities,
            progress: productivity.habitProgress,
          ),

          const SizedBox(height: 14),

          _ProgressItem(
            title: 'Задачи',
            completed: productivity.completedTasks,
            total: productivity.totalTasks,
            progress: productivity.taskProgress,
          ),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Общая продуктивность',
                style: TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '${(productivity.overallProgress * 100).round()}%',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (isReviewAvailable)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onAddReview,
                icon: Icon(
                  hasReview
                      ? Icons.edit_rounded
                      : Icons.rate_review_outlined,
                ),
                label: Text(
                  hasReview ? 'Edit review' : 'Add review',
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProgressItem extends StatelessWidget {
  const _ProgressItem({
    required this.title,
    required this.completed,
    required this.total,
    required this.progress,
  });

  final String title;
  final int completed;
  final int total;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title),
            Text(
              '$completed / $total',
              style: const TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            backgroundColor: AppColors.surface,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}