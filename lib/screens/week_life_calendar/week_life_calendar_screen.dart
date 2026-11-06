import 'package:daily/cubits/life_calendar/life_calendar_cubit.dart';
import 'package:daily/cubits/life_calendar/life_calendar_state.dart';
import 'package:daily/data/repositories/life_calendar_repository.dart';
import 'package:daily/dialogs/life_calendar_setup_dialog.dart';
import 'package:daily/utils/app_theme.dart';
import 'package:daily/utils/date_utils.dart';
import 'package:daily/utils/service_locator.dart';
import 'package:daily/widgets/week_info_expansion.dart';
import 'package:daily/widgets/week_life_calendar_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WeekLifeCalendarScreen extends StatelessWidget {
  const WeekLifeCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<LifeCalendarCubit>()..load(),
      child: const _WeekLifeCalendarView(),
    );
  }
}

class _WeekLifeCalendarView extends StatefulWidget {
  const _WeekLifeCalendarView();

  @override
  State<_WeekLifeCalendarView> createState() =>
      _WeekLifeCalendarViewState();
}

class _WeekLifeCalendarViewState
    extends State<_WeekLifeCalendarView> {
  int? _selectedWeek;

  Future<void> _showSetup() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: context.read<LifeCalendarCubit>(),
        child: const LifeCalendarSetupDialog(),
      ),
    );
  }

  DateTime _getWeekStart(DateTime date) {
    final normalized = AppDateUtils.normalizeDate(date);

    return normalized.subtract(
      Duration(days: normalized.weekday - 1),
    );
  }

  int _getCurrentWeekIndex(DateTime startedAt) {
    final start = _getWeekStart(startedAt);
    final today = AppDateUtils.today;

    final current = _getWeekStart(today);

    return current.difference(start).inDays ~/ 7;
  }

  DateTime _getWeekDate(DateTime start, int index) {
    return start.add(Duration(days: index * 7));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LifeCalendarCubit, LifeCalendarState>(
      listener: (context, state) {
        if (state is LifeCalendarSetupRequired) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _showSetup();
          });
        }

        if (state is LifeCalendarLoaded) {
          setState(() => _selectedWeek = null);
        }
      },
      builder: (context, state) {
        if (state is LifeCalendarLoading ||
            state is LifeCalendarInitial) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (state is LifeCalendarError) {
          return Center(
            child: Text(
              state.message,
              style: const TextStyle(color: AppColors.error),
            ),
          );
        }

        if (state is LifeCalendarSetupRequired) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (state is! LifeCalendarLoaded) {
          return const SizedBox.shrink();
        }

        final settings = state.settings;

        final currentWeek = _getCurrentWeekIndex(
          settings.startedAt,
        );

        final totalWeeks =
            (settings.targetAge - settings.startAge) * 52;

        final firstWeek = _getWeekStart(settings.startedAt);

        final selectedDate = _selectedWeek == null
            ? null
            : _getWeekDate(firstWeek, _selectedWeek!);

        return LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: WeekLifeCalendarGrid(
                      totalWeeks: totalWeeks,
                      currentWeekIndex: currentWeek,
                      selectedWeekIndex: _selectedWeek,
                      targetAge: settings.targetAge,
                      onWeekTap: (index) {
                        if (index > currentWeek) {
                          return;
                        }

                        setState(() {
                          _selectedWeek =
                          _selectedWeek == index ? null : index;
                        });
                      },
                    ),
                  ),
                ),

                AnimatedSize(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOutCubic,
                  alignment: Alignment.topCenter,
                  child: _selectedWeek == null
                      ? const SizedBox(
                    width: double.infinity,
                    height: 0,
                  )
                      : SizedBox(
                    width: double.infinity,
                    child: FutureBuilder<WeekProductivity>(
                      key: ValueKey(_selectedWeek),
                      future: getIt<LifeCalendarRepository>()
                          .getWeekProductivity(selectedDate!),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final weekStart = selectedDate;

                        return FutureBuilder(
                          future: getIt<LifeCalendarRepository>()
                              .getWeeklyReview(weekStart),
                          builder: (context, reviewSnapshot) {
                            return WeekInfoExpansion(
                              weekNumber: _selectedWeek! + 1,
                              startDate: weekStart,
                              productivity: snapshot.data!,
                              isReviewAvailable:
                              weekStart.add(
                                const Duration(days: 6),
                              ).isBefore(
                                AppDateUtils.today,
                              ) ||
                                  AppDateUtils.isSameDay(
                                    weekStart.add(
                                      const Duration(days: 6),
                                    ),
                                    AppDateUtils.today,
                                  ) &&
                                      AppDateUtils.today.weekday ==
                                          DateTime.sunday,
                              hasReview: reviewSnapshot.hasData &&
                                  reviewSnapshot.data != null,
                              onAddReview: () {
                                _showWeeklyReview(
                                  context,
                                  weekStart,
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showWeeklyReview(
      BuildContext context,
      DateTime weekStart,
      ) async {
    final descriptionController = TextEditingController();
    var rating = 5;

    try {
      final existing = await getIt<LifeCalendarRepository>()
          .getWeeklyReview(weekStart);

      if (!mounted) return;

      descriptionController.text = existing?.description ?? '';
      rating = existing?.rating ?? 5;

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Weekly review'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Оценка недели: $rating / 10'),
                      Slider(
                        value: rating.toDouble(),
                        min: 1,
                        max: 10,
                        divisions: 9,
                        onChanged: (value) {
                          setDialogState(() {
                            rating = value.round();
                          });
                        },
                      ),
                      TextField(
                        controller: descriptionController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'Как прошла неделя?',
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () =>
                        Navigator.pop(dialogContext),
                    child: const Text('Отмена'),
                  ),
                  FilledButton(
                    onPressed: () async {
                      try {
                        await getIt<LifeCalendarRepository>()
                            .saveWeeklyReview(
                          weekStart: weekStart,
                          rating: rating,
                          description:
                          descriptionController.text.trim(),
                        );

                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }

                        if (mounted) {
                          setState(() {});
                        }
                      } catch (error) {
                        if (dialogContext.mounted) {
                          ScaffoldMessenger.of(dialogContext)
                              .showSnackBar(
                            SnackBar(
                              content: Text(error.toString()),
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Сохранить'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      descriptionController.dispose();
    }
  }
}