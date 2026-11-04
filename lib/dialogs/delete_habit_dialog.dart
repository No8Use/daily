import 'package:daily/utils/app_theme.dart';
import 'package:flutter/material.dart';

class DeleteHabitDialog extends StatelessWidget {
  const DeleteHabitDialog({
    super.key,
    required this.habitTitle,
  });

  final String habitTitle;

  static Future<bool> show(
      BuildContext context, {
        required String habitTitle,
      }) async {
    return await showDialog<bool>(
      context: context,
      builder: (_) => DeleteHabitDialog(
        habitTitle: habitTitle,
      ),
    ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(
        Icons.delete_outline_rounded,
        color: AppColors.error,
        size: 28,
      ),
      title: const Text('Удалить привычку?'),
      content: Text(
        'Привычка «$habitTitle» будет отменена. '
            'История её достижений за прошлые дни сохранится.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Отмена'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(true),
          icon: const Icon(Icons.delete_outline_rounded),
          label: const Text('Удалить'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}