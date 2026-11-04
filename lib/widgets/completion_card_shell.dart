
import 'dart:math';

import 'package:daily/utils/app_hints.dart';
import 'package:daily/utils/card_done_patterns.dart';
import 'package:daily/utils/date_utils.dart';
import 'package:daily/utils/models/operation_result.dart';
import 'package:daily/utils/service_locator.dart';
import 'package:flutter/material.dart';

class CompletionCardShell extends StatefulWidget {
  const CompletionCardShell({
    required this.initialCompleted,
    required this.date,
    required this.onChanged,
    required this.childBuilder,
    this.onLockedTap,
    this.doneStyle = false,
    super.key,
  });

  final bool initialCompleted;
  final DateTime date;
  final Future<OperationResult> Function(bool previousState) onChanged;
  final Widget Function(
      BuildContext context,
      bool isCompleted,
      bool isSaving,
      ) childBuilder;
  final VoidCallback? onLockedTap;
  final bool doneStyle;

  @override
  State<CompletionCardShell> createState() => _CompletionCardShellState();
}

class _CompletionCardShellState extends State<CompletionCardShell>
    with SingleTickerProviderStateMixin {
  static const _strokeColor = Color(0xFF32E653);

  late bool _completed;
  late final AnimationController _controller;
  late final int _strokePattern;

  bool _saving = false;
  bool _animating = false;
  bool _drawing = true;

  bool get _pastDay =>
      AppDateUtils.normalizeDate(widget.date)
          .isBefore(AppDateUtils.today);

  @override
  void initState() {
    super.initState();
    _completed = widget.initialCompleted;
    _strokePattern = getIt<Random>().nextInt(8); // change 8 is CardDonePatterns.patterns.length will change

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..addStatusListener(_onAnimationStatus);
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      setState(() {
        _animating = false;
      });
    }
  }

  @override
  void didUpdateWidget(covariant CompletionCardShell oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initialCompleted != widget.initialCompleted &&
        !_saving &&
        !_animating) {
      _completed = widget.initialCompleted;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_saving || _animating) return;

    if (_pastDay) {
      widget.onLockedTap?.call();
      return;
    }

    final previous = _completed;
    final next = !previous;

    setState(() {
      _saving = true;
      _animating = true;
      _drawing = next;
      _completed = next;
    });

    _controller.forward(from: 0);

    String? error;

    try {
      final result = await widget.onChanged(previous);
      if (!result.ok) {
        error = result.error ?? 'Не удалось сохранить изменение.';
      }
    } catch (e) {
      error = 'Не удалось сохранить изменение: $e';
    }

    if (!mounted) return;

    if (error != null) {
      _controller.stop();
      setState(() {
        _completed = previous;
        _animating = false;
      });

      AppHints.showError(
        context,
        title: 'Не удалось сохранить изменение',
        message: error,
      );
    }

    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggle,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final progress = _animating ? _controller.value : 1.0;

            return ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF181818),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _completed
                            ? _strokeColor.withValues(alpha: 0.35)
                            : Colors.white12,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: widget.childBuilder(
                      context,
                      _completed,
                      _saving,
                    ),
                  ),

                  // Completed: permanent stroke.
                  // Completing: reveal left to right.
                  // Undoing: erase from right to left.
                  if (_completed || _animating)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _HandStrokePainter(
                            progress: _animating
                                ? (_drawing ? progress : 1 - progress)
                                : 1,
                            color: _strokeColor,
                            pattern: _strokePattern
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HandStrokePainter extends CustomPainter {
  const _HandStrokePainter({
    required this.progress,
    required this.color,
    required this.pattern,
  });

  final double progress;
  final Color color;
  final int pattern;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || progress <= 0) return;

    final points = CardDonePatterns.patterns[pattern];

    final path = Path()
      ..moveTo(
        points.first.dx * size.width,
        points.first.dy * size.height,
      );

    for (var i = 1; i < points.length; i++) {
      final previous = points[i - 1];
      final current = points[i];

      final midpoint = Offset(
        (previous.dx + current.dx) * size.width / 2,
        (previous.dy + current.dy) * size.height / 2,
      );

      path.quadraticBezierTo(
        previous.dx * size.width,
        previous.dy * size.height,
        midpoint.dx,
        midpoint.dy,
      );
    }

    path.lineTo(
      points.last.dx * size.width,
      points.last.dy * size.height,
    );

    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;

    final metric = metrics.first;
    final visiblePath = metric.extractPath(
      0,
      metric.length * progress.clamp(0.0, 1.0),
    );

    final paint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (size.height * 0.154).clamp(7.0, 14.0)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(visiblePath, paint);
  }

  @override
  bool shouldRepaint(covariant _HandStrokePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.pattern != pattern;
  }
}
