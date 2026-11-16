import 'dart:math' as math;

import 'package:daily/cubits/life_calendar/life_calendar_cubit.dart';
import 'package:daily/cubits/life_calendar/life_calendar_state.dart';
import 'package:daily/data/models/life_calendar_models.dart';
import 'package:daily/dialogs/life_calendar_setup_dialog.dart';
import 'package:daily/utils/app_theme.dart';
import 'package:daily/utils/date_utils.dart';
import 'package:daily/utils/service_locator.dart';
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
  static const int _weeksPerRow = 52;

  static const double _cellSize = 12;
  static const double _cellGap = 3;
  static const double _canvasPadding = 16;

  static const double _maximumScale = 12;

  final TransformationController _transformationController =
  TransformationController();

  int? _selectedWeekIndex;

  double _fitScale = 1;
  double _minScale = 0.5;
  double _maxScale = _maximumScale;

  bool _initialTransformApplied = false;
  bool _setupDialogVisible = false;
  bool _setupWasRequired = false;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _scheduleSetupDialog() {
    if (_setupDialogVisible) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _setupDialogVisible) return;

      _showSetupDialog();
    });
  }

  Future<void> _showSetupDialog() async {
    if (!mounted || _setupDialogVisible) return;

    _setupDialogVisible = true;

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => BlocProvider.value(
          value: context.read<LifeCalendarCubit>(),
          child: const LifeCalendarSetupDialog(),
        ),
      );
    } finally {
      _setupDialogVisible = false;
    }
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity()
      ..scale(_fitScale);
  }

  void _zoomBy(double factor) {
    final currentScale =
    _transformationController.value.getMaxScaleOnAxis();

    final nextScale = (currentScale * factor)
        .clamp(_minScale, _maxScale)
        .toDouble();

    if ((nextScale - currentScale).abs() < 0.001) {
      return;
    }

    final focalPoint = Offset(
      MediaQuery.sizeOf(context).width / 2,
      MediaQuery.sizeOf(context).height / 2,
    );

    final scenePoint = _transformationController.toScene(
      focalPoint,
    );

    _transformationController.value = Matrix4.identity()
      ..translate(
        focalPoint.dx - scenePoint.dx * nextScale,
        focalPoint.dy - scenePoint.dy * nextScale,
      )
      ..scale(nextScale);
  }

  void _applyInitialTransform(double fitScale) {
    if (_initialTransformApplied) return;

    _initialTransformApplied = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _transformationController.value = Matrix4.identity()
        ..scale(fitScale);
    });
  }

  Future<void> _showWeekDetails({
    required int weekIndex,
    required LifeCalendarCubit cubit,
  }) async {
    if (weekIndex < 0) return;

    final currentState = cubit.state;

    if (currentState is! LifeCalendarLoaded) return;

    if (weekIndex > currentState.currentWeekIndex) {
      return;
    }

    final weekStart = cubit.getWeekStart(weekIndex);

    setState(() {
      _selectedWeekIndex = weekIndex;
    });

    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return BlocProvider.value(
          value: cubit,
          child: _WeekDetailsBottomSheet(
            weekIndex: weekIndex,
            weekStart: weekStart,
          ),
        );
      },
    );

    if (!mounted) return;

    setState(() {
      _selectedWeekIndex = null;
    });
  }

  int? _getWeekIndexAtPosition({
    required Offset position,
    required int totalWeeks,
  }) {
    final localX = position.dx - _canvasPadding;
    final localY = position.dy - _canvasPadding;

    if (localX < 0 || localY < 0) {
      return null;
    }

    final stride = _cellSize + _cellGap;

    final column = (localX / stride).floor();
    final row = (localY / stride).floor();

    if (column < 0 ||
        column >= _weeksPerRow ||
        row < 0) {
      return null;
    }

    final insideCellX = localX - column * stride;
    final insideCellY = localY - row * stride;

    if (insideCellX >= _cellSize ||
        insideCellY >= _cellSize) {
      return null;
    }

    final index = row * _weeksPerRow + column;

    if (index >= totalWeeks) {
      return null;
    }

    return index;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LifeCalendarCubit, LifeCalendarState>(
      listener: (context, state) {
        if (state is LifeCalendarSetupRequired) {
          _setupWasRequired = true;
          _scheduleSetupDialog();
        }

        if (state is LifeCalendarLoaded && _setupWasRequired) {
          _setupWasRequired = false;
          _initialTransformApplied = false;
          _selectedWeekIndex = null;
        }
      },
      builder: (context, state) {
        if (state is LifeCalendarInitial ||
            state is LifeCalendarLoading ||
            state is LifeCalendarSetupRequired) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (state is LifeCalendarError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 36,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {
                      context.read<LifeCalendarCubit>().load();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Повторить'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is! LifeCalendarLoaded) {
          return const SizedBox.shrink();
        }

        final cubit = context.read<LifeCalendarCubit>();

        final totalWeeks = state.totalWeeks;
        final currentWeekIndex = state.currentWeekIndex;
        final trackingStartWeekIndex =
            state.trackingStartWeekIndex;

        final rowCount = (totalWeeks / _weeksPerRow).ceil();

        final canvasWidth = _canvasPadding * 2 +
            _weeksPerRow * _cellSize +
            (_weeksPerRow - 1) * _cellGap;

        final canvasHeight = _canvasPadding * 2 +
            rowCount * _cellSize +
            (rowCount - 1) * _cellGap;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Life calendar',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${state.totalWeeks} недель · '
                              'цель ${state.settings.targetAge} лет',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Обновить календарь',
                    onPressed: cubit.refresh,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final viewportWidth = constraints.maxWidth;
                  final viewportHeight = constraints.maxHeight;

                  final fitScale = math.min(
                    viewportWidth / canvasWidth,
                    viewportHeight / canvasHeight,
                  ).clamp(0.01, 1.0).toDouble();

                  _fitScale = fitScale;
                  _minScale = (fitScale * 0.6)
                      .clamp(0.01, 1.0)
                      .toDouble();
                  _maxScale = math.max(
                    _maximumScale,
                    fitScale * 20,
                  );

                  _applyInitialTransform(fitScale);

                  return Stack(
                    children: [
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: ClipRect(
                            child: InteractiveViewer(
                              transformationController:
                              _transformationController,
                              constrained: false,
                              alignment: Alignment.center,
                              minScale: _minScale,
                              maxScale: _maxScale,
                              boundaryMargin:
                              const EdgeInsets.all(300),
                              panEnabled: true,
                              scaleEnabled: true,
                              clipBehavior: Clip.hardEdge,
                              child: SizedBox(
                                width: canvasWidth,
                                height: canvasHeight,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTapUp: (details) {
                                    final index =
                                    _getWeekIndexAtPosition(
                                      position:
                                      details.localPosition,
                                      totalWeeks: totalWeeks,
                                    );

                                    if (index == null ||
                                        index > currentWeekIndex) {
                                      return;
                                    }

                                    _showWeekDetails(
                                      weekIndex: index,
                                      cubit: cubit,
                                    );
                                  },
                                  child: CustomPaint(
                                    size: Size(
                                      canvasWidth,
                                      canvasHeight,
                                    ),
                                    painter: _LifeCalendarPainter(
                                      totalWeeks: totalWeeks,
                                      selectedWeekIndex:
                                      _selectedWeekIndex,
                                      currentWeekIndex:
                                      currentWeekIndex,
                                      trackingStartWeekIndex:
                                      trackingStartWeekIndex,
                                      weeksPerRow: _weeksPerRow,
                                      cellSize: _cellSize,
                                      cellGap: _cellGap,
                                      padding: _canvasPadding,
                                      weeklyScores:
                                      state.weeklyScores,
                                      isSunday:
                                      AppDateUtils.today.weekday ==
                                          DateTime.sunday,
                                      futureColor: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      neutralColor: Colors.blueGrey
                                          .withValues(alpha: 0.35),
                                      currentColor:
                                      Colors.blueGrey.shade500,
                                      currentBorderColor:
                                      AppColors.secondary,
                                      selectedBorderColor:
                                      Theme.of(context)
                                          .colorScheme
                                          .primary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // These controls are outside InteractiveViewer.
                      // They remain clickable regardless of canvas scale.
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: _ZoomControls(
                          onZoomIn: () => _zoomBy(1.5),
                          onZoomOut: () => _zoomBy(1 / 1.5),
                          onReset: _resetZoom,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 14),
              child: _CalendarLegend(),
            ),
          ],
        );
      },
    );
  }
}

class _ZoomControls extends StatelessWidget {
  const _ZoomControls({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onReset,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      color: Theme.of(context).colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Увеличить',
            onPressed: onZoomIn,
            icon: const Icon(Icons.add),
          ),
          IconButton(
            tooltip: 'Уменьшить',
            onPressed: onZoomOut,
            icon: const Icon(Icons.remove),
          ),
          IconButton(
            tooltip: 'Вписать весь календарь',
            onPressed: onReset,
            icon: const Icon(Icons.fit_screen),
          ),
        ],
      ),
    );
  }
}

class _CalendarLegend extends StatelessWidget {
  const _CalendarLegend();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _LegendItem(
          color: Colors.blueGrey.shade500,
          label: 'Текущая неделя',
        ),
        _LegendItem(
          color: Colors.red.shade400,
          label: 'Низкая оценка',
        ),
        _LegendItem(
          color: Colors.green.shade500,
          label: 'Высокая оценка',
        ),
        _LegendItem(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest,
          label: 'Будущее',
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}

class _LifeCalendarPainter extends CustomPainter {
  const _LifeCalendarPainter({
    required this.totalWeeks,
    required this.selectedWeekIndex,
    required this.currentWeekIndex,
    required this.trackingStartWeekIndex,
    required this.weeksPerRow,
    required this.cellSize,
    required this.cellGap,
    required this.padding,
    required this.weeklyScores,
    required this.isSunday,
    required this.futureColor,
    required this.neutralColor,
    required this.currentColor,
    required this.currentBorderColor,
    required this.selectedBorderColor,
  });

  final int totalWeeks;
  final int? selectedWeekIndex;
  final int currentWeekIndex;
  final int trackingStartWeekIndex;

  final int weeksPerRow;
  final double cellSize;
  final double cellGap;
  final double padding;

  final Map<int, double?> weeklyScores;

  final bool isSunday;

  final Color futureColor;
  final Color neutralColor;
  final Color currentColor;
  final Color currentBorderColor;
  final Color selectedBorderColor;

  Color _getScoreColor(double score) {
    final normalized = score.clamp(0.0, 1.0);

    if (normalized <= 0.5) {
      return Color.lerp(
        Colors.red.shade400,
        Colors.yellow.shade600,
        normalized * 2,
      )!;
    }

    return Color.lerp(
      Colors.yellow.shade600,
      Colors.green.shade500,
      (normalized - 0.5) * 2,
    )!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..isAntiAlias = true;

    final stride = cellSize + cellGap;
    final radius = Radius.circular(
      math.max(1.5, cellSize * 0.2),
    );

    for (var index = 0; index < totalWeeks; index++) {
      final row = index ~/ weeksPerRow;
      final column = index % weeksPerRow;

      final rect = Rect.fromLTWH(
        padding + column * stride,
        padding + row * stride,
        cellSize,
        cellSize,
      );

      final isCurrent = index == currentWeekIndex;
      final isSelected = index == selectedWeekIndex;
      final isFuture = index > currentWeekIndex;
      final isBeforeTracking = index < trackingStartWeekIndex;

      if (isCurrent && isSunday) {
        fillPaint.color = currentBorderColor;
      } else if (isCurrent) {
        fillPaint.color = currentColor;
      } else if (isFuture) {
        fillPaint.color = futureColor;
      } else if (isBeforeTracking) {
        fillPaint.color = neutralColor;
      } else {
        final score = weeklyScores[index];

        fillPaint.color = score == null
            ? neutralColor
            : _getScoreColor(score);
      }

      final rrect = RRect.fromRectAndRadius(
        rect,
        radius,
      );

      canvas.drawRRect(rrect, fillPaint);

      if (isCurrent || isSelected) {
        borderPaint.color = isSelected
            ? selectedBorderColor
            : currentBorderColor;

        borderPaint.strokeWidth = isSelected ? 2.2 : 1.5;

        canvas.drawRRect(rrect, borderPaint);
      }
    }
  }

  @override
  bool shouldRepaint(
      covariant _LifeCalendarPainter oldDelegate,
      ) {
    return totalWeeks != oldDelegate.totalWeeks ||
        selectedWeekIndex != oldDelegate.selectedWeekIndex ||
        currentWeekIndex != oldDelegate.currentWeekIndex ||
        trackingStartWeekIndex !=
            oldDelegate.trackingStartWeekIndex ||
        !identical(weeklyScores, oldDelegate.weeklyScores) ||
        isSunday != oldDelegate.isSunday ||
        futureColor != oldDelegate.futureColor ||
        neutralColor != oldDelegate.neutralColor ||
        currentColor != oldDelegate.currentColor ||
        currentBorderColor != oldDelegate.currentBorderColor ||
        selectedBorderColor != oldDelegate.selectedBorderColor;
  }
}

class _WeekDetailsBottomSheet extends StatelessWidget {
  const _WeekDetailsBottomSheet({
    required this.weekIndex,
    required this.weekStart,
  });

  final int weekIndex;
  final DateTime weekStart;

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day.$month.${date.year}';
  }

  Future<void> _showReviewEditor({
    required BuildContext context,
    required LifeCalendarCubit cubit,
    required WeeklyReviewData? existingReview,
  }) async {
    final controller = TextEditingController(
      text: existingReview?.description ?? '',
    );

    var rating = existingReview?.rating ?? 5;

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          var isSaving = false;

          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Text(
                  existingReview == null
                      ? 'Новый отзыв о неделе'
                      : 'Редактирование отзыва',
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Оценка недели: $rating / 10'),
                      Slider(
                        value: rating.toDouble(),
                        min: 1,
                        max: 10,
                        divisions: 9,
                        label: rating.toString(),
                        onChanged: isSaving
                            ? null
                            : (value) {
                          setDialogState(() {
                            rating = value.round();
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: controller,
                        enabled: !isSaving,
                        maxLines: 5,
                        minLines: 3,
                        maxLength: 1000,
                        decoration: const InputDecoration(
                          labelText: 'Описание',
                          hintText: 'Как прошла эта неделя?',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isSaving
                        ? null
                        : () {
                      Navigator.of(dialogContext).pop();
                    },
                    child: const Text('Отмена'),
                  ),
                  FilledButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                      setDialogState(() {
                        isSaving = true;
                      });

                      try {
                        await cubit.saveWeeklyReview(
                          weekIndex: weekIndex,
                          rating: rating,
                          description: controller.text.trim(),
                        );

                        if (dialogContext.mounted) {
                          Navigator.of(dialogContext).pop();
                        }
                      } catch (error) {
                        if (!dialogContext.mounted) return;

                        setDialogState(() {
                          isSaving = false;
                        });

                        ScaffoldMessenger.of(dialogContext)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(
                              content: Text(error.toString()),
                            ),
                          );
                      }
                    },
                    child: isSaving
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                        : const Text('Сохранить'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Material(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
          clipBehavior: Clip.antiAlias,
          child: BlocBuilder<LifeCalendarCubit, LifeCalendarState>(
            builder: (context, state) {
              if (state is! LifeCalendarLoaded) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final cubit = context.read<LifeCalendarCubit>();

              final productivity =
                  state.weeklyProductivity[weekIndex] ??
                      WeekProductivity.empty;

              final review = state.weeklyReviews[weekIndex];

              final canAddReview =
              cubit.canAddWeeklyReview(weekIndex);

              final weekEnd = weekStart.add(
                const Duration(days: 6),
              );

              return SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .outlineVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Неделя ${weekIndex + 1}',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${_formatDate(weekStart)} — '
                          '${_formatDate(weekEnd)}',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Продуктивность',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium,
                    ),
                    const SizedBox(height: 16),

                    if (!productivity.hasData)
                      const Text(
                        'За эту неделю пока нет данных '
                            'о привычках и задачах.',
                      )
                    else ...[
                      _ProgressRow(
                        title: 'Привычки',
                        completed: productivity.completedHabits,
                        total:
                        productivity.totalHabitOpportunities,
                        progress: productivity.habitProgress,
                      ),
                      const SizedBox(height: 18),
                      _ProgressRow(
                        title: 'Задачи',
                        completed: productivity.completedTasks,
                        total: productivity.totalTasks,
                        progress: productivity.taskProgress,
                      ),
                      const SizedBox(height: 18),
                      _ProgressRow(
                        title: 'Общий результат',
                        completed: productivity.completedHabits +
                            productivity.completedTasks,
                        total:
                        productivity.totalHabitOpportunities +
                            productivity.totalTasks,
                        progress: productivity.overallProgress,
                      ),
                    ],

                    const SizedBox(height: 28),
                    const Divider(),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Отзыв о неделе',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium,
                          ),
                        ),
                        if (review != null)
                          Text(
                            '${review.rating}/10',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (review != null) ...[
                      Text(
                        review.description.trim().isEmpty
                            ? 'Описание отсутствует.'
                            : review.description,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium,
                      ),
                      const SizedBox(height: 16),
                    ] else
                      Text(
                        canAddReview
                            ? 'Ты можешь добавить отзыв об этой неделе.'
                            : 'Отзыв можно добавить после завершения недели.',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),

                    if (canAddReview)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            _showReviewEditor(
                              context: context,
                              cubit: cubit,
                              existingReview: review,
                            );
                          },
                          icon: Icon(
                            review == null
                                ? Icons.add
                                : Icons.edit,
                          ),
                          label: Text(
                            review == null
                                ? 'Добавить отзыв'
                                : 'Изменить отзыв',
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.title,
    required this.completed,
    required this.total,
    required this.progress,
  });

  final String title;
  final int completed;
  final int total;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final percentage = (progress * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            Text(
              '$completed / $total',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '$percentage%',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest,
          ),
        ),
      ],
    );
  }
}