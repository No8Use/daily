import 'package:daily/cubits/habits/habits_cubit.dart';
import 'package:daily/cubits/heatmap/heatmap_cubit.dart';
import 'package:daily/cubits/life_calendar/life_calendar_cubit.dart';
import 'package:daily/cubits/life_calendar/life_calendar_state.dart';
import 'package:daily/cubits/notes/notes_cubit.dart';
import 'package:daily/cubits/reviews/reviews_cubit.dart';
import 'package:daily/cubits/tasks/tasks_cubit.dart';
import 'package:daily/screens/summary_screen/summary_screen.dart';
import 'package:daily/screens/week_life_calendar/week_life_calendar_screen.dart';
import 'package:daily/utils/app_theme.dart';
import 'package:daily/utils/date_utils.dart';
import 'package:daily/utils/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HeatmapCubit _heatmapCubit;
  late final TasksCubit _tasksCubit;
  late final HabitsCubit _habitsCubit;
  late final NotesCubit _notesCubit;
  late final ReviewsCubit _reviewsCubit;
  late final LifeCalendarCubit _lifeCalendarCubit;

  int _selectedPage = 0;

  @override
  void initState() {
    super.initState();

    _heatmapCubit = getIt<HeatmapCubit>()..loadHeatmapData();

    _tasksCubit = getIt<TasksCubit>()
      ..loadTasksForDate(AppDateUtils.today);

    _habitsCubit = getIt<HabitsCubit>()..loadHabits();

    _notesCubit = getIt<NotesCubit>()..loadNotes();

    _reviewsCubit = getIt<ReviewsCubit>()
      ..loadReviewForDate(AppDateUtils.today);

    _lifeCalendarCubit = getIt<LifeCalendarCubit>()..load();
  }

  @override
  void dispose() {
    _heatmapCubit.close();
    _tasksCubit.close();
    _habitsCubit.close();
    _notesCubit.close();
    _reviewsCubit.close();
    _lifeCalendarCubit.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _heatmapCubit),
        BlocProvider.value(value: _tasksCubit),
        BlocProvider.value(value: _habitsCubit),
        BlocProvider.value(value: _notesCubit),
        BlocProvider.value(value: _reviewsCubit),
        BlocProvider.value(value: _lifeCalendarCubit),
      ],
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: _selectedPage == 0
                ? 'Открыть Dashboard'
                : 'Открыть Life Calendar',
            icon: Icon(
              _selectedPage == 0
                  ? Icons.dashboard_outlined
                  : Icons.calendar_view_week_rounded,
              color: AppColors.primary,
            ),
            onPressed: () {
              setState(() {
                _selectedPage = _selectedPage == 0 ? 1 : 0;
              });
            },
          ),
          title: Text(
            _selectedPage == 0 ? 'Life Calendar' : 'Daily',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 23,
            ),
          ),
          actions: [
            if (_selectedPage == 0)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) async {
                  if (value == 'target_age') {
                    await _showTargetAgeDialog(context);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'target_age',
                    child: Row(
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 10),
                        Text('Настройки календаря'),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
        body: IndexedStack(
          index: _selectedPage,
          children: const [
            WeekLifeCalendarScreen(),
            SummaryScreen(),
          ],
        ),
      ),
    );
  }

  Future<void> _showTargetAgeDialog(BuildContext context) async {
    final cubit = context.read<LifeCalendarCubit>();
    final state = cubit.state;

    if (state is! LifeCalendarLoaded) return;

    final controller = TextEditingController(
      text: state.settings.targetAge.toString(),
    );

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Настройки календаря'),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Возраст отображения',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Отмена'),
              ),
              FilledButton(
                onPressed: () async {
                  final age = int.tryParse(controller.text);

                  if (age == null ||
                      age <= state.settings.startAge ||
                      age > 120) {
                    return;
                  }

                  await cubit.updateTargetAge(age);

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                },
                child: const Text('Сохранить'),
              ),
            ],
          );
        },
      );
    } finally {
      controller.dispose();
    }
  }
}