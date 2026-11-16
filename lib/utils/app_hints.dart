
import 'dart:async';

import 'package:daily/utils/app_theme.dart';
import 'package:flutter/material.dart';

enum AppHintType {
  info,
  success,
  warning,
  error,
}

class AppHints {
  AppHints._();

  static OverlayEntry? _activeEntry;
  static Timer? _dismissTimer;

  /// Shows a configurable notification at the bottom of the screen.
  static void show(
      BuildContext context, {
        String? title,
        required String message,
        AppHintType type = AppHintType.info,
        IconData? icon,
        Duration duration = const Duration(seconds: 3),
        String? actionLabel,
        VoidCallback? onAction,
      }) {
    _removeActiveHint();

    final overlay = Overlay.of(context, rootOverlay: true);

    late final OverlayEntry entry;

    entry = OverlayEntry(
      builder: (overlayContext) {
        final bottomInset = MediaQuery.of(overlayContext).padding.bottom;

        return Positioned(
          left: 16,
          right: 16,
          bottom: bottomInset + 24,
          child: SafeArea(
            top: false,
            child: Material(
              color: Colors.transparent,
              child: _AppHintCard(
                title: title,
                message: message,
                type: type,
                icon: icon,
                actionLabel: actionLabel,
                onAction: onAction,
                onClose: () => _removeEntry(entry),
              ),
            ),
          ),
        );
      },
    );

    _activeEntry = entry;
    overlay.insert(entry);

    if (duration > Duration.zero) {
      _dismissTimer = Timer(
        duration,
            () => _removeEntry(entry),
      );
    }
  }

  static void showInfo(
      BuildContext context, {
        String? title,
        required String message,
        Duration duration = const Duration(seconds: 3),
      }) {
    show(
      context,
      title: title,
      message: message,
      type: AppHintType.info,
      duration: duration,
    );
  }

  static void showSuccess(
      BuildContext context, {
        String? title,
        required String message,
        Duration duration = const Duration(seconds: 3),
      }) {
    show(
      context,
      title: title ?? 'Успешно',
      message: message,
      type: AppHintType.success,
      duration: duration,
    );
  }

  static void showWarning(
      BuildContext context, {
        String? title,
        required String message,
        Duration duration = const Duration(seconds: 3),
      }) {
    show(
      context,
      title: title ?? 'Внимание',
      message: message,
      type: AppHintType.warning,
      duration: duration,
    );
  }

  static void showError(
      BuildContext context, {
        String? title,
        required String message,
        Duration duration = const Duration(seconds: 4),
      }) {
    show(
      context,
      title: title ?? 'Ошибка',
      message: message,
      type: AppHintType.error,
      duration: duration,
    );
  }

  /// Keeps the existing API used by screens.
  static void showPastDayHint(BuildContext context) {
    showWarning(
      context,
      title: 'Прошлый день',
      message: 'Состояние задач и привычек прошлого изменить нельзя',
      duration: const Duration(seconds: 3),
    );
  }

  static void _removeActiveHint() {
    _dismissTimer?.cancel();
    _dismissTimer = null;

    final entry = _activeEntry;
    _activeEntry = null;

    if (entry != null && entry.mounted) {
      entry.remove();
    }
  }

  static void _removeEntry(OverlayEntry entry) {
    if (identical(_activeEntry, entry)) {
      _dismissTimer?.cancel();
      _dismissTimer = null;
      _activeEntry = null;
    }

    if (entry.mounted) {
      entry.remove();
    }
  }
}

class _AppHintCard extends StatefulWidget {
  const _AppHintCard({
    required this.message,
    required this.type,
    required this.onClose,
    this.title,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String? title;
  final String message;
  final AppHintType type;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onClose;

  @override
  State<_AppHintCard> createState() => _AppHintCardState();
}

class _AppHintCardState extends State<_AppHintCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  Color get _accentColor {
    switch (widget.type) {
      case AppHintType.info:
        return AppColors.primary;
      case AppHintType.success:
        return Colors.green;
      case AppHintType.warning:
        return Colors.orange;
      case AppHintType.error:
        return AppColors.error;
    }
  }

  IconData get _icon {
    if (widget.icon != null) return widget.icon!;

    switch (widget.type) {
      case AppHintType.info:
        return Icons.info_outline_rounded;
      case AppHintType.success:
        return Icons.check_circle_outline_rounded;
      case AppHintType.warning:
        return Icons.warning_amber_rounded;
      case AppHintType.error:
        return Icons.error_outline_rounded;
    }
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _accentColor.withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 8, 13),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    _icon,
                    color: _accentColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.title != null) ...[
                        Text(
                          widget.title!,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 3),
                      ],
                      Text(
                        widget.message,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      if (widget.actionLabel != null &&
                          widget.onAction != null) ...[
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: widget.onAction,
                            style: TextButton.styleFrom(
                              foregroundColor: _accentColor,
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 32),
                              tapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(widget.actionLabel!),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  onPressed: widget.onClose,
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Закрыть',
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textSecondary,
                    size: 19,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
