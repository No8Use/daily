import 'package:daily/cubits/heatmap/heatmap_cubit.dart';
import 'package:daily/cubits/tasks/tasks_cubit.dart';
import 'package:daily/utils/app_theme.dart';
import 'package:daily/utils/date_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddTaskDialog extends StatefulWidget {
  const AddTaskDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<TasksCubit>()),
          BlocProvider.value(value: context.read<HeatmapCubit>()),
        ],
        child: const AddTaskDialog(),
      ),
    );
  }

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final titleController = TextEditingController();
  final descController = TextEditingController();
  DateTime selectedDueDate = AppDateUtils.today;

  @override
  void dispose() {
    titleController.dispose();
    descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Новая задача на сегодня'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Название задачи'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Описание (опционально)'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Дата: ${AppDateUtils.formatDateDisplay(selectedDueDate)}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_month, color: AppColors.primary),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDueDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => selectedDueDate = picked);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: () {
            final title = titleController.text.trim();
            final desc = descController.text.trim().isEmpty ? null : descController.text.trim();
            if (title.isNotEmpty) {
              context.read<TasksCubit>().createTask(title, desc, selectedDueDate);
              context.read<HeatmapCubit>().loadHeatmapData();
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.black,
          ),
          child: const Text('Создать'),
        ),
      ],
    );
  }
}
