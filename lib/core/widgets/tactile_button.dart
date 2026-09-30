import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/omnya_colors.dart';
import '../theme/omnya_typography.dart';
import 'omnya_logo.dart';

/// [onDark] is the cream button for plum surfaces.
enum TactileButtonVariant { primary, secondary, outline, ghost, onDark }

/// Pill button that presses in to 0.96 with a light haptic.
class TactileButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final TactileButtonVariant variant;
  final Widget? leading;
  final double? width;
  final double height;
  final bool isLoading;

  const TactileButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = TactileButtonVariant.primary,
    this.leading,
    this.width,
    this.height = 44,
    this.isLoading = false,
  });

  @override
  State<TactileButton> createState() => _TactileButtonState();
}

class _TactileButtonState extends State<TactileButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100),
    reverseDuration: const Duration(milliseconds: 140),
  );
  late final Animation<double> _scale = Tween<double>(
    begin: 1,
    end: 0.96,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _enabled => widget.onPressed != null && !widget.isLoading;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (widget.variant) {
      TactileButtonVariant.primary => (OmnyaColors.plum, OmnyaColors.cream, null),
      TactileButtonVariant.secondary => (OmnyaColors.sandMuted, OmnyaColors.charcoal, null),
      TactileButtonVariant.outline => (Colors.transparent, OmnyaColors.charcoal, Border.all(color: OmnyaColors.taupe)),
      TactileButtonVariant.ghost => (Colors.transparent, OmnyaColors.charcoalMuted, null),
      TactileButtonVariant.onDark => (OmnyaColors.cream, OmnyaColors.plum, null),
    };

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      excludeSemantics: true,
      child: ScaleTransition(
        scale: _scale,
        child: GestureDetector(
          onTapDown: _enabled
              ? (_) {
                  HapticFeedback.lightImpact();
                  _controller.forward();
                }
              : null,
          onTapUp: _enabled ? (_) => _controller.reverse() : null,
          onTapCancel: _enabled ? _controller.reverse : null,
          onTap: _enabled ? widget.onPressed : null,
          behavior: HitTestBehavior.opaque,
          child: AnimatedOpacity(
            opacity: _enabled || widget.isLoading ? 1 : 0.45,
            duration: const Duration(milliseconds: 150),
            child: Container(
              width: widget.width,
              height: widget.height,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(widget.height / 2),
                border: border,
              ),
              child: Row(
                mainAxisSize: widget.width == null ? MainAxisSize.min : MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.isLoading)
                    OmnyaLogoLoader(size: 24, onDark: widget.variant == TactileButtonVariant.primary)
                  else ...[
                    if (widget.leading != null) ...[widget.leading!, const SizedBox(width: 8)],
                    Flexible(
                      child: Text(
                        widget.label,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: OmnyaTypography.label(color: fg, weight: FontWeight.w600),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
