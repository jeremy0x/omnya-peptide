import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import '../theme/omnya_colors.dart';
import '../theme/omnya_typography.dart';

enum OmnyaToastType {
  success,
  info,
  warning,
  error,
}

class OmnyaToast {
  static OverlayEntry? _activeEntry;
  static _OmnyaToastState? _activeState;

  /// Show a morphing floating toast notification matching Toastiva aesthetics.
  static void show(
    BuildContext context, {
    required String title,
    String? message,
    OmnyaToastType type = OmnyaToastType.success,
    Widget? customIcon,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(milliseconds: 3200),
    bool showProgress = true,
  }) {
    // Dismiss existing toast if active
    dismiss();

    final overlay = Overlay.maybeOf(context, rootOverlay: true) ?? Overlay.of(context);

    // Haptic feedback upon appearance
    HapticFeedback.lightImpact();

    late OverlayEntry entry;
    final stateKey = GlobalKey<_OmnyaToastState>();

    entry = OverlayEntry(
      builder: (context) {
        return _OmnyaToastWidget(
          key: stateKey,
          title: title,
          message: message,
          type: type,
          customIcon: customIcon,
          actionLabel: actionLabel,
          onAction: onAction,
          duration: duration,
          showProgress: showProgress,
          onDismissed: () {
            if (_activeEntry == entry) {
              entry.remove();
              _activeEntry = null;
              _activeState = null;
            }
          },
        );
      },
    );

    _activeEntry = entry;
    overlay.insert(entry);
  }

  /// Manually dismiss the active toast with animation
  static void dismiss() {
    _activeState?.dismiss();
    _activeEntry?.remove();
    _activeEntry = null;
    _activeState = null;
  }
}

class _OmnyaToastWidget extends StatefulWidget {
  final String title;
  final String? message;
  final OmnyaToastType type;
  final Widget? customIcon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Duration duration;
  final bool showProgress;
  final VoidCallback onDismissed;

  const _OmnyaToastWidget({
    super.key,
    required this.title,
    this.message,
    required this.type,
    this.customIcon,
    this.actionLabel,
    this.onAction,
    required this.duration,
    required this.showProgress,
    required this.onDismissed,
  });

  @override
  State<_OmnyaToastWidget> createState() => _OmnyaToastState();
}

class _OmnyaToastState extends State<_OmnyaToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  double _dragOffsetY = 0.0;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    OmnyaToast._activeState = this;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _scaleAnimation = Tween<double>(begin: 0.90, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const ElasticOutCurve(0.9),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.45),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _controller.forward();

    // Auto dismiss after duration
    Future.delayed(widget.duration, () {
      if (mounted && !_isDismissing) {
        dismiss();
      }
    });
  }

  void dismiss() {
    if (_isDismissing) return;
    _isDismissing = true;
    _controller.reverse(from: _controller.value).then((_) {
      if (mounted) {
        widget.onDismissed();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    if (OmnyaToast._activeState == this) {
      OmnyaToast._activeState = null;
    }
    super.dispose();
  }

  Color _getAccentColor(bool isDark) {
    switch (widget.type) {
      case OmnyaToastType.success:
        return OmnyaColors.sage;
      case OmnyaToastType.warning:
        return const Color(0xFFE5A93C);
      case OmnyaToastType.error:
        return const Color(0xFFEF4444);
      case OmnyaToastType.info:
        return isDark ? OmnyaColors.plumSoft : OmnyaColors.plum;
    }
  }

  Widget _buildIcon(Color accentColor, bool isDark) {
    if (widget.customIcon != null) {
      return widget.customIcon!;
    }

    final dynamic iconData;
    switch (widget.type) {
      case OmnyaToastType.success:
        iconData = HugeIcons.strokeRoundedCheckmarkCircle02;
        break;
      case OmnyaToastType.warning:
        iconData = HugeIcons.strokeRoundedAlertCircle;
        break;
      case OmnyaToastType.error:
        iconData = HugeIcons.strokeRoundedCancel01;
        break;
      case OmnyaToastType.info:
        iconData = HugeIcons.strokeRoundedSparkles;
        break;
    }

    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: isDark ? 0.22 : 0.12),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: HugeIcon(
        icon: iconData,
        size: 15,
        color: accentColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = _getAccentColor(isDark);

    return Positioned(
      top: topPadding + 14 + _dragOffsetY,
      left: 16,
      right: 16,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Material(
            type: MaterialType.transparency,
            child: GestureDetector(
            onVerticalDragUpdate: (details) {
              if (details.primaryDelta != null && details.primaryDelta! < 0) {
                setState(() {
                  _dragOffsetY += details.primaryDelta!;
                });
              }
            },
            onVerticalDragEnd: (details) {
              if (_dragOffsetY < -15 || (details.primaryVelocity ?? 0) < -200) {
                HapticFeedback.lightImpact();
                dismiss();
              } else {
                setState(() {
                  _dragOffsetY = 0.0;
                });
              }
            },
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: child,
                    ),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1B1816).withValues(alpha: 0.94)
                          : OmnyaColors.cream.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF38322B).withValues(alpha: 0.85)
                            : OmnyaColors.taupe.withValues(alpha: 0.28),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.09),
                          blurRadius: 26,
                          offset: const Offset(0, 10),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                          child: Row(
                            children: [
                              _buildIcon(accentColor, isDark),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.title,
                                      style: OmnyaTypography.label(
                                        color: isDark ? OmnyaColors.cream : OmnyaColors.charcoal,
                                        weight: FontWeight.w600,
                                      ),
                                    ),
                                    if (widget.message != null) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        widget.message!,
                                        style: OmnyaTypography.bodySmall(
                                          color: isDark
                                              ? OmnyaColors.sandMuted
                                              : OmnyaColors.charcoalMuted,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (widget.actionLabel != null && widget.onAction != null) ...[
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    widget.onAction?.call();
                                    dismiss();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF2C2723)
                                          : OmnyaColors.sand.withValues(alpha: 0.7),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isDark
                                            ? const Color(0xFF423B35)
                                            : OmnyaColors.taupe.withValues(alpha: 0.3),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      widget.actionLabel!,
                                      style: OmnyaTypography.label(
                                        color: isDark ? OmnyaColors.cream : OmnyaColors.charcoal,
                                        weight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Bottom countdown progress bar
                        if (widget.showProgress)
                          _ToastCountdownBar(
                            duration: widget.duration,
                            accentColor: accentColor,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
}

class _ToastCountdownBar extends StatefulWidget {
  final Duration duration;
  final Color accentColor;

  const _ToastCountdownBar({
    required this.duration,
    required this.accentColor,
  });

  @override
  State<_ToastCountdownBar> createState() => _ToastCountdownBarState();
}

class _ToastCountdownBarState extends State<_ToastCountdownBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progressController,
      builder: (context, _) {
        final progress = 1.0 - _progressController.value;
        return Container(
          height: 2,
          alignment: Alignment.centerLeft,
          color: widget.accentColor.withValues(alpha: 0.1),
          child: FractionallySizedBox(
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              color: widget.accentColor.withValues(alpha: 0.65),
            ),
          ),
        );
      },
    );
  }
}
