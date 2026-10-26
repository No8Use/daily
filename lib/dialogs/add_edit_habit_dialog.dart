
import 'package:daily/cubits/habits/habits_cubit.dart';
import 'package:daily/data/database/app_database.dart';
import 'package:daily/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddEditHabitDialog extends StatefulWidget {
  const AddEditHabitDialog({
    super.key,
    this.habit,
  });

  final Habit? habit;

  static Future<void> show(
      BuildContext context, {
        Habit? habit,
      }) {
    // Capture the Cubit before opening the dialog.
    final habitsCubit = context.read<HabitsCubit>();

    return showDialog<void>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: habitsCubit,
        child: AddEditHabitDialog(habit: habit),
      ),
    );
  }

  @override
  State<AddEditHabitDialog> createState() => _AddEditHabitDialogState();
}

class _AddEditHabitDialogState extends State<AddEditHabitDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  bool _isSaving = false;
  String? _validationError;

  bool get _isEditing => widget.habit != null;

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(
      text: widget.habit?.title ?? '',
    );

    _descriptionController = TextEditingController(
      text: widget.habit?.description ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final descriptionText = _descriptionController.text.trim();
    final description =
    descriptionText.isEmpty ? null : descriptionText;

    if (title.isEmpty) {
      setState(() => _validationError = 'Введите название привычки.');
      return;
    }

    setState(() {
      _isSaving = true;
      _validationError = null;
    });

    try {
      final cubit = context.read<HabitsCubit>();

      if (_isEditing) {
        await cubit.updateHabit(
          widget.habit!.id,
          title,
          description,
        );
      } else {
        await cubit.createHabit(title, description);
      }

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
        _validationError = 'Не удалось сохранить привычку.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Icon(
        _isEditing ? Icons.edit_rounded : Icons.add_task_rounded,
        color: AppColors.primary,
        size: 30,
      ),
      title: Text(
        _isEditing ? 'Редактировать привычку' : 'Создать привычку',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              enabled: !_isSaving,
              decoration: const InputDecoration(
                labelText: 'Название',
                hintText: 'Например, чтение',
                prefixIcon: Icon(Icons.edit_note_rounded),
              ),
              onChanged: (_) {
                if (_validationError != null) {
                  setState(() => _validationError = null);
                }
              },
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              enabled: !_isSaving,
              textCapitalization: TextCapitalization.sentences,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Описание',
                hintText: 'Необязательно',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            if (_validationError != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _validationError!,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving
              ? null
              : () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton.icon(
          onPressed: _isSaving ? null : _save,
          icon: _isSaving
              ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.black,
            ),
          )
              : const Icon(Icons.check_rounded),
          label: Text(_isEditing ? 'Сохранить' : 'Создать'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.black,
          ),
        ),
      ],
    );
  }
}
