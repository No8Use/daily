import 'package:daily/cubits/life_calendar/life_calendar_cubit.dart';
import 'package:daily/cubits/life_calendar/life_calendar_state.dart';
import 'package:daily/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LifeCalendarSetupDialog extends StatefulWidget {
  const LifeCalendarSetupDialog({super.key});

  @override
  State<LifeCalendarSetupDialog> createState() =>
      _LifeCalendarSetupDialogState();
}

class _LifeCalendarSetupDialogState
    extends State<LifeCalendarSetupDialog> {
  final _startAgeController = TextEditingController();
  final _targetAgeController = TextEditingController(text: '80');

  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _startAgeController.dispose();
    _targetAgeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final startAge = int.tryParse(_startAgeController.text);
    final targetAge = int.tryParse(_targetAgeController.text);

    if (startAge == null ||
        targetAge == null ||
        startAge < 0 ||
        targetAge <= startAge ||
        targetAge > 120) {
      setState(() {
        _error = 'Проверьте введённые значения.';
      });
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    await context.read<LifeCalendarCubit>().configure(
      startAge: startAge,
      targetAge: targetAge,
    );

    if (!mounted) return;

    final state = context.read<LifeCalendarCubit>().state;

    if (state is LifeCalendarLoaded) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _saving = false;
        _error = 'Не удалось сохранить настройки.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('Life Calendar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Настройте временной диапазон календаря.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _startAgeController,
              enabled: !_saving,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Ваш текущий возраст',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _targetAgeController,
              enabled: !_saving,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Показывать календарь до возраста',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.error),
              ),
            ],
          ],
        ),
        actions: [
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
                : const Text('Начать'),
          ),
        ],
      ),
    );
  }
}