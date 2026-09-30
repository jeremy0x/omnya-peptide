import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/omnya_colors.dart';
import '../theme/omnya_typography.dart';

enum TactileButtonVariant { primary, secondary, outline, ghost }

class TactileButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final TactileButtonVariant variant;
  final Widget? leading;
  final Widget? trailing;
  final double? width;
  final double height;
  final double borderRadius;
  final bool isLoading;

  const TactileButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = TactileButtonVariant.primary,
    this.leading,
    this.trailing,
    this.width,
    this.height = 52.0,
    this.borderRadius = 16.0,
    this.isLoading = false,
  });

  @override
  State<TactileButton> createState() => _TactileButtonState();
}

class _TactileButtonState extends State<TactileButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 140),
    );
    // Design system rule: Scale precisely to 0.96 for optimal tactile feedback
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed == null || widget.isLoading) return;
    HapticFeedback.lightImpact();
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed == null || widget.isLoading) return;
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg;
    Color fg;
    Border? border;

    switch (widget.variant) {
      case TactileButtonVariant.primary:
        bg = isDark ? OmnyaColors.plumSoft : OmnyaColors.plum;
        fg = OmnyaColors.cream;
        break;
      case TactileButtonVariant.secondary:
        bg = isDark ? const Color(0xFF2E2B29) : OmnyaColors.sand;
        fg = isDark ? OmnyaColors.cream : OmnyaColors.charcoal;
        break;
      case TactileButtonVariant.outline:
        bg = Colors.transparent;
        fg = isDark ? OmnyaColors.cream : OmnyaColors.charcoal;
        border = Border.all(
          color: isDark ? const Color(0x33FFFFFF) : OmnyaColors.taupe,
          width: 1.0,
        );
        break;
      case TactileButtonVariant.ghost:
        bg = Colors.transparent;
        fg = isDark ? OmnyaColors.taupe : OmnyaColors.charcoalMuted;
        break;
    }

    final isEnabled = widget.onPressed != null && !widget.isLoading;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: GestureDetector(
        onTapDown: isEnabled ? _onTapDown : null,
        onTapUp: isEnabled ? _onTapUp : null,
        onTapCancel: isEnabled ? _onTapCancel : null,
        onTap: isEnabled ? widget.onPressed : null,
        behavior: HitTestBehavior.opaque,
        child: Opacity(
          opacity: isEnabled ? 1.0 : 0.45,
          child: Container(
            width: widget.width,
            height: widget.height,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: border,
              boxShadow: widget.variant == TactileButtonVariant.primary
                  ? [
                      BoxShadow(
                        color: bg.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize:
                  widget.width == null ? MainAxisSize.min : MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.isLoading) ...[
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(fg),
                    ),
                  ),
                ] else ...[
                  if (widget.leading != null) ...[
                    widget.leading!,
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      widget.label,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: OmnyaTypography.label(
                        color: fg,
                        weight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (widget.trailing != null) ...[
                    const SizedBox(width: 8),
                    widget.trailing!,
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
