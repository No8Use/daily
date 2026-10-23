
import 'dart:math' as math;

import 'package:daily/data/database/app_database.dart';
import 'package:daily/utils/app_theme.dart';
import 'package:daily/utils/date_utils.dart';
import 'package:flutter/material.dart';

class TaskCard extends StatefulWidget {
  const TaskCard({
    required this.task,
    required this.date,
    required this.onChanged,
    this.onEdit,
    this.onLockedTap,
    super.key,
  });

  final Task task;
  final DateTime date;

  /// Persists the new completion state.
  final Future<void> Function(bool isCompleted) onChanged;

  /// Opens the task editor.
  final VoidCallback? onEdit;

  /// Called when a past task is tapped.
  final VoidCallback? onLockedTap;

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard>
    with SingleTickerProviderStateMixin {
  late bool _isCompleted;
  bool _isSaving = false;
  bool _isWaveAnimating = false;

  Offset? _tapPosition;

  late final AnimationController _waveController;
  late final Animation<double> _waveAnimation;

  bool get _isPastDay {
    final date = AppDateUtils.normalizeDate(widget.date);
    final today = AppDateUtils.normalizeDate(AppDateUtils.today);

    return date.isBefore(today);
  }

  Color get _accentColor {
    if (_isCompleted) return AppColors.primary;
    if (_isPastDay) return AppColors.error;

    return AppColors.textSecondary;
  }

  Color get _backgroundColor {
    if (_isCompleted) {
      return AppColors.primary.withValues(alpha: 0.10);
    }

    if (_isPastDay) {
      return AppColors.error.withValues(alpha: 0.09);
    }

    return AppColors.cardBackground;
  }

  @override
  void initState() {
    super.initState();

    _isCompleted = widget.task.isCompleted;

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );

    _waveAnimation = CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeOutCubic,
    );

    _waveController.addStatusListener(_onWaveStatusChanged);
  }

  void _onWaveStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      setState(() => _isWaveAnimating = false);
    }
  }

  @override
  void didUpdateWidget(covariant TaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.task.isCompleted != widget.task.isCompleted &&
        !_isSaving) {
      _isCompleted = widget.task.isCompleted;
    }
  }

  @override
  void dispose() {
    _waveController.removeStatusListener(_onWaveStatusChanged);
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_isSaving) return;

    if (_isPastDay) {
      widget.onLockedTap?.call();
      return;
    }

    final previousValue = _isCompleted;
    final nextValue = !previousValue;

    if (nextValue) {
      // Start the green wave from the actual tap position.
      _waveController.stop();
      _waveController.value = 0;

      setState(() {
        _isCompleted = true;
        _isSaving = true;
        _isWaveAnimating = true;
      });

      _waveController.forward();
    } else {
      _waveController.stop();

      setState(() {
        _isCompleted = false;
        _isSaving = true;
        _isWaveAnimating = false;
      });
    }

    try {
      await widget.onChanged(nextValue);
    } catch (_) {
      if (!mounted) return;

      _waveController.stop();

      setState(() {
        _isCompleted = previousValue;
        _isWaveAnimating = false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Не удалось сохранить изменение.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _accentColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: AnimatedScale(
        scale: _isCompleted ? 0.99 : 1,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            _tapPosition = details.localPosition;
          },
          onTap: _toggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: _isWaveAnimating
                  ? AppColors.cardBackground
                  : _backgroundColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                children: [
                  // Expanding green circle, clipped to the card.
                  if (_isWaveAnimating && _tapPosition != null)
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _waveAnimation,
                        builder: (context, child) {
                          return ClipPath(
                            clipper: _WaveClipper(
                              center: _tapPosition!,
                              progress: _waveAnimation.value,
                            ),
                            child: child,
                          );
                        },
                        child: ColoredBox(
                          color: AppColors.primary.withValues(alpha: 0.15),
                        ),
                      ),
                    ),

                  // Card content.
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: 27,
                          height: 27,
                          decoration: BoxDecoration(
                            color: _isCompleted
                                ? AppColors.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(
                              color: accentColor,
                              width: 1.6,
                            ),
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            transitionBuilder: (child, animation) {
                              return ScaleTransition(
                                scale: animation,
                                child: child,
                              );
                            },
                            child: _isCompleted
                                ? const Icon(
                              Icons.check_rounded,
                              key: ValueKey('checked'),
                              color: Colors.black,
                              size: 20,
                            )
                                : const SizedBox(
                              key: ValueKey('unchecked'),
                              width: 20,
                              height: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 220),
                                style: TextStyle(
                                  color: _isCompleted
                                      ? AppColors.textSecondary
                                      : AppColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  decoration: _isCompleted
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                  decorationColor: AppColors.primary,
                                ),
                                child: Text(widget.task.title),
                              ),
                              if (widget.task.description != null &&
                                  widget.task.description!
                                      .trim()
                                      .isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  widget.task.description!,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                              if (_isPastDay && !_isCompleted) ...[
                                const SizedBox(height: 5),
                                const Text(
                                  'День завершён',
                                  style: TextStyle(
                                    color: AppColors.error,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Edit button replaces the redundant right checkbox.
                        if (!_isPastDay && widget.onEdit != null) ...[
                          const SizedBox(width: 4),
                          IconButton(
                            tooltip: 'Редактировать задачу',
                            visualDensity: VisualDensity.compact,
                            constraints: const BoxConstraints(
                              minWidth: 40,
                              minHeight: 40,
                            ),
                            onPressed: _isSaving ? null : widget.onEdit,
                            icon: const Icon(
                              Icons.edit_outlined,
                              size: 19,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WaveClipper extends CustomClipper<Path> {
  const _WaveClipper({
    required this.center,
    required this.progress,
  });

  final Offset center;
  final double progress;

  @override
  Path getClip(Size size) {
    final dx = math.max(center.dx, size.width - center.dx);
    final dy = math.max(center.dy, size.height - center.dy);

    // Distance from the tap point to the farthest corner.
    final maxRadius = math.sqrt(dx * dx + dy * dy);
    final radius = maxRadius * progress;

    return Path()
      ..addOval(
        Rect.fromCircle(
          center: center,
          radius: radius,
        ),
      );
  }

  @override
  bool shouldReclip(covariant _WaveClipper oldClipper) {
    return oldClipper.center != center ||
        oldClipper.progress != progress;
  }
}
