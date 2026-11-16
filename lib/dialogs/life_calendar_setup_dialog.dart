
import 'package:daily/cubits/life_calendar/life_calendar_cubit.dart';
import 'package:daily/cubits/life_calendar/life_calendar_state.dart';
import 'package:daily/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LifeCalendarSetupDialog extends StatefulWidget {
  const LifeCalendarSetupDialog({super.key});

  static Future<void> show(BuildContext context) {
    final cubit = context.read<LifeCalendarCubit>();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: const LifeCalendarSetupDialog(),
      ),
    );
  }

  @override
  State<LifeCalendarSetupDialog> createState() =>
      _LifeCalendarSetupDialogState();
}

class _LifeCalendarSetupDialogState
    extends State<LifeCalendarSetupDialog> {
  final TextEditingController _targetAgeController =
  TextEditingController(text: '80');

  DateTime? _birthDate;

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _targetAgeController.dispose();
    super.dispose();
  }

  int _calculateAge(DateTime birthDate, DateTime currentDate) {
    var age = currentDate.year - birthDate.year;

    final hasBirthdayPassed = currentDate.month > birthDate.month ||
        (currentDate.month == birthDate.month &&
            currentDate.day >= birthDate.day);

    if (!hasBirthdayPassed) {
      age--;
    }

    return age;
  }

  Future<void> _selectBirthDate() async {
    final today = DateUtils.dateOnly(DateTime.now());

    final initialDate = _birthDate ??
        DateTime(
          today.year - 20,
          today.month,
          today.day.clamp(1, 28),
        );

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: today,
      helpText: 'Выберите дату рождения',
      cancelText: 'Отмена',
      confirmText: 'Выбрать',
    );

    if (!mounted || selectedDate == null) return;

    setState(() {
      _birthDate = DateUtils.dateOnly(selectedDate);
      _errorMessage = null;
    });
  }

  Future<void> _save() async {
    final birthDate = _birthDate;
    final targetAge = int.tryParse(_targetAgeController.text.trim());

    if (birthDate == null) {
      setState(() {
        _errorMessage = 'Выберите дату рождения.';
      });
      return;
    }

    if (targetAge == null || targetAge < 1 || targetAge > 120) {
      setState(() {
        _errorMessage = 'Укажите возраст от 1 до 120 лет.';
      });
      return;
    }

    final currentAge = _calculateAge(birthDate, DateTime.now());

    if (targetAge <= currentAge) {
      setState(() {
        _errorMessage =
        'Возраст окончания календаря должен быть больше вашего текущего возраста ($currentAge лет).';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await context.read<LifeCalendarCubit>().configure(
        birthDate: birthDate,
        targetAge: targetAge,
      );

      if (!mounted) return;

      final state = context.read<LifeCalendarCubit>().state;

      if (state is LifeCalendarLoaded) {
        Navigator.of(context).pop();
        return;
      }

      setState(() {
        _isSaving = false;
        _errorMessage = 'Не удалось сохранить настройки.';
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
        _errorMessage = 'Не удалось сохранить настройки.';
      });
    }
  }

  String _formatBirthDate(BuildContext context) {
    if (_birthDate == null) return 'Выберите дату рождения';

    return MaterialLocalizations.of(context).formatMediumDate(
      _birthDate!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);

    final availableHeight =
        mediaQuery.size.height - mediaQuery.viewInsets.bottom - 32;

    final currentAge = _birthDate == null
        ? null
        : _calculateAge(_birthDate!, DateTime.now());

    return PopScope(
      canPop: !_isSaving,
      child: Dialog(
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
                    const Icon(
                      Icons.calendar_month_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Life Calendar',
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
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Настройте календарь своей жизни. '
                            'Выберите дату рождения и возраст, '
                            'до которого хотите видеть календарь.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Дата рождения',
                        style: theme.textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _isSaving ? null : _selectBirthDate,
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.cake_outlined),
                            suffixIcon: Icon(
                              Icons.calendar_today_rounded,
                            ),
                          ),
                          child: Text(
                            _formatBirthDate(context),
                            style: TextStyle(
                              color: _birthDate == null
                                  ? AppColors.textSecondary
                                  : null,
                            ),
                          ),
                        ),
                      ),
                      if (currentAge != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Текущий возраст: $currentAge лет',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      TextField(
                        controller: _targetAgeController,
                        enabled: !_isSaving,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Показывать календарь до возраста',
                          hintText: 'Например, 80',
                          prefixIcon: Icon(Icons.flag_outlined),
                        ),
                        onChanged: (_) {
                          if (_errorMessage != null) {
                            setState(() => _errorMessage = null);
                          }
                        },
                        onSubmitted: (_) {
                          if (!_isSaving) _save();
                        },
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
                    Expanded(
                      child: _BottomActionButton(
                        onPressed: _isSaving ? null : _save,
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
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
                            : const Text(
                          'Начать',
                          style: TextStyle(
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
