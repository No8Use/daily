
import 'package:daily/data/database/app_database.dart';
import 'package:daily/data/repositories/tasks_repository.dart';
import 'package:daily/dialogs/delete_task_dialog.dart';
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

    final shouldDelete = await DeleteTaskDialog.show(
      context,
      taskTitle: task.title,
    );

    if (!shouldDelete || !mounted) return;

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
      Navigator.of(context).pop();
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
    final mediaQuery = MediaQuery.of(context);
    final availableHeight =
        mediaQuery.size.height - mediaQuery.viewInsets.bottom - 32;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      backgroundColor: AppColors.cardBackground,
      surfaceTintColor: Colors.transparent,
      elevation: 12,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: availableHeight.clamp(180.0, double.infinity),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
              child: Row(
                children: [
                  Icon(
                    widget.isEditing
                        ? Icons.edit_note_rounded
                        : Icons.add_task_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.isEditing
                          ? 'Редактировать задачу'
                          : 'Новая задача',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Закрыть',
                    visualDensity: VisualDensity.compact,
                    onPressed: _isSaving
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _titleController,
                      autofocus: false,
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
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
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
            ),
            SizedBox(
              height: 56,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.isEditing)
                    SizedBox(
                      width: 64,
                      child: _BottomActionButton(
                        onPressed: _isSaving ? null : _delete,
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                        ),
                      ),
                    ),
                  Expanded(
                    child: _BottomActionButton(
                      onPressed: _isSaving ? null : _save,
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      child: _isSaving
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                          : Text(
                        widget.isEditing
                            ? 'Сохранить'
                            : 'Создать',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 104,
                    child: _BottomActionButton(
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.of(context).pop(),
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      foregroundColor:
                      Theme.of(context).colorScheme.onSurface,
                      borderRadius: const BorderRadius.only(
                        bottomRight: Radius.circular(16),
                      ),
                      child: const Text('Отмена'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomActionButton extends StatelessWidget {
  const _BottomActionButton({
    required this.onPressed,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.child,
    this.borderRadius = BorderRadius.zero,
  });

  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final Widget child;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      child: InkWell(
        onTap: onPressed,
        borderRadius: borderRadius,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
          ),
          child: Center(
            child: IconTheme(
              data: IconThemeData(
                color: foregroundColor,
                size: 22,
              ),
              child: DefaultTextStyle(
                style: TextStyle(
                  color: foregroundColor,
                  fontSize: 14,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
