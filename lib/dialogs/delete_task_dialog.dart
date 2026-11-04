
import 'package:flutter/material.dart';
import 'package:daily/utils/app_theme.dart';

class DeleteTaskDialog extends StatelessWidget {
  const DeleteTaskDialog({
    super.key,
    required this.taskTitle,
  });

  final String taskTitle;

  static Future<bool> show(
      BuildContext context, {
        required String taskTitle,
      }) async {
    return await showDialog<bool>(
      context: context,
      builder: (_) => DeleteTaskDialog(taskTitle: taskTitle),
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
      title: const Text('Удалить задачу?'),
      content: Text(
        'Задача «$taskTitle» будет удалена без возможности восстановления.',
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
