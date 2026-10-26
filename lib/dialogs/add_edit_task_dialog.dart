import 'package:daily/data/database/app_database.dart';
import 'package:daily/data/repositories/tasks_repository.dart';
import 'package:daily/utils/app_theme.dart';
import 'package:daily/utils/date_utils.dart';
import 'package:daily/utils/service_locator.dart';
import 'package:flutter/material.dart';

class AddEditTaskDialog extends StatefulWidget {
  const AddEditTaskDialog({
    super.key,
    this.task,
    this.initialDate,
    this.onSaved,
  });

  final Task? task;
  final DateTime? initialDate;

  /// Called after creating, updating, or deleting a task.
  final Future<void> Function()? onSaved;

  bool get isEditing => task != null;

  static Future<void> show(
      BuildContext context, {
        Task? task,
        DateTime? initialDate,
        Future<void> Function()? onSaved,
      }) {
    return showDialog<void>(
      context: context,
      builder: (_) => AddEditTaskDialog(
        task: task,
        initialDate: initialDate,
        onSaved: onSaved,
      ),
    );
  }

  @override
  State<AddEditTaskDialog> createState() => _AddEditTaskDialogState();
}

class _AddEditTaskDialogState extends State<AddEditTaskDialog> {
  final TasksRepository _repository = getIt<TasksRepository>();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  late DateTime _selectedDueDate;

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(
      text: widget.task?.title ?? '',
    );

    _descriptionController = TextEditingController(
      text: widget.task?.description ?? '',
    );

    _selectedDueDate = AppDateUtils.normalizeDate(
      widget.task?.dueDate ??
          widget.initialDate ??
          AppDateUtils.today,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = AppDateUtils.today;

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(today.year + 10, 12, 31),
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedDueDate = AppDateUtils.normalizeDate(picked);
        _errorMessage = null;
      });
    }
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final descriptionText = _descriptionController.text.trim();
    final description =
    descriptionText.isEmpty ? null : descriptionText;

    if (title.isEmpty) {
      setState(() => _errorMessage = 'Введите название задачи.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      if (widget.task == null) {
        await _repository.createTask(
          title,
          description,
          _selectedDueDate,
        );
      } else {
        final updated = await _repository.updateTask(
          widget.task!.id,
          title,
          description,
          _selectedDueDate,
        );

        if (!updated) {
          throw StateError('Task was not updated.');
        }
      }

      await widget.onSaved?.call();

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
        _errorMessage = 'Не удалось сохранить задачу.';
      });
    }
  }

  Future<void> _delete() async {
    final task = widget.task;
    if (task == null) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (confirmationContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.delete_outline_rounded,
            color: AppColors.error,
            size: 32,
          ),
          title: const Text('Удалить задачу?'),
          content: Text(
            'Задача «${task.title}» будет удалена без возможности восстановления.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(confirmationContext).pop(false),
              child: const Text('Отмена'),
            ),
            FilledButton.icon(
              onPressed: () =>
                  Navigator.of(confirmationContext).pop(true),
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Удалить'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final deleted = await _repository.deleteTask(task.id);

      if (!deleted) {
        throw StateError('Task was not deleted.');
      }

      await widget.onSaved?.call();

      if (!mounted) return;
      Navigator.of(context).pop(); // Close the task form.
      Navigator.of(context).pop(); // Close the confirmation's parent route.
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
        _errorMessage = 'Не удалось удалить задачу.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.isEditing;

    return AlertDialog(
      icon: Icon(
        isEditing ? Icons.edit_note_rounded : Icons.add_task_rounded,
        color: AppColors.primary,
        size: 32,
      ),
      title: Text(
        isEditing ? 'Редактировать задачу' : 'Новая задача',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              autofocus: true,
              enabled: !_isSaving,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Название задачи',
                prefixIcon: Icon(Icons.edit_rounded),
              ),
              onChanged: (_) {
                if (_errorMessage != null) {
                  setState(() => _errorMessage = null);
                }
              },
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
            const SizedBox(height: 12),
            Material(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _isSaving ? null : _pickDate,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_month_rounded,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Дата задачи',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              AppDateUtils.formatDateDisplay(
                                _selectedDueDate,
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _errorMessage!,
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
        if (isEditing)
          IconButton(
            tooltip: 'Удалить задачу',
            onPressed: _isSaving ? null : _delete,
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.error,
            ),
          ),
        TextButton(
          onPressed: _isSaving
              ? null
              : () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.black,
          ),
          child: _isSaving
              ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.black,
            ),
          )
              : Text(isEditing ? 'Сохранить' : 'Создать'),
        ),
      ],
    );
  }
}
