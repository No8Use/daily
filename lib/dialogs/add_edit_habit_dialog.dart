import 'package:daily/cubits/habits/habits_cubit.dart';
import 'package:daily/data/database/app_database.dart';
import 'package:daily/dialogs/delete_habit_dialog.dart';
import 'package:daily/utils/app_theme.dart';
import 'package:daily/utils/date_utils.dart';
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
  String? _errorMessage;

  bool get _isEditing => widget.habit != null;

  bool get _wasCreatedToday {
    if (widget.habit == null) return false;

    return AppDateUtils.normalizeDate(widget.habit!.createdAt) ==
        AppDateUtils.today;
  }

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
      setState(() {
        _errorMessage = 'Введите название привычки.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
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
        _errorMessage = 'Не удалось сохранить привычку.';
      });
    }
  }

  Future<void> _delete() async {
    final habit = widget.habit;

    if (habit == null || _isSaving) return;

    if (!_wasCreatedToday) {
      final shouldDelete = await DeleteHabitDialog.show(
        context,
        habitTitle: habit.title,
      );

      if (!shouldDelete || !mounted) return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final cubit = context.read<HabitsCubit>();

      if (_wasCreatedToday) {
        await cubit.deleteHabit(habit.id);
      } else {
        await cubit.cancelHabit(habit.id);
      }

      if (!mounted) return;

      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
        _errorMessage = 'Не удалось удалить привычку.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                    _isEditing
                        ? Icons.edit_rounded
                        : Icons.add_task_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _isEditing
                          ? 'Редактировать привычку'
                          : 'Новая привычка',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Закрыть',
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
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _titleController,
                      autofocus: false,
                      enabled: !_isSaving,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Название',
                        hintText: 'Например, чтение',
                        prefixIcon: Icon(Icons.edit_note_rounded),
                      ),
                      onChanged: (_) {
                        if (_errorMessage != null) {
                          setState(() => _errorMessage = null);
                        }
                      },
                      onSubmitted: (_) {
                        FocusScope.of(context).nextFocus();
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
                children: [
                  if (_isEditing)
                    SizedBox(
                      width: 64,
                      child: _BottomActionButton(
                        onPressed: _isSaving ? null : _delete,
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Icon(
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
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                          : Text(
                        _isEditing ? 'Сохранить' : 'Создать',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
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
                      backgroundColor:
                      theme.colorScheme.surfaceContainerHighest,
                      foregroundColor: theme.colorScheme.onSurface,
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